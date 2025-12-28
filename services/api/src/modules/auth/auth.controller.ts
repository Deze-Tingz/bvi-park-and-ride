/**
 * Auth Controller
 *
 * REST API endpoints for authentication:
 * - POST /auth/register - Create new user account
 * - POST /auth/login - Login and get JWT token
 * - POST /auth/register-driver - Register as driver (requires additional info)
 * - GET /auth/profile - Get current user profile (requires authentication)
 *
 * LEARNING NOTE:
 * Controllers handle HTTP requests. They receive data, call services
 * to do the work, and return responses. Keep them thin - business
 * logic belongs in services.
 */

import {
  Controller,
  Post,
  Get,
  Body,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';

import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { RegisterDriverDto } from './dto/register-driver.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  /**
   * Register a new rider account
   * Riders are the general public using the shuttle service
   */
  @Post('register')
  @ApiOperation({ summary: 'Register a new rider account' })
  @ApiResponse({ status: 201, description: 'User successfully registered' })
  @ApiResponse({ status: 400, description: 'Invalid input data' })
  @ApiResponse({ status: 409, description: 'Email already exists' })
  async register(@Body() registerDto: RegisterDto) {
    return this.authService.register(registerDto);
  }

  /**
   * Login with email and password
   * Returns a JWT token for authenticated requests
   */
  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Login and get JWT token' })
  @ApiResponse({ status: 200, description: 'Login successful, returns token' })
  @ApiResponse({ status: 401, description: 'Invalid credentials' })
  async login(@Body() loginDto: LoginDto) {
    return this.authService.login(loginDto);
  }

  /**
   * Register a new driver account
   * Requires additional information like license number
   */
  @Post('register-driver')
  @ApiOperation({ summary: 'Register a new driver account' })
  @ApiResponse({ status: 201, description: 'Driver successfully registered' })
  @ApiResponse({ status: 400, description: 'Invalid input data' })
  @ApiResponse({ status: 409, description: 'Email already exists' })
  async registerDriver(@Body() registerDriverDto: RegisterDriverDto) {
    return this.authService.registerDriver(registerDriverDto);
  }

  /**
   * Get current user's profile
   * Requires authentication (JWT token in header)
   */
  @Get('profile')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current user profile' })
  @ApiResponse({ status: 200, description: 'Returns user profile' })
  @ApiResponse({ status: 401, description: 'Not authenticated' })
  async getProfile(@Request() req) {
    return this.authService.getProfile(req.user.id);
  }
}
