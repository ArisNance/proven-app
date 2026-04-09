#!/usr/bin/env bash
set -euo pipefail

if ! command -v ruby >/dev/null 2>&1; then
  echo "Ruby is not installed" >&2
  exit 1
fi

ruby -v
bundle -v
node -v
npm -v

bundle install
npm install

bin/rails db:create db:migrate

echo "Bootstrap complete. Start with: bin/dev"
