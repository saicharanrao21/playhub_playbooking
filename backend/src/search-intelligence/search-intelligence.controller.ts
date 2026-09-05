import {
  Controller,
  Get,
  Post,
  Query,
  Body,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { QueryUnderstandingService } from './query-understanding.service';
import { RankingScoringService, ScoringWeights } from './ranking-scoring.service';
import { RecommendationService } from './recommendation.service';
import { SuggestionsService } from './suggestions.service';
import { VenuesService } from '../venues/venues.service';
import { Public } from '../common/decorators/public.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserIdentity } from '../common/interfaces/user-identity.interface';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PlatformAdminGuard } from '../common/guards/platform-admin.guard';

@ApiTags('search-intelligence')
@Controller()
export class SearchIntelligenceController {
  constructor(
    private readonly queryUnderstandingService: QueryUnderstandingService,
    private readonly rankingScoringService: RankingScoringService,
    private readonly recommendationService: RecommendationService,
    private readonly suggestionsService: SuggestionsService,
    private readonly venuesService: VenuesService,
  ) {}

  @Public()
  @Get('search')
  @ApiOperation({ summary: 'Intelligent, intent-aware venue discovery & ranking' })
  async search(
    @Query('q') query?: string,
    @Query('latitude') latitude?: number,
    @Query('longitude') longitude?: number,
    @Query('radius') radius?: number,
    @Query('cityId') cityId?: string,
    @Query('sport') sport?: string,
  ) {
    const lat = Number(latitude || 17.4401);
    const lng = Number(longitude || 78.3489);
    const rad = Number(radius || 15.0);

    // 1. Parse Query Intent
    const parsedIntent = this.queryUnderstandingService.parse(query);

    // 2. Candidate Retrieval
    const nearby = await this.venuesService.findNearby({
      latitude: lat,
      longitude: lng,
      radius: rad,
      cityId,
      query: parsedIntent.rawQuery,
      skip: 0,
      limit: 30,
    } as any);

    // 3. Rank & Score Candidates
    const rankedItems = this.rankingScoringService.rankCandidates(
      nearby.items || [],
      parsedIntent,
    );

    return {
      query: parsedIntent.rawQuery,
      parsedIntent,
      total: rankedItems.length,
      items: rankedItems,
    };
  }

  @Public()
  @Get('search/suggestions')
  @ApiOperation({ summary: 'Fast autocomplete & search suggestions' })
  async getSuggestions(
    @Query('q') query?: string,
    @Query('cityId') cityId?: string,
  ) {
    return this.suggestionsService.getSuggestions(query, cityId);
  }

  @Public()
  @Get('recommendations')
  @ApiOperation({ summary: 'Contextual recommendations for customer discovery' })
  async getRecommendations(
    @Query('latitude') latitude?: number,
    @Query('longitude') longitude?: number,
    @Query('radius') radius?: number,
    @CurrentUser() user?: UserIdentity,
  ) {
    const lat = Number(latitude || 17.4401);
    const lng = Number(longitude || 78.3489);
    const rad = Number(radius || 15.0);

    return this.recommendationService.getRecommendations(user?.userId, lat, lng, rad);
  }

  @Get('admin/search/config')
  @UseGuards(JwtAuthGuard, PlatformAdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Admin: Get search ranking scoring weights' })
  getRankingConfig() {
    return this.rankingScoringService.getWeights();
  }

  @Post('admin/search/config')
  @UseGuards(JwtAuthGuard, PlatformAdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Admin: Update search ranking scoring weights' })
  updateRankingConfig(@Body() newWeights: Partial<ScoringWeights>) {
    return this.rankingScoringService.updateWeights(newWeights);
  }
}
