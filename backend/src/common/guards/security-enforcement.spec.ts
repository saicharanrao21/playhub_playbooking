import { Test, TestingModule } from '@nestjs/testing';
import { OrganizationGuard } from './organization.guard';
import { PlatformAdminGuard } from './platform-admin.guard';
import { PermissionsGuard } from './permissions.guard';
import { OrganizationsService } from '../../organizations/organizations.service';
import { ExecutionContext, ForbiddenException, BadRequestException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';

describe('Security & Multi-Tenant IDOR Protection', () => {
  let orgGuard: OrganizationGuard;
  let adminGuard: PlatformAdminGuard;
  let permissionsGuard: PermissionsGuard;

  const mockOrganizationsService = {
    getMembership: jest.fn(),
  };

  const mockReflector = {
    getAllAndOverride: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OrganizationGuard,
        PlatformAdminGuard,
        PermissionsGuard,
        { provide: OrganizationsService, useValue: mockOrganizationsService },
        { provide: Reflector, useValue: mockReflector },
      ],
    }).compile();

    orgGuard = module.get<OrganizationGuard>(OrganizationGuard);
    adminGuard = module.get<PlatformAdminGuard>(PlatformAdminGuard);
    permissionsGuard = module.get<PermissionsGuard>(PermissionsGuard);
  });

  function createMockContext(user: any, headers: Record<string, string> = {}): ExecutionContext {
    return {
      switchToHttp: () => ({
        getRequest: () => ({
          user,
          headers,
          params: {},
        }),
      }),
      getHandler: () => ({}),
      getClass: () => ({}),
    } as any;
  }

  it('should block partner user from accessing Organization B data (IDOR Protection)', async () => {
    const user = { userId: 'user-101' };
    mockOrganizationsService.getMembership.mockResolvedValue(null);
    const ctx = createMockContext(user, { 'x-organization-id': 'org-B' });

    await expect(orgGuard.canActivate(ctx)).rejects.toThrow(ForbiddenException);
    expect(mockOrganizationsService.getMembership).toHaveBeenCalledWith('user-101', 'org-B');
  });

  it('should allow partner user access to their own Organization A data', async () => {
    const user = { userId: 'user-101' };
    mockOrganizationsService.getMembership.mockResolvedValue({
      id: 'mem-1',
      roles: [{ name: 'BUSINESS_OWNER', permissions: [{ action: 'read', resource: 'organization' }] }],
    });
    const ctx = createMockContext(user, { 'x-organization-id': 'org-A' });

    const result = await orgGuard.canActivate(ctx);
    expect(result).toBe(true);
  });

  it('should block non-admin users from platform admin endpoints', () => {
    const user = {
      userId: 'user-102',
      isPlatformAdmin: false,
    };
    const ctx = createMockContext(user);

    expect(() => adminGuard.canActivate(ctx)).toThrow(ForbiddenException);
  });

  it('should allow platform admin access to admin endpoints', () => {
    const user = {
      userId: 'user-ADMIN',
      isPlatformAdmin: true,
    };
    const ctx = createMockContext(user);

    expect(adminGuard.canActivate(ctx)).toBe(true);
  });
});
