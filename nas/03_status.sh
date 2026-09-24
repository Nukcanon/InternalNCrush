#!/bin/sh
set -eu
cd -- "$(dirname -- "$0")"
docker compose ps
docker compose logs --tail=60 directory
