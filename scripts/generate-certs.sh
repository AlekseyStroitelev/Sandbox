#!/bin/bash
set -e

mkdir -p /tmp/certs
if [ -f /tmp/certs/kafka.truststore.jks ]; then
  echo "Certificates already exist, skipping generation"
  exit 0
fi

# CA
openssl req -x509 -newkey rsa:4096 -keyout /tmp/certs/ca-key -out /tmp/certs/ca-cert -days 365 -nodes -subj "/CN=Kafka-CA"

for broker in kafka-1 kafka-2 kafka-3 kafka-4 kafka-5 kafka-6; do
  keytool -keystore /tmp/certs/${broker}.keystore.jks -alias localhost -validity 365 -genkey -keyalg RSA \
    -dname "CN=${broker}" -ext "SAN=DNS:${broker},DNS:localhost" -storepass changeit -keypass changeit
  keytool -keystore /tmp/certs/${broker}.keystore.jks -alias localhost -validity 365 -certreq -keyalg RSA \
    -file /tmp/certs/${broker}.csr -storepass changeit -keypass changeit
  openssl x509 -req -CA /tmp/certs/ca-cert -CAkey /tmp/certs/ca-key -in /tmp/certs/${broker}.csr \
    -out /tmp/certs/${broker}-signed.crt -days 365 -CAcreateserial -passin pass:changeit
  keytool -keystore /tmp/certs/${broker}.keystore.jks -alias CARoot -importcert -file /tmp/certs/ca-cert \
    -storepass changeit -keypass changeit -noprompt
  keytool -keystore /tmp/certs/${broker}.keystore.jks -alias localhost -importcert -file /tmp/certs/${broker}-signed.crt \
    -storepass changeit -keypass changeit -noprompt
done

keytool -keystore /tmp/certs/kafka.truststore.jks -alias CARoot -importcert -file /tmp/certs/ca-cert \
  -storepass changeit -keypass changeit -noprompt

# ZooKeeper super digest (на случай ручного доступа)
echo "Computing ZooKeeper super digest..."
ZK_DIGEST=$(java -cp /opt/kafka/libs/zookeeper-3.8.4.jar:/opt/kafka/libs/zookeeper-jute-3.8.4.jar org.apache.zookeeper.server.auth.DigestAuthenticationProvider zkadmin:zkadmin-secret 2>&1 | grep "^zkadmin:" | awk '{print $2}')
echo "$ZK_DIGEST" > /tmp/certs/zk-super-digest
echo "ZooKeeper super digest saved."
echo "Certificates generated successfully"