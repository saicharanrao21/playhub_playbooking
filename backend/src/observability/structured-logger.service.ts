import { Injectable, LoggerService, LogLevel } from '@nestjs/common';
import { traceContextStorage } from './trace-context.util';

export interface StructuredLogRecord {
  timestamp: string;
  level: string;
  message: string;
  context?: string;
  requestId?: string;
  traceId?: string;
  spanId?: string;
  organizationId?: string;
  userId?: string;
  durationMs?: number;
  error?: Record<string, any>;
  [key: string]: any;
}

@Injectable()
export class StructuredLoggerService implements LoggerService {
  private readonly isProduction = process.env.NODE_ENV === 'production';

  log(message: any, context?: string) {
    this.output('info', message, context);
  }

  error(message: any, trace?: string, context?: string) {
    this.output('error', message, context, { stack: trace });
  }

  warn(message: any, context?: string) {
    this.output('warn', message, context);
  }

  debug(message: any, context?: string) {
    if (!this.isProduction) {
      this.output('debug', message, context);
    }
  }

  verbose(message: any, context?: string) {
    if (!this.isProduction) {
      this.output('verbose', message, context);
    }
  }

  private output(level: string, message: any, context?: string, errorMeta?: any) {
    const traceCtx = traceContextStorage.getContext();

    const record: StructuredLogRecord = {
      timestamp: new Date().toISOString(),
      level,
      message: typeof message === 'object' ? JSON.stringify(this.sanitize(message)) : String(message),
      context: context || 'PlayHubBackend',
      service: 'playhub-backend',
      environment: process.env.NODE_ENV || 'development',
      ...(traceCtx?.requestId ? { requestId: traceCtx.requestId } : {}),
      ...(traceCtx?.traceId ? { traceId: traceCtx.traceId } : {}),
      ...(traceCtx?.spanId ? { spanId: traceCtx.spanId } : {}),
      ...(traceCtx?.organizationId ? { organizationId: traceCtx.organizationId } : {}),
      ...(traceCtx?.userId ? { userId: traceCtx.userId } : {}),
      ...(errorMeta ? { error: errorMeta } : {}),
    };

    if (this.isProduction) {
      // Production: Output structured JSON line to stdout/stderr
      const jsonLine = JSON.stringify(record);
      if (level === 'error') {
        process.stderr.write(jsonLine + '\n');
      } else {
        process.stdout.write(jsonLine + '\n');
      }
    } else {
      // Development: Pretty console format
      const ctxStr = context ? `[${context}] ` : '';
      const reqStr = traceCtx?.requestId ? `[req:${traceCtx.requestId.substring(0, 8)}] ` : '';
      console.log(`[${record.timestamp}] ${level.toUpperCase()} ${ctxStr}${reqStr}${record.message}`);
    }
  }

  private sanitize(obj: any): any {
    if (!obj || typeof obj !== 'object') return obj;

    const copy = Array.isArray(obj) ? [...obj] : { ...obj };
    const sensitiveKeys = [
      'password',
      'passwordHash',
      'token',
      'accessToken',
      'refreshToken',
      'secret',
      'signature',
      'cvv',
      'cardNumber',
    ];

    for (const key of Object.keys(copy)) {
      if (sensitiveKeys.some((s) => key.toLowerCase().includes(s))) {
        copy[key] = '[REDACTED]';
      } else if (typeof copy[key] === 'object' && copy[key] !== null) {
        copy[key] = this.sanitize(copy[key]);
      }
    }

    return copy;
  }
}
