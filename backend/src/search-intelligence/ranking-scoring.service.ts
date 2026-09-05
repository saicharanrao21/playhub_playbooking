import { Injectable, Logger } from '@nestjs/common';
import { ParsedSearchQuery } from './query-understanding.service';

export interface ScoringWeights {
  textRelevance: number;     // Default 0.25
  activityMatch: number;     // Default 0.20
  locationDistance: number;  // Default 0.20
  availability: number;      // Default 0.15
  ratingQuality: number;     // Default 0.10
  priceCompetitiveness: number; // Default 0.05
  personalization: number;   // Default 0.05
}

export interface RankedVenueCandidate {
  id: string;
  name: string;
  description?: string;
  address?: string;
  city?: string;
  latitude?: number;
  longitude?: number;
  rating?: number;
  distanceMeters?: number;
  distanceKm?: number;
  minPrice?: number;
  hasOpenSlots?: boolean;
  sportsAvailable: string[];
  facilitiesCount: number;
  finalScore: number;
  scoreBreakdown: Record<string, number>;
  relevanceBadges: string[];
  rawVenue: any;
}

@Injectable()
export class RankingScoringService {
  private readonly logger = new Logger(RankingScoringService.name);

  private weights: ScoringWeights = {
    textRelevance: 0.25,
    activityMatch: 0.20,
    locationDistance: 0.20,
    availability: 0.15,
    ratingQuality: 0.10,
    priceCompetitiveness: 0.05,
    personalization: 0.05,
  };

  getWeights(): ScoringWeights {
    return { ...this.weights };
  }

  updateWeights(newWeights: Partial<ScoringWeights>) {
    this.weights = { ...this.weights, ...newWeights };
    this.logger.log(`Search ranking scoring weights updated: ${JSON.stringify(this.weights)}`);
    return this.weights;
  }

