import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

@Catch()
export class ApiExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(ApiExceptionFilter.name);

  catch(exception: any, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();
    const requestId = request['requestId'];

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    const message =
      exception instanceof HttpException
        ? exception.getResponse()
        : 'Internal server error';

    // Standardized error structure
    const errorResponse = {
      error: {
        code: this._getErrorCode(status, exception),
        message: typeof message === 'string' ? message : (message as any).message || 'An unexpected error occurred',
        requestId: requestId,
        timestamp: new Date().toISOString(),
        path: request.url,
      },
    };

    // Log the error (Sanitized)
    if (status >= 500) {
      this.logger.error(
        `[${requestId}] ${request.method} ${request.url} - ${status} - ${exception.message}`,
        exception.stack,
      );
    } else {
      this.logger.warn(
        `[${requestId}] ${request.method} ${request.url} - ${status} - ${JSON.stringify(message)}`,
      );
    }

    // In production, suppress detailed messages for 500 errors
    if (process.env.NODE_ENV === 'production' && status === HttpStatus.INTERNAL_SERVER_ERROR) {
      errorResponse.error.message = 'An internal server error occurred.';
    }

    response.status(status).json(errorResponse);
  }

  private _getErrorCode(status: number, exception: any): string {
    if (exception.response?.code) return exception.response.code;

    switch (status) {
      case 401: return 'AUTH_REQUIRED';
      case 403: return 'INSUFFICIENT_PERMISSIONS';
      case 404: return 'RESOURCE_NOT_FOUND';
      case 409: return 'RESOURCE_CONFLICT';
      case 422: return 'VALIDATION_ERROR';
      case 429: return 'RATE_LIMITED';
      default: return 'INTERNAL_ERROR';
    }
  }
}
