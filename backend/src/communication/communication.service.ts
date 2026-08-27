import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  CommunicationChannel,
  CommunicationCategory,
  CommunicationStatus
} from '@prisma/client';
import { TemplateRegistry } from './template.registry';
import { ResendEmailProvider } from './providers/resend-email.provider';
import { MockSmsProvider } from './providers/mock-sms.provider';
import { MockWhatsAppProvider } from './providers/mock-whatsapp.provider';
import { MockPushProvider } from './providers/mock-push.provider';

@Injectable()
export class CommunicationService {
  private readonly logger = new Logger(CommunicationService.name);

  constructor(
    private prisma: PrismaService,
    private templateRegistry: TemplateRegistry,
    private emailProvider: ResendEmailProvider,
    private smsProvider: MockSmsProvider,
    private whatsappProvider: MockWhatsAppProvider,
    private pushProvider: MockPushProvider,
  ) {}

  async sendNotification(params: {
    userId: string;
    organizationId?: string;
    bookingId?: string;
    paymentId?: string;
    type: string;
    category: CommunicationCategory;
    variables: any;
    channels?: CommunicationChannel[];
  }) {
    const { userId, type, category, variables, channels: requestedChannels } = params;

    // 1. Get user preferences
    const preferences = await this.prisma.communicationPreference.findMany({
      where: { userId, category },
    });

    // 2. Determine enabled channels (In-app is always enabled for transactional)
    const activeChannels = requestedChannels || [
      CommunicationChannel.IN_APP,
      CommunicationChannel.EMAIL,
      CommunicationChannel.PUSH,
    ];

    const results = [];

    for (const channel of activeChannels) {
      const pref = preferences.find((p) => p.channel === channel);
      if (pref && !pref.isEnabled && category !== CommunicationCategory.SECURITY) {
        this.logger.log(`Channel ${channel} disabled by user preference for ${category}`);
        continue;
      }

      results.push(this.dispatch(channel, params));
    }

    return Promise.all(results);
  }

  private async dispatch(channel: CommunicationChannel, params: any) {
    const { userId, type, variables, organizationId, bookingId, paymentId } = params;
    const template = this.templateRegistry.getTemplate(type, variables);

    const logEntry = await this.prisma.communicationLog.create({
      data: {
        userId,
        organizationId,
        bookingId,
        paymentId,
        channel,
        provider: 'PENDING',
        status: CommunicationStatus.PENDING,
        templateId: type,
      },
    });

    try {
      let result;
      let providerName = '';

      switch (channel) {
        case CommunicationChannel.EMAIL:
          const user = await this.prisma.user.findUnique({ where: { id: userId } });
          if (!user?.email) throw new Error('User email not found');
          providerName = this.emailProvider.getName();
          result = await this.emailProvider.send({
            to: user.email,
            subject: template.subject || 'Notification from PlayHub',
            html: `<p>${template.body}</p>`,
            text: template.body,
          });
          break;

        case CommunicationChannel.SMS:
          const uSms = await this.prisma.user.findUnique({ where: { id: userId } });
          if (!uSms?.phoneNumber) throw new Error('User phone not found');
          providerName = this.smsProvider.getName();
          result = await this.smsProvider.send({
            to: uSms.phoneNumber,
            message: template.body,
          });
          break;

        case CommunicationChannel.PUSH:
          const devices = await this.prisma.device.findMany({
            where: { userId, isActive: true },
          });
          if (devices.length === 0) {
            result = { success: true, skipped: true };
            providerName = 'NONE';
          } else {
            providerName = this.pushProvider.getName();
            result = await this.pushProvider.send({
              tokens: devices.map((d) => d.token),
              title: template.subject || 'PlayHub Update',
              body: template.body,
            });
          }
          break;

        case CommunicationChannel.WHATSAPP:
          const uWa = await this.prisma.user.findUnique({ where: { id: userId } });
          if (!uWa?.phoneNumber) throw new Error('User phone not found');
          providerName = this.whatsappProvider.getName();
          result = await this.whatsappProvider.send({
            to: uWa.phoneNumber,
            templateName: type.toLowerCase(),
            variables,
          });
          break;

        default:
          return;
      }

      await this.prisma.communicationLog.update({
        where: { id: logEntry.id },
        data: {
          status: result.success ? CommunicationStatus.SENT : CommunicationStatus.FAILED,
          provider: providerName,
          providerRef: result.messageId,
          error: result.error,
          sentAt: result.success ? new Date() : null,
        },
      });
    } catch (error) {
      this.logger.error(`Failed to dispatch ${channel}: ${error.message}`);
      await this.prisma.communicationLog.update({
        where: { id: logEntry.id },
        data: {
          status: CommunicationStatus.FAILED,
          error: error.message,
        },
      });
    }
  }

  async registerDevice(userId: string, token: string, platform?: string) {
    return this.prisma.device.upsert({
      where: { token },
      update: { userId, platform, isActive: true, lastUsedAt: new Date() },
      create: { userId, token, platform },
    });
  }

  async unregisterDevice(token: string) {
    return this.prisma.device.updateMany({
      where: { token },
      data: { isActive: false },
    });
  }

  async getPreferences(userId: string) {
    return this.prisma.communicationPreference.findMany({
      where: { userId },
    });
  }

  async updatePreference(userId: string, category: CommunicationCategory, channel: CommunicationChannel, isEnabled: boolean) {
    return this.prisma.communicationPreference.upsert({
      where: { userId_category_channel: { userId, category, channel } },
      update: { isEnabled },
      create: { userId, category, channel, isEnabled },
    });
  }
}
