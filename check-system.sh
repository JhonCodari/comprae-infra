#!/bin/bash

echo "==================================="
echo "VERIFICACAO DO SISTEMA COMPRAE"
echo "==================================="
echo ""

echo "1. Verificando containers Docker:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "2. Verificando servicos do docker-compose:"
docker-compose ps

echo ""
echo "3. Verificando conexoes de rede:"
echo "PostgreSQL (5432):"
nc -z localhost 5432 && echo "  ✓ PostgreSQL OK" || echo "  ✗ PostgreSQL OFFLINE"

echo "Redis (6379):"
nc -z localhost 6379 && echo "  ✓ Redis OK" || echo "  ✗ Redis OFFLINE"

echo "Kafka (9092):"
nc -z localhost 9092 && echo "  ✓ Kafka OK" || echo "  ✗ Kafka OFFLINE"

echo "Zookeeper (2181):"
nc -z localhost 2181 && echo "  ✓ Zookeeper OK" || echo "  ✗ Zookeeper OFFLINE"

echo ""
echo "4. Verificando servicos web:"
echo "Config Server (8888):"
curl -s http://localhost:8888/actuator/health > /dev/null && echo "  ✓ Config Server OK" || echo "  ✗ Config Server OFFLINE"

echo "Produto Service (8082):"
curl -s http://localhost:8082/actuator/health > /dev/null && echo "  ✓ Produto Service OK" || echo "  ✗ Produto Service OFFLINE"

echo ""
echo "==================================="
echo "VERIFICACAO CONCLUIDA"
echo "==================================="
