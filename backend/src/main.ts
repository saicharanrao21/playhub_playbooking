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
  const app = await NestFactory.create(AppModule);

  const configService = app.get(ConfigService);
  const prismaService = app.get(PrismaService);
  const port = configService.get<number>('PORT') || 3000;
  const apiPrefix = configService.get<string>('API_PREFIX') || 'api/v1';

  // Security
  app.use(helmet());

  const allowedOrigins = configService.get<string>('CORS_ORIGINS')?.split(',') || [];
  app.enableCors({
    origin: (origin, callback) => {
      if (!origin || allowedOrigins.includes(origin) || configService.get('NODE_ENV') !== 'production') {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    },
    credentials: true,
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    allowedHeaders: 'Content-Type, Accept, Authorization, x-organization-id, x-idempotency-key, x-razorpay-signature, stripe-signature',
  });

  // Body parser limits
  const { json, urlencoded } = require('express');
  app.use(json({ limit: '1mb' }));
  app.use(urlencoded({ extended: true, limit: '1mb' }));

  // Global Prefix
  app.setGlobalPrefix(apiPrefix);

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

  await app.listen(port);
  logger.log(`PlayHub Backend is running on: http://localhost:${port}/${apiPrefix}`);
  if (configService.get('NODE_ENV') !== 'production') {
    logger.log(`API Documentation available at: http://localhost:${port}/docs`);
  }
}
bootstrap();
