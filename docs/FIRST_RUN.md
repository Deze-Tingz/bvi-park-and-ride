# BVI Park & Ride - First Run Guide

This guide will help you set up and run the BVI Park & Ride platform for the first time.

## Prerequisites

### Required Software
- **Node.js** 18+ (LTS recommended)
- **npm** or **pnpm**
- **Flutter** 3.0+ with Dart SDK
- **Android Studio** (for Android development)
- **Docker** and **Docker Compose**
- **PostgreSQL** (or use Docker)
- **Git**

### Accounts Needed
- **Mapbox** account (free tier available): https://account.mapbox.com/
- **Firebase** account (for push notifications): https://console.firebase.google.com/

## Quick Start

### 1. Clone the Repository
```bash
git clone <your-repo-url>
cd BVI_Park_and_Ride
```

### 2. Set Up Environment Variables
```bash
# Copy the example environment file
cp infra/env.example infra/.env

# Edit the .env file with your values
# Required: DB_PASSWORD, JWT_SECRET, MAPBOX_TOKEN
```

### 3. Start Docker Services
```bash
cd infra
docker-compose up -d
```

This starts:
- PostgreSQL database (port 5432)
- Redis cache (port 6379)

### 4. Set Up the Backend API
```bash
cd services/api

# Install dependencies
npm install

# Run database migrations
npm run migration:run

# Seed initial data (routes and stops)
npm run seed

# Start the development server
npm run start:dev
```

The API will be available at:
- REST API: http://localhost:3000
- Swagger Docs: http://localhost:3000/api/docs
- WebSocket: ws://localhost:3000/tracking

### 5. Set Up the Rider App
```bash
cd apps/rider_app

# Get Flutter dependencies
flutter pub get

# Run on Android
flutter run

# Or run on iOS
flutter run -d ios
```

### 6. Set Up the Driver App
```bash
cd apps/driver_app

# Get Flutter dependencies
flutter pub get

# Run on Android
flutter run
```

## Configuration

### Mapbox Token
1. Go to https://account.mapbox.com/access-tokens/
2. Create a new token with required scopes
3. Add to `infra/.env`:
   ```
   MAPBOX_TOKEN=pk.your_token_here
   ```
4. Add to Flutter apps in the appropriate config files

### Firebase (Push Notifications)
1. Create a Firebase project
2. Add Android and iOS apps
3. Download config files:
   - `google-services.json` → `apps/rider_app/android/app/`
   - `GoogleService-Info.plist` → `apps/rider_app/ios/Runner/`
4. Get FCM Server Key from Firebase Console
5. Add to `infra/.env`:
   ```
   FCM_SERVER_KEY=your_key_here
   ```

## Project Structure

```
BVI_Park_and_Ride/
├── apps/
│   ├── rider_app/          # Flutter rider app
│   ├── driver_app/         # Flutter driver app
│   └── admin_dashboard/    # Next.js admin (coming soon)
├── services/
│   └── api/                # NestJS backend
├── data/
│   ├── stops.json          # BVI stop locations
│   └── routes.geojson      # Route polylines
├── docs/
│   ├── PRD.md              # Product requirements
│   ├── ARCHITECTURE.md     # System architecture
│   └── FIRST_RUN.md        # This file
├── infra/
│   ├── docker-compose.yml  # Docker services
│   └── env.example         # Environment template
└── scripts/
    └── hourly_commit.ps1   # Auto-commit script
```

## Common Issues

### Port Already in Use
```bash
# Find process using port 3000
lsof -i :3000

# Kill the process
kill -9 <PID>
```

### Database Connection Failed
1. Check if PostgreSQL container is running: `docker ps`
2. Verify DATABASE_URL in .env matches Docker config
3. Check container logs: `docker logs bvi_postgres`

### Flutter Build Errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Mapbox Not Loading
1. Verify MAPBOX_TOKEN is correct
2. Check Mapbox token has required scopes
3. Ensure billing is active on Mapbox account

## Development Workflow

### Making Changes
1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make changes
3. Test locally
4. Commit and push
5. Create pull request

### Auto-Commits
The hourly commit script (`scripts/hourly_commit.ps1`) can be set up in Windows Task Scheduler to automatically commit changes every hour.

## Testing

### API Testing
```bash
cd services/api
npm run test
```

### Flutter Testing
```bash
cd apps/rider_app
flutter test
```

## Deployment

### API Deployment
The API is containerized and can be deployed to any Docker-compatible host:
```bash
cd services/api
docker build -t bvi-api .
docker run -p 3000:3000 bvi-api
```

### Mobile App Deployment
- **Android**: Build APK with `flutter build apk --release`
- **iOS**: Build with Xcode or use Codemagic CI/CD

## Need Help?

- Check the PRD.md for product requirements
- Check ARCHITECTURE.md for system design
- Review code comments - they're written for learning

## Next Steps

1. ✅ Set up development environment
2. ⬜ Run the backend API
3. ⬜ Run the rider app
4. ⬜ Run the driver app
5. ⬜ Test real-time tracking
6. ⬜ Customize for your needs
