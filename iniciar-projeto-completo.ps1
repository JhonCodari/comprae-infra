# Script Master para Executar o Projeto Comprae Completo
param(
    [switch]$BuildImages,
    [switch]$Background,
    [switch]$Logs
)

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "         COMPRAE - PROJETO COMPLETO                   " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar Docker
Write-Host "Verificando Docker..." -ForegroundColor Yellow
try {
    docker ps | Out-Null
    Write-Host "Docker esta rodando!" -ForegroundColor Green
} catch {
    Write-Host "Docker nao esta em execucao!" -ForegroundColor Red
    exit 1
}

# Build das imagens se necessario
if ($BuildImages) {
    Write-Host "Buildando imagens Docker..." -ForegroundColor Cyan
    
    Write-Host "   Buildando Config Server..." -ForegroundColor Yellow
    Push-Location "..\comprae-config-server\config-server"
    docker build -t comprae/config-server:latest .
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erro ao buildar Config Server!" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Pop-Location
    
    Write-Host "   Buildando Produto Service..." -ForegroundColor Yellow
    Push-Location "..\comprae-produto-service"
    docker build -t comprae/produto-service:latest .
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erro ao buildar Produto Service!" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Pop-Location
    
    Write-Host "Todas as imagens foram buildadas!" -ForegroundColor Green
} else {
    # Verificar se as imagens existem
    Write-Host "Verificando imagens Docker..." -ForegroundColor Yellow
    $configImage = docker images -q comprae/config-server:latest
    $produtoImage = docker images -q comprae/produto-service:latest
    
    if (-not $configImage -or -not $produtoImage) {
        Write-Host "Algumas imagens nao foram encontradas. Executando build automatico..." -ForegroundColor Yellow
        
        if (-not $configImage) {
            Write-Host "   Buildando Config Server..." -ForegroundColor Yellow
            Push-Location "..\comprae-config-server\config-server"
            docker build -t comprae/config-server:latest .
            Pop-Location
        }
        
        if (-not $produtoImage) {
            Write-Host "   Buildando Produto Service..." -ForegroundColor Yellow
            Push-Location "..\comprae-produto-service"
            docker build -t comprae/produto-service:latest .
            Pop-Location
        }
    }
    Write-Host "Todas as imagens estao disponiveis!" -ForegroundColor Green
}

# Parar containers existentes
Write-Host "Parando containers existentes..." -ForegroundColor Yellow
docker-compose down --remove-orphans

# Mostrar informacoes dos servicos
Write-Host ""
Write-Host "Servicos que serao iniciados:" -ForegroundColor Cyan
Write-Host "   PostgreSQL Config : localhost:5432 (configdb)" -ForegroundColor White
Write-Host "   PostgreSQL Produto: localhost:5433 (comprae_produtos)" -ForegroundColor White
Write-Host "   Redis             : localhost:6379" -ForegroundColor White
Write-Host "   Kafka             : localhost:9092" -ForegroundColor White
Write-Host "   Config Server     : localhost:8080" -ForegroundColor White
Write-Host "   Produto Service   : localhost:8081" -ForegroundColor White
Write-Host ""

# Executar Docker Compose
$dockerCmd = "docker-compose up"
if ($Background) {
    $dockerCmd += " -d"
}

Write-Host "Iniciando Ecossistema Comprae..." -ForegroundColor Green
Write-Host "Comando: $dockerCmd" -ForegroundColor Gray
Write-Host ""

try {
    Invoke-Expression $dockerCmd
    
    if ($Background) {
        Write-Host ""
        Write-Host "Sistema iniciado em background!" -ForegroundColor Green
        
        # Aguardar servicos iniciarem
        Write-Host "Aguardando servicos iniciarem..." -ForegroundColor Yellow
        Start-Sleep 30
        
        Write-Host ""
        Write-Host "Status dos containers:" -ForegroundColor Cyan
        docker-compose ps
        
        Write-Host ""
        Write-Host "Testando endpoints:" -ForegroundColor Cyan
        
        # Testar Config Server
        try {
            Invoke-WebRequest -Uri "http://localhost:8080/actuator/health" -TimeoutSec 5 | Out-Null
            Write-Host "   Config Server: ONLINE" -ForegroundColor Green
        } catch {
            Write-Host "   Config Server: OFFLINE" -ForegroundColor Red
        }
        
        # Testar Produto Service
        try {
            Invoke-WebRequest -Uri "http://localhost:8081/actuator/health" -TimeoutSec 5 | Out-Null
            Write-Host "   Produto Service: ONLINE" -ForegroundColor Green
        } catch {
            Write-Host "   Produto Service: OFFLINE" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "Erro ao iniciar o sistema!" -ForegroundColor Red
    Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if ($Logs) {
    Write-Host ""
    Write-Host "Mostrando logs..." -ForegroundColor Blue
    docker-compose logs -f
}

Write-Host ""
Write-Host "Endpoints para teste:" -ForegroundColor Cyan
Write-Host "   Config Server Health : http://localhost:8080/actuator/health" -ForegroundColor White
Write-Host "   Config API           : http://localhost:8080/api/v1/configuracoes" -ForegroundColor White
Write-Host "   Produto Health       : http://localhost:8081/actuator/health" -ForegroundColor White
Write-Host "   Produto API          : http://localhost:8081/api/produtos" -ForegroundColor White
Write-Host ""

Write-Host "Comandos uteis:" -ForegroundColor Cyan
Write-Host "   Ver status       : docker-compose ps" -ForegroundColor White
Write-Host "   Ver logs         : docker-compose logs -f [servico]" -ForegroundColor White
Write-Host "   Parar sistema    : docker-compose down" -ForegroundColor White
Write-Host "   Reiniciar servico: docker-compose restart [servico]" -ForegroundColor White
Write-Host ""

Write-Host "Sistema pronto para uso!" -ForegroundColor Green