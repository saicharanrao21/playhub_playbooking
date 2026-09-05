import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateMembershipPlanDto } from './dto/create-membership-plan.dto';
import { Decimal } from '@prisma/client/runtime/library';

@Injectable()
export class MembershipsService {
  private readonly logger = new Logger(MembershipsService.name);

  constructor(private readonly prisma: PrismaService) {}

  async createPlan(dto: CreateMembershipPlanDto) {
    const code = dto.code.toUpperCase().trim();

    const existing = await this.prisma.membershipPlan.findUnique({ where: { code } });
    if (existing) {
      throw new ConflictException(`Membership plan code [${code}] already exists.`);
    }

    return this.prisma.membershipPlan.create({
      data: {
        organizationId: dto.organizationId || null,
        name: dto.name,
        description: dto.description,
        code,
        price: new Decimal(dto.price),
        currency: dto.currency || 'INR',
        duration: dto.duration || 1,
        durationUnit: dto.durationUnit || 'MONTHS',
        benefits: dto.benefits || [],
      },
    });
  }

  async getPlans(organizationId?: string) {
    return this.prisma.membershipPlan.findMany({
      where: {
        status: 'ACTIVE',
        OR: [
          ...(organizationId ? [{ organizationId }] : []),
          { organizationId: null },
        ],
      },
      orderBy: { price: 'asc' },
    });
  }

  async getActiveCustomerMembership(userId: string) {
    const now = new Date();
    return this.prisma.customerMembership.findFirst({
      where: {
        userId,
        status: 'ACTIVE',
        expiryDate: { gte: now },
      },
      include: {
        plan: true,
        organization: true,
      },
    });
  }

  async purchaseMembership(userId: string, planId: string, paymentId?: string) {
    const plan = await this.prisma.membershipPlan.findUnique({
      where: { id: planId },
    });

    if (!plan || plan.status !== 'ACTIVE') {
      throw new NotFoundException('Membership plan not found or inactive');
    }

    const startDate = new Date();
    let expiryDate = new Date(startDate);

    if (plan.durationUnit === 'DAYS') {
      expiryDate.setDate(expiryDate.getDate() + plan.duration);
    } else if (plan.durationUnit === 'YEARS') {
      expiryDate.setFullYear(expiryDate.getFullYear() + plan.duration);
    } else {
      // Default MONTHS
      expiryDate.setMonth(expiryDate.getMonth() + plan.duration);
    }

    return this.prisma.customerMembership.create({
      data: {
        userId,
        organizationId: plan.organizationId,
        planId: plan.id,
        paymentId: paymentId || null,
        startDate,
        expiryDate,
        status: 'ACTIVE',
        amountPaid: plan.price,
        currency: plan.currency,
      },
      include: { plan: true },
    });
  }
}
