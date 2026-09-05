import { Test, TestingModule } from '@nestjs/testing';
import { QueryUnderstandingService } from './query-understanding.service';
import { RankingScoringService } from './ranking-scoring.service';
import { SuggestionsService } from './suggestions.service';
import { PrismaService } from '../prisma/prisma.service';

describe('Search Intelligence & Recommendation Engine', () => {
  let queryUnderstandingService: QueryUnderstandingService;
  let rankingScoringService: RankingScoringService;
  let suggestionsService: SuggestionsService;

  const mockPrisma = {
    venue: { findMany: jest.fn() },
    booking: { findMany: jest.fn() },
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        QueryUnderstandingService,
        RankingScoringService,
        SuggestionsService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    queryUnderstandingService = module.get<QueryUnderstandingService>(QueryUnderstandingService);
    rankingScoringService = module.get<RankingScoringService>(RankingScoringService);
    suggestionsService = module.get<SuggestionsService>(SuggestionsService);
  });

  it('should parse freeform queries and extract sport, price cap, and ranking intent', () => {
    const query = 'cricket turf under 600 near me';
    const parsed = queryUnderstandingService.parse(query);

    expect(parsed.detectedSports).toContain('cricket');
    expect(parsed.maxPrice).toBe(600);
    expect(parsed.rankingIntent).toBe('NEARBY');
  });

  it('should rank venue candidates deterministically using weighted scoring formula', () => {
    const candidates = [
      {
        id: 'v1',
        name: 'Gachibowli Cricket Arena',
        distanceKm: 1.5,
        rating: 4.8,
        minPrice: 500,
        hasOpenSlots: true,
        facilities: [{ activity: { name: 'cricket' } }],
      },
      {
        id: 'v2',
        name: 'Far Away Court',
        distanceKm: 25.0,
        rating: 3.5,
        minPrice: 1200,
        hasOpenSlots: false,
        facilities: [{ activity: { name: 'tennis' } }],
      },
    ];

    const parsedQuery = queryUnderstandingService.parse('cricket turf');
    const ranked = rankingScoringService.rankCandidates(candidates, parsedQuery);

    expect(ranked).toHaveLength(2);
    expect(ranked[0].id).toBe('v1');
    expect(ranked[0].finalScore).toBeGreaterThan(ranked[1].finalScore);
    expect(ranked[0].relevanceBadges).toContain('Under 2 km');
  });

  it('should return autocomplete suggestions for search input', async () => {
    mockPrisma.venue.findMany.mockResolvedValue([
      { id: 'v1', name: 'Gachibowli Arena', city: 'Hyderabad', address: 'Main Rd' },
    ]);

    const suggestions = await suggestionsService.getSuggestions('bad');
    expect(suggestions.some((s) => s.text === 'Badminton')).toBe(true);
  });
});
