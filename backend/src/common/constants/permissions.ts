export const Permissions = {
  // Organization
  ORGANIZATION_READ: 'read:organization',
  ORGANIZATION_UPDATE: 'update:organization',
  ORGANIZATION_DELETE: 'delete:organization',
  ORGANIZATION_SETTINGS_READ: 'read:organization_settings',

  // Business
  BUSINESS_CREATE: 'create:business',
  BUSINESS_READ: 'read:business',
  BUSINESS_UPDATE: 'update:business',
  BUSINESS_DELETE: 'delete:business',
  BUSINESS_VERIFY: 'verify:business',

  // Venue
  VENUE_CREATE: 'create:venue',
  VENUE_READ: 'read:venue',
  VENUE_UPDATE: 'update:venue',
  VENUE_DELETE: 'delete:venue',
  VENUE_APPROVE: 'approve:venue',
  VENUE_SUSPEND: 'suspend:venue',

  // Facility
  FACILITY_CREATE: 'create:facility',
  FACILITY_READ: 'read:facility',
  FACILITY_UPDATE: 'update:facility',
  FACILITY_DELETE: 'delete:facility',

  // Pricing
  PRICING_CREATE: 'create:pricing',
  PRICING_READ: 'read:pricing',
  PRICING_UPDATE: 'update:pricing',
  PRICING_DELETE: 'delete:pricing',

  // Availability Blocks
  AVAILABILITY_BLOCK_CREATE: 'create:availability_block',
  AVAILABILITY_BLOCK_READ: 'read:availability_block',
  AVAILABILITY_BLOCK_UPDATE: 'update:availability_block',
  AVAILABILITY_BLOCK_DELETE: 'delete:availability_block',

  // Bookings
  BOOKING_CREATE: 'create:booking',
  BOOKING_READ: 'read:booking',
  BOOKING_UPDATE: 'update:booking',
  BOOKING_DELETE: 'delete:booking',
  BOOKING_ACCEPT: 'accept:booking',
  BOOKING_REJECT: 'reject:booking',
  BOOKING_CANCEL: 'cancel:booking',
  BOOKING_RESCHEDULE: 'reschedule:booking',
  BOOKING_CHECKIN: 'checkin:booking',
  BOOKING_NOSHOW: 'noshow:booking',
  BOOKING_COMPLETE: 'complete:booking',
  BOOKING_OVERRIDE: 'override:booking',

  // Payments & Payouts
  PAYMENT_READ: 'read:payment',
  PAYMENT_UPDATE: 'update:payment',
  PAYMENT_REFUND: 'refund:payment',
  PAYOUT_READ: 'read:payout',
  PAYOUT_REQUEST: 'request:payout',
  PAYOUT_APPROVE: 'approve:payout',
  PAYOUT_SETTLE: 'settle:payout',

  // Staff & RBAC
  STAFF_MANAGE: 'manage:staff',
  USER_READ: 'read:user',
  USER_MANAGE: 'manage:user',
  USER_SUSPEND: 'suspend:user',
  RBAC_MANAGE: 'manage:rbac',

  // Community & Matches
  COMMUNITY_READ: 'read:community',
  COMMUNITY_POST: 'post:community',
  COMMUNITY_MODERATE: 'moderate:community',
  MATCH_READ: 'read:match',
  MATCH_JOIN: 'join:match',
  MATCH_HOST: 'host:match',
  TOURNAMENT_READ: 'read:tournament',
  TOURNAMENT_REGISTER: 'register:tournament',
  TOURNAMENT_MANAGE: 'manage:tournament',

  // Reviews & Support
  REVIEW_CREATE: 'create:review',
  REVIEW_READ: 'read:review',
  REVIEW_MODERATE: 'moderate:review',
  SUPPORT_TICKET_CREATE: 'create:support_ticket',
  SUPPORT_TICKET_READ: 'read:support_ticket',
  SUPPORT_TICKET_UPDATE: 'update:support_ticket',
  SUPPORT_TICKET_RESOLVE: 'resolve:support_ticket',
  DISPUTE_READ: 'read:dispute',
  DISPUTE_UPDATE: 'update:dispute',
  DISPUTE_RESOLVE: 'resolve:dispute',

  // Platform Ops & Config
  AUDIT_READ: 'read:audit',
  ANALYTICS_BUSINESS_READ: 'read:analytics_business',
  ANALYTICS_PLATFORM_READ: 'read:analytics_platform',
  ANALYTICS_FINANCE_READ: 'read:analytics_finance',
  PROMOTION_MANAGE: 'manage:promotion',
  SYSTEM_CONFIG_MANAGE: 'manage:system_config',

  // Master Catalog
  CITY_CREATE: 'create:city',
  CITY_UPDATE: 'update:city',
  CATEGORY_CREATE: 'create:category',
  CATEGORY_UPDATE: 'update:category',
  ACTIVITY_CREATE: 'create:activity',
  ACTIVITY_UPDATE: 'update:activity',
} as const;

export type PermissionType = (typeof Permissions)[keyof typeof Permissions];
