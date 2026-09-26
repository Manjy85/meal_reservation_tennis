#!/usr/bin/env bash
# Builds both web apps and publishes them on Firebase Hosting (free on the
# Spark plan). Needs Node.js; the Firebase CLI is run through npx, so no
# global install. First time: `npx -y firebase-tools login`. See README.
set -euo pipefail
cd "$(dirname "$0")/.."

./scripts/build_web.sh
npx -y firebase-tools deploy --only hosting
