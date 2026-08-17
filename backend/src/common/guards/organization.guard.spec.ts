import { ExecutionContext, ForbiddenException, BadRequestException } from '@nestjs/common';
import { OrganizationGuard } from './organization.guard';
import { OrganizationsService } from '../../organizations/organizations.service';

describe('OrganizationGuard', () => {
  let guard: OrganizationGuard;
  let mockOrganizationsService: any;

  beforeEach(() => {
    mockOrganizationsService = {
      getMembership: jest.fn(),
    };
    guard = new OrganizationGuard(mockOrganizationsService);
  });

  it('should throw ForbiddenException if user is missing', async () => {
    const context = createMockContext({ user: null });
    await expect(guard.canActivate(context)).rejects.toThrow(ForbiddenException);
  });

  it('should throw BadRequestException if organizationId is missing', async () => {
    const context = createMockContext({ user: { userId: '123' }, headers: {}, params: {} });
    await expect(guard.canActivate(context)).rejects.toThrow(BadRequestException);
  });

  it('should allow access if user is a member', async () => {
    const user = { userId: 'u1' };
    const orgId = 'o1';
    const mockMembership = {
      id: 'm1',
      roles: [{ name: 'ADMIN', permissions: [{ action: 'read', resource: 'venue' }] }]
    };

    mockOrganizationsService.getMembership.mockResolvedValue(mockMembership);

    const context = createMockContext({
      user,
      headers: { 'x-organization-id': orgId },
      params: {}
    });

    const result = await guard.canActivate(context);
    expect(result).toBe(true);

    const req = context.switchToHttp().getRequest();
    expect(req.organizationId).toBe(orgId);
    expect(req.user.permissions).toContain('read:venue');
  });

  function createMockContext(reqData: any): ExecutionContext {
    return {
      switchToHttp: () => ({
        getRequest: () => reqData,
      }),
    } as any;
  }
});
