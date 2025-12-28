# BVI Park & Ride Shuttle - System Architecture

## Overview

```
                                    ┌─────────────────┐
                                    │   Admin Web     │
                                    │   (Next.js)     │
                                    └────────┬────────┘
                                             │
    ┌─────────────────┐              ┌───────▼────────┐              ┌─────────────────┐
    │   Rider App     │◄────────────►│    NestJS      │◄────────────►│   Driver App    │
    │   (Flutter)     │   WebSocket  │    Backend     │   WebSocket  │   (Flutter)     │
    └─────────────────┘              └───────┬────────┘              └─────────────────┘
                                             │
                              ┌──────────────┼──────────────┐
                              │              │              │
                       ┌──────▼─────┐ ┌──────▼─────┐ ┌──────▼─────┐
                       │ PostgreSQL │ │   Redis    │ │  Mapbox    │
                       │  Database  │ │  Pub/Sub   │ │    API     │
                       └────────────┘ └────────────┘ └────────────┘
```

## Technology Stack

### Backend (NestJS)
| Component | Technology | Purpose |
|-----------|------------|---------|
| Framework | NestJS | REST APIs, WebSockets, modules |
| Database | PostgreSQL | Persistent data storage |
| Cache | Redis | Pub/sub, session cache, rate limiting |
| WebSockets | Socket.IO | Real-time vehicle tracking |
| Auth | JWT + Passport | Authentication & authorization |
| Validation | class-validator | Request validation |
| API Docs | Swagger | API documentation |

### Mobile Apps (Flutter)
| Component | Technology | Purpose |
|-----------|------------|---------|
| Framework | Flutter | Cross-platform mobile |
| State | Riverpod | State management |
| Maps | Mapbox | Map rendering |
| Location | Geolocator | GPS access |
| HTTP | Dio | REST API calls |
| WebSocket | socket_io_client | Real-time updates |
| Storage | flutter_secure_storage | Token storage |
| Routing | go_router | Navigation |

### Admin Dashboard (Next.js)
| Component | Technology | Purpose |
|-----------|------------|---------|
| Framework | Next.js 14 | React with App Router |
| Styling | Tailwind CSS | Utility-first CSS |
| Maps | react-map-gl | Mapbox React wrapper |
| Charts | Recharts | Analytics visualization |
| State | TanStack Query | Server state management |
| WebSocket | socket.io-client | Real-time updates |

## Module Structure (NestJS)

```
services/api/src/
├── app.module.ts                 # Root module
├── main.ts                       # Entry point
│
├── modules/
│   ├── auth/                     # Authentication
│   │   ├── auth.module.ts
│   │   ├── auth.controller.ts    # Login, register endpoints
│   │   ├── auth.service.ts       # JWT token logic
│   │   ├── strategies/
│   │   │   └── jwt.strategy.ts   # Passport JWT strategy
│   │   ├── guards/
│   │   │   ├── jwt-auth.guard.ts
│   │   │   └── roles.guard.ts
│   │   └── dto/
│   │       ├── login.dto.ts
│   │       └── register.dto.ts
│   │
│   ├── vehicles/                 # Vehicle management
│   │   ├── vehicles.module.ts
│   │   ├── vehicles.controller.ts
│   │   ├── vehicles.service.ts
│   │   ├── entities/
│   │   │   └── vehicle.entity.ts
│   │   └── dto/
│   │       └── create-vehicle.dto.ts
│   │
│   ├── routes/                   # Route management
│   │   ├── routes.module.ts
│   │   ├── routes.controller.ts
│   │   ├── routes.service.ts
│   │   ├── entities/
│   │   │   └── route.entity.ts
│   │   └── dto/
│   │       └── create-route.dto.ts
│   │
│   ├── stops/                    # Stop management
│   │   ├── stops.module.ts
│   │   ├── stops.controller.ts
│   │   ├── stops.service.ts
│   │   ├── entities/
│   │   │   └── stop.entity.ts
│   │   └── dto/
│   │       └── create-stop.dto.ts
│   │
│   ├── tracking/                 # Real-time tracking
│   │   ├── tracking.module.ts
│   │   ├── tracking.gateway.ts   # WebSocket gateway
│   │   ├── tracking.service.ts
│   │   └── dto/
│   │       └── location-update.dto.ts
│   │
│   ├── eta/                      # ETA calculations
│   │   ├── eta.module.ts
│   │   └── eta.service.ts
│   │
│   ├── notifications/            # Push notifications
│   │   ├── notifications.module.ts
│   │   └── notifications.service.ts
│   │
│   └── admin/                    # Admin operations
│       ├── admin.module.ts
│       ├── admin.controller.ts
│       └── admin.service.ts
│
├── database/
│   ├── database.module.ts
│   └── migrations/
│
└── common/
    ├── decorators/
    ├── filters/
    ├── interceptors/
    └── pipes/
```

