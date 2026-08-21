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

    const isProduction = process.env.NODE_ENV === 'production';

    // Standardized error structure
    const errorResponse = {
      error: {
        code: this._getErrorCode(status, exception),
        message: this._formatMessage(message, status, isProduction),
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

    response.status(status).json(errorResponse);
  }

  private _formatMessage(message: any, status: number, isProduction: boolean): string {
    if (isProduction && status === HttpStatus.INTERNAL_SERVER_ERROR) {
      return 'An internal server error occurred.';
    }

    if (typeof message === 'string') return message;

    // Handle NestJS ValidationPipe response
    if (message.message && Array.isArray(message.message)) {
      return message.message.join(', ');
    }

    return message.message || 'An unexpected error occurred';
  }

  private _getErrorCode(status: number, exception: any): string {
    if (exception.response?.code) return exception.response.code;
    if (exception instanceof Prisma.PrismaClientKnownRequestError) {
      if (exception.code === 'P2002') return 'UNIQUE_CONSTRAINT_FAILED';
      if (exception.code === 'P2025') return 'RESOURCE_NOT_FOUND';
    }

    switch (status) {
      case 400: return 'BAD_REQUEST';
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
    const isProduction = process.env.NODE_ENV === 'production';
    switch (error.code) {
      case 'P2002':
        if (isProduction) return 'A unique constraint was violated.';
        const target = (error.meta?.target as string[])?.join(', ');
        return `Unique constraint failed on the fields: ${target}`;
      case 'P2025':
        return 'An operation failed because it depends on one or more records that were not found.';
      default:
        return 'A database error occurred.';
    }
  }
}
