#!/usr/bin/env bash
set -euo pipefail

: "${S3_BUCKET:?S3_BUCKET is required}"

# Ensure wasm is served correctly (prevents CanvasKit blank screens)
if aws s3 ls "s3://${S3_BUCKET}/canvaskit/canvaskit.wasm" >/dev/null 2>&1; then
  aws s3 cp "s3://${S3_BUCKET}/canvaskit/canvaskit.wasm" "s3://${S3_BUCKET}/canvaskit/canvaskit.wasm" \
    --metadata-directive REPLACE \
    --content-type application/wasm \
    --cache-control "public,max-age=31536000,immutable"
fi

# Ensure flutter.js is served as JS
if aws s3 ls "s3://${S3_BUCKET}/flutter.js" >/dev/null 2>&1; then
  aws s3 cp "s3://${S3_BUCKET}/flutter.js" "s3://${S3_BUCKET}/flutter.js" \
    --metadata-directive REPLACE \
    --content-type application/javascript \
    --cache-control "public,max-age=31536000,immutable"
fi
