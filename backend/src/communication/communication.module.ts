import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { CommunicationService } from './communication.service';
import { CommunicationController } from './communication.controller';
import { TemplateRegistry } from './template.registry';
import { PrismaModule } from '../prisma/prisma.module';
import { CommunicationEventsListener } from './communication-events.listener';
import {
  EMAIL_PROVIDER,
  SMS_PROVIDER,
  WHATSAPP_PROVIDER,
  PUSH_PROVIDER
} from './interfaces/provider-tokens';
import { ResendEmailProvider } from './providers/resend-email.provider';
import { MockSmsProvider } from './providers/mock-sms.provider';
import { MockWhatsAppProvider } from './providers/mock-whatsapp.provider';
import { MockPushProvider } from './providers/mock-push.provider';

@Module({
  imports: [PrismaModule, ConfigModule],
  controllers: [CommunicationController],
  providers: [
    CommunicationService,
    TemplateRegistry,
    CommunicationEventsListener,
    {
      provide: EMAIL_PROVIDER,
      useClass: ResendEmailProvider,
    },
    {
      provide: SMS_PROVIDER,
      useClass: MockSmsProvider,
    },
    {
      provide: WHATSAPP_PROVIDER,
      useClass: MockWhatsAppProvider,
    },
    {
      provide: PUSH_PROVIDER,
      useClass: MockPushProvider,
    },
  ],
  exports: [CommunicationService],
})
export class CommunicationModule {}
