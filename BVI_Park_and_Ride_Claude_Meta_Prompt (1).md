# 🚍 BVI Park & Ride Shuttle – Claude Code Master Meta Prompt

## Purpose
This document is a **master meta prompt** intended to be pasted directly into **Claude Code**.
It instructs Claude to design and build a **premium, Uber-like Park & Ride Shuttle platform**
for the **British Virgin Islands (Tortola / Road Town)**.

This is a **GovTech SaaS platform**:
- Riders use the app **for free**
- The **Government / Operator pays** for the software
- No rider payments, subscriptions, or in-app purchases

---

## 🔴 NON-NEGOTIABLE PRODUCT GOAL
The experience must feel **as close to Uber as possible**, even though it is a shuttle service.

Must include:
- Live moving vehicles
- Smooth map animations (no teleporting)
- Accurate ETAs
- Realtime updates via WebSockets
- Map-first UX
- Reliability suitable for government operations

---

## 🧠 SYSTEM ARCHITECTURE (LOCKED)

### Backend (NestJS)
**NestJS IS THE BACKEND.**

Responsibilities:
- REST APIs
- WebSockets (live tracking)
- Authentication
- Vehicle telemetry ingestion
- ETA calculations
- Notifications
- Admin operations

Stack:
- Node.js + NestJS
- PostgreSQL
- Redis (pub/sub + caching)
- Socket.IO WebSockets
- Docker-ready

---

### Mobile Apps
- Flutter
  - Rider App (public)
  - Driver App (restricted login)

---

### Web
- Admin Dashboard (Next.js or similar)
- Live fleet map identical in fidelity to rider app

---

### Maps
- Mapbox or Google Maps
- Must support:
  - Route polylines
  - Stop markers
  - Smooth animated vehicle markers
  - Optional snap-to-road

---

## 🗺️ DATA SOURCE (CRITICAL)
Park & Ride routes and stops are **publicly published by the BVI Government** via PDFs.

You MUST:
1. Treat these as **authoritative seed data**
2. Build an ingestion pipeline that produces:
   - stops.json
   - routes.geojson

### Example publicly listed stops:
Festival Grounds Parking Lot  
CCT / Eureka Parking  
Bobby’s Supermarket  
Mill Mall  
Banco Popular  
Tortola Pier Park (rear parking)  
Ferry Terminal  
RiteWay Road Reef  
Slaney Hill Roundabout  
Dr. D. Orlando Smith Hospital lot  
Pusser’s Parking  
Elmore Stoutt High School  
Road Town Police Station  
Althea Scatliffe Primary  
OneMart Parking Lot  
Delta / Golden Hind  
Moorings  

Routes:
- Green Line
- Yellow Line

### Ingestion Rules
- Support:
  - Manual YAML/JSON stop definitions
  - Optional PDF text extraction helper
- Geocode stops to lat/lng
- Output clean GeoJSON

---

## 📱 RIDER APP (FREE PUBLIC SERVICE)
Uber-like UX requirements:
- App opens directly to a **live map**
- User sees:
  - Their location
  - Nearest stops
  - Shuttles moving in real time
  - Route lines
- Pickup-first flow:
  - “Nearest stop”
  - “Next shuttle arriving in X min”
- Uber-style bottom card:
  - Finding shuttle
  - Shuttle approaching
  - Arrived
  - In transit
- Push notifications for arrivals and alerts

---

## 🚐 DRIVER APP
- Start / End shift
- Assigned route (Green / Yellow)
- Live GPS sharing
- Buttons:
  - Arrived
  - Departed
  - Full
  - Out of service
- Incident reporting
- Battery-aware tracking

---

## 🖥️ ADMIN DASHBOARD
- Live fleet map
- Vehicle status
- Route & stop management
- Broadcast alerts
- Analytics:
  - Peak stops
  - Headways
  - On-time performance
- SLA tools:
  - Last-seen alerts
  - Silent vehicle detection

---

## ⚡ REALTIME (UBER-LEVEL)

### Driver Telemetry
- Adaptive GPS updates:
  - Moving: every 1–3 seconds
  - Stopped: 10–20 seconds
- Payload:
  - lat, lng, speed, heading, accuracy, timestamp

### Backend
- Validate GPS
- Remove jitter
- Maintain last-known vehicle state
- Broadcast via WebSockets

### Rider Client
- Interpolate positions
- Smooth animations
- Heading-based rotation
- Stale indicator if feed drops

---

## 🧩 NESTJS MODULE STRUCTURE
```
auth
vehicles
routes
stops
tracking
eta
notifications
admin
```

Each module must include:
- Controller
- Service
- DTOs
- Clear comments explaining purpose

---

## 🧑‍🏫 LEARNING REQUIREMENT
This is the developer’s **first NestJS project**.

You MUST:
- Explain WHY each module exists
- Comment code generously
- Keep patterns simple
- Avoid over-engineering
- Build a working baseline before optimizations

---

## 📁 REQUIRED REPO STRUCTURE
```
/apps
  /rider_app
  /driver_app
  /admin_dashboard
/services
  /api
/data
  stops.json
  routes.geojson
  seed scripts
/docs
  PRD.md
  API.md
  ARCHITECTURE.md
  FIRST_RUN.md
/infra
  docker-compose.yml
  env.example
```

---

## 🛠️ IMPLEMENTATION ORDER (STRICT)
1. PRD + user stories
2. Architecture + DB schema
3. NestJS project setup
4. Core modules + REST APIs
5. WebSocket tracking gateway
6. Data ingestion (stops/routes)
7. Rider app map + realtime
8. Driver app telemetry
9. Admin dashboard
10. Local dev + Docker setup

---

## 📦 OUTPUT RULES
- Generate real files with paths
- Provide runnable code
- Include FIRST_RUN.md with exact commands
- If complex, implement simplest working version first

---

## 🚀 START NOW
Begin by generating:
1. PRD
2. System Architecture
3. Database Schema
4. API & WebSocket Spec

Then proceed to full implementation.
