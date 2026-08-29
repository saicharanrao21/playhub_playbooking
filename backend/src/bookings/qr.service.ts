import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class QrService {
  constructor(
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  async generateBookingToken(bookingId: string, organizationId: string) {
    const payload = {
      bid: bookingId,
      oid: organizationId,
      purpose: 'booking_checkin',
    };
    return this.jwtService.signAsync(payload, {
      secret: this.configService.get('JWT_ACCESS_SECRET'),
      expiresIn: '24h',
    });
  }

  async verifyBookingToken(token: string) {
    try {
      const payload = await this.jwtService.verifyAsync(token, {
        secret: this.configService.get('JWT_ACCESS_SECRET'),
      });
      if (payload.purpose !== 'booking_checkin') {
        return null;
      }
      return {
        bookingId: payload.bid,
        organizationId: payload.oid,
      };
    } catch (e) {
      return null;
    }
  }
}
