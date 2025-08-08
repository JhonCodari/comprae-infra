# Script de Inicializacao do Ecossistema Comprae
# Versao simplificada sem caracteres especiais

$ErrorActionPreference = "Stop"

Write-Host "Iniciando Ecossistema Completo Comprae..." -ForegroundColor Green
Write-Host ""

# Funcao para verificar se um servico esta rodando
function Test-Service {
    param(
        [string]$Url,
        [string]$ServiceName,
        [int]$MaxAttempts = 30
    )
    
    Write-Host "Aguardando $ServiceName estar disponivel..." -ForegroundColor Yellow
    
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            $response = Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec 5 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-Host "SUCESSO: $ServiceName esta disponivel!" -ForegroundColor Green
                return $true
            }
        } catch {
            # Servico ainda nao esta disponivel
        }
        
        Write-Host "Tentativa $attempt/$MaxAttempts - Aguardando $ServiceName..." -ForegroundColor Yellow
        Start-Sleep -Seconds 3
    }
    
    Write-Host "ERRO: $ServiceName nao ficou disponivel apos $($MaxAttempts * 3) segundos" -ForegroundColor Red
    return $false
}

# Verificar se estamos no diretorio correto
if (-not (Test-Path "docker-compose.yml")) {
    Write-Host "ERRO: Execute este script no diretorio comprae-infra" -ForegroundColor Red
    exit 1
}

Write-Host "Iniciando infraestrutura base..." -ForegroundColor Blue
Write-Host ""

# 1. Iniciar servicos base (PostgreSQL, Redis, Kafka)
Write-Host "Iniciando servicos de infraestrutura..." -ForegroundColor Blue
docker-compose up -d postgres redis zookeeper kafka kafka-ui

# 2. Iniciar Config Server
Write-Host "Iniciando Config Server..." -ForegroundColor Blue
docker-compose up -d config-server

if (-not (Test-Service -Url "http://localhost:8888/actuator/health" -ServiceName "Config Server")) {
    Write-Host "ERRO: Config Server falhou ao iniciar" -ForegroundColor Red
    exit 1
}

# 3. Popular configuracoes do produto service
Write-Host "Configurando Produto Service..." -ForegroundColor Blue
if (Test-Path "../comprae-produto-service/scripts/popular-configuracoes.ps1") {
    Set-Location "../comprae-produto-service"
    try {
        & "./scripts/popular-configuracoes.ps1"
        Write-Host "SUCESSO: Configuracoes do Produto Service populadas" -ForegroundColor Green
    } catch {
        Write-Host "AVISO: Erro ao popular configuracoes do Produto Service" -ForegroundColor Yellow
    }
    Set-Location "../comprae-infra"
}

# 4. Iniciar microservicos
Write-Host "Iniciando microservicos..." -ForegroundColor Blue
docker-compose up -d comprae-produto-service

# Aguardar produto service
if (Test-Service -Url "http://localhost:8082/actuator/health" -ServiceName "Produto Service") {
    Write-Host "SUCESSO: Produto Service iniciado com sucesso!" -ForegroundColor Green
}

# 5. Iniciar monitoramento
Write-Host "Iniciando servicos de monitoramento..." -ForegroundColor Blue
docker-compose up -d prometheus grafana

Write-Host ""
Write-Host "ECOSSISTEMA COMPRAE INICIADO COM SUCESSO!" -ForegroundColor Green
Write-Host ""
Write-Host "Servicos disponiveis:" -ForegroundColor Blue
Write-Host ""
Write-Host "Infraestrutura:" -ForegroundColor Yellow
Write-Host "• Config Server: http://localhost:8888" -ForegroundColor Cyan
Write-Host "• Kafka UI: http://localhost:8090" -ForegroundColor Cyan
Write-Host ""
Write-Host "Microservicos:" -ForegroundColor Yellow
Write-Host "• Produto Service API: http://localhost:8082/api/v1/produtos" -ForegroundColor Cyan
Write-Host "• Produto Service Swagger: http://localhost:8082/swagger-ui.html" -ForegroundColor Cyan
Write-Host "• Configuracoes: http://localhost:8082/api/v1/configuracoes" -ForegroundColor Cyan
Write-Host ""
Write-Host "Monitoramento:" -ForegroundColor Yellow
Write-Host "• Prometheus: http://localhost:9090" -ForegroundColor Cyan
Write-Host "• Grafana: http://localhost:3000 (admin/admin)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para acompanhar logs:" -ForegroundColor Yellow
Write-Host "docker-compose logs -f comprae-produto-service" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para parar tudo:" -ForegroundColor Yellow
Write-Host "docker-compose down" -ForegroundColor Cyan
Write-Host ""
