import { Test, TestingModule } from '@nestjs/testing';
import { MetricsService } from './metrics.service';
import { MetricsController } from './metrics.controller';

describe('MetricsService & Prometheus Exporter', () => {
  let service: MetricsService;
  let controller: MetricsController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [MetricsController],
      providers: [MetricsService],
    }).compile();

    service = module.get<MetricsService>(MetricsService);
    controller = module.get<MetricsController>(MetricsController);
    service.onModuleInit();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
    expect(controller).toBeDefined();
  });

  it('should record HTTP request counter and histogram', async () => {
    service.httpRequestsTotal.inc({ method: 'GET', route: '/api/v1/venues', status_code: '200' });
    service.httpRequestDurationSeconds.observe({ method: 'GET', route: '/api/v1/venues', status_code: '200' }, 0.045);

    const metricsStr = await service.getMetrics();
    expect(metricsStr).toContain('http_requests_total');
    expect(metricsStr).toContain('http_request_duration_seconds');
    expect(metricsStr).toContain('GET');
  });

  it('should record business booking and payment metrics', async () => {
    service.bookingsTotal.inc({ status: 'success' });
    service.paymentsTotal.inc({ provider: 'RAZORPAY', status: 'captured' });
    service.webhooksTotal.inc({ provider: 'RAZORPAY', status: 'processed' });

    const metricsStr = await service.getMetrics();
    expect(metricsStr).toContain('playhub_bookings_total');
    expect(metricsStr).toContain('playhub_payments_total');
    expect(metricsStr).toContain('playhub_webhooks_total');
  });

  it('should return metrics formatted for Prometheus via controller', async () => {
    const response = await controller.getMetrics();
    expect(typeof response).toBe('string');
    expect(response).toContain('# HELP');
  });
});
