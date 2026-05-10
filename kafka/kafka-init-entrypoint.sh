#!/bin/sh
set -e

for entry in $KAFKA_TOPICS; do
  topic=$(echo "$entry" | cut -d: -f1)
  partitions=$(echo "$entry" | cut -d: -f2)
  replication=$(echo "$entry" | cut -d: -f3)

  /opt/kafka/bin/kafka-topics.sh --create --if-not-exists \
    --bootstrap-server kafka:9092 \
    --topic "$topic" \
    --partitions "${partitions:-1}" \
    --replication-factor "${replication:-1}"

  echo "Created topic: $topic (partitions=${partitions:-1}, replication=${replication:-1})"
done
