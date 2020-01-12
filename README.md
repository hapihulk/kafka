### Start a cluster:

```bash
docker-compose up -d
docker image ls
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

Kafka Manager: http://localhost:9000
Zookeeper UI: http://localhost:9090/
docker service ls --format 'table {{.Name}}\t{{.Replicas}}\t{{.Ports}}'
