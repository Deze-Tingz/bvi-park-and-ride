/**
 * JWT Auth Guard
 *
 * This guard protects routes that require authentication.
 * It validates the JWT token in the Authorization header.
 *
 * Usage:
 * @UseGuards(JwtAuthGuard)
 * async myProtectedEndpoint() { ... }
 */

import { Injectable, ExecutionContext } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  canActivate(context: ExecutionContext) {
    // Call the parent AuthGuard's canActivate
    // This triggers the JWT strategy validation
    return super.canActivate(context);
  }
}
