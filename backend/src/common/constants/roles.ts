import { Permissions } from './permissions';

export const Roles = {
  // Consumer
  CUSTOMER: 'CUSTOMER',

  // Partner / Business Roles
  PARTNER_OWNER: 'PARTNER_OWNER',
  PARTNER_MANAGER: 'PARTNER_MANAGER',
  PARTNER_STAFF: 'PARTNER_STAFF',

  // Internal PlayHub Admin & Operations Roles
  PLAYHUB_SUPER_ADMIN: 'PLAYHUB_SUPER_ADMIN',
  PLAYHUB_ADMIN: 'PLAYHUB_ADMIN',
  PLAYHUB_OPERATIONS: 'PLAYHUB_OPERATIONS',
  PLAYHUB_SUPPORT: 'PLAYHUB_SUPPORT',
  PLAYHUB_FINANCE: 'PLAYHUB_FINANCE',
  PLAYHUB_RISK: 'PLAYHUB_RISK',
  PLAYHUB_MARKETING: 'PLAYHUB_MARKETING',
} as const;

export type RoleType = (typeof Roles)[keyof typeof Roles];

/**
 * Standard Role-to-Permissions Mapping for Multi-Tenant RBAC
 */
export const RolePermissionsMap: Record<RoleType, string[]> = {
  [Roles.CUSTOMER]: [
    Permissions.BOOKING_CREATE,
    Permissions.BOOKING_READ,
    Permissions.BOOKING_CANCEL,
    Permissions.PAYMENT_READ,
    Permissions.COMMUNITY_READ,
    Permissions.COMMUNITY_POST,
    Permissions.MATCH_READ,
    Permissions.MATCH_JOIN,
    Permissions.MATCH_HOST,
    Permissions.TOURNAMENT_READ,
    Permissions.TOURNAMENT_REGISTER,
    Permissions.REVIEW_CREATE,
    Permissions.REVIEW_READ,
    Permissions.SUPPORT_TICKET_CREATE,
    Permissions.SUPPORT_TICKET_READ,
  ],

  [Roles.PARTNER_OWNER]: [
    Permissions.ORGANIZATION_READ,
    Permissions.ORGANIZATION_UPDATE,
    Permissions.BUSINESS_READ,
    Permissions.BUSINESS_UPDATE,
    Permissions.VENUE_CREATE,
    Permissions.VENUE_READ,
    Permissions.VENUE_UPDATE,
    Permissions.VENUE_DELETE,
    Permissions.FACILITY_CREATE,
    Permissions.FACILITY_READ,
    Permissions.FACILITY_UPDATE,
    Permissions.FACILITY_DELETE,
    Permissions.PRICING_CREATE,
    Permissions.PRICING_READ,
    Permissions.PRICING_UPDATE,
    Permissions.PRICING_DELETE,
    Permissions.AVAILABILITY_BLOCK_CREATE,
    Permissions.AVAILABILITY_BLOCK_READ,
    Permissions.AVAILABILITY_BLOCK_UPDATE,
    Permissions.AVAILABILITY_BLOCK_DELETE,
    Permissions.BOOKING_READ,
    Permissions.BOOKING_ACCEPT,
    Permissions.BOOKING_REJECT,
    Permissions.BOOKING_CHECKIN,
    Permissions.BOOKING_NOSHOW,
    Permissions.BOOKING_COMPLETE,
    Permissions.BOOKING_RESCHEDULE,
    Permissions.PAYMENT_READ,
    Permissions.PAYOUT_READ,
    Permissions.PAYOUT_REQUEST,
    Permissions.STAFF_MANAGE,
    Permissions.ANALYTICS_BUSINESS_READ,
  ],

  [Roles.PARTNER_MANAGER]: [
    Permissions.BUSINESS_READ,
    Permissions.VENUE_READ,
    Permissions.VENUE_UPDATE,
    Permissions.FACILITY_READ,
    Permissions.FACILITY_UPDATE,
    Permissions.PRICING_READ,
    Permissions.AVAILABILITY_BLOCK_CREATE,
    Permissions.AVAILABILITY_BLOCK_READ,
    Permissions.AVAILABILITY_BLOCK_UPDATE,
    Permissions.AVAILABILITY_BLOCK_DELETE,
    Permissions.BOOKING_READ,
    Permissions.BOOKING_ACCEPT,
    Permissions.BOOKING_REJECT,
    Permissions.BOOKING_CHECKIN,
    Permissions.BOOKING_NOSHOW,
    Permissions.BOOKING_COMPLETE,
    Permissions.BOOKING_RESCHEDULE,
    Permissions.PAYMENT_READ,
    Permissions.ANALYTICS_BUSINESS_READ,
  ],

  [Roles.PARTNER_STAFF]: [
    Permissions.VENUE_READ,
    Permissions.FACILITY_READ,
    Permissions.AVAILABILITY_BLOCK_READ,
    Permissions.BOOKING_READ,
    Permissions.BOOKING_CHECKIN,
    Permissions.BOOKING_NOSHOW,
    Permissions.BOOKING_COMPLETE,
  ],

  [Roles.PLAYHUB_SUPER_ADMIN]: [
    '*', // Wildcard platform bypass
  ],

  [Roles.PLAYHUB_ADMIN]: [
    Permissions.ORGANIZATION_READ,
    Permissions.ORGANIZATION_UPDATE,
    Permissions.BUSINESS_READ,
    Permissions.BUSINESS_UPDATE,
    Permissions.BUSINESS_VERIFY,
    Permissions.VENUE_READ,
    Permissions.VENUE_APPROVE,
    Permissions.VENUE_SUSPEND,
    Permissions.BOOKING_READ,
    Permissions.BOOKING_OVERRIDE,
    Permissions.PAYMENT_READ,
    Permissions.PAYMENT_REFUND,
    Permissions.PAYOUT_READ,
    Permissions.PAYOUT_APPROVE,
    Permissions.USER_MANAGE,
    Permissions.RBAC_MANAGE,
    Permissions.AUDIT_READ,
    Permissions.ANALYTICS_PLATFORM_READ,
    Permissions.SYSTEM_CONFIG_MANAGE,
  ],

  [Roles.PLAYHUB_OPERATIONS]: [
    Permissions.BUSINESS_READ,
    Permissions.BUSINESS_VERIFY,
    Permissions.VENUE_READ,
    Permissions.VENUE_APPROVE,
    Permissions.BOOKING_READ,
    Permissions.BOOKING_OVERRIDE,
    Permissions.USER_READ,
    Permissions.AUDIT_READ,
  ],

  [Roles.PLAYHUB_SUPPORT]: [
    Permissions.BOOKING_READ,
    Permissions.USER_READ,
    Permissions.PAYMENT_READ,
    Permissions.SUPPORT_TICKET_READ,
    Permissions.SUPPORT_TICKET_UPDATE,
    Permissions.SUPPORT_TICKET_RESOLVE,
    Permissions.DISPUTE_READ,
    Permissions.DISPUTE_UPDATE,
  ],

  [Roles.PLAYHUB_FINANCE]: [
    Permissions.PAYMENT_READ,
    Permissions.PAYMENT_REFUND,
    Permissions.PAYOUT_READ,
    Permissions.PAYOUT_APPROVE,
    Permissions.PAYOUT_SETTLE,
    Permissions.ANALYTICS_FINANCE_READ,
    Permissions.AUDIT_READ,
  ],

  [Roles.PLAYHUB_RISK]: [
    Permissions.USER_READ,
    Permissions.USER_SUSPEND,
    Permissions.BOOKING_READ,
    Permissions.PAYMENT_READ,
    Permissions.DISPUTE_READ,
    Permissions.DISPUTE_RESOLVE,
    Permissions.AUDIT_READ,
  ],

  [Roles.PLAYHUB_MARKETING]: [
    Permissions.COMMUNITY_READ,
    Permissions.COMMUNITY_MODERATE,
    Permissions.PROMOTION_MANAGE,
    Permissions.TOURNAMENT_READ,
    Permissions.TOURNAMENT_MANAGE,
  ],
};
