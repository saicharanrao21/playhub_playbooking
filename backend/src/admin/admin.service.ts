import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { BusinessStatus, BookingStatus, KYCStatus, OrganizationStatus } from '@prisma/client';
import { AuditService } from '../common/services/audit.service';
import { ReviewPartnerDto } from './dto/review-partner.dto';

@Injectable()
export class AdminService {
  constructor(
    private prisma: PrismaService,
    private auditService: AuditService,
  ) {}

  async getDashboardStats() {
    const [totalUsers, totalVenues, activeBookings, pendingBusinesses, pendingKYC] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.venue.count({ where: { status: 'ACTIVE' } }),
      this.prisma.booking.count({
        where: {
          status: { in: [BookingStatus.CONFIRMED, BookingStatus.PENDING] },
          startTime: { gte: new Date() }
        }
      }),
      this.prisma.business.count({ where: { status: BusinessStatus.PENDING_ONBOARDING } }),
      this.prisma.organization.count({ where: { kycStatus: KYCStatus.SUBMITTED } }),
    ]);

    return {
      totalUsers,
      totalVenues,
      activeBookings,
      pendingBusinesses,
      pendingKYC,
    };
  }

  async getPartners(filters: { status?: OrganizationStatus; kycStatus?: KYCStatus; skip?: number; take?: number }) {
    const [items, total] = await Promise.all([
      this.prisma.organization.findMany({
        where: {
          status: filters.status,
          kycStatus: filters.kycStatus,
        },
        include: {
          businesses: true,
          memberships: {
            include: { user: true },
            take: 1, // Usually the owner
          },
        },
        orderBy: { createdAt: 'desc' },
        skip: filters.skip,
        take: filters.take,
      }),
      this.prisma.organization.count({
        where: {
          status: filters.status,
          kycStatus: filters.kycStatus,
        },
      }),
    ]);

    return { items, total };
  }

  async getPartnerDetails(id: string) {
    const org = await this.prisma.organization.findUnique({
      where: { id },
      include: {
        businesses: {
          include: { venues: { include: { facilities: true } } },
        },
        memberships: { include: { user: true, roles: true } },
        financialTransactions: { take: 5, orderBy: { createdAt: 'desc' } },
        auditLogs: { take: 10, orderBy: { createdAt: 'desc' } },
      },
    });

    if (!org) throw new NotFoundException('Partner organization not found');
    return org;
  }

  async reviewPartner(adminId: string, orgId: string, dto: ReviewPartnerDto) {
    const org = await this.prisma.organization.findUnique({
      where: { id: orgId },
      include: { businesses: true },
    });

    if (!org) throw new NotFoundException('Partner not found');

    const result = await this.prisma.$transaction(async (tx) => {
      // 1. Update Organization KYC
      const updatedOrg = await tx.organization.update({
        where: { id: orgId },
        data: { kycStatus: dto.kycStatus },
      });

      // 2. If approved, activate businesses
      if (dto.kycStatus === KYCStatus.APPROVED) {
        await tx.business.updateMany({
          where: { organizationId: orgId, status: BusinessStatus.PENDING_ONBOARDING },
          data: { status: BusinessStatus.ACTIVE },
        });
      }

      // 3. Record Audit
      await this.auditService.record({
        userId: adminId,
        organizationId: orgId,
        action: `partner:review_kyc:${dto.kycStatus.toLowerCase()}`,
        resource: 'organization',
        resourceId: orgId,
        payload: { previousStatus: org.kycStatus, newStatus: dto.kycStatus, reason: dto.reason },
        status: 'success',
      });

      return updatedOrg;
    });

    return result;
  }

  async approveBusiness(businessId: string) {
    // Legacy support for basic approval
    const business = await this.prisma.business.findUnique({
      where: { id: businessId },
    });

    if (!business) {
      throw new NotFoundException('Business not found');
    }

    return this.prisma.business.update({
      where: { id: businessId },
      data: { status: BusinessStatus.ACTIVE },
    });
  }

  async getAuditLogs(filters: { skip?: number; take?: number }) {
    const [items, total] = await Promise.all([
      this.prisma.auditLog.findMany({
        include: { user: true, organization: true },
        orderBy: { createdAt: 'desc' },
        skip: filters.skip,
        take: filters.take,
      }),
      this.prisma.auditLog.count(),
    ]);

    return { items, total };
  }
}
