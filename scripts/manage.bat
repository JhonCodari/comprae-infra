@echo off
echo ====================================
echo    COMPRAE INFRASTRUCTURE MANAGER
echo ====================================
echo.

if "%1"=="" goto show_help
if "%1"=="help" goto show_help
if "%1"=="start" goto start_services
if "%1"=="stop" goto stop_services
if "%1"=="restart" goto restart_services
if "%1"=="logs" goto show_logs
if "%1"=="status" goto show_status
if "%1"=="dev" goto dev_mode
if "%1"=="prod" goto prod_mode
if "%1"=="build" goto build_images
if "%1"=="clean" goto clean_environment

:show_help
echo Uso: %0 [comando]
echo.
echo Comandos disponíveis:
echo   start     - Inicia todos os serviços
echo   stop      - Para todos os serviços
echo   restart   - Reinicia todos os serviços
echo   logs      - Mostra logs dos serviços
echo   status    - Mostra status dos containers
echo   dev       - Inicia ambiente de desenvolvimento
echo   prod      - Inicia ambiente de produção
echo   build     - Constrói todas as imagens
echo   clean     - Remove containers, volumes e imagens
echo   help      - Mostra esta ajuda
echo.
goto end

:start_services
echo Iniciando todos os serviços...
docker-compose up -d
echo Serviços iniciados!
echo Acesse:
echo   - API Gateway: http://localhost:8080
echo   - Eureka: http://localhost:8761
echo   - Kafka UI: http://localhost:8080
echo   - Grafana: http://localhost:3000
echo   - Kibana: http://localhost:5601
echo   - Zipkin: http://localhost:9411
goto end

:stop_services
echo Parando todos os serviços...
docker-compose down
echo Serviços parados!
goto end

:restart_services
echo Reiniciando todos os serviços...
docker-compose down
docker-compose up -d
echo Serviços reiniciados!
goto end

:show_logs
if "%2"=="" (
    echo Mostrando logs de todos os serviços...
    docker-compose logs -f
) else (
    echo Mostrando logs do serviço %2...
    docker-compose logs -f %2
)
goto end

:show_status
echo Status dos containers:
docker-compose ps
echo.
echo Uso de recursos:
docker stats --no-stream
goto end

:dev_mode
echo Iniciando ambiente de desenvolvimento...
docker-compose -f docker-compose.dev.yml up -d
echo Ambiente de desenvolvimento iniciado!
echo Acesse:
echo   - PostgreSQL: localhost:5433
echo   - Redis: localhost:6380
echo   - Kafka UI: http://localhost:8081
echo   - Elasticsearch: http://localhost:9201
echo   - Adminer: http://localhost:8082
echo   - MailHog: http://localhost:8025
goto end

:prod_mode
echo Iniciando ambiente de produção...
docker-compose up -d
echo Ambiente de produção iniciado!
goto end

:build_images
echo Construindo todas as imagens...
echo Construindo Config Server...
cd ..\comprae-config-server
docker build -t comprae/config-server:latest .
cd ..\comprae-infra

echo Construindo Eureka Server...
cd ..\comprae-eureka-server
docker build -t comprae/eureka-server:latest .
cd ..\comprae-infra

echo Construindo API Gateway...
cd ..\comprae-api-gateway
docker build -t comprae/api-gateway:latest .
cd ..\comprae-infra

echo Construindo User Service...
cd ..\comprae-user-service
docker build -t comprae/user-service:latest .
cd ..\comprae-infra

echo Construindo Product Service...
cd ..\comprae-product-service
docker build -t comprae/product-service:latest .
cd ..\comprae-infra

echo Construindo Order Service...
cd ..\comprae-order-service
docker build -t comprae/order-service:latest .
cd ..\comprae-infra

echo Construindo Payment Service...
cd ..\comprae-payment-service
docker build -t comprae/payment-service:latest .
cd ..\comprae-infra

echo Construindo Notification Service...
cd ..\comprae-notification-service
docker build -t comprae/notification-service:latest .
cd ..\comprae-infra

echo Todas as imagens foram construídas!
goto end

:clean_environment
echo ATENÇÃO: Isso removerá TODOS os containers, volumes e imagens do Compraê!
set /p confirm="Tem certeza? (s/N): "
if /I "%confirm%"=="s" (
    echo Removendo containers...
    docker-compose down -v --remove-orphans
    docker-compose -f docker-compose.dev.yml down -v --remove-orphans
    
    echo Removendo imagens...
    docker rmi comprae/config-server:latest 2>nul
    docker rmi comprae/eureka-server:latest 2>nul
    docker rmi comprae/api-gateway:latest 2>nul
    docker rmi comprae/user-service:latest 2>nul
    docker rmi comprae/product-service:latest 2>nul
    docker rmi comprae/order-service:latest 2>nul
    docker rmi comprae/payment-service:latest 2>nul
    docker rmi comprae/notification-service:latest 2>nul
    
    echo Removendo volumes órfãos...
    docker volume prune -f
    
    echo Ambiente limpo!
) else (
    echo Operação cancelada.
)
goto end

:end
pause
