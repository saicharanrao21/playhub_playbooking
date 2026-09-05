import { Injectable, OnModuleInit } from '@nestjs/common';
import { Registry, collectDefaultMetrics, Counter, Histogram, Gauge } from 'prom-client';

@Injectable()
export class MetricsService implements OnModuleInit {
  private readonly registry = new Registry();

  // 1. HTTP Metrics
  public readonly httpRequestsTotal = new Counter({
    name: 'http_requests_total',
    help: 'Total count of HTTP requests',
    labelNames: ['method', 'route', 'status_code'],
    registers: [this.registry],
  });

  public readonly httpRequestDurationSeconds = new Histogram({
    name: 'http_request_duration_seconds',
    help: 'Duration of HTTP requests in seconds',
    labelNames: ['method', 'route', 'status_code'],
    buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
    registers: [this.registry],
  });

  public readonly httpActiveRequests = new Gauge({
    name: 'http_active_requests',
    help: 'Number of currently active HTTP requests',
    labelNames: ['method'],
    registers: [this.registry],
  });

  // 2. Booking Business Metrics
  public readonly bookingsTotal = new Counter({
    name: 'playhub_bookings_total',
    help: 'Total count of booking attempts by status',
    labelNames: ['status'], // 'attempted', 'success', 'conflict', 'failed'
    registers: [this.registry],
  });

  public readonly bookingDurationSeconds = new Histogram({
    name: 'playhub_booking_duration_seconds',
    help: 'Duration of booking reservation transaction processing in seconds',
    buckets: [0.05, 0.1, 0.25, 0.5, 1, 2, 5],
    registers: [this.registry],
  });

  // 3. Payment & Webhook Business Metrics
  public readonly paymentsTotal = new Counter({
    name: 'playhub_payments_total',
    help: 'Total count of payments processed by provider and status',
    labelNames: ['provider', 'status'], // 'initiated', 'captured', 'failed', 'refunded'
    registers: [this.registry],
  });

  public readonly webhooksTotal = new Counter({
    name: 'playhub_webhooks_total',
    help: 'Total count of payment webhooks received and processed',
    labelNames: ['provider', 'status'], // 'received', 'queued', 'processed', 'failed', 'ignored'
    registers: [this.registry],
  });

  public readonly webhookDurationSeconds = new Histogram({
    name: 'playhub_webhook_duration_seconds',
    help: 'Duration of asynchronous webhook worker processing in seconds',
    labelNames: ['provider', 'eventType'],
    buckets: [0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
    registers: [this.registry],
  });

  // 4. Redis & Caching Metrics
  public readonly cacheOperationsTotal = new Counter({
    name: 'playhub_cache_operations_total',
    help: 'Total count of cache operations',
    labelNames: ['operation', 'result'], // operation: 'get','set','del', result: 'hit','miss','error'
    registers: [this.registry],
  });

  // 5. BullMQ Queue Metrics
  public readonly queueJobsTotal = new Counter({
    name: 'playhub_queue_jobs_total',
    help: 'Total count of queue jobs processed',
    labelNames: ['queue', 'status'], // queue: 'notifications','webhooks', status: 'added','completed','failed','retried'
    registers: [this.registry],
  });

  public readonly queueJobDurationSeconds = new Histogram({
    name: 'playhub_queue_job_duration_seconds',
    help: 'Duration of BullMQ job processing in seconds',
    labelNames: ['queue', 'jobName'],
    buckets: [0.01, 0.05, 0.1, 0.5, 1, 5, 10],
    registers: [this.registry],
  });

  // 6. Reconciliation & Financial Governance Metrics
  public readonly reconciliationDiscrepancies = new Gauge({
    name: 'playhub_reconciliation_discrepancies',
    help: 'Count of financial ledger discrepancies detected by reconciliation engine',
    labelNames: ['status'], // 'healthy', 'discrepancies'
    registers: [this.registry],
  });

  // 7. Database Metrics
  public readonly dbQueryDurationSeconds = new Histogram({
    name: 'playhub_db_query_duration_seconds',
    help: 'Duration of PostgreSQL/Prisma database queries in seconds',
    labelNames: ['operation', 'model'],
    buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5],
    registers: [this.registry],
  });

  onModuleInit() {
    // Collect default Node.js process metrics (memory, CPU, GC, handles)
    collectDefaultMetrics({
      register: this.registry,
      prefix: 'node_',
    });
  }

  async getMetrics(): Promise<string> {
    return this.registry.metrics();
  }

  getRegistry(): Registry {
    return this.registry;
  }
}
