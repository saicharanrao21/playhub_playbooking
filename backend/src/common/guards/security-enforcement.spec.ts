import { ExecutionContext, ForbiddenException, BadRequestException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { OrganizationGuard } from './organization.guard';
import { PermissionsGuard } from './permissions.guard';
import { PlatformAdminGuard } from './platform-admin.guard';
import { OrganizationsService } from '../../organizations/organizations.service';
import { Roles } from '../constants/roles';
import { Permissions } from '../constants/permissions';

describe('Security & Multi-Tenant Authorization Enforcement', () => {
  describe('OrganizationGuard (Tenant Isolation)', () => {
    let guard: OrganizationGuard;
    let mockOrgService: Partial<OrganizationsService>;

    beforeEach(() => {
      mockOrgService = {
        getMembership: jest.fn(),
      };
      guard = new OrganizationGuard(mockOrgService as OrganizationsService);
    });

    it('should throw ForbiddenException if user context is missing from request', async () => {
      const mockContext = {
        switchToHttp: () => ({
          getRequest: () => ({
            headers: { 'x-organization-id': 'org-1' },
          }),
        }),
      } as unknown as ExecutionContext;

      await expect(guard.canActivate(mockContext)).rejects.toThrow(ForbiddenException);
    });

    it('should throw BadRequestException if organization context is missing', async () => {
      const mockContext = {
        switchToHttp: () => ({
          getRequest: () => ({
            user: { userId: 'user-1' },
            headers: {},
            params: {},
          }),
        }),
      } as unknown as ExecutionContext;

      await expect(guard.canActivate(mockContext)).rejects.toThrow(BadRequestException);
    });

    it('should throw ForbiddenException if user is not a verified member of the requested organization (Tenant Cross-Access Prevention)', async () => {
      (mockOrgService.getMembership as jest.Mock).mockResolvedValue(null);

      const mockContext = {
        switchToHttp: () => ({
          getRequest: () => ({
            user: { userId: 'user-attacker' },
            headers: { 'x-organization-id': 'org-victim' },
            params: {},
          }),
        }),
      } as unknown as ExecutionContext;

      await expect(guard.canActivate(mockContext)).rejects.toThrow(ForbiddenException);
      expect(mockOrgService.getMembership).toHaveBeenCalledWith('user-attacker', 'org-victim');
    });

    it('should successfully activate and attach verified organization context and permissions', async () => {
      const mockMembership = {
        id: 'mem-1',
        roles: [
          {
            name: Roles.PARTNER_OWNER,
            permissions: [
              { action: 'read', resource: 'venue' },
              { action: 'update', resource: 'venue' },
            ],
          },
        ],
      };
      (mockOrgService.getMembership as jest.Mock).mockResolvedValue(mockMembership);

      const req: any = {
        user: { userId: 'user-owner' },
        headers: { 'x-organization-id': 'org-owner' },
        params: {},
      };
      const mockContext = {
        switchToHttp: () => ({
          getRequest: () => req,
        }),
      } as unknown as ExecutionContext;

      const result = await guard.canActivate(mockContext);
      expect(result).toBe(true);
      expect(req.organizationId).toBe('org-owner');
      expect(req.user.permissions).toContain('read:venue');
      expect(req.user.permissions).toContain('update:venue');
    });
  });

  describe('PermissionsGuard (RBAC Enforcement)', () => {
    let guard: PermissionsGuard;
    let mockReflector: Partial<Reflector>;

    beforeEach(() => {
      mockReflector = {
        getAllAndOverride: jest.fn(),
      };
      guard = new PermissionsGuard(mockReflector as Reflector);
    });

    it('should allow access if no permissions are specified on endpoint', () => {
      (mockReflector.getAllAndOverride as jest.Mock).mockReturnValue(undefined);

      const mockContext = {
        getHandler: () => {},
        getClass: () => {},
        switchToHttp: () => ({
          getRequest: () => ({ user: { userId: 'user-1' } }),
        }),
      } as unknown as ExecutionContext;

      expect(guard.canActivate(mockContext)).toBe(true);
    });

    it('should throw ForbiddenException if user lacks required permission', () => {
      (mockReflector.getAllAndOverride as jest.Mock).mockReturnValue([Permissions.VENUE_APPROVE]);

      const mockContext = {
        getHandler: () => {},
        getClass: () => {},
        switchToHttp: () => ({
          getRequest: () => ({
            user: {
              userId: 'partner-user',
              permissions: ['read:venue', 'update:venue'],
            },
          }),
        }),
      } as unknown as ExecutionContext;

      expect(() => guard.canActivate(mockContext)).toThrow(ForbiddenException);
    });

    it('should allow access if user has exact required permission', () => {
      (mockReflector.getAllAndOverride as jest.Mock).mockReturnValue([Permissions.BOOKING_READ]);

      const mockContext = {
        getHandler: () => {},
        getClass: () => {},
        switchToHttp: () => ({
          getRequest: () => ({
            user: {
              userId: 'customer-user',
              permissions: [Permissions.BOOKING_READ],
            },
          }),
        }),
      } as unknown as ExecutionContext;

      expect(guard.canActivate(mockContext)).toBe(true);
    });

    it('should allow access if user is PLATFORM_ADMIN or PLAYHUB_SUPER_ADMIN (wildcard bypass)', () => {
      (mockReflector.getAllAndOverride as jest.Mock).mockReturnValue([Permissions.VENUE_APPROVE]);

      const mockContext = {
        getHandler: () => {},
        getClass: () => {},
        switchToHttp: () => ({
          getRequest: () => ({
            user: {
              userId: 'super-admin-user',
              roles: [Roles.PLAYHUB_SUPER_ADMIN],
              permissions: ['*'],
            },
          }),
        }),
      } as unknown as ExecutionContext;

      expect(guard.canActivate(mockContext)).toBe(true);
    });
  });

  describe('PlatformAdminGuard (Internal Platform Boundary)', () => {
    let guard: PlatformAdminGuard;

    beforeEach(() => {
      guard = new PlatformAdminGuard();
    });

    it('should throw ForbiddenException if user is not a platform admin', () => {
      const mockContext = {
        switchToHttp: () => ({
          getRequest: () => ({
            user: {
              userId: 'customer-1',
              roles: [Roles.CUSTOMER],
            },
          }),
        }),
      } as unknown as ExecutionContext;

      expect(() => guard.canActivate(mockContext)).toThrow(ForbiddenException);
    });

    it('should allow access if user has PLAYHUB_SUPER_ADMIN or isPlatformAdmin flag', () => {
      const mockContext = {
        switchToHttp: () => ({
          getRequest: () => ({
            user: {
              userId: 'admin-1',
              isPlatformAdmin: true,
            },
          }),
        }),
      } as unknown as ExecutionContext;

      expect(guard.canActivate(mockContext)).toBe(true);
    });
  });
});
