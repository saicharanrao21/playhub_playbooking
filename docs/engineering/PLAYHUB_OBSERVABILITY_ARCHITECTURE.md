# PlayHub Observability & Reliability Architecture

## 1. Observability Pillars

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

1. **Structured JSON Logging**: All backend services log structured JSON including `timestamp`, `level`, `context`, `requestId`, and `organizationId`.
2. **Prometheus Metrics**: Exposes metrics for HTTP latency, database queries, Redis cache hits/misses, and BullMQ queue lengths.
3. **Trace Propagation**: `x-request-id` is injected at entry, passed through `RequestIdMiddleware`, attached to BullMQ job metadata, and recorded in audit logs.

---

## 2. Key Operational Metrics & Thresholds

| Metric | Target Threshold | Alerting Condition |
| :--- | :--- | :--- |
| **API Latency (p95)** | < 150 ms | > 300 ms for 3 consecutive minutes |
| **Cache Hit Ratio** | > 85% | < 60% cache hit ratio |
| **Failed Webhook Queue Jobs** | 0 jobs | > 5 failed webhook jobs in 10 minutes |
| **Reconciliation Status** | `HEALTHY` | `DISCREPANCIES_FOUND` |
| **DB Connection Pool** | < 70% utilization | > 85% connection pool exhaustion |

---

## 3. Health & Readiness Probes
- `GET /api/v1/health/readiness`: Returns health statuses for PostgreSQL database, Redis connection, and BullMQ worker queues.
- `GET /api/v1/admin/queues/health`: Operator endpoint providing real-time job counts (`active`, `waiting`, `completed`, `failed`, `delayed`).
