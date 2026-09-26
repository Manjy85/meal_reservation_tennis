#!/usr/bin/env bash
# Builds both web apps: build/web_client (client) and build/web_admin (admin).
# The web/ folder is shared, so the admin build gets its title and names
# rewritten afterwards.
set -euo pipefail
cd "$(dirname "$0")/.."
root="$PWD"

# Built in the default build/web then copied: `flutter build web -o` skips
# web/manifest.json and favicon.png.
build() {
  flutter build web --release -t "$1"
  rm -rf "$root/build/$2"
  cp -r "$root/build/web" "$root/build/$2"
}
build lib/main.dart web_client
build lib/main_admin.dart web_admin

admin="$root/build/web_admin"
sed -i \
  -e 's|<title>Réservation Repas</title>|<title>Réservation Repas Admin</title>|' \
  -e 's|name="apple-mobile-web-app-title" content="Repas"|name="apple-mobile-web-app-title" content="Repas Admin"|' \
  -e 's|content="Réserve tes repas pour les événements du club."|content="Espace restaurateur : carte, dates et commandes."|' \
  "$admin/index.html"
sed -i \
  -e 's|"name": "Réservation Repas"|"name": "Réservation Repas Admin"|' \
  -e 's|"short_name": "Repas"|"short_name": "Repas Admin"|' \
  -e 's|"description": "Réserve tes repas pour les événements du club."|"description": "Espace restaurateur : carte, dates et commandes."|' \
  "$admin/manifest.json"

echo "Web apps built in build/web_client and build/web_admin"
