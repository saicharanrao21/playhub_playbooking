export const Events = {
  // Booking Lifecycle Events
  BOOKING_CREATED: 'booking.created',
  BOOKING_PENDING_APPROVAL: 'booking.pending_approval',
  BOOKING_ACCEPTED: 'booking.accepted',
  BOOKING_REJECTED: 'booking.rejected',
  BOOKING_CONFIRMED: 'booking.confirmed',
  BOOKING_CANCELLED: 'booking.cancelled',
  BOOKING_RESCHEDULED: 'booking.rescheduled',
  BOOKING_ARRIVED: 'booking.arrived',
  BOOKING_NOSHOW: 'booking.noshow',
  BOOKING_COMPLETED: 'booking.completed',
  BOOKING_EXPIRED: 'booking.expired',

  // Payment & Financial Events
  PAYMENT_INITIATED: 'payment.initiated',
  PAYMENT_CAPTURED: 'payment.captured',
  PAYMENT_FAILED: 'payment.failed',
  PAYMENT_CANCELLED: 'payment.cancelled',
  PAYMENT_REFUND_REQUESTED: 'payment.refund_requested',
  PAYMENT_REFUNDED: 'payment.refunded',
  PAYMENT_DISPUTED: 'payment.disputed',

  // Payout & Settlement Events
  PAYOUT_INITIATED: 'payout.initiated',
  PAYOUT_SETTLED: 'payout.settled',
  PAYOUT_FAILED: 'payout.failed',

  // Partner & Venue Onboarding Events
  VENDOR_ONBOARDING_SUBMITTED: 'vendor.onboarding_submitted',
  VENDOR_APPROVED: 'vendor.approved',
  VENDOR_REJECTED: 'vendor.rejected',
  VENDOR_SUSPENDED: 'vendor.suspended',
  VENUE_SUBMITTED: 'venue.submitted',
  VENUE_APPROVED: 'venue.approved',
  VENUE_REJECTED: 'venue.rejected',

  // Communication & Alert Events
  NOTIFICATION_CREATED: 'notification.created',
  COMMUNICATION_DISPATCHED: 'communication.dispatched',
  COMMUNICATION_DELIVERED: 'communication.delivered',
  COMMUNICATION_FAILED: 'communication.failed',

  // Matches & Community Events
  MATCH_CREATED: 'match.created',
  MATCH_JOINED: 'match.joined',
  MATCH_LEFT: 'match.left',
  MATCH_CANCELLED: 'match.cancelled',
  MATCH_COMPLETED: 'match.completed',
  COMMUNITY_POST_CREATED: 'community.post_created',
  COMMUNITY_COMMENT_ADDED: 'community.comment_added',

  // Support & Dispute Events
  SUPPORT_TICKET_CREATED: 'support.ticket_created',
  SUPPORT_TICKET_UPDATED: 'support.ticket_updated',
  SUPPORT_TICKET_RESOLVED: 'support.ticket_resolved',
  DISPUTE_CREATED: 'dispute.created',
  DISPUTE_RESOLVED: 'dispute.resolved',

  // Audit & Security Events
  SECURITY_SESSION_REVOKED: 'security.session_revoked',
  SECURITY_ACCOUNT_LOCKED: 'security.account_locked',
} as const;

export type EventType = (typeof Events)[keyof typeof Events];
