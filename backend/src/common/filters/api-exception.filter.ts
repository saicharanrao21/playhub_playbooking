import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { Prisma } from '@prisma/client';

@Catch()
export class ApiExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(ApiExceptionFilter.name);

  catch(exception: any, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();
    const requestId = request['requestId'];

    let status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    let message =
      exception instanceof HttpException
        ? exception.getResponse()
        : 'Internal server error';

    // Handle Prisma Errors
    if (exception instanceof Prisma.PrismaClientKnownRequestError) {
      status = HttpStatus.BAD_REQUEST;
      message = this._handlePrismaError(exception);
    } else if (exception instanceof Prisma.PrismaClientValidationError) {
      status = HttpStatus.UNPROCESSABLE_ENTITY;
      message = 'Validation failed in the database layer.';
    }

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

    // In production, suppress detailed messages for 500 errors and Prisma internals
    if (process.env.NODE_ENV === 'production' && status === HttpStatus.INTERNAL_SERVER_ERROR) {
      errorResponse.error.message = 'An internal server error occurred.';
    }

    response.status(status).json(errorResponse);
  }

  private _getErrorCode(status: number, exception: any): string {
    if (exception.response?.code) return exception.response.code;
    if (exception instanceof Prisma.PrismaClientKnownRequestError) {
      if (exception.code === 'P2002') return 'UNIQUE_CONSTRAINT_FAILED';
      if (exception.code === 'P2025') return 'RESOURCE_NOT_FOUND';
    }

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

  private _handlePrismaError(error: Prisma.PrismaClientKnownRequestError): string {
    switch (error.code) {
      case 'P2002':
        const target = (error.meta?.target as string[])?.join(', ');
        return `Unique constraint failed on the fields: ${target}`;
      case 'P2025':
        return 'An operation failed because it depends on one or more records that were not found.';
      default:
        return 'A database error occurred.';
    }
  }
}
