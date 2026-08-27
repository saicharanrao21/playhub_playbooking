import { Injectable } from '@nestjs/common';

export interface MessageTemplate {
  subject?: string;
  body: string;
}

@Injectable()
export class TemplateRegistry {
  private templates: Record<string, (vars: any) => MessageTemplate> = {
    BOOKING_CONFIRMED: (vars) => ({
      subject: `Booking Confirmed: ${vars.venueName}`,
      body: `Hi ${vars.customerName}, your booking for ${vars.facilityName} at ${vars.venueName} is confirmed for ${vars.startTime}. Booking ID: ${vars.bookingId}.`,
    }),
    BOOKING_CANCELLED: (vars) => ({
      subject: `Booking Cancelled: ${vars.venueName}`,
      body: `Hi ${vars.customerName}, your booking for ${vars.facilityName} at ${vars.venueName} on ${vars.startTime} has been cancelled.`,
    }),
    PAYMENT_SUCCESS: (vars) => ({
      subject: `Payment Successful: ${vars.bookingId}`,
      body: `Hi ${vars.customerName}, we have received your payment of ${vars.currency} ${vars.amount} for booking ${vars.bookingId}.`,
    }),
    ORGANIZATION_APPROVED: (vars) => ({
      subject: `Welcome to PlayHub!`,
      body: `Hi ${vars.ownerName}, your organization "${vars.orgName}" has been approved. You can now start adding venues.`,
    }),
  };

  getTemplate(type: string, vars: any): MessageTemplate {
    const templateFn = this.templates[type];
    if (!templateFn) {
      return { body: `Notification: ${type}` };
    }
    return templateFn(vars);
  }
}
