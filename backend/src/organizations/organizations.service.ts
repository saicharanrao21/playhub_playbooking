import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class OrganizationsService {
  constructor(private prisma: PrismaService) {}

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
