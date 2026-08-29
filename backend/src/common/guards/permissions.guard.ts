import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PERMISSION_KEY } from '../decorators/require-permission.decorator';

@Injectable()
export class PermissionsGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredPermissions = this.reflector.getAllAndOverride<string[]>(PERMISSION_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!requiredPermissions || requiredPermissions.length === 0) {
      return true;
    }

    const { user } = context.switchToHttp().getRequest();

    if (!user || !user.permissions) {
      throw new ForbiddenException('Insufficient permissions');
    }

    // Platform Admins and Super Admins bypass individual permission checks
    if (
      user.roles?.includes('PLATFORM_ADMIN') ||
      user.roles?.includes('PLAYHUB_SUPER_ADMIN') ||
      user.isPlatformAdmin ||
      user.permissions.includes('*')
    ) {
      return true;
    }

    const hasPermission = requiredPermissions.every((permission) =>
      user.permissions.includes(permission) || user.permissions.includes('*'),
    );

    if (!hasPermission) {
      throw new ForbiddenException('Insufficient permissions');
    }

    return true;
  }
}
