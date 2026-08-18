import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Logger,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AuditInterceptor implements NestInterceptor {
  private readonly logger = new Logger('Audit');

  constructor(private prisma: PrismaService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const { method, url, user, organizationId } = request;

    // Only audit mutations by default
    const isMutation = ['POST', 'PUT', 'PATCH', 'DELETE'].includes(method);
    if (!isMutation || url.includes('/health')) {
      return next.handle();
    }

    const now = Date.now();

    return next.handle().pipe(
      tap({
        next: (data) => {
          this._logAudit(request, 'success', data);
        },
        error: (err) => {
          this._logAudit(request, 'failure', err);
        },
      }),
    );
  }

  private async _logAudit(request: any, status: string, responseData: any) {
    try {
      const { method, url, user, organizationId, body, requestId, ip } = request;

      // Extract resource and action from URL
      const pathParts = url.split('/').filter(p => p && p !== 'api' && p !== 'v1');
      const resource = pathParts[0] || 'unknown';
      const action = method.toLowerCase();

      // Sanitized request payload
      const payload = { ...body };
      this._sanitize(payload);

      // Sanitized response data
      let sanitizedResponse = null;
      if (responseData && typeof responseData === 'object') {
        sanitizedResponse = Array.isArray(responseData)
          ? responseData.map(item => this._sanitize({ ...item }))
          : this._sanitize({ ...responseData });
      }

      await this.prisma.auditLog.create({
        data: {
          userId: user?.userId,
          action: `${action}:${resource}`,
          resource: resource,
          resourceId: request.params.id || body.id || (responseData as any)?.id,
          ipAddress: ip,
          status: status,
          payload: {
            request: payload,
            response: sanitizedResponse,
          },
        },
      });
    } catch (e) {
      this.logger.error('Failed to create audit log', e.stack);
    }
  }

  private _sanitize(obj: any) {
    if (!obj || typeof obj !== 'object') return obj;
    const sensitiveFields = [
      'password', 'passwordHash', 'token', 'refreshToken', 'accessToken',
      'secret', 'key', 'signature', 'cvv', 'cardNumber'
    ];
    sensitiveFields.forEach(field => {
      if (field in obj) obj[field] = '[REDACTED]';
    });
    return obj;
  }
}
