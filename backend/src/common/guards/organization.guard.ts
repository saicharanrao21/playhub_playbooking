import { Injectable, CanActivate, ExecutionContext, ForbiddenException, BadRequestException } from '@nestjs/common';
import { OrganizationsService } from '../../organizations/organizations.service';

@Injectable()
export class OrganizationGuard implements CanActivate {
  constructor(private organizationsService: OrganizationsService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user || !user.userId) {
      throw new ForbiddenException('User context missing');
    }

    // Try to get organizationId from header first, then from path params
    let organizationId = request.headers['x-organization-id'];
    if (!organizationId) {
      organizationId = request.params.organizationId;
    }

    if (!organizationId) {
      throw new BadRequestException('Organization context required');
    }

    const membership = await this.organizationsService.getMembership(user.userId, organizationId);

    if (!membership) {
      throw new ForbiddenException('User is not a member of this organization');
    }

    // Extract all permissions from all roles
    const roles = membership.roles.map(r => r.name);
    const permissions = new Set<string>();

    membership.roles.forEach(role => {
      role.permissions.forEach(permission => {
        permissions.add(`${permission.action}:${permission.resource}`);
      });
    });

    // Enforce the verified identity on the request
    request.organizationId = organizationId;
    request.membershipId = membership.id;
    request.user.organizationId = organizationId;
    request.user.membershipId = membership.id;
    request.user.roles = roles;
    request.user.permissions = Array.from(permissions);

    return true;
  }
}
