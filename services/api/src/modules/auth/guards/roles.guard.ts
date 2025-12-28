/**
 * Roles Guard
 *
 * This guard checks if the authenticated user has the required role.
 * Used with @Roles() decorator to protect admin-only endpoints.
 *
 * Usage:
 * @Roles('admin')
 * @UseGuards(JwtAuthGuard, RolesGuard)
 * async adminOnlyEndpoint() { ... }
 */

import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    // Get the roles required for this endpoint
    const requiredRoles = this.reflector.get<string[]>(
      'roles',
      context.getHandler(),
    );

    // If no roles specified, allow access
    if (!requiredRoles) {
      return true;
    }

    // Get the user from the request (set by JwtAuthGuard)
    const { user } = context.switchToHttp().getRequest();

    // Check if user's role matches any of the required roles
    return requiredRoles.includes(user.role);
  }
}