  /**
   * Evaluates and scores venue candidates deterministically based on intent signals,
   * distance, rating, price competitiveness, availability, and user preferences.
   */
  rankCandidates(
    candidates: any[],
    parsedQuery: ParsedSearchQuery,
    userPreferences?: { preferredSports?: string[]; favoriteVenueIds?: string[] },
  ): RankedVenueCandidate[] {
    const scoredList: RankedVenueCandidate[] = candidates.map((v) => {
      const badges: string[] = [];

      // 1. Text Relevance Score (0 - 100)
      let textScore = 50;
      if (parsedQuery.normalizedText) {
        const nameLower = (v.name || '').toLowerCase();
        const descLower = (v.description || '').toLowerCase();
        const addrLower = (v.address || '').toLowerCase();

        if (nameLower.includes(parsedQuery.normalizedText)) {
          textScore = 100;
          badges.push('Exact Match');
        } else if (descLower.includes(parsedQuery.normalizedText) || addrLower.includes(parsedQuery.normalizedText)) {
          textScore = 80;
        }
      }

      // 2. Activity / Sport Match Score (0 - 100)
      const venueSports: string[] = (v.facilities || [])
        .map((f: any) => (f.activity?.name || f.category?.name || '').toLowerCase())
        .filter(Boolean);

      let activityScore = 50;
      if (parsedQuery.detectedSports.length > 0) {
        const matchesSport = parsedQuery.detectedSports.some((s) =>
          venueSports.some((vs) => vs.includes(s)),
        );
        if (matchesSport) {
          activityScore = 100;
          badges.push(`Top ${parsedQuery.detectedSports[0].toUpperCase()} Turf`);
        } else {
          activityScore = 10;
        }
      }

      // 3. Distance / Location Score (0 - 100)
      const distKm = v.distanceKm !== undefined ? v.distanceKm : 5.0;
      let locationScore = 100;
      if (distKm <= 2.0) {
        locationScore = 100;
        badges.push('Under 2 km');
      } else if (distKm <= 5.0) {
        locationScore = 85;
      } else if (distKm <= 10.0) {
        locationScore = 70;
      } else if (distKm <= 25.0) {
        locationScore = 50;
      } else {
        locationScore = Math.max(10, 100 - distKm * 3);
      }

      // 4. Availability Score (0 - 100)
      const hasOpenSlots = v.hasOpenSlots !== false;
      const availScore = hasOpenSlots ? 100 : 20;
      if (hasOpenSlots && (parsedQuery.timeIntent || parsedQuery.rankingIntent === 'AVAILABLE')) {
        badges.push('Open Slots Tonight');
      }

      // 5. Rating & Quality Score (0 - 100)
      const rating = v.rating !== undefined && v.rating !== null ? Number(v.rating) : 4.5;
      const ratingScore = (rating / 5.0) * 100;
      if (rating >= 4.7) {
        badges.push(`★ ${rating.toFixed(1)} High Quality`);
      }

      // 6. Price Competitiveness Score (0 - 100)
      const prices = (v.facilities || []).flatMap((f: any) =>
        (f.pricingRules || []).map((pr: any) => Number(pr.basePrice)),
      );
      const minPrice = prices.length > 0 ? Math.min(...prices) : (v.minPrice || 400);

      let priceScore = 70;
      if (parsedQuery.maxPrice !== undefined) {
        if (minPrice <= parsedQuery.maxPrice) {
          priceScore = 100;
          badges.push(`Under ₹${parsedQuery.maxPrice}`);
        } else {
          priceScore = 20;
        }
      } else {
        priceScore = Math.max(20, Math.min(100, 100 - (minPrice / 20)));
      }

      // 7. Personalization Score (0 - 100)
      let prefScore = 50;
      if (userPreferences) {
        if (userPreferences.favoriteVenueIds?.includes(v.id)) {
          prefScore = 100;
          badges.push('Frequently Booked');
        } else if (
          userPreferences.preferredSports?.some((ps) =>
            venueSports.some((vs) => vs.includes(ps.toLowerCase())),
          )
        ) {
          prefScore = 85;
        }
      }

      // Compute Weighted Final Score
      const finalScore =
        textScore * this.weights.textRelevance +
        activityScore * this.weights.activityMatch +
        locationScore * this.weights.locationDistance +
        availScore * this.weights.availability +
        ratingScore * this.weights.ratingQuality +
        priceScore * this.weights.priceCompetitiveness +
        prefScore * this.weights.personalization;

      return {
        id: v.id,
        name: v.name,
        description: v.description,
        address: v.address,
        city: v.city,
        latitude: v.latitude,
        longitude: v.longitude,
        rating,
        distanceMeters: v.distanceMeters,
        distanceKm: distKm,
        minPrice,
        hasOpenSlots,
        sportsAvailable: venueSports,
        facilitiesCount: (v.facilities || []).length,
        finalScore: Math.round(finalScore * 10) / 10,
        scoreBreakdown: {
          textScore,
          activityScore,
          locationScore,
          availScore,
          ratingScore,
          priceScore,
          prefScore,
        },
        relevanceBadges: Array.from(new Set(badges)).slice(0, 3), // Max 3 clean badges
        rawVenue: v,
      };
    });

    // Sort descending by finalScore
    scoredList.sort((a, b) => b.finalScore - a.finalScore);

    // Apply Result Diversity: Avoid same business/organization taking top 5 positions
    return this.applyDiversityFilter(scoredList);
  }

  private applyDiversityFilter(list: RankedVenueCandidate[]): RankedVenueCandidate[] {
    if (list.length <= 3) return list;

    const diversified: RankedVenueCandidate[] = [];
    const seenBusinessIds = new Set<string>();

    // Pass 1: Add top result per business
    for (const item of list) {
      const bizId = item.rawVenue?.businessId || item.id;
      if (!seenBusinessIds.has(bizId)) {
        seenBusinessIds.add(bizId);
        diversified.push(item);
      }
    }

    // Pass 2: Append remaining items to preserve volume
    for (const item of list) {
      if (!diversified.some((d) => d.id === item.id)) {
        diversified.push(item);
      }
    }

    return diversified;
  }
}
