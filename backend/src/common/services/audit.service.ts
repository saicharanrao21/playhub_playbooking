import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AuditService {
  constructor(private prisma: PrismaService) {}

  async record(payload: {
    userId?: string;
    organizationId?: string;
    action: string;
    resource?: string;
    resourceId?: string;
    payload?: any;
    status: 'success' | 'failure';
    ipAddress?: string;
  }) {
    return this.prisma.auditLog.create({
      data: {
        userId: payload.userId,
        organizationId: payload.organizationId,
        action: payload.action,
        resource: payload.resource,
        resourceId: payload.resourceId,
        payload: payload.payload,
        status: payload.status,
        ipAddress: payload.ipAddress,
      },
    });
  }
}
