### Start a cluster:

```bash
docker-compose up -d
docker-compose -f docker-compose-spotify.yml up
docker-compose -f docker-compose-spotify.yml down
docker-compose -f docker-compose-wurstmeister.yml up
docker-compose -f docker-compose-wurstmeister.yml down
docker image ls
docker network ls
docker service ls --format 'table {{.Name}}\t{{.Replicas}}\t{{.Ports}}'
docker service rm $(docker service ls -q)
kafkacat -b localhost:9093 -L
```

### Check container running:

```bash
docker ps
```

### Add more brokers:

```bash
docker-compose scale kafka=3
```

### Destroy a cluster:

```bash
docker-compose stop
```

### turn off running containers

```bash
docker-compose down
```

sudo docker service ls  
sudo docker service rm <ID>

docker swarm init --advertise-addr <ipv6>

```bash
docker network create -d bridge kafkanet
docker network create -d overlay --attachable kafka-net
```

### Step-1: Start Zookeeper

```bash
docker service create --network kafka-net --name=zookeeper --publish 2181:2181 qnib/plain-zookeeper:latest
```

### Step-2: Start Zookeeper UI

```bash
docker service create --network kafka-net --name=zkui --publish 9090:9090 qnib/plain-zkui:latest
docker service ls --format 'table {{.Name}}\t{{.Replicas}}\t{{.Ports}}'
```

### Step-3: Check Zookeeper UI

Zookeeper UI: http://localhost:9090/

### Step-4: Start Kafka

```bash
docker service create --network kafka-net --name broker --publish 9092:9092 \
 --hostname="{{.Service.Name}}.{{.Task.Slot}}.{{.Task.ID}}" \
 -e KAFKA_BROKER_ID={{.Task.Slot}} -e ZK_SERVERS=tasks.zookeeper \
 qnib/plain-kafka:latest
```

### Step-5: Create topic 'test'

```bash
docker exec -t -e JMX_PORT="" \
 $(docker ps -q --filter 'label=com.docker.swarm.service.name=broker'|head -n1) \
 /opt/kafka/bin/kafka-topics.sh --zookeeper tasks.zookeeper:2181 \
 --partitions=1 --replication-factor=1 --create --topic test
```

### Step-6: Start Kafka Manager

```bash
docker service create --network kafka-net --name manager \
 -e ZOOKEEPER_HOSTS=tasks.zookeeper --publish=9000:9000 \
 qnib/plain-kafka-manager:latest
```

### Step-7: Check Kafka Manager UI

Kafka Manager: http://localhost:9000  
Add a cluster with the default config  
Cluster Name: kafka  
Cluster Zookeeper Hosts: tasks.zookeeper:2181

### Step-8: Publish messages to Kafka

```bash
docker run -t --rm --network kafka-net qnib/golang-kafka-producer:latest 5
```

### Step-9: Update to 3 brokers

```bash
docker service update --replicas=3 broker
```

[2020-01-12 21:04:41,453] ERROR org.apache.kafka.common.errors.InvalidReplicationFactorException: Replication factor: 2 larger than available brokers: 1.
(kafka.admin.TopicCommand\$)

### Step-10: Create topic 'scaled'

```bash
docker exec -t -e JMX_PORT="" \
 $(docker ps -q --filter 'label=com.docker.swarm.service.name=broker'|head -n1) \
 /opt/kafka/bin/kafka-topics.sh --zookeeper tasks.zookeeper:2181 \
 --partitions=2 --replication-factor=2 --create --topic scaled
```

### Step-11: Publish messages to Kafka topic 'scaled'

```bash
docker service create --network kafka-net --name producer \
 --replicas=3 -e KAFKA_BROKER=tasks.broker \
 -e KAFKA_TOPIC=scaled \
 qnib/golang-kafka-producer:latest
```

### Step-12: Check log of producer

```bash
sleep 10 && docker service logs producer | head
```

### To get rid of the old network. This will not delete volumes.

```bash
docker system prune -a
```
