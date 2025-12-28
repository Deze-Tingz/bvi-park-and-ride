/**
 * Auth Service
 *
 * Business logic for authentication:
 * - Password hashing with bcrypt
 * - JWT token generation
 * - User validation
 *
 * LEARNING NOTE:
 * Services contain the business logic. They're reusable across
 * controllers and can be injected into other services. This is
 * where the "real work" happens.
 */

import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';

import { User } from '../../database/entities/user.entity';
import { Driver } from '../../database/entities/driver.entity';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { RegisterDriverDto } from './dto/register-driver.dto';

@Injectable()
export class AuthService {
  constructor(
    // Inject the User repository (database access)
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,

    // Inject the Driver repository
    @InjectRepository(Driver)
    private readonly driverRepository: Repository<Driver>,

    // Inject JWT service for token generation
    private readonly jwtService: JwtService,
  ) {}

  /**
   * Register a new rider
   * @param registerDto - Email and password
   * @returns User object (without password)
   */
  async register(registerDto: RegisterDto) {
    const { email, password } = registerDto;

    // Check if email already exists
    const existingUser = await this.userRepository.findOne({
      where: { email },
    });

    if (existingUser) {
      throw new ConflictException('Email already registered');
    }

    // Hash the password (never store plain text passwords!)
    const passwordHash = await bcrypt.hash(password, 10);

    // Create the user
    const user = this.userRepository.create({
      email,
      passwordHash,
      role: 'rider',
    });

    await this.userRepository.save(user);

    // Return user without password
    const { passwordHash: _, ...result } = user;
    return result;
  }

  /**
   * Login and get JWT token
   * @param loginDto - Email and password
   * @returns JWT access token
   */
  async login(loginDto: LoginDto) {
    const { email, password } = loginDto;

    // Find user by email
    const user = await this.userRepository.findOne({
      where: { email },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Compare password with hash
    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);

    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Generate JWT token
    // The payload is what gets encoded in the token
    const payload = {
      sub: user.id,      // 'sub' is standard JWT claim for subject (user ID)
      email: user.email,
      role: user.role,
    };

    return {
      accessToken: this.jwtService.sign(payload),
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
      },
    };
  }

  /**
   * Register a new driver
   * Creates both User and Driver records
   */
  async registerDriver(registerDriverDto: RegisterDriverDto) {
    const { email, password, name, phone, licenseNumber } = registerDriverDto;

    // Check if email already exists
    const existingUser = await this.userRepository.findOne({
      where: { email },
    });

    if (existingUser) {
      throw new ConflictException('Email already registered');
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 10);

    // Create user with driver role
    const user = this.userRepository.create({
      email,
      passwordHash,
      role: 'driver',
    });

    await this.userRepository.save(user);

    // Create driver profile
    const driver = this.driverRepository.create({
      userId: user.id,
      name,
      email,
      phone,
      licenseNumber,
      status: 'offline',
    });

    await this.driverRepository.save(driver);

    return {
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
      },
      driver: {
        id: driver.id,
        name: driver.name,
        status: driver.status,
      },
    };
  }

  /**
   * Get user profile by ID
   */
  async getProfile(userId: string) {
    const user = await this.userRepository.findOne({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // If user is a driver, include driver info
    if (user.role === 'driver') {
      const driver = await this.driverRepository.findOne({
        where: { userId },
      });

      return {
        id: user.id,
        email: user.email,
        role: user.role,
        driver: driver ? {
          id: driver.id,
          name: driver.name,
          status: driver.status,
          assignedVehicleId: driver.assignedVehicleId,
          assignedRouteId: driver.assignedRouteId,
        } : null,
      };
    }

    return {
      id: user.id,
      email: user.email,
      role: user.role,
    };
  }

  /**
   * Validate user by ID (used by JWT strategy)
   */
  async validateUser(userId: string) {
    return this.userRepository.findOne({
      where: { id: userId },
    });
  }
}
