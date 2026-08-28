import { Injectable, Logger, Inject, ConflictException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  CommunicationChannel,
  CommunicationCategory,
  CommunicationStatus,
  Prisma
} from '@prisma/client';
import { TemplateRegistry } from './template.registry';
import {
  EMAIL_PROVIDER,
  SMS_PROVIDER,
  WHATSAPP_PROVIDER,
  PUSH_PROVIDER
} from './interfaces/provider-tokens';
import { EmailProvider } from './interfaces/email-provider.interface';
import { SmsProvider } from './interfaces/sms-provider.interface';
import { WhatsAppProvider } from './interfaces/whatsapp-provider.interface';
import { PushProvider } from './interfaces/push-provider.interface';

@Injectable()
export class CommunicationService {
  private readonly logger = new Logger(CommunicationService.name);

  constructor(
    private prisma: PrismaService,
    private templateRegistry: TemplateRegistry,
    @Inject(EMAIL_PROVIDER) private emailProvider: EmailProvider,
    @Inject(SMS_PROVIDER) private smsProvider: SmsProvider,
    @Inject(WHATSAPP_PROVIDER) private whatsappProvider: WhatsAppProvider,
    @Inject(PUSH_PROVIDER) private pushProvider: PushProvider,
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
    idempotencyKey?: string;
  }) {
    const { userId, category, channels: requestedChannels, idempotencyKey } = params;

    // 1. Determine base channels if none requested
    let targetChannels = requestedChannels;
    if (!targetChannels) {
      if (category === CommunicationCategory.SECURITY) {
        targetChannels = [CommunicationChannel.EMAIL];
      } else if (category === CommunicationCategory.TRANSACTIONAL) {
        targetChannels = [CommunicationChannel.IN_APP, CommunicationChannel.EMAIL, CommunicationChannel.PUSH];
      } else {
        targetChannels = [CommunicationChannel.IN_APP, CommunicationChannel.PUSH];
      }
    }

    // 2. Get user preferences
    const preferences = await this.prisma.communicationPreference.findMany({
      where: { userId, category },
    });

    const results = [];

    for (const channel of targetChannels) {
      // In-app is always enabled for non-marketing
      if (channel === CommunicationChannel.IN_APP) {
        // Handle in-app separately if needed, for now we assume it's handled by NotificationsService
        // But Phase 48 design said In-app is always enabled for transactional.
        continue;
      }

      const pref = preferences.find((p) => p.channel === channel);

      // Security category bypasses preferences.
      // Transactional has fallback logic: if Email is requested but disabled, we might still send it
      // if it's the only reliable channel, but usually we respect it unless it's SECURITY.
      // For PlayHub, let's stick to: SECURITY bypasses, others respect.
      if (pref && !pref.isEnabled && category !== CommunicationCategory.SECURITY) {
        this.logger.log(`Channel ${channel} disabled by user preference for ${category}`);

        // Log as SKIPPED if idempotencyKey is provided to avoid duplicate "skipped" attempts
        if (idempotencyKey) {
          await this.logSkipped(userId, channel, idempotencyKey, 'DISABLED_BY_USER', params);
        }
        continue;
      }

      results.push(this.dispatch(channel, params));
    }

    return Promise.all(results);
  }

  private async logSkipped(userId: string, channel: CommunicationChannel, idempotencyKey: string, reason: string, params: any) {
    try {
      await this.prisma.communicationLog.create({
        data: {
          userId,
          organizationId: params.organizationId,
          bookingId: params.bookingId,
          paymentId: params.paymentId,
          channel,
          provider: 'NONE',
          status: CommunicationStatus.SKIPPED,
          templateId: params.type,
          idempotencyKey,
          error: reason,
        },
      });
    } catch (e) {
      if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
        // Already logged/processed
        return;
      }
      throw e;
    }
  }

  private async dispatch(channel: CommunicationChannel, params: any) {
    const { userId, type, variables, organizationId, bookingId, paymentId, idempotencyKey } = params;
    const template = this.templateRegistry.getTemplate(type, variables);

    let logEntry;
    try {
      logEntry = await this.prisma.communicationLog.create({
        data: {
          userId,
          organizationId,
          bookingId,
          paymentId,
          channel,
          provider: 'PENDING',
          status: CommunicationStatus.PENDING,
          templateId: type,
          idempotencyKey,
        },
      });
    } catch (e) {
      if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
        this.logger.log(`Communication already processed for user ${userId}, channel ${channel}, key ${idempotencyKey}`);
        return;
      }
      throw e;
    }

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
            result = { success: true, skipped: true, reason: 'NO_ACTIVE_DEVICES' };
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
          status: result.skipped
            ? CommunicationStatus.SKIPPED
            : (result.success ? CommunicationStatus.SENT : CommunicationStatus.FAILED),
          provider: providerName,
          providerRef: result.messageId,
          error: result.error || result.reason,
          sentAt: (result.success && !result.skipped) ? new Date() : null,
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
    // If token belongs to another user, we take it over (e.g. user changed on same phone)
    return this.prisma.device.upsert({
      where: { token },
      update: { userId, platform, isActive: true, lastUsedAt: new Date() },
      create: { userId, token, platform },
    });
  }

  async unregisterDevice(userId: string, token: string) {
    const device = await this.prisma.device.findUnique({
      where: { token }
    });

    if (!device) {
      throw new NotFoundException('Device not found');
    }

    if (device.userId !== userId) {
      throw new ForbiddenException('You do not own this device registration');
    }

    return this.prisma.device.update({
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
