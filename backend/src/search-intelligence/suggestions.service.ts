import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export interface SearchSuggestionItem {
  type: 'SPORT' | 'VENUE' | 'LOCATION';
  text: string;
  subtitle?: string;
  id?: string;
}

@Injectable()
export class SuggestionsService {
  private readonly logger = new Logger(SuggestionsService.name);

  private readonly POPULAR_SPORTS = [
    'Cricket',
    'Football',
    'Badminton',
    'Tennis',
    'Pickleball',
    'Basketball',
    'Volleyball',
    'Swimming',
    'Table Tennis',
    'Squash',
  ];

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Fast autocomplete and deterministic search suggestions.
   */
  async getSuggestions(query?: string, cityId?: string): Promise<SearchSuggestionItem[]> {
    if (!query || !query.trim()) {
      // Default popular suggestions
      return [
        { type: 'SPORT', text: 'Cricket', subtitle: 'Box cricket & turfs' },
        { type: 'SPORT', text: 'Football', subtitle: '5v5 & 7v7 football turfs' },
        { type: 'SPORT', text: 'Badminton', subtitle: 'Indoor wooden & synthetic courts' },
        { type: 'SPORT', text: 'Pickleball', subtitle: 'Trending pickleball courts' },
      ];
    }

    const qLower = query.toLowerCase().trim();
    const suggestions: SearchSuggestionItem[] = [];

    // 1. Sport Suggestions
    for (const sport of this.POPULAR_SPORTS) {
      if (sport.toLowerCase().includes(qLower)) {
        suggestions.push({
          type: 'SPORT',
          text: sport,
          subtitle: `${sport} courts & turfs near you`,
        });
      }
    }

    // 2. Venue Name Autocomplete
    const matchingVenues = await this.prisma.venue.findMany({
      where: {
        status: 'ACTIVE',
        ...(cityId ? { cityId } : {}),
        name: { contains: query, mode: 'insensitive' as const },
      },
      select: { id: true, name: true, city: true, address: true },
      take: 5,
    });

    for (const v of matchingVenues) {
      suggestions.push({
        type: 'VENUE',
        id: v.id,
        text: v.name,
        subtitle: `${v.city || v.address || 'Sports Venue'}`,
      });
    }

    return suggestions.slice(0, 8);
  }
}
