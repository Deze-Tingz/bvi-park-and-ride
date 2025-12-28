/**
 * Location Update DTO
 *
 * Data structure for GPS updates from drivers.
 */

import { IsString, IsNumber, IsOptional, Min, Max } from 'class-validator';

export class LocationUpdateDto {
  @IsString()
  vehicleId: string;

  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  speed?: number; // km/h

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(360)
  heading?: number; // degrees (0 = North)

  @IsOptional()
  @IsNumber()
  @Min(0)
  accuracy?: number; // meters

  @IsOptional()
  @IsString()
  timestamp?: string;
}
