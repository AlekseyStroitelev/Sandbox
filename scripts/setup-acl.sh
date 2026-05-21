#!/bin/bash
set -e

echo "Waiting for Kafka to be ready..."
sleep 30

echo "Setting up ACLs..."
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:admin" --operation All --topic "*"
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:admin" --operation All --group "*"
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:admin" --operation All --cluster "kafka-cluster"

/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:producer" --operation Write --topic "test"
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:producer" --operation Describe --topic "test"
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:producer" --operation Create --topic "test"

/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:consumer" --operation Read --topic "test"
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:consumer" --operation Describe --topic "test"
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:consumer" --operation Read --group "group-*"
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:consumer" --operation Describe --group "group-*"

/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:schema" --operation Read --topic "_schemas"
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:schema" --operation Write --topic "_schemas"
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:schema" --operation Describe --topic "_schemas"
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:schema" --operation Create --topic "_schemas"
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:schema" --operation Read --group "schema-registry"
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:schema" --operation Describe --group "schema-registry"

/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:akhq" --operation All --topic "*"
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:akhq" --operation All --group "*"
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:akhq" --operation Describe --cluster "kafka-cluster"

# MirrorMaker 2 – права на топики и группы
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:mm2" --operation Read --topic "*"
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:mm2" --operation Write --topic "*"
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:mm2" --operation Describe --topic "*"
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:mm2" --operation Create --topic "*"
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:mm2" --operation Read --group "*"
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:mm2" --operation Describe --group "*"

# MirrorMaker 2 – права на внутренние топики Connect с префиксом primary.connect
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:mm2" --operation Create --topic "primary.connect" --resource-pattern-type prefixed
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:mm2" --operation Write --topic "primary.connect" --resource-pattern-type prefixed
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:mm2" --operation Read --topic "primary.connect" --resource-pattern-type prefixed
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --add --allow-principal "User:mm2" --operation Describe --topic "primary.connect" --resource-pattern-type prefixed

echo "Creating test topic..."
/opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka-1:29092 --command-config /tmp/client-sasl.conf \
  --create --topic test --partitions 3 --replication-factor 3 --if-not-exists

echo "ACL setup completed successfully"