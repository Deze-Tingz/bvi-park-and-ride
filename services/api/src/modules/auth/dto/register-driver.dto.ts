/**
 * Register Driver DTO
 * Includes additional fields required for driver accounts
 */

import { ApiProperty } from '@nestjs/swagger';
import {
  IsEmail,
  IsString,
  MinLength,
  MaxLength,
  IsOptional,
} from 'class-validator';

export class RegisterDriverDto {
  @ApiProperty({
    example: 'driver@example.com',
    description: 'Driver email address',
  })
  @IsEmail()
  email: string;

  @ApiProperty({
    example: 'SecurePass123!',
    description: 'Password (min 8 characters)',
  })
  @IsString()
  @MinLength(8)
  @MaxLength(100)
  password: string;

  @ApiProperty({
    example: 'John Smith',
    description: 'Driver full name',
  })
  @IsString()
  @MinLength(2)
  @MaxLength(255)
  name: string;

  @ApiProperty({
    example: '+1-284-555-0123',
    description: 'Driver phone number',
    required: false,
  })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiProperty({
    example: 'BVI-DL-12345',
    description: 'Driver license number',
  })
  @IsString()
  licenseNumber: string;
}
