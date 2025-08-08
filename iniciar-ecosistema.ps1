# ======================================================================
# SCRIPT DE INICIALIZAÇÃO COMPLETA DO ECOSSISTEMA COMPRAÊ
# ======================================================================

$ErrorActionPreference = "Stop"

Write-Host "🚀 Iniciando Ecossistema Completo Compraê..." -ForegroundColor Green
Write-Host ""

# Função para verificar se um serviço está rodando
function Test-Service {
    param(
        [string]$Url,
        [string]$ServiceName,
        [int]$MaxAttempts = 30
    )
    
    Write-Host "Aguardando $ServiceName estar disponível..." -ForegroundColor Yellow
    
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            $response = Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec 5 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-Host "✓ $ServiceName está disponível!" -ForegroundColor Green
                return $true
            }
        }
        catch {
            # Serviço ainda não está disponível
        }
        
        Write-Host "Tentativa $attempt/$MaxAttempts - Aguardando $ServiceName..." -ForegroundColor Yellow
        Start-Sleep -Seconds 3
    }
    
    Write-Host "✗ $ServiceName não ficou disponível após $($MaxAttempts * 3) segundos" -ForegroundColor Red
    return $false
}

# Verificar se estamos no diretório correto
if (-not (Test-Path "docker-compose.yml")) {
    Write-Host "❌ Execute este script no diretório comprae-infra" -ForegroundColor Red
    exit 1
}

Write-Host "🐳 Iniciando infraestrutura base..." -ForegroundColor Blue
Write-Host ""

# 1. Iniciar serviços base (PostgreSQL, Redis, Kafka)
Write-Host "📦 Iniciando serviços de infraestrutura..." -ForegroundColor Blue
docker-compose up -d postgres redis zookeeper kafka kafka-ui

# 2. Aguardar serviços base estarem prontos
if (-not (Test-Service -Url "http://localhost:9200/_cluster/health" -ServiceName "Elasticsearch")) {
    Write-Host "Iniciando Elasticsearch..." -ForegroundColor Yellow
    docker-compose up -d elasticsearch
}

# 3. Iniciar Config Server
Write-Host "🔧 Iniciando Config Server..." -ForegroundColor Blue
docker-compose up -d config-server

if (-not (Test-Service -Url "http://localhost:8888/actuator/health" -ServiceName "Config Server")) {
    Write-Host "❌ Config Server falhou ao iniciar" -ForegroundColor Red
    exit 1
}

# 4. Popular configurações do produto service
Write-Host "📋 Configurando Produto Service..." -ForegroundColor Blue
if (Test-Path "../comprae-produto-service/scripts/popular-configuracoes.ps1") {
    Set-Location "../comprae-produto-service"
    try {
        & "./scripts/popular-configuracoes.ps1"
        Write-Host "✓ Configurações do Produto Service populadas" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ Erro ao popular configurações do Produto Service" -ForegroundColor Yellow
    }
    Set-Location "../comprae-infra"
}

# 5. Iniciar microserviços
Write-Host "🚀 Iniciando microserviços..." -ForegroundColor Blue
docker-compose up -d comprae-produto-service

# Aguardar produto service
if (Test-Service -Url "http://localhost:8082/actuator/health" -ServiceName "Produto Service") {
    Write-Host "✓ Produto Service iniciado com sucesso!" -ForegroundColor Green
}

# 6. Iniciar monitoramento
Write-Host "📊 Iniciando serviços de monitoramento..." -ForegroundColor Blue
docker-compose up -d prometheus grafana

Write-Host ""
Write-Host "🎉 Ecossistema Compraê iniciado com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "📚 Serviços disponíveis:" -ForegroundColor Blue
Write-Host ""
Write-Host "🔧 Infraestrutura:" -ForegroundColor Yellow
Write-Host "• Config Server: http://localhost:8888" -ForegroundColor Cyan
Write-Host "• Kafka UI: http://localhost:8090" -ForegroundColor Cyan
Write-Host "• Elasticsearch: http://localhost:9200" -ForegroundColor Cyan
Write-Host ""
Write-Host "🛍️ Microserviços:" -ForegroundColor Yellow
Write-Host "• Produto Service API: http://localhost:8082/api/v1/produtos" -ForegroundColor Cyan
Write-Host "• Produto Service Swagger: http://localhost:8082/swagger-ui.html" -ForegroundColor Cyan
Write-Host "• Configurações: http://localhost:8082/api/v1/configuracoes" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 Monitoramento:" -ForegroundColor Yellow
Write-Host "• Prometheus: http://localhost:9090" -ForegroundColor Cyan
Write-Host "• Grafana: http://localhost:3000 (admin/admin)" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔍 Para acompanhar logs:" -ForegroundColor Yellow
Write-Host "docker-compose logs -f comprae-produto-service" -ForegroundColor Cyan
Write-Host ""
Write-Host "🛑 Para parar tudo:" -ForegroundColor Yellow
Write-Host "docker-compose down" -ForegroundColor Cyan
Write-Host ""
