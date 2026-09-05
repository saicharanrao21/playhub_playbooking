import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { ApiExceptionFilter } from './common/filters/api-exception.filter';
import { AuditInterceptor } from './common/interceptors/audit.interceptor';
import { PrismaService } from './prisma/prisma.service';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule, { rawBody: true });

  const configService = app.get(ConfigService);
  const prismaService = app.get(PrismaService);
  const port = configService.get<number>('PORT') || 3000;
  const apiPrefix = configService.get<string>('API_PREFIX') || 'api/v1';

  // Security Headers via Helmet with production CSP rules
  app.use(
    helmet({
      contentSecurityPolicy: configService.get('NODE_ENV') === 'production',
      crossOriginEmbedderPolicy: configService.get('NODE_ENV') === 'production',
      referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
    }),
  );

  const allowedOrigins = configService.get<string>('CORS_ORIGINS')?.split(',').map(o => o.trim()) || [];
  app.enableCors({
    origin: (origin, callback) => {
      // In production, reject request if Origin header is present but not explicitly allowed
      if (!origin || allowedOrigins.includes(origin) || configService.get('NODE_ENV') !== 'production') {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by production CORS policy'));
      }
    },
    credentials: true,
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    allowedHeaders: 'Content-Type, Accept, Authorization, x-organization-id, x-idempotency-key, x-request-id, x-razorpay-signature, stripe-signature, traceparent',
  });

  // Body parser limits
  const { json, urlencoded } = require('express');
  app.use(json({ limit: '1mb' }));
  app.use(urlencoded({ extended: true, limit: '1mb' }));

  // Global Prefix
  app.setGlobalPrefix(apiPrefix);

  // Enable graceful shutdown
  app.enableShutdownHooks();

  // Global Filters
  app.useGlobalFilters(new ApiExceptionFilter());

  // Global Interceptors
  app.useGlobalInterceptors(new AuditInterceptor(prismaService));

  // Validation
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  // OpenAPI/Swagger
  if (configService.get('NODE_ENV') !== 'production') {
    const config = new DocumentBuilder()
      .setTitle('PlayHub API')
      .setDescription('PlayHub Platform Backend API Documentation')
      .setVersion('1.0')
      .addBearerAuth()
      .build();
    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('docs', app, document);
  }

  await app.listen(port, '0.0.0.0');
  logger.log(`PlayHub Backend is running on: http://0.0.0.0:${port}/${apiPrefix}`);
  if (configService.get('NODE_ENV') !== 'production') {
    logger.log(`API Documentation available at: http://localhost:${port}/docs`);
  }
}
bootstrap();
