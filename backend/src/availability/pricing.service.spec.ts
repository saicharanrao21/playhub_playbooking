import { Test, TestingModule } from '@nestjs/testing';
import { PricingService } from './pricing.service';
import { PrismaService } from '../prisma/prisma.service';
import { DayOfWeek } from '@prisma/client';

describe('PricingService', () => {
  let service: PricingService;
  let prisma: PrismaService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PricingService,
        {
          provide: PrismaService,
          useValue: {
            pricingRule: {
              findMany: jest.fn(),
            },
          },
        },
      ],
    }).compile();

    service = module.get<PricingService>(PricingService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should calculate base price correctly for 1 hour', async () => {
    const startTime = new Date('2026-08-30T10:00:00Z');
    const endTime = new Date('2026-08-30T11:00:00Z');

    (prisma.pricingRule.findMany as jest.Mock).mockResolvedValue([
      {
        id: 'rule-1',
        name: 'Base Rule',
        basePrice: 500,
        currency: 'INR',
        daysOfWeek: [],
        startTime: null,
        endTime: null,
        priority: 0,
        isActive: true,
      },
    ]);

    const result = await service.calculatePrice('fac-1', startTime, endTime);
    expect(result.totalPrice).toBe(500);
  });

  it('should apply peak pricing if priority is higher', async () => {
    const startTime = new Date('2026-08-30T19:00:00Z');
    const endTime = new Date('2026-08-30T20:00:00Z');

    (prisma.pricingRule.findMany as jest.Mock).mockResolvedValue([
      {
        id: 'peak-rule',
        name: 'Peak Rule',
        basePrice: 1000,
        currency: 'INR',
        daysOfWeek: [],
        startTime: '18:00',
        endTime: '22:00',
        priority: 10,
        isActive: true,
      },
      {
        id: 'base-rule',
        name: 'Base Rule',
        basePrice: 500,
        currency: 'INR',
        daysOfWeek: [],
        startTime: null,
        endTime: null,
        priority: 0,
        isActive: true,
      },
    ]);

    const result = await service.calculatePrice('fac-1', startTime, endTime);
    expect(result.totalPrice).toBe(1000);
  });
});
