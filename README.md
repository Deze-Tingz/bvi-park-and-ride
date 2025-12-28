# BVI Park & Ride Shuttle

A premium, Uber-like Park & Ride Shuttle platform for the British Virgin Islands (Tortola / Road Town).

## Overview

This is a **GovTech SaaS platform** providing real-time shuttle tracking for the BVI Government's Park & Ride service:
- **Riders** use the app for free
- **Government/Operator** pays for the software
- No rider payments, subscriptions, or in-app purchases

## Features

### Rider App (Mobile)
- Live map showing shuttle locations in real-time
- Smooth vehicle animations (Uber-like experience)
- Nearest stop detection
- ETA to next shuttle
- Route selection (Green Line / Yellow Line)
- Push notifications for arrivals

### Driver App (Mobile)
- Start/End shift management
- Route assignment
- Live GPS broadcasting
- Stop arrival/departure buttons
- Full/Out of Service status

### Admin Dashboard (Web)
- Live fleet map
- Vehicle status monitoring
- Route and stop management
- Analytics and reporting
- Broadcast alerts

## Tech Stack

| Component | Technology |
|-----------|------------|
| Backend | NestJS + PostgreSQL + Redis |
| Mobile Apps | Flutter + Riverpod |
| Maps | Mapbox |
| Real-time | WebSockets (Socket.IO) |
| Admin Dashboard | Next.js (coming soon) |

## Routes

- **Green Line**: Western corridor (Festival Grounds → Ferry Terminal)
- **Yellow Line**: Eastern corridor (RiteWay → Moorings → Ferry Terminal)

## Quick Start

```bash
# Start Docker services
cd infra && docker-compose up -d

# Start API
cd services/api && npm install && npm run start:dev

# Start Rider App
cd apps/rider_app && flutter pub get && flutter run
```

See [docs/FIRST_RUN.md](docs/FIRST_RUN.md) for detailed setup instructions.

## Documentation

- [Product Requirements (PRD)](docs/PRD.md)
- [System Architecture](docs/ARCHITECTURE.md)
- [First Run Guide](docs/FIRST_RUN.md)

## License

Proprietary - BVI Government
