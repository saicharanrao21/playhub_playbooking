import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { PrismaService } from '../prisma/prisma.service';

@ApiTags('health')
@Controller('health')
export class HealthController {
  constructor(private prisma: PrismaService) {}

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
  async readiness() {
    try {
      // Basic check to see if DB is reachable
      await this.prisma.$queryRaw`SELECT 1`;
      return {
        status: 'ready',
        database: 'connected',
      };
    } catch (error) {
      return {
        status: 'not_ready',
        database: 'disconnected',
        error: process.env.NODE_ENV !== 'production' ? error.message : undefined,
      };
    }
  }
}
