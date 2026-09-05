# PlayHub Observability & Reliability Architecture

## 1. Observability Pillars & Implementation

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PLAYHUB OBSERVABILITY PILLARS                   │
│                                                                        │
│   ┌────────────────────┐ ┌────────────────────┐ ┌───────────────────┐  │
│   │ Structured Logs    │ │ Prometheus Metrics │ │ OpenTelemetry     │  │
│   │ (JSON + Trace IDs) │ │ (HTTP, Queues, DB)│ │ (Distributed Traces)│  │
│   └────────────────────┘ └────────────────────┘ └───────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
```

1. **Structured JSON Logging**: `StructuredLoggerService` formats log entries as JSON with `timestamp`, `level`, `context`, `requestId`, `traceId`, `spanId`, `organizationId`, `durationMs`, and sanitized error metadata. Automatically redacts `password`, `token`, `secret`, `signature`, `cvv`, `cardNumber`.
2. **Prometheus Metrics**: `MetricsService` and `MetricsController` expose Prometheus scraping format at `GET /api/v1/metrics`.
3. **W3C Trace Context & Propagation**: `MetricsMiddleware` inspects and injects `traceparent` headers (`00-{traceId}-{spanId}-01`) and `x-request-id` headers, propagating context through `AsyncLocalStorage`.

---

## 2. Metrics Catalog (`GET /api/v1/metrics`)

### A. HTTP Metrics
- `http_requests_total` (Counter): Labels: `method`, `route` (normalized, e.g. `/api/v1/venues/:id`), `status_code`.
- `http_request_duration_seconds` (Histogram): Buckets: `[0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]`.
- `http_active_requests` (Gauge): Labels: `method`.

### B. Business & Domain Metrics
- `playhub_bookings_total` (Counter): Labels: `status` ('attempted', 'success', 'conflict', 'failed').
- `playhub_booking_duration_seconds` (Histogram).
- `playhub_payments_total` (Counter): Labels: `provider`, `status` ('initiated', 'captured', 'failed', 'refunded').
- `playhub_webhooks_total` (Counter): Labels: `provider`, `status` ('received', 'queued', 'processed', 'failed', 'ignored').
- `playhub_webhook_duration_seconds` (Histogram): Labels: `provider`, `eventType`.

### C. Infrastructure Metrics
- `playhub_cache_operations_total` (Counter): Labels: `operation` ('get', 'set', 'del'), `result` ('hit', 'miss', 'error').
- `playhub_queue_jobs_total` (Counter): Labels: `queue`, `status` ('added', 'completed', 'failed', 'retried').
- `playhub_queue_job_duration_seconds` (Histogram): Labels: `queue`, `jobName`.
- `playhub_reconciliation_discrepancies` (Gauge): Labels: `status` ('healthy', 'discrepancies').
- `playhub_db_query_duration_seconds` (Histogram): Labels: `operation`, `model`.

---

## 3. Route Normalization & Cardinality Protection
To prevent label explosion in Prometheus time series databases:
`MetricsMiddleware.normalizeRoute` strips dynamic UUIDs and numeric IDs from URLs:
- `/api/v1/venues/550e8400-e29b-41d4-a716-446655440000/facilities` ➔ `/api/v1/venues/:id/facilities`
- `/api/v1/bookings/12345` ➔ `/api/v1/bookings/:id`

---

## 4. Key Operational Metrics & Thresholds

| Metric | Target Threshold | Alerting Condition |
| :--- | :--- | :--- |
| **API Latency (p95)** | < 150 ms | `histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le)) > 0.3` for 3 mins |
| **Cache Hit Ratio** | > 85% | `sum(rate(playhub_cache_operations_total{result="hit"}[5m])) / sum(rate(playhub_cache_operations_total[5m])) < 0.6` |
| **Failed Webhook Queue Jobs** | 0 jobs | `increase(playhub_webhooks_total{status="failed"}[10m]) > 5` |
| **Reconciliation Status** | `HEALTHY` | `playhub_reconciliation_discrepancies{status="discrepancies"} > 0` |

---

## 5. Health & Readiness Probes
- `GET /api/v1/health/readiness`: Returns health statuses for PostgreSQL database, Redis connection, and BullMQ worker queues (`notifications`, `finance`, `reconciliation`, `settlement`, `webhooks`).
- `GET /api/v1/admin/queues/health`: Operator endpoint providing real-time job counts (`active`, `waiting`, `completed`, `failed`, `delayed`).
