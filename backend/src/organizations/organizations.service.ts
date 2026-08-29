import { Injectable, NotFoundException } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateOrganizationDto } from './dto/update-organization.dto';
import { OnboardPartnerDto } from './dto/onboard-partner.dto';
import { BookingStatus, BusinessStatus, OrganizationStatus, KYCStatus } from '@prisma/client';
import { Events } from '../common/constants/events';

@Injectable()
export class OrganizationsService {
  constructor(
    private prisma: PrismaService,
    private eventEmitter: EventEmitter2,
  ) {}

  async findAll(filters: { skip?: number; take?: number }) {
    const [items, total] = await Promise.all([
      this.prisma.organization.findMany({
        skip: filters.skip,
        take: filters.take,
      }),
      this.prisma.organization.count(),
    ]);

    return { items, total };
  }

  async findOne(id: string) {
    const organization = await this.prisma.organization.findUnique({
      where: { id },
      include: {
        businesses: {
          include: {
            venues: {
              include: {
                facilities: true,
              },
            },
          },
        },
      },
    });
    if (!organization) {
      throw new NotFoundException('Organization not found');
    }
    return organization;
  }

  async getUserOrganizations(userId: string) {
    const memberships = await this.prisma.membership.findMany({
      where: { userId },
      include: {
        roles: {
          include: {
            permissions: true,
          },
        },
        organization: {
          include: {
            businesses: {
              include: {
                venues: {
                  include: {
                    facilities: true,
                  },
                },
              },
            },
          },
        },
      },
    });

    return memberships.map((m) => ({
      membershipId: m.id,
      roles: m.roles.map((r) => r.name),
      organization: m.organization,
    }));
  }

  async onboardPartner(userId: string, dto: OnboardPartnerDto) {
    const slugBase = dto.organizationName.toLowerCase().replace(/[^a-z0-9]/g, '-');
    const slug = `${slugBase}-${Date.now().toString().slice(-4)}`;

    const result = await this.prisma.$transaction(async (tx) => {
      // 1. Create Organization
      const org = await tx.organization.create({
        data: {
          name: dto.organizationName,
          slug,
          status: OrganizationStatus.ACTIVE,
          kycStatus: KYCStatus.SUBMITTED,
          panNumber: dto.panNumber,
          gstNumber: dto.gstNumber,
          accountHolderName: dto.accountHolderName,
          accountNumber: dto.accountNumber,
          ifscCode: dto.ifscCode,
          bankName: dto.bankName,
        },
      });

      // 2. Resolve Role (BUSINESS_OWNER or ADMIN)
      let ownerRole = await tx.role.findFirst({
        where: {
          name: { in: ['BUSINESS_OWNER', 'PARTNER_OWNER', 'ADMIN'] },
        },
      });

      if (!ownerRole) {
        ownerRole = await tx.role.create({
          data: {
            name: 'BUSINESS_OWNER',
            description: 'Business Owner & Partner Administrator',
          },
        });
      }

      // 3. Create Membership
      const membership = await tx.membership.create({
        data: {
          userId,
          organizationId: org.id,
          roles: {
            connect: [{ id: ownerRole.id }],
          },
        },
      });

      // 4. Create Business Entity
      const business = await tx.business.create({
        data: {
          organizationId: org.id,
          legalName: dto.legalName,
          displayName: dto.displayName,
          status: BusinessStatus.ACTIVE,
        },
      });

      return {
        organization: org,
        membership,
        business,
      };
    });

    // 5. Emit Domain Event
    this.eventEmitter.emit(Events.VENDOR_ONBOARDING_SUBMITTED, {
      userId,
      organizationId: result.organization.id,
      businessId: result.business.id,
      displayName: dto.displayName,
    });

    return result;
  }

  async update(id: string, dto: UpdateOrganizationDto) {
    await this.findOne(id);
    return this.prisma.organization.update({
      where: { id },
      data: dto,
    });
  }

  async getDashboardStats(organizationId: string) {
    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const endOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

    const [venuesCount, facilitiesCount, todayBookings, upcomingBookings] = await Promise.all([
      this.prisma.venue.count({ where: { business: { organizationId }, status: 'ACTIVE' } }),
      this.prisma.facility.count({ where: { venue: { business: { organizationId } }, status: 'ACTIVE' } }),
      this.prisma.booking.count({
        where: {
          organizationId,
          startTime: { gte: startOfToday, lte: endOfToday },
          status: { in: [BookingStatus.CONFIRMED, BookingStatus.PENDING] },
        },
      }),
      this.prisma.booking.count({
        where: {
          organizationId,
          startTime: { gt: now },
          status: { in: [BookingStatus.CONFIRMED, BookingStatus.PENDING] },
        },
      }),
    ]);

    return {
      venuesCount,
      facilitiesCount,
      todayBookings,
      upcomingBookings,
    };
  }

  async getMembership(userId: string, organizationId: string) {
    return this.prisma.membership.findUnique({
      where: {
        userId_organizationId: {
          userId,
          organizationId,
        },
      },
      include: {
        roles: {
          include: {
            permissions: true,
          },
        },
      },
    });
  }
}