## Database Schema

```sql
-- Core entities
┌─────────────────────────────────────────────────────────────────┐
│                          users                                   │
├─────────────────────────────────────────────────────────────────┤
│ id            UUID PRIMARY KEY                                   │
│ email         VARCHAR(255) UNIQUE NOT NULL                       │
│ password_hash VARCHAR(255)                                       │
│ role          VARCHAR(50) DEFAULT 'rider' -- rider, admin        │
│ fcm_token     VARCHAR(255)                                       │
│ created_at    TIMESTAMP DEFAULT NOW()                            │
│ updated_at    TIMESTAMP DEFAULT NOW()                            │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         drivers                                  │
├─────────────────────────────────────────────────────────────────┤
│ id                  UUID PRIMARY KEY                             │
│ user_id             UUID REFERENCES users(id)                    │
│ name                VARCHAR(255) NOT NULL                        │
│ email               VARCHAR(255) UNIQUE NOT NULL                 │
│ phone               VARCHAR(50)                                  │
│ license_number      VARCHAR(100)                                 │
│ status              VARCHAR(50) DEFAULT 'offline'                │
│ assigned_vehicle_id UUID                                         │
│ assigned_route_id   UUID                                         │
│ fcm_token           VARCHAR(255)                                 │
│ created_at          TIMESTAMP DEFAULT NOW()                      │
│ updated_at          TIMESTAMP DEFAULT NOW()                      │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         vehicles                                 │
├─────────────────────────────────────────────────────────────────┤
│ id                UUID PRIMARY KEY                               │
│ name              VARCHAR(255) NOT NULL                          │
│ plate_number      VARCHAR(50) UNIQUE NOT NULL                    │
│ vehicle_type      VARCHAR(50) DEFAULT 'shuttle'                  │
│ capacity          INTEGER DEFAULT 15                             │
│ status            VARCHAR(50) DEFAULT 'available'                │
│ current_driver_id UUID REFERENCES drivers(id)                    │
│ current_route_id  UUID                                           │
│ created_at        TIMESTAMP DEFAULT NOW()                        │
│ updated_at        TIMESTAMP DEFAULT NOW()                        │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                          routes                                  │
├─────────────────────────────────────────────────────────────────┤
│ id          UUID PRIMARY KEY                                     │
│ name        VARCHAR(255) NOT NULL -- "Green Line", "Yellow Line" │
│ color       VARCHAR(50) NOT NULL  -- "#22c55e", "#eab308"        │
│ description TEXT                                                 │
│ geojson     JSONB                 -- Full route polyline         │
│ is_active   BOOLEAN DEFAULT true                                 │
│ created_at  TIMESTAMP DEFAULT NOW()                              │
│ updated_at  TIMESTAMP DEFAULT NOW()                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                          stops                                   │
├─────────────────────────────────────────────────────────────────┤
│ id         UUID PRIMARY KEY                                      │
│ name       VARCHAR(255) NOT NULL                                 │
│ latitude   DECIMAL(10, 8) NOT NULL                               │
│ longitude  DECIMAL(11, 8) NOT NULL                               │
│ address    TEXT                                                  │
│ is_active  BOOLEAN DEFAULT true                                  │
│ created_at TIMESTAMP DEFAULT NOW()                               │
│ updated_at TIMESTAMP DEFAULT NOW()                               │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                       route_stops                                │
├─────────────────────────────────────────────────────────────────┤
│ id             UUID PRIMARY KEY                                  │
│ route_id       UUID REFERENCES routes(id) ON DELETE CASCADE      │
│ stop_id        UUID REFERENCES stops(id) ON DELETE CASCADE       │
│ sequence_order INTEGER NOT NULL                                  │
│ UNIQUE(route_id, stop_id)                                        │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    vehicle_locations                             │
├─────────────────────────────────────────────────────────────────┤
│ id          UUID PRIMARY KEY                                     │
│ vehicle_id  UUID REFERENCES vehicles(id)                         │
│ latitude    DECIMAL(10, 8) NOT NULL                              │
│ longitude   DECIMAL(11, 8) NOT NULL                              │
│ speed       DECIMAL(5, 2)                                        │
│ heading     DECIMAL(5, 2)                                        │
│ accuracy    DECIMAL(5, 2)                                        │
│ recorded_at TIMESTAMP DEFAULT NOW()                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      driver_shifts                               │
├─────────────────────────────────────────────────────────────────┤
│ id         UUID PRIMARY KEY                                      │
│ driver_id  UUID REFERENCES drivers(id)                           │
│ vehicle_id UUID REFERENCES vehicles(id)                          │
│ route_id   UUID REFERENCES routes(id)                            │
│ started_at TIMESTAMP DEFAULT NOW()                               │
│ ended_at   TIMESTAMP                                             │
│ status     VARCHAR(50) DEFAULT 'active'                          │
└─────────────────────────────────────────────────────────────────┘
```

