#!/usr/bin/env bash
set -euo pipefail

# #! /bin/bash
#
# dlv debug ./ --output="./__debug_bin" --headless --continue --api-version=2 --accept-multiclient --listen=:2345

# ---- Configurable defaults (override via environment) ----
: "${APP_PKG:=./cmd/server}"                     # main package path
: "${APP_BIN:=/tmp/app}"                         # compiled binary path inside container
: "${DLV_ADDR:=0.0.0.0:2345}"                    # delve listen address
: "${AIR_TMPDIR:=/tmp/air}"                      # air temp dir
: "${AIR_EXCLUDE_DIRS:=vendor,.git,$AIR_TMPDIR}" # comma-separated
: "${AIR_DELAY_MS:=500}"                         # debounce rebuild delay

mkdir -p "$(dirname "$APP_BIN")" "$AIR_TMPDIR"

# Build and run commands
GO_BUILD_CMD="go build -gcflags=all=-N -l -o ${APP_BIN} ${APP_PKG}"
DLV_RUN_CMD="dlv exec ${APP_BIN} --headless --listen=${DLV_ADDR} --api-version=2 --accept-multiclient --continue"

# Generate a throwaway .air.toml each run (so env overrides Just Work™)
AIR_TOML="$(mktemp)"
cat >"$AIR_TOML" <<EOF
root = "."
tmp_dir = "${AIR_TMPDIR}"
delay = ${AIR_DELAY_MS}

[build]
cmd = "${GO_BUILD_CMD}"
bin = "${APP_BIN}"
# Run the freshly built binary through Delve
full_bin = "${DLV_RUN_CMD}"

# Ignore common noisy dirs
exclude_dir = [$(printf '"%s",' ${AIR_EXCLUDE_DIRS//,/ } | sed 's/,$//')]
EOF

echo "==> Air config:"
cat "$AIR_TOML"
echo

exec air -c "$AIR_TOML"
