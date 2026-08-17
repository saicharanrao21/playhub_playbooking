export interface UserIdentity {
  userId: string;
  email: string;
  organizationId?: string;
  membershipId?: string;
  roles: string[];
  permissions: string[];
  isPlatformAdmin: boolean;
}
