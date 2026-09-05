import { Injectable, Logger } from '@nestjs/common';

export interface ParsedSearchQuery {
  rawQuery: string;
  normalizedText: string;
  detectedSports: string[];
  maxPrice?: number;
  minPrice?: number;
  timeIntent?: 'NOW' | 'TONIGHT' | 'TOMORROW' | 'WEEKEND';
  rankingIntent?: 'NEARBY' | 'CHEAP' | 'BEST' | 'POPULAR' | 'AVAILABLE';
  amenities: string[];
  isIndoor?: boolean;
}

@Injectable()
export class QueryUnderstandingService {
  private readonly logger = new Logger(QueryUnderstandingService.name);

  private readonly SPORT_KEYWORDS: Record<string, string[]> = {
    cricket: ['cricket', 'box cricket', 'box-cricket', 'pitch', 'turf cricket'],
    football: ['football', 'futsal', 'soccer', 'turf football', '5v5', '7v7'],
    badminton: ['badminton', 'shuttle', 'court badminton', 'wooden court', 'synthetic court'],
    tennis: ['tennis', 'lawn tennis', 'clay court', 'hard court'],
    pickleball: ['pickleball', 'pickle ball'],
    basketball: ['basketball', 'hoop', 'dunk'],
    volleyball: ['volleyball', 'beach volleyball'],
    swimming: ['swimming', 'pool', 'swim'],
    table_tennis: ['table tennis', 'tt', 'ping pong'],
    squash: ['squash'],
  };

  private readonly AMENITY_KEYWORDS: Record<string, string[]> = {
    floodlights: ['floodlights', 'lights', 'night lighting', 'lighting'],
    parking: ['parking', 'car parking', 'parking available'],
    ac: ['ac', 'air conditioned', 'air conditioning', 'indoor ac'],
    shower: ['shower', 'changing room', 'restroom', 'washroom'],
    equipment: ['equipment', 'racket rental', 'bat rental', 'gear'],
  };

  /**
   * Deterministic query-understanding engine that normalizes raw input text
   * into structured domain intent (sports, pricing caps, time windows, and ranking intent).
   */
  parse(rawQuery?: string): ParsedSearchQuery {
    if (!rawQuery || !rawQuery.trim()) {
      return {
        rawQuery: '',
        normalizedText: '',
        detectedSports: [],
        amenities: [],
      };
    }

    const text = rawQuery.toLowerCase().trim();
    const detectedSports: string[] = [];
    const amenities: string[] = [];

    // 1. Detect Sports / Activities
    for (const [sport, keywords] of Object.entries(this.SPORT_KEYWORDS)) {
      if (keywords.some((kw) => text.includes(kw))) {
        detectedSports.push(sport);
      }
    }

    // 2. Detect Amenities & Indoor
    for (const [amenity, keywords] of Object.entries(this.AMENITY_KEYWORDS)) {
      if (keywords.some((kw) => text.includes(kw))) {
        amenities.push(amenity);
      }
    }
    const isIndoor = text.includes('indoor') || text.includes('wooden') || text.includes('ac');

    // 3. Detect Price Intent (e.g. "under 500", "below 800", "less than 600")
    let maxPrice: number | undefined = undefined;
    let minPrice: number | undefined = undefined;

    const underMatch = text.match(/(under|below|less than|<|cheap)\s*₹?\s*(\d+)/i);
    if (underMatch && underMatch[2]) {
      maxPrice = parseInt(underMatch[2], 10);
    }

    // 4. Detect Time Intent
    let timeIntent: 'NOW' | 'TONIGHT' | 'TOMORROW' | 'WEEKEND' | undefined = undefined;
    if (text.includes('now') || text.includes('currently')) {
      timeIntent = 'NOW';
    } else if (text.includes('tonight') || text.includes('evening')) {
      timeIntent = 'TONIGHT';
    } else if (text.includes('tomorrow')) {
      timeIntent = 'TOMORROW';
    } else if (text.includes('weekend')) {
      timeIntent = 'WEEKEND';
    }

    // 5. Detect Ranking Intent
    let rankingIntent: 'NEARBY' | 'CHEAP' | 'BEST' | 'POPULAR' | 'AVAILABLE' | undefined = undefined;
    if (text.includes('near me') || text.includes('nearby') || text.includes('closest')) {
      rankingIntent = 'NEARBY';
    } else if (text.includes('cheap') || text.includes('budget') || maxPrice !== undefined) {
      rankingIntent = 'CHEAP';
    } else if (text.includes('best') || text.includes('top rated') || text.includes('highest rated')) {
      rankingIntent = 'BEST';
    } else if (text.includes('popular') || text.includes('trending')) {
      rankingIntent = 'POPULAR';
    } else if (text.includes('available') || timeIntent !== undefined) {
      rankingIntent = 'AVAILABLE';
    }

    return {
      rawQuery,
      normalizedText: text,
      detectedSports,
      maxPrice,
      minPrice,
      timeIntent,
      rankingIntent,
      amenities,
      isIndoor,
    };
  }
}
