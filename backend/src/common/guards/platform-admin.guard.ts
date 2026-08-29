import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';

@Injectable()
export class PlatformAdminGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const { user } = context.switchToHttp().getRequest();

    const isPlatformAdmin =
      user?.isPlatformAdmin ||
      user?.roles?.includes('PLATFORM_ADMIN') ||
      user?.roles?.includes('PLAYHUB_SUPER_ADMIN') ||
      user?.roles?.includes('PLAYHUB_ADMIN');

    if (!isPlatformAdmin) {
      throw new ForbiddenException('Platform administrator access required');
    }

    return true;
  }
}
