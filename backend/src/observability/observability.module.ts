import { Module, Global } from '@nestjs/common';
import { MetricsService } from './metrics.service';
import { MetricsController } from './metrics.controller';
import { StructuredLoggerService } from './structured-logger.service';
import { MetricsMiddleware } from './metrics.middleware';

@Global()
@Module({
  controllers: [MetricsController],
  providers: [MetricsService, StructuredLoggerService, MetricsMiddleware],
  exports: [MetricsService, StructuredLoggerService, MetricsMiddleware],
})
export class ObservabilityModule {}
