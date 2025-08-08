@echo off
echo Iniciando Ecossistema Comprae...
echo.

echo Parando containers existentes...
docker-compose down

echo.
echo Iniciando servicos base...
docker-compose up -d postgres redis zookeeper kafka

echo.
echo Aguardando servicos ficarem prontos...
timeout /t 30

echo.
echo Verificando status dos containers...
docker-compose ps

echo.
echo Ecossistema basico iniciado!
echo PostgreSQL: localhost:5432
echo Redis: localhost:6379  
echo Zookeeper: localhost:2181
echo Kafka: localhost:9092
echo.
pause
