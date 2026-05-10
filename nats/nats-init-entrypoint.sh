#!/bin/sh
set -e

if [ -z "$NATS_STREAMS" ]; then
  echo "No streams to create"
  exit 0
fi

for entry in $NATS_STREAMS; do
  name=$(echo "$entry" | cut -d: -f1)
  subjects=$(echo "$entry" | cut -d: -f2)
  subjects="${subjects:-${name}.>}"

  nats --server nats://nats:4222 stream add "$name" \
    --subjects "$subjects" \
    --defaults 2>/dev/null \
    || echo "Stream $name already exists, skipping"

  echo "Stream ready: $name (subjects=$subjects)"
done
