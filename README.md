# Kafka Cluster with Security (SASL/SCRAM, SSL, ACL)

Этот проект разворачивает локальный кластер Apache Kafka версии 3.9.2 с безопасной конфигурацией, подходящей для тестовых и демонстрационных сред. Все компоненты (ZooKeeper, Kafka, Schema Registry, AKHQ) запускаются в Docker Compose.

**Основные возможности:**
- Три Kafka-брокера со встроенным ZooKeeper (требование руководителя).
- Шифрование и аутентификация межброкерного взаимодействия (SASL_SSL).
- Аутентификация клиентов через SCRAM-SHA-512.
- Авторизация на основе ACL (AclAuthorizer).
- Изолированный ZooKeeper (порты не выставляются наружу).
- Автоматическая генерация SSL-сертификатов с поддержкой SAN.
- Schema Registry и веб-интерфейс AKHQ.
- Проверки работоспособности контейнеров (healthcheck).

## Структура проекта

.
├── docker-compose.yaml # Основной файл сборки
├── client-sasl.conf # Конфигурация клиента для SASL_PLAINTEXT
├── client-ssl.conf # Конфигурация клиента для SASL_SSL
├── certs/ # Сгенерированные сертификаты (создаётся автоматически)
├── configs/ # Конфигурационные файлы для каждого брокера
│ ├── kafka-1/
│ │ ├── zookeeper.properties
│ │ ├── server.properties
│ │ ├── kafka_server_jaas.conf
│ │ └── healthcheck-client.conf
│ ├── kafka-2/ # Аналогично kafka-1, с broker.id=2
│ └── kafka-3/ # Аналогично kafka-1, с broker.id=3
└── scripts/ # Скрипты инициализации и запуска
├── generate-certs.sh # Генерация SSL-сертификатов
├── setup-acl.sh # Настройка ACL и создание тестового топика
└── start-kafka.sh # Запуск ZooKeeper и Kafka-брокера


## Требования

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/) (обычно входит в Docker Desktop)

## Порядок запуска

1. **Склонируйте репозиторий или скопируйте файлы** в отдельную директорию.

2. **Создайте папку для сертификатов и установите права:**
   ```bash
   mkdir -p ./certs
   chmod 777 ./certs

3. **Запустите кластер:**
    ```bash
    docker-compose up -d

При первом запуске произойдёт:

Генерация SSL-сертификатов (контейнер cert-generator).
Запуск трёх Kafka-брокеров со встроенными ZooKeeper.
Создание SCRAM-пользователей в ZooKeeper перед стартом Kafka.
Настройка ACL и тестового топика test (контейнер acl-setup).
Запуск Schema Registry и AKHQ.

4. **Проверьте состояние контейнеров:**
    ```bash
    docker-compose ps

Все сервисы должны быть в статусе healthy (кроме cert-generator и acl-setup, которые завершаются после выполнения).

## Доступ к сервисам
Сервис	URL / порт	Учётные данные (роль)
Kafka (SASL)	localhost:29092 (SASL_PLAINTEXT)	см. ниже
Kafka (SASL_SSL)	localhost:9093	см. ниже
Schema Registry	http://localhost:8081	без аутентификации
AKHQ	http://localhost:8080	без аутентификации (UI)
Учётные записи SCRAM
Все пароли заданы статически (для тестового окружения). При необходимости измените их в файлах scripts/start-kafka.sh, scripts/setup-acl.sh и client-sasl.conf, client-ssl.conf.

Пользователь	Пароль	Назначение
admin	admin-secret	Администратор кластера (super.user)
interbroker	interbroker-secret	Межброкерное взаимодействие
producer	producer-secret	Запись в топик test
consumer	consumer-secret	Чтение из топика test
schema	schema-secret	Schema Registry
akhq	akhq-secret	AKHQ
Тестирование работы
Запись и чтение сообщений
Создайте файл producer.conf:

ini
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username="producer" password="producer-secret";
Отправьте сообщение:

bash
docker run --rm -it --network kafka-network -v $(pwd)/producer.conf:/tmp/producer.conf \
  apache/kafka:3.9.2 bash -c 'echo "Hello Kafka" | /opt/kafka/bin/kafka-console-producer.sh \
  --bootstrap-server kafka-1:29092,kafka-2:29092,kafka-3:29092 --topic test --producer.config /tmp/producer.conf'
Создайте consumer.conf:

ini
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username="consumer" password="consumer-secret";
Прочитайте сообщение:

bash
docker run --rm -it --network kafka-network -v $(pwd)/consumer.conf:/tmp/consumer.conf \
  apache/kafka:3.9.2 bash -c '/opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server kafka-1:29092,kafka-2:29092,kafka-3:29092 --topic test --from-beginning --consumer.config /tmp/consumer.conf --max-messages 1'
Проверка нарушения ACL
Попытка записи пользователем consumer (у которого нет прав на Write):

bash
docker run --rm -it --network kafka-network -v $(pwd)/consumer.conf:/tmp/consumer.conf \
  apache/kafka:3.9.2 bash -c 'echo "should fail" | /opt/kafka/bin/kafka-console-producer.sh \
  --bootstrap-server kafka-1:29092,kafka-2:29092,kafka-3:29092 --topic test --producer.config /tmp/consumer.conf'
Ожидается ошибка авторизации.

Остановка и очистка
Остановка кластера с удалением контейнеров и томов:

bash
docker-compose down -v
Для полной пересборки удалите также сгенерированные сертификаты:

bash
rm -rf ./certs
Примечания по безопасности
ZooKeeper порты не проброшены на хост, доступ только из внутренней Docker-сети.

Межброкерное взаимодействие защищено протоколом SASL_SSL.

PLAINTEXT листенер полностью убран – все клиентские подключения требуют SASL.

ACL разграничивают права для продюсеров, консьюмеров и сервисов.

Пароли хранятся в конфигурационных файлах – для продакшен-среды следует использовать внешний vault и механизмы секретов Docker Swarm или Kubernetes.

Данный кластер готов к использованию в качестве полигона для изучения и тестирования приложений, работающих с защищённым Kafka.