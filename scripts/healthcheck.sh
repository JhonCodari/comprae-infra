#!/bin/bash

# Script de verificação de saúde dos serviços Compraê
# Uso: ./healthcheck.sh [service_name]

SERVICES=(
    "config-server:8888:/actuator/health"
    "eureka-server:8761:/actuator/health"
    "api-gateway:8080:/actuator/health"
    "user-service:8081:/actuator/health"
    "product-service:8082:/actuator/health"
    "order-service:8083:/actuator/health"
    "payment-service:8084:/actuator/health"
    "notification-service:8085:/actuator/health"
    "postgres:5432"
    "redis:6379"
    "kafka:9092"
    "elasticsearch:9200:/_cluster/health"
    "grafana:3000:/api/health"
    "prometheus:9090:/-/healthy"
    "zipkin:9411:/health"
)

check_service() {
    local service_info=$1
    IFS=':' read -ra ADDR <<< "$service_info"
    local service=${ADDR[0]}
    local port=${ADDR[1]}
    local endpoint=${ADDR[2]:-""}
    
    if [ -n "$endpoint" ]; then
        # HTTP health check
        url="http://localhost:$port$endpoint"
        if curl -s -f "$url" > /dev/null 2>&1; then
            echo "✅ $service: Saudável ($url)"
            return 0
        else
            echo "❌ $service: Falha na verificação ($url)"
            return 1
        fi
    else
        # TCP health check
        if nc -z localhost $port > /dev/null 2>&1; then
            echo "✅ $service: Porta $port respondendo"
            return 0
        else
            echo "❌ $service: Porta $port não está respondendo"
            return 1
        fi
    fi
}

main() {
    echo "=================================="
    echo "    COMPRAE HEALTH CHECK"
    echo "=================================="
    echo ""
    
    local target_service=$1
    local failed_services=0
    local total_services=0
    
    for service_info in "${SERVICES[@]}"; do
        IFS=':' read -ra ADDR <<< "$service_info"
        local service=${ADDR[0]}
        
        # Se um serviço específico foi fornecido, verificar apenas ele
        if [ -n "$target_service" ] && [ "$service" != "$target_service" ]; then
            continue
        fi
        
        total_services=$((total_services + 1))
        
        if ! check_service "$service_info"; then
            failed_services=$((failed_services + 1))
        fi
    done
    
    echo ""
    echo "=================================="
    echo "Resumo: $((total_services - failed_services))/$total_services serviços saudáveis"
    
    if [ $failed_services -eq 0 ]; then
        echo "🎉 Todos os serviços estão funcionando!"
        exit 0
    else
        echo "⚠️  $failed_services serviço(s) com problemas"
        exit 1
    fi
}

# Verificar se curl e nc estão disponíveis
if ! command -v curl &> /dev/null; then
    echo "❌ curl não está instalado. Instale curl para executar este script."
    exit 1
fi

if ! command -v nc &> /dev/null; then
    echo "❌ netcat (nc) não está instalado. Instale netcat para executar este script."
    exit 1
fi

main "$1"
