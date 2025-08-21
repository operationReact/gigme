# Gigmework Multi-Module Workspace

root/
├── app-frontend/  (Flutter UI)
└── app-backend/   (Spring Boot API)

## Backend (Spring Boot)
Run (dev, in‑memory H2):
```
./gradlew :app-backend:bootRun
```
Main class: `com.gigmework.GigmeworkApplication`
API base path example: `http://localhost:8080/api/jobs`

Profiles:
- dev (default, H2 in‑memory)
- prod (PostgreSQL – configure URL/credentials in application.yml or env vars)

## Frontend (Flutter)
From `app-frontend/`:
```
flutter pub get
flutter run    # Select device (Android emulator, Chrome, etc.)
```
Environment base URL logic:
- Android emulator: `http://10.0.2.2:8080`
- Web / desktop / iOS simulator: `http://localhost:8080`
- Real device (LAN): replace with your host machine IP, e.g. `http://192.168.x.x:8080`

Adjust by editing `lib/env.dart`.

## Endpoints
`GET /api/jobs` – list jobs
`POST /api/jobs` – create job `{ "title": "...", "description": "..." }`

## CORS
Configured in `CorsConfig` to allow all origins for `/api/**` (dev convenience). Tighten for production.

## Run Configurations (Android Studio / IntelliJ)
Two run configs placed under `.run/`:
- Flutter Frontend -> runs `lib/main.dart`
- Spring Boot Backend -> runs backend with `dev` profile

## Notes
- Modules are isolated. Flutter does not compile backend code.
- Switch run target by selecting the desired configuration.
- For prod Postgres: start DB, set `SPRING_PROFILES_ACTIVE=prod`.

## Sample curl
```
curl -X POST http://localhost:8080/api/jobs \
  -H 'Content-Type: application/json' \
  -d '{"title":"Test Job","description":"Demo"}'
```

## Next Steps (Optional)
- Add persistence entities & repositories
- Introduce DTO validation annotations
- Add dio client & error handling layer in Flutter
- Docker-compose for Postgres

