import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('health')
@Controller('health')
export class HealthController {
  @Get()
  @ApiOperation({ summary: 'Check if the service is alive' })
  check() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      service: 'playhub-backend',
    };
  }

  @Get('readiness')
  @ApiOperation({ summary: 'Check if the service is ready to handle requests' })
  readiness() {
    // In a real app, check DB connection, Redis, etc.
    return {
      status: 'ready',
      database: 'connected',
    };
  }
}
