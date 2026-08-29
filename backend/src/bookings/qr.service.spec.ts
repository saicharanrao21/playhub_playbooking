import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { QrService } from './qr.service';

describe('QrService', () => {
  let service: QrService;
  let jwtService: JwtService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        QrService,
        {
          provide: JwtService,
          useValue: {
            signAsync: jest.fn().mockResolvedValue('mock-token'),
            verifyAsync: jest.fn().mockResolvedValue({ bid: 'b1', oid: 'org1', purpose: 'booking_checkin' }),
          },
        },
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn().mockReturnValue('secret'),
          },
        },
      ],
    }).compile();

    service = module.get<QrService>(QrService);
    jwtService = module.get<JwtService>(JwtService);
  });

  it('should generate a token', async () => {
    const token = await service.generateBookingToken('b1', 'org1');
    expect(token).toBe('mock-token');
    expect(jwtService.signAsync).toHaveBeenCalled();
  });

  it('should verify a token', async () => {
    const payload = await service.verifyBookingToken('mock-token');
    expect(payload).toEqual({ bookingId: 'b1', organizationId: 'org1' });
  });

  it('should return null for invalid purpose', async () => {
    (jwtService.verifyAsync as jest.Mock).mockResolvedValue({ bid: 'b1', oid: 'org1', purpose: 'wrong' });
    const payload = await service.verifyBookingToken('mock-token');
    expect(payload).toBeNull();
  });
});
