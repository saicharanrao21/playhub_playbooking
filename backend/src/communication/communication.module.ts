import { Module } from '@nestjs/common';
import { CommunicationService } from './communication.service';
import { CommunicationController } from './communication.controller';
import { TemplateRegistry } from './template.registry';
import { ResendEmailProvider } from './providers/resend-email.provider';
import { MockSmsProvider } from './providers/mock-sms.provider';
import { MockWhatsAppProvider } from './providers/mock-whatsapp.provider';
import { MockPushProvider } from './providers/mock-push.provider';
import { PrismaModule } from '../prisma/prisma.module';
import { ConfigModule } from '@nestjs/config';

import { CommunicationEventsListener } from './communication-events.listener';

@Module({
  imports: [PrismaModule, ConfigModule],
  controllers: [CommunicationController],
  providers: [
    CommunicationService,
    TemplateRegistry,
    ResendEmailProvider,
    MockSmsProvider,
    MockWhatsAppProvider,
    MockPushProvider,
    CommunicationEventsListener,
  ],
  exports: [CommunicationService],
})
export class CommunicationModule {}
