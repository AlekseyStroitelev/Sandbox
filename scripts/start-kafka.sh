#!/bin/bash
set -e

# Копируем подготовленные конфиги в рабочие директории
cp /opt/kafka/config/custom/zookeeper.properties /opt/kafka/config/zookeeper.properties
mkdir -p /tmp/zookeeper
echo "${BROKER_ID}" > /tmp/zookeeper/myid
cp /opt/kafka/config/custom/kafka_server_jaas.conf /opt/kafka/config/kafka_server_jaas.conf
cp /opt/kafka/config/custom/server.properties /opt/kafka/config/server.properties
cp /opt/kafka/config/custom/healthcheck-client.conf /tmp/healthcheck-client.conf

echo "Starting Zookeeper..."
export SERVER_JVMFLAGS="-Dzookeeper.DigestAuthenticationProvider.superDigest=$(cat /opt/kafka/certs/zk-super-digest)"
/opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties &

echo "Waiting for Zookeeper quorum..."
until echo srvr | nc localhost 2181 | grep -qE "Mode: (leader|follower)"; do
  echo "ZooKeeper quorum not ready yet, retrying in 5s..."
  sleep 5
done
echo "ZooKeeper quorum established!"

echo "Creating SCRAM users in ZooKeeper..."
for user in admin:admin-secret producer:producer-secret consumer:consumer-secret schema:schema-secret akhq:akhq-secret interbroker:interbroker-secret mm2:mm2-secret; do
  u="${user%%:*}"
  p="${user##*:}"
  /opt/kafka/bin/kafka-configs.sh --zookeeper localhost:2181 --alter \
    --add-config "SCRAM-SHA-512=[password=$p]" --entity-type users --entity-name "$u" || true
done
echo "SCRAM users created."
sleep 5

echo "Starting Kafka..."
export KAFKA_OPTS="-Djava.security.auth.login.config=/opt/kafka/config/kafka_server_jaas.conf"
/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties &

# Запускаем MirrorMaker 2 во всех контейнерах
echo "Starting MirrorMaker 2 inside this container..."
export KAFKA_OPTS=""
/opt/kafka/bin/connect-standalone.sh /opt/kafka/config/mm2.properties &

# Удерживаем контейнер живым
tail -f /dev/null