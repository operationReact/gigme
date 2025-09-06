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


## Deploying to AWS (S3 + CloudFront)
This repo includes a GitHub Actions workflow that builds the Flutter web app (canvaskit) and deploys it to S3 behind CloudFront using GitHub OIDC (no long‑lived secrets).

Files:
- .github/workflows/deploy.yml – CI/CD pipeline
- scripts/fix-mime.sh – fixes MIME types for wasm/js objects in S3
- infra/iam/github-oidc-trust.json – IAM role trust policy (GitHub OIDC, main branch)
- infra/iam/github-oidc-role.json – IAM permissions policy (S3 upload + CloudFront invalidation)

One‑time AWS setup (console or CLI):
1) Create or choose an S3 bucket for your site assets (e.g., my-site-bucket). With CloudFront, you typically restrict direct public access and serve via CloudFront.
2) Create or choose a CloudFront distribution with the S3 bucket as origin.
   - Default Root Object: index.html
   - Error responses: map 403 and 404 to /index.html with HTTP 200 (for SPA routing)
3) Create an IAM Role for GitHub Actions OIDC:
   - Trust policy: use infra/iam/github-oidc-trust.json and replace placeholders:
     - YOUR_AWS_ACCOUNT_ID
     - YOUR_GITHUB_ORG/YOUR_GITHUB_REPO
   - Permissions policy: use infra/iam/github-oidc-role.json and replace placeholders:
     - YOUR_S3_BUCKET_NAME -> your target bucket name
     - YOUR_AWS_ACCOUNT_ID -> your AWS account ID
     - YOUR_CLOUDFRONT_DISTRIBUTION_ID -> your distribution ID
   - Note the Role ARN (arn:aws:iam::123456789012:role/YourGithubDeployRole)

Required GitHub Variables (Repository or Environment -> Variables):
- S3_BUCKET – your bucket name
- CF_DISTRIBUTION_ID – your CloudFront distribution ID
- AWS_REGION – e.g., us-east-1
- AWS_ROLE_ARN – the IAM role ARN to assume via OIDC (no secret)

How the workflow deploys:
- On push to main, it builds the Flutter web app with canvaskit and base href "/".
- Uses aws-actions/configure-aws-credentials@v4 to assume the IAM role via OIDC (no long‑lived keys).
- Syncs all files to S3 except index.html with Cache-Control: public,max-age=31536000,immutable.
- Uploads index.html separately with Cache-Control: no-cache and content-type text/html.
- Runs scripts/fix-mime.sh to force:
  - canvaskit/canvaskit.wasm -> application/wasm
  - flutter.js -> application/javascript
- Creates a CloudFront invalidation for path /*.

SPA rewrite notes (CloudFront):
- Set Default Root Object to index.html.
- Add custom error responses: 403 and 404 -> /index.html, HTTP 200.

Run it:
- Push to main. The workflow will build and deploy to S3, then invalidate CloudFront.
