import { Module } from '@nestjs/common';
import { QueryUnderstandingService } from './query-understanding.service';
import { RankingScoringService } from './ranking-scoring.service';
import { RecommendationService } from './recommendation.service';
import { SuggestionsService } from './suggestions.service';
import { SearchIntelligenceController } from './search-intelligence.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { VenuesModule } from '../venues/venues.module';

@Module({
  imports: [PrismaModule, VenuesModule],
  controllers: [SearchIntelligenceController],
  providers: [
    QueryUnderstandingService,
    RankingScoringService,
    RecommendationService,
    SuggestionsService,
  ],
  exports: [
    QueryUnderstandingService,
    RankingScoringService,
    RecommendationService,
    SuggestionsService,
  ],
})
export class SearchIntelligenceModule {}
