#!/bin/bash
set -Eeu -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIR
# shellcheck disable=SC1091
. "$SCRIPT_DIR"/tools/colored_echo.sh
# shellcheck disable=SC1091
. "$SCRIPT_DIR"/tools/container_engine.sh

CONTAINER_ENGINE=$(detect_container_engine)
readonly CONTAINER_ENGINE

IMAGE_NAME=ghcr.io/shakiyam/license_finder
readonly IMAGE_NAME

if [[ $CONTAINER_ENGINE == docker ]]; then
  ENGINE_OPTS=(-u "$(id -u):$(id -g)")
else
  ENGINE_OPTS=(--security-opt label=disable)
fi
readonly ENGINE_OPTS

WORK_DIR=$(mktemp -d)
readonly WORK_DIR
trap 'rm -rf "$WORK_DIR"' EXIT

cp "$SCRIPT_DIR"/Gemfile "$SCRIPT_DIR"/Gemfile.lock "$WORK_DIR"/

if ! $CONTAINER_ENGINE container run \
  --name "test_license_finder_$(uuidgen | head -c8)" \
  --rm \
  --pull=never \
  "${ENGINE_OPTS[@]}" \
  -v "$WORK_DIR":/scan:ro \
  "$IMAGE_NAME" report >"$WORK_DIR"/report.csv; then
  echo_error 'Test failed: license_finder report exited with a non-zero status.'
  exit 1
fi

if ! grep -q '^license_finder, ' "$WORK_DIR"/report.csv; then
  echo_error 'Test failed: the report does not contain license_finder.'
  cat "$WORK_DIR"/report.csv
  exit 1
fi

echo_success 'Test passed: license_finder generated a report successfully.'
