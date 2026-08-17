import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';
import { OrganizationsService } from '../src/organizations/organizations.service';

describe('Security Enforcement (e2e)', () => {
  let app: INestApplication;

  const mockOrganizationsService = {
    getMembership: jest.fn(),
  };

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(OrganizationsService)
      .useValue(mockOrganizationsService)
      .compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe());
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  describe('Unauthenticated Access', () => {
    it('/organizations (GET) should allow public access if configured, but here it requires JWT', () => {
      return request(app.getHttpServer())
        .get('/organizations')
        .expect(401);
    });
  });

  // Further e2e tests would require a valid JWT which is complex to generate here without secrets.
  // We'll rely on unit tests for guards for now to demonstrate the logic.
});
