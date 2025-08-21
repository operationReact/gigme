# GigMe Monorepo

GigMe is a simple freelancing marketplace where clients can post gigs and freelancers can browse them.  This repository contains both the Flutter frontend and the Spring Boot backend so that you can work on the entire stack from a single code base.  The goal of the skeleton is to give you a working starting point that runs locally on web, Android, iOS and desktop.

## Structure

```
gigme/
├── backend/    # Java 21 + Spring Boot API service
│   ├── build.gradle       # Gradle build file
│   ├── settings.gradle    # Project settings
│   └── src/
│       ├── main/java/com/gigme/app/    # Application code
│       │   ├── GigmeApplication.java   # Application entry point
│       │   ├── model/                  # Entities
│       │   ├── repository/             # Spring Data repositories
│       │   └── controller/             # REST controllers
│       └── main/resources/
│           └── application.yml         # Spring configuration (H2/PostgreSQL)
└── frontend/ # Flutter application
    ├── lib/
    │   └── main.dart     # Flutter entry point
    └── pubspec.yaml      # Flutter dependencies and configuration
```

## Running the backend

1. Make sure you have **Java 21** and **Gradle** installed.
2. Navigate into the `backend` directory:

   ```bash
   cd backend
   ```

3. Start the API service using the Spring Boot Gradle plugin:

   ```bash
   ./gradlew bootRun
   ```

By default the backend runs against an in‑memory H2 database using the `h2` profile.  To use PostgreSQL instead, set the `SPRING_PROFILES_ACTIVE` environment variable:

```bash
SPRING_PROFILES_ACTIVE=postgres ./gradlew bootRun
```

The API will be available on `http://localhost:8080`.  Useful endpoints include:

* `POST /api/users/register` – register a user (body: JSON with `username`, `email` and `role`)
* `GET  /api/users` – list users
* `POST /api/gigs` – create a gig (body: JSON with `title`, `description`, `budget`, and optional `client.id`)
* `GET  /api/gigs` – list gigs

## Running the frontend

1. Install the [Flutter SDK](https://flutter.dev/docs/get-started/install) if you haven’t already.  Flutter automatically supports web, Android and iOS from a single code base.
2. Navigate into the `frontend` directory:

   ```bash
   cd frontend
   ```

3. Fetch dependencies and run the app on the target platform:

   ```bash
   flutter pub get
   
   # To run on the web (opens in the browser)
   flutter run -d chrome
   
   # To run on an Android device or emulator
   flutter run -d android
   
   # To run on an iOS device or simulator (requires macOS)
   flutter run -d ios
   ```

The Flutter app will connect to the backend at `http://localhost:8080` by default.  If you run the backend on a different host or port you can adjust the base URL in `lib/main.dart`.

## Notes

* The code is intentionally simple.  It does not implement authentication or advanced business logic.  Feel free to extend it with your own features.
* The H2 profile uses an in‑memory database so all data is lost when the application stops.  Use the PostgreSQL profile (`postgres`) for persistence.
* This repository uses a monorepo structure so that both the server and client live in the same Git repository.  You can open two terminal windows, one for the backend and one for the frontend, and develop both simultaneously.