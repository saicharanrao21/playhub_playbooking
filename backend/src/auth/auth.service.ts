import {
  Injectable,
  UnauthorizedException,
  ForbiddenException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { UsersService } from '../users/users.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private prisma: PrismaService,
    private usersService: UsersService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  async register(registerDto: RegisterDto) {
    const existingUser = await this.usersService.findByEmail(registerDto.email);
    if (existingUser) {
      throw new ConflictException('User already exists');
    }

    const passwordHash = await bcrypt.hash(registerDto.password, 10);

    const user = await this.prisma.user.create({
      data: {
        email: registerDto.email,
        fullName: registerDto.fullName,
        passwordHash,
      },
    });

    return this.login({ email: user.email, password: registerDto.password });
  }

  async login(loginDto: LoginDto) {
    const user = await this.usersService.findByEmail(loginDto.email);
    if (!user || !user.passwordHash) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isPasswordValid = await bcrypt.compare(
      loginDto.password,
      user.passwordHash,
    );
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Create session
    const sessionId = crypto.randomUUID();
    const sessionExpiresAt = new Date();
    sessionExpiresAt.setDate(sessionExpiresAt.getDate() + 7); // 7 days for session

    await this.prisma.session.create({
      data: {
        id: sessionId,
        userId: user.id,
        expiresAt: sessionExpiresAt,
      },
    });

    return this.generateTokens(user.id, user.email, sessionId);
  }

  async refresh(refreshToken: string) {
    const tokenHash = this._hashToken(refreshToken);

    try {
      const payload = await this.jwtService.verifyAsync(refreshToken, {
        secret: this.configService.get('JWT_REFRESH_SECRET'),
      });

      // Transaction to handle concurrent refresh and ensure atomicity
      return await this.prisma.$transaction(async (tx) => {
        // 1. Find the token record
        const tokenRecord = await tx.refreshToken.findUnique({
          where: { tokenHash },
          include: { session: true },
        });

        // 2. Reuse Detection
        if (!tokenRecord || tokenRecord.isUsed || tokenRecord.isRevoked || !tokenRecord.session.isActive) {
          this.logger.warn(`Potential refresh token reuse or invalid token detected for session: ${payload.sid}`);

          if (tokenRecord) {
            // Revoke the entire session family
            await tx.session.update({
              where: { id: tokenRecord.sessionId },
              data: { isActive: false, revokedAt: new Date() },
            });

            await tx.refreshToken.updateMany({
              where: { sessionId: tokenRecord.sessionId },
              data: { isRevoked: true },
            });

            await tx.auditLog.create({
              data: {
                userId: payload.sub,
                action: 'security:refresh_token_reuse_detected',
                resource: 'session',
                resourceId: tokenRecord.sessionId,
                status: 'failure',
                payload: { reason: 'Token already used or revoked' },
              },
            });
          }

          throw new UnauthorizedException({
            message: 'Authentication session compromised. Please login again.',
            code: 'SESSION_COMPROMISED',
          });
        }

        // 3. Session Expiry check
        if (tokenRecord.session.expiresAt < new Date()) {
           throw new UnauthorizedException('Session expired');
        }

        // 4. Mark current token as used atomically to prevent race conditions
        try {
          await tx.refreshToken.update({
            where: {
              id: tokenRecord.id,
              isUsed: false,
              isRevoked: false,
            },
            data: { isUsed: true },
          });
        } catch (e) {
          // If update fails, it means another request already used/revoked it
          this.logger.warn(`Race condition or reuse detected during refresh for session: ${payload.sid}`);
          throw new UnauthorizedException({
            message: 'Authentication session compromised.',
            code: 'SESSION_COMPROMISED',
          });
        }

        // 5. Issue new tokens
        return this.generateTokens(payload.sub, payload.email, payload.sid, tx);
      });
    } catch (e) {
      if (e instanceof UnauthorizedException) throw e;
      this.logger.error('Token refresh failed', e.stack);
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  async generateTokens(userId: string, email: string, sessionId: string, tx?: any) {
    const payload = { sub: userId, email, sid: sessionId };

    const accessToken = await this.jwtService.signAsync(payload, {
      secret: this.configService.get('JWT_ACCESS_SECRET'),
      expiresIn: this.configService.get('JWT_ACCESS_EXPIRES_IN'),
    });

    const refreshToken = await this.jwtService.signAsync(payload, {
      secret: this.configService.get('JWT_REFRESH_SECRET'),
      expiresIn: this.configService.get('JWT_REFRESH_EXPIRES_IN'),
    });

    const tokenHash = this._hashToken(refreshToken);
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // Match JWT expiry

    const prisma = tx || this.prisma;
    await prisma.refreshToken.create({
      data: {
        tokenHash,
        sessionId,
        expiresAt,
      },
    });

    return {
      accessToken,
      refreshToken,
    };
  }

  async logout(sessionId: string) {
    await this.prisma.$transaction([
        this.prisma.session.update({
          where: { id: sessionId },
          data: { isActive: false, revokedAt: new Date() },
        }),
        this.prisma.refreshToken.updateMany({
          where: { sessionId },
          data: { isRevoked: true }
        })
    ]);
    return { success: true };
  }

  private _hashToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }
}
