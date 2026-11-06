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

cp "$SCRIPT_DIR"/Gemfile "$WORK_DIR"/

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

# TODO: Remove once base image includes json >= 2.19.9 (CVE-2026-33210, CVE-2026-54696)
# shellcheck disable=SC2016
if ! JSON_LOADED=$($CONTAINER_ENGINE container run \
  --name "test_license_finder_$(uuidgen | head -c8)" \
  --rm \
  --pull=never \
  "${ENGINE_OPTS[@]}" \
  --entrypoint ruby \
  "$IMAGE_NAME" -e '
    require "json"
    path = $LOADED_FEATURES.grep(%r{/json/version\.rb\z}).first.to_s
    puts "#{JSON::VERSION} from #{path}"
    exit(Gem::Version.new(JSON::VERSION) >= Gem::Version.new("2.19.9") && path.start_with?("/opt/lf_bundle/"))
  '); then
  echo_error "Test failed: json ${JSON_LOADED} is loaded instead of >= 2.19.9 from /opt/lf_bundle."
  exit 1
fi

# TODO: Remove once license_finder allows rubyzip >= 3.4.0 (CVE-2026-85396)
if ! RUBYZIP_RESULT=$($CONTAINER_ENGINE container run \
  --name "test_license_finder_$(uuidgen | head -c8)" \
  --rm \
  --pull=never \
  "${ENGINE_OPTS[@]}" \
  --entrypoint ruby \
  "$IMAGE_NAME" -e '
    require "license_finder"
    require "tmpdir"
    require "zip/version"
    mit = File.read(File.join(Gem.loaded_specs["license_finder"].full_gem_path, "lib/license_finder/license/templates/MIT.txt"))
    licenses = Dir.mktmpdir do |dir|
      jar = File.join(dir, "test.jar")
      Zip::OutputStream.open(jar) do |zip|
        zip.put_next_entry("META-INF/LICENSE")
        zip.write(mit)
      end
      LicenseFinder::LicenseFiles.find(jar).map { |file| file.license.name }
    end
    puts "rubyzip #{Zip::VERSION} found #{licenses.inspect}"
    exit(Gem::Version.new(Zip::VERSION) >= Gem::Version.new("3.4.0") && licenses == ["MIT"])
  ' 2>&1); then
  echo_error "Test failed: ${RUBYZIP_RESULT} instead of rubyzip >= 3.4.0 found [\"MIT\"]."
  exit 1
fi

echo_success 'Test passed: license_finder generated a report successfully.'
