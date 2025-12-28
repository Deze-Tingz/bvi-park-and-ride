/**
 * JWT Strategy
 *
 * Passport strategy for validating JWT tokens.
 * Extracts the token from the Authorization header,
 * validates it, and attaches the user to the request.
 *
 * LEARNING NOTE:
 * Passport.js uses strategies to handle different auth methods.
 * This strategy handles JWT tokens. The validate() method is called
 * after the token is verified, and its return value becomes req.user.
 */

import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { AuthService } from '../auth.service';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private configService: ConfigService,
    private authService: AuthService,
  ) {
    super({
      // Extract token from Bearer header
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      // Don't ignore expired tokens
      ignoreExpiration: false,
      // Secret key for verification
      secretOrKey: configService.get<string>('JWT_SECRET'),
    });
  }

  /**
   * Validate the JWT payload
   * Called after token is verified
   * Return value becomes req.user
   */
  async validate(payload: { sub: string; email: string; role: string }) {
    // Verify the user still exists in the database
    const user = await this.authService.validateUser(payload.sub);

    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    // Return user info to be attached to request
    return {
      id: payload.sub,
      email: payload.email,
      role: payload.role,
    };
  }
}