## WebSocket Events

### Tracking Gateway (`/tracking`)

**Client → Server:**
```typescript
// Driver sends location update
socket.emit('driver:location', {
  vehicleId: 'uuid',
  latitude: 18.4285,
  longitude: -64.6189,
  speed: 25.5,
  heading: 180.0,
  accuracy: 5.0,
  timestamp: '2024-01-15T10:30:00Z'
});

// Rider subscribes to a route
socket.emit('subscribe:route', { routeId: 'green-line' });

// Rider unsubscribes from a route
socket.emit('unsubscribe:route', { routeId: 'green-line' });
```

**Server → Client:**
```typescript
// Vehicle position update (broadcast to route subscribers)
socket.on('vehicle:update', {
  vehicleId: 'uuid',
  routeId: 'green-line',
  latitude: 18.4285,
  longitude: -64.6189,
  speed: 25.5,
  heading: 180.0,
  status: 'on_route', // on_route, at_stop, full, out_of_service
  nextStopId: 'stop-003',
  nextStopEta: 120 // seconds
});

// Vehicle arrived at stop
socket.on('stop:arrival', {
  vehicleId: 'uuid',
  stopId: 'stop-003',
  stopName: 'Bobby\'s Supermarket',
  timestamp: '2024-01-15T10:30:00Z'
});

// Broadcast alert
socket.on('alert:broadcast', {
  type: 'info', // info, warning, emergency
  title: 'Service Update',
  message: 'Green Line delayed by 10 minutes',
  timestamp: '2024-01-15T10:30:00Z'
});
```

## API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/register` | Register new user |
| POST | `/auth/login` | Login and get JWT |
| POST | `/auth/refresh` | Refresh JWT token |

### Routes
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/routes` | Get all routes |
| GET | `/routes/:id` | Get route by ID |
| GET | `/routes/:id/stops` | Get stops for a route |
| POST | `/routes` | Create route (admin) |
| PATCH | `/routes/:id` | Update route (admin) |

### Stops
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/stops` | Get all stops |
| GET | `/stops/:id` | Get stop by ID |
| GET | `/stops/nearest` | Get nearest stop to coordinates |
| POST | `/stops` | Create stop (admin) |
| PATCH | `/stops/:id` | Update stop (admin) |

### Vehicles
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/vehicles` | Get all vehicles |
| GET | `/vehicles/:id` | Get vehicle by ID |
| GET | `/vehicles/:id/location` | Get current location |
| POST | `/vehicles` | Create vehicle (admin) |
| PATCH | `/vehicles/:id` | Update vehicle (admin) |

### Driver
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/driver/shift/start` | Start shift |
| POST | `/driver/shift/end` | End shift |
| POST | `/driver/status` | Update status (full, etc.) |
| POST | `/driver/stop/arrived` | Mark arrived at stop |
| POST | `/driver/stop/departed` | Mark departed from stop |

### ETA
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/eta/:stopId` | Get ETA to stop |
| GET | `/eta/route/:routeId` | Get ETAs for all stops on route |

## Real-time Tracking Flow

```
1. Driver starts shift
   └─► Driver App sends POST /driver/shift/start
       └─► Backend assigns vehicle & route
           └─► Backend creates shift record

2. Driver broadcasts location
   └─► Driver App emits 'driver:location' every 1-3 seconds
       └─► Backend validates GPS data
           └─► Backend updates vehicle_locations table
               └─► Backend calculates ETAs
                   └─► Backend broadcasts 'vehicle:update' to route subscribers

3. Rider receives update
   └─► Rider App receives 'vehicle:update'
       └─► Rider App interpolates position for smooth animation
           └─► Rider App updates ETA display
```

## Deployment

### Docker Compose Services
```yaml
services:
  postgres:    # PostgreSQL 15
  redis:       # Redis 7 Alpine
  api:         # NestJS backend
  admin:       # Next.js dashboard
```

### Environment Variables
```
DATABASE_URL=postgresql://user:pass@postgres:5432/bvi_park_ride
REDIS_URL=redis://redis:6379
JWT_SECRET=<secret>
MAPBOX_TOKEN=<token>
FCM_SERVER_KEY=<key>
```

## Security Considerations

1. **Authentication**: JWT tokens with short expiry, refresh tokens
2. **Authorization**: Role-based access (rider, driver, admin)
3. **Rate Limiting**: Redis-based rate limiting on API endpoints
4. **Input Validation**: class-validator on all DTOs
5. **CORS**: Configured for specific origins
6. **HTTPS**: Required in production
7. **Secrets**: Environment variables, never in code
