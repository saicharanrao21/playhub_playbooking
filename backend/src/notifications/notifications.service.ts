import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationType } from '@prisma/client';

@Injectable()
export class NotificationsService {
  constructor(private prisma: PrismaService) {}

  async create(data: {
    organizationId: string;
    userId: string;
    bookingId?: string;
    type: NotificationType;
    title: string;
    message: string;
    payload?: any;
  }) {
    return this.prisma.notification.create({
      data: {
        organizationId: data.organizationId,
        userId: data.userId,
        bookingId: data.bookingId,
        type: data.type,
        title: data.title,
        message: data.message,
        data: data.payload,
      },
    });
  }

  async findAll(organizationId: string, userId: string) {
    return this.prisma.notification.findMany({
      where: { organizationId, userId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  async markAsRead(organizationId: string, userId: string, id: string) {
    const notification = await this.prisma.notification.findFirst({
      where: { id, organizationId, userId },
    });

    if (!notification) {
      throw new NotFoundException('Notification not found');
    }

    return this.prisma.notification.update({
      where: { id },
      data: { isRead: true, readAt: new Date() },
    });
  }

  async markAllAsRead(organizationId: string, userId: string) {
    return this.prisma.notification.updateMany({
      where: { organizationId, userId, isRead: false },
      data: { isRead: true, readAt: new Date() },
    });
  }
}
