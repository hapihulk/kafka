#!/bin/bash
docker service create --network kafka-net --name=zookeeper --publish 2181:2181 qnib/plain-zookeeper:latest
echo "...........................Zookeeper started..........................."
docker service create --network kafka-net --name=zkui --publish 9090:9090 qnib/plain-zkui:latest
echo "...........................Zookeeper ui started..........................."
docker service create --network kafka-net --name broker --publish 9092:9092 --publish 9093:9093 \
 --hostname="{{.Service.Name}}.{{.Task.Slot}}.{{.Task.ID}}" \
 -e KAFKA_ADVERTISED_HOST_NAME=localhost \
 -e KAFKA_BROKER_ID={{.Task.Slot}} \
 -e KAFKA_LISTENERS=INTERNAL://:9092,EXTERNAL://:9093 \
 -e KAFKA_INTER_BROKER_LISTENER_NAME=INTERNAL \
 -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT \
 -e KAFKA_ADVERTISED_LISTENERS=INTERNAL://:9092,EXTERNAL://:9093 \
 -e ZK_SERVERS=tasks.zookeeper \
 qnib/plain-kafka:latest
echo "...........................Kafka broker started..........................."
docker exec -t -e JMX_PORT="" \
 $(docker ps -q --filter 'label=com.docker.swarm.service.name=broker'|head -n1) \
 /opt/kafka/bin/kafka-topics.sh --zookeeper tasks.zookeeper:2181 \
 --partitions=1 --replication-factor=1 --create --topic test
echo "...........................Topic test started..........................."
docker service create --network kafka-net --name manager \
 -e ZOOKEEPER_HOSTS=tasks.zookeeper --publish=9000:9000 \
 qnib/plain-kafka-manager:latest
echo "...........................Kafka manager test started..........................."
#docker service update --replicas=3 broker
#echo "...........................3 brokers created..........................."
#docker exec -t -e JMX_PORT="" \
# $(docker ps -q --filter 'label=com.docker.swarm.service.name=broker'|head -n1) \
# /opt/kafka/bin/kafka-topics.sh --zookeeper tasks.zookeeper:2181 \
# --partitions=2 --replication-factor=2 --create --topic scaled
#echo "...........................Topic scaling complete..........................."

#sudo # -nlpt | grep dockerd
