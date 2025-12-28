# BVI Park & Ride Shuttle - Product Requirements Document

## Executive Summary

The BVI Park & Ride Shuttle is a **GovTech SaaS platform** providing Uber-like real-time transit tracking for the British Virgin Islands Government's Park & Ride shuttle service. The platform is **free for riders** - the Government/Operator pays for the software.

## Product Vision

Deliver a premium, Uber-quality experience for a fixed-route shuttle service in Road Town, Tortola. Users should experience:
- Live moving vehicles on a map
- Smooth animations (no teleporting)
- Accurate ETAs
- Real-time updates
- Map-first user experience

## Target Users

### 1. Riders (Public)
- Residents and visitors in the BVI
- People commuting to/from parking areas
- Free access, no registration required for basic tracking

### 2. Drivers (Restricted)
- Licensed shuttle operators
- Government-approved drivers
- Authenticated access only

### 3. Administrators
- BVI Government transit officials
- Fleet managers
- Operations supervisors

## Core Features

### Rider App (Mobile - Flutter)

| Feature | Priority | Description |
|---------|----------|-------------|
| Live Map | P0 | Full-screen Mapbox map showing current location |
| Vehicle Tracking | P0 | Real-time shuttle positions with smooth animations |
| Route Display | P0 | Green and Yellow line routes shown as polylines |
| Stop Markers | P0 | All official stops displayed on map |
| Nearest Stop | P0 | Automatically identify closest stop to user |
| ETA Display | P0 | "Next shuttle in X minutes" |
| Route Selection | P1 | Filter to show only Green or Yellow line |
| Push Notifications | P1 | Alerts when shuttle is approaching |
| Offline Mode | P2 | Basic schedule available offline |

### Driver App (Mobile - Flutter)

| Feature | Priority | Description |
|---------|----------|-------------|
| Shift Management | P0 | Start/End shift buttons |
| Route Assignment | P0 | Display assigned route (Green/Yellow) |
| GPS Broadcasting | P0 | Continuous location updates to backend |
| Stop Checklist | P0 | Arrived/Departed buttons at each stop |
| Status Controls | P0 | Full/Out of Service toggles |
| Incident Reporting | P1 | Report delays, issues |
| Battery Optimization | P1 | Adaptive GPS frequency |

### Admin Dashboard (Web - Next.js)

| Feature | Priority | Description |
|---------|----------|-------------|
| Live Fleet Map | P0 | Same map fidelity as rider app |
| Vehicle Status | P0 | Real-time status of all vehicles |
| Route Management | P1 | Edit routes and stops |
| Broadcast Alerts | P1 | Send notifications to all riders |
| Analytics | P1 | Peak stops, headways, on-time performance |
| Driver Management | P2 | Add/remove/manage drivers |
| SLA Monitoring | P2 | Last-seen alerts, silent vehicle detection |

## Routes & Stops

### Green Line
Primary route serving the western corridor.

### Yellow Line
Primary route serving the eastern corridor.

### Official Stops (16+)
1. Festival Grounds Parking Lot
2. CCT / Eureka Parking
3. Bobby's Supermarket
4. Mill Mall
5. Banco Popular
6. Tortola Pier Park (rear parking)
7. Ferry Terminal
8. RiteWay Road Reef
9. Slaney Hill Roundabout
10. Dr. D. Orlando Smith Hospital lot
11. Pusser's Parking
12. Elmore Stoutt High School
13. Road Town Police Station
14. Althea Scatliffe Primary
15. OneMart Parking Lot
16. Delta / Golden Hind
17. Moorings

## Technical Requirements

### Real-time Tracking
- GPS updates: 1-3 seconds when moving, 10-20 seconds when stopped
- WebSocket-based broadcasting
- Client-side interpolation for smooth animations
- Stale indicator when feed drops

### Performance
- Map load time: < 2 seconds
- ETA accuracy: within 2 minutes
- Vehicle position update latency: < 500ms

### Reliability
- 99.9% uptime target
- Graceful degradation when offline
- Automatic reconnection

## User Stories

### Rider Stories

**RS-1**: As a rider, I want to see where all shuttles are on a map so I can plan my trip.

**RS-2**: As a rider, I want to know how long until the next shuttle arrives at my stop.

**RS-3**: As a rider, I want to see which route each shuttle is on (Green/Yellow).

**RS-4**: As a rider, I want to find the nearest stop to my current location.

**RS-5**: As a rider, I want to receive a notification when my shuttle is approaching.

### Driver Stories

**DS-1**: As a driver, I want to start my shift and begin broadcasting my location.

**DS-2**: As a driver, I want to mark when I arrive at and depart from each stop.

**DS-3**: As a driver, I want to indicate when my shuttle is full.

**DS-4**: As a driver, I want to mark my vehicle as out of service if needed.

**DS-5**: As a driver, I want my app to conserve battery while still tracking accurately.

### Admin Stories

**AS-1**: As an admin, I want to see all vehicles on a live map.

**AS-2**: As an admin, I want to know if a vehicle has gone silent (no updates).

**AS-3**: As an admin, I want to broadcast emergency alerts to all riders.

**AS-4**: As an admin, I want to see analytics on stop usage and on-time performance.

**AS-5**: As an admin, I want to manage routes and stops without code changes.

## Success Metrics

| Metric | Target |
|--------|--------|
| ETA Accuracy | > 85% within 2 minutes |
| Map Load Time | < 2 seconds |
| Daily Active Riders | Track adoption |
| Driver App Usage | 100% of shifts |
| System Uptime | 99.9% |

## Out of Scope (v1)

- Payment processing
- Ride reservations
- Multi-island support
- Historical trip logging for riders
- Driver ratings

## Timeline

This is the developer's first NestJS project. Implementation follows the strict order:
1. Backend setup and core APIs
2. Data ingestion (stops/routes)
3. WebSocket tracking
4. Rider app with Mapbox
5. Driver app with GPS broadcasting
6. Admin dashboard
7. Docker infrastructure

## Appendix

### Glossary
- **Headway**: Time between successive shuttles on the same route
- **ETA**: Estimated Time of Arrival
- **Telemetry**: GPS and vehicle status data
- **GovTech**: Government Technology solutions
