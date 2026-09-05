import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { MetricsService } from './metrics.service';
import { traceContextStorage } from './trace-context.util';

@Injectable()
export class MetricsMiddleware implements NestMiddleware {
  constructor(private readonly metricsService: MetricsService) {}

  use(req: Request, res: Response, next: NextFunction) {
    // 1. Extract or initialize Trace Context
    const traceparentHeader = req.headers['traceparent'] as string | undefined;
    const { traceId } = traceContextStorage.parseTraceparent(traceparentHeader);
    const spanId = traceContextStorage.generateSpanId();
    const requestId = (req['requestId'] as string) || traceContextStorage.generateSpanId();

    const traceparent = traceContextStorage.generateTraceparent(traceId, spanId);
    res.setHeader('traceparent', traceparent);
    res.setHeader('x-request-id', requestId);

    const startTime = Date.now();
    const method = req.method;

    // Track Active HTTP Requests
    this.metricsService.httpActiveRequests.inc({ method });

    // Execute request within AsyncLocalStorage Trace Context
    traceContextStorage.run(
      {
        requestId,
        traceId,
        spanId,
        organizationId: req.headers['x-organization-id'] as string,
        userId: (req as any).user?.userId,
      },
      () => {
        res.on('finish', () => {
          this.metricsService.httpActiveRequests.dec({ method });

          const durationSec = (Date.now() - startTime) / 1000.0;
          const statusCode = res.statusCode.toString();
          const route = this.normalizeRoute(req.baseUrl || req.path);

          // Record HTTP Metrics
          this.metricsService.httpRequestsTotal.inc({
            method,
            route,
            status_code: statusCode,
          });

          this.metricsService.httpRequestDurationSeconds.observe(
            {
              method,
              route,
              status_code: statusCode,
            },
            durationSec,
          );
        });

        next();
      },
    );
  }

  /**
   * Normalizes dynamic URL path parameters to prevent label explosion in Prometheus.
   * e.g. /api/v1/venues/550e8400-e29b-41d4-a716-446655440000/facilities -> /api/v1/venues/:id/facilities
   */
  private normalizeRoute(path: string): string {
    if (!path) return 'unknown';

    return path
      // UUIDs
      .replace(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi, ':id')
      // Numeric IDs
      .replace(/\/\d+/g, '/:id')
      // Clean query params
      .split('?')[0];
  }
}
