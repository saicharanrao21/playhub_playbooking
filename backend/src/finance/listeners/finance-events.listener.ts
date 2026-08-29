import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { Events } from '../../common/constants/events';
import { FinanceService } from '../finance.service';

@Injectable()
export class FinanceEventsListener {
  private readonly logger = new Logger(FinanceEventsListener.name);

  constructor(private readonly financeService: FinanceService) {}

  @OnEvent(Events.PAYMENT_CAPTURED)
  async handlePaymentCaptured(payload: any) {
    this.logger.log(`Recording financial event for payment: ${payload.paymentId}`);
    try {
      await this.financeService.recordPayment({
        paymentId: payload.paymentId,
        bookingId: payload.bookingId,
        organizationId: payload.organizationId,
        amount: payload.amount,
        userId: payload.userId,
      });
    } catch (e) {
      this.logger.error(`Failed to record financial event: ${e.message}`, e.stack);
    }
  }

  // TODO: Add handlePaymentRefunded in this phase or next
}
