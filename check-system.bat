@echo off
echo ===================================
echo VERIFICACAO DO SISTEMA COMPRAE
echo ===================================
echo.

echo 1. Verificando containers Docker:
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo.
echo 2. Verificando servicos do docker-compose:
docker-compose ps

echo.
echo 3. Testando conexoes:
echo PostgreSQL (5432):
powershell -Command "try { $tcp = New-Object System.Net.Sockets.TcpClient; $tcp.Connect('localhost', 5432); $tcp.Close(); Write-Host '  V PostgreSQL OK' -ForegroundColor Green } catch { Write-Host '  X PostgreSQL OFFLINE' -ForegroundColor Red }"

echo Redis (6379):
powershell -Command "try { $tcp = New-Object System.Net.Sockets.TcpClient; $tcp.Connect('localhost', 6379); $tcp.Close(); Write-Host '  V Redis OK' -ForegroundColor Green } catch { Write-Host '  X Redis OFFLINE' -ForegroundColor Red }"

echo Kafka (9092):
powershell -Command "try { $tcp = New-Object System.Net.Sockets.TcpClient; $tcp.Connect('localhost', 9092); $tcp.Close(); Write-Host '  V Kafka OK' -ForegroundColor Green } catch { Write-Host '  X Kafka OFFLINE' -ForegroundColor Red }"

echo.
echo 4. Verificando servicos web:
echo Config Server (8888):
powershell -Command "try { Invoke-WebRequest -Uri 'http://localhost:8888/actuator/health' -TimeoutSec 3 -UseBasicParsing | Out-Null; Write-Host '  V Config Server OK' -ForegroundColor Green } catch { Write-Host '  X Config Server OFFLINE' -ForegroundColor Red }"

echo Produto Service (8082):
powershell -Command "try { Invoke-WebRequest -Uri 'http://localhost:8082/actuator/health' -TimeoutSec 3 -UseBasicParsing | Out-Null; Write-Host '  V Produto Service OK' -ForegroundColor Green } catch { Write-Host '  X Produto Service OFFLINE' -ForegroundColor Red }"

echo.
echo ===================================
echo VERIFICACAO CONCLUIDA
echo ===================================
echo.
pause
