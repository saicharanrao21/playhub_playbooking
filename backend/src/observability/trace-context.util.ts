import { AsyncLocalStorage } from 'async_hooks';
import * as crypto from 'crypto';

export interface TraceContext {
  requestId: string;
  traceId: string;
  spanId: string;
  organizationId?: string;
  userId?: string;
}

class TraceContextStorage {
  private readonly storage = new AsyncLocalStorage<TraceContext>();

  run<R>(context: TraceContext, fn: () => R): R {
    return this.storage.run(context, fn);
  }

  getContext(): TraceContext | undefined {
    return this.storage.getStore();
  }

  getTraceId(): string | undefined {
    return this.storage.getStore()?.traceId;
  }

  getRequestId(): string | undefined {
    return this.storage.getStore()?.requestId;
  }

  /**
   * Generates a 32-hex character W3C Trace ID.
   */
  generateTraceId(): string {
    return crypto.randomBytes(16).toString('hex');
  }

  /**
   * Generates an 8-byte / 16-hex character W3C Span ID.
   */
  generateSpanId(): string {
    return crypto.randomBytes(8).toString('hex');
  }

  /**
   * Generates W3C traceparent header: 00-{traceId}-{spanId}-01
   */
  generateTraceparent(traceId?: string, spanId?: string): string {
    const tid = traceId || this.generateTraceId();
    const sid = spanId || this.generateSpanId();
    return `00-${tid}-${sid}-01`;
  }

  /**
   * Parses incoming W3C traceparent header: 00-{traceId}-{spanId}-{flags}
   */
  parseTraceparent(header?: string): { traceId: string; parentSpanId?: string } {
    if (header && typeof header === 'string') {
      const parts = header.trim().split('-');
      if (parts.length >= 4 && parts[0] === '00' && parts[1].length === 32) {
        return {
          traceId: parts[1],
          parentSpanId: parts[2],
        };
      }
    }

    // Default fallback: Generate fresh Trace ID
    return {
      traceId: this.generateTraceId(),
    };
  }
}

export const traceContextStorage = new TraceContextStorage();
