#!/bin/bash
set -Eeu -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIR
# shellcheck disable=SC1091
. "$SCRIPT_DIR"/colored_echo.sh
# shellcheck disable=SC1091
. "$SCRIPT_DIR"/container_engine.sh

readonly RUBY_IMAGE="docker.io/library/ruby:4.0.6-slim-trixie"

CONTAINER_ENGINE=$(detect_container_engine)
readonly CONTAINER_ENGINE
if [[ $CONTAINER_ENGINE == docker ]]; then
  ENGINE_OPTS=(-u "$(id -u):$(id -g)")
else
  ENGINE_OPTS=(--security-opt label=disable)
fi
readonly ENGINE_OPTS

[[ -e Gemfile.lock ]] || touch Gemfile.lock
$CONTAINER_ENGINE container run \
  --name "update_lockfile_$(uuidgen | head -c8)" \
  --rm \
  "${ENGINE_OPTS[@]}" \
  -v "$PWD/Gemfile":/work/Gemfile:ro \
  -v "$PWD/Gemfile.lock":/work/Gemfile.lock \
  -w /work \
  "$RUBY_IMAGE" sh -c 'HOME=/tmp bundle lock --update --add-platform aarch64-linux x86_64-linux'
