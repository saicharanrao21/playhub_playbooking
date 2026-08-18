import { Module } from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { PaymentsController } from './payments.controller';
import { OrganizationsModule } from '../organizations/organizations.module';
import { MockPaymentProvider } from './providers/mock-payment.provider';
import { IPaymentProvider, PAYMENT_PROVIDER } from './interfaces/payment-provider.interface';

@Module({
  imports: [OrganizationsModule],
  controllers: [PaymentsController],
  providers: [
    PaymentsService,
    {
      provide: PAYMENT_PROVIDER,
      useClass: MockPaymentProvider,
    },
  ],
})
export class PaymentsModule {}
