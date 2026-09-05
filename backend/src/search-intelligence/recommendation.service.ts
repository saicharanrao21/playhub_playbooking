import { Injectable, Logger, Optional } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { VenuesService } from '../venues/venues.service';
import { RankingScoringService } from './ranking-scoring.service';
import { CacheService } from '../redis/cache.service';
import { MetricsService } from '../observability/metrics.service';

export interface RecommendationSection {
  category: 'RECOMMENDED_FOR_YOU' | 'AVAILABLE_NOW' | 'POPULAR_NEAR_YOU' | 'BEST_VALUE';
  title: string;
  subtitle: string;
  items: any[];
}

@Injectable()
export class RecommendationService {
  private readonly logger = new Logger(RecommendationService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly venuesService: VenuesService,
    private readonly rankingScoringService: RankingScoringService,
    @Optional() private readonly cacheService?: CacheService,
    @Optional() private readonly metricsService?: MetricsService,
  ) {}

  /**
   * Generates contextual recommendation sections for customer discovery screens.
   */
  async getRecommendations(
    userId?: string,
    latitude = 17.4401,
    longitude = 78.3489,
    radius = 15.0,
  ): Promise<RecommendationSection[]> {
    const cacheKey = `recommendations:${userId || 'guest'}:${latitude.toFixed(2)}_${longitude.toFixed(2)}:${radius}`;

    if (this.cacheService) {
      const cached = await this.cacheService.get<RecommendationSection[]>(cacheKey);
      if (cached) {
        if (this.metricsService) {
          this.metricsService.cacheOperationsTotal.inc({ operation: 'get_rec', result: 'hit' });
        }
        return cached;
      }
    }

    // 1. Fetch Candidates nearby via VenuesService Haversine bounding box
    const nearby = await this.venuesService.findNearby({
      latitude,
      longitude,
      radius,
      skip: 0,
      limit: 30,
    } as any);

    const candidates = nearby.items || [];

    // 2. Fetch User History for Personalization (if authenticated)
    let userPreferences: { preferredSports: string[]; favoriteVenueIds: string[] } | undefined = undefined;

    if (userId) {
      userPreferences = await this.getUserPreferences(userId);
    }

    // 3. Score candidates
    const ranked = this.rankingScoringService.rankCandidates(
      candidates,
      { rawQuery: '', normalizedText: '', detectedSports: [], amenities: [] },
      userPreferences,
    );

    const sections: RecommendationSection[] = [];

    // Section 1: Recommended For You / Cold-Start Near You
    if (userPreferences && userPreferences.preferredSports.length > 0) {
      sections.push({
        category: 'RECOMMENDED_FOR_YOU',
        title: 'Recommended For You',
        subtitle: `Based on your favorite sports (${userPreferences.preferredSports.slice(0, 2).join(', ').toUpperCase()})`,
        items: ranked.slice(0, 6).map((r) => r.rawVenue),
      });
    } else {
      sections.push({
        category: 'POPULAR_NEAR_YOU',
        title: 'Popular Near You',
        subtitle: 'Top-rated sports venues in your area',
        items: ranked.slice(0, 6).map((r) => r.rawVenue),
      });
    }

    // Section 2: Available Court Slots Today
    const availableNowItems = ranked.filter((r) => r.hasOpenSlots).slice(0, 6).map((r) => r.rawVenue);
    if (availableNowItems.length > 0) {
      sections.push({
        category: 'AVAILABLE_NOW',
        title: 'Available Court Slots Today',
        subtitle: 'Instant booking available for today',
        items: availableNowItems,
      });
    }

    // Section 3: Best Value / Affordable Courts
    const bestValueItems = [...ranked]
      .sort((a, b) => a.minPrice - b.minPrice)
      .slice(0, 6)
      .map((r) => r.rawVenue);

    sections.push({
      category: 'BEST_VALUE',
      title: 'Best Value Courts',
      subtitle: 'Great facilities at affordable rates',
      items: bestValueItems,
    });

    if (this.cacheService) {
      this.cacheService.set(cacheKey, sections, 300).catch(() => {});
    }

    if (this.metricsService) {
      this.metricsService.cacheOperationsTotal.inc({ operation: 'get_rec', result: 'miss' });
    }

    return sections;
  }

  private async getUserPreferences(userId: string) {
    const userBookings = await this.prisma.booking.findMany({
      where: { userId, status: { in: ['CONFIRMED', 'CHECKED_IN', 'COMPLETED'] } },
      include: { facility: { include: { category: true, activity: true } } },
      orderBy: { createdAt: 'desc' },
      take: 20,
    });

    const sportsSet = new Set<string>();
    const favoriteVenuesSet = new Set<string>();

    for (const b of userBookings) {
      if (b.facility?.activity?.name) sportsSet.add(b.facility.activity.name.toLowerCase());
      if (b.facility?.category?.name) sportsSet.add(b.facility.category.name.toLowerCase());
      if (b.facility?.venueId) favoriteVenuesSet.add(b.facility.venueId);
    }

    return {
      preferredSports: Array.from(sportsSet),
      favoriteVenueIds: Array.from(favoriteVenuesSet),
    };
  }
}
