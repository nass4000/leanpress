#!/usr/bin/env bash
set -euo pipefail

echo "▶ Post-start: helpful tips"

echo "You can now:"
echo " 1) Start the Mirror (Actix) in the dev container:"
echo "    cargo run -p mirror"
echo ""
echo " 2) Start the Panel (Actix/React) once you add it:"
echo "    cargo run -p panel # or npm run dev if using React/Vite"
echo ""
echo "Open these in your browser:"
echo " - Origin WP: http://localhost:8080"
echo " - Mirror via Caddy http://localhost:8001 (proxies GETs to dev:9001)"
