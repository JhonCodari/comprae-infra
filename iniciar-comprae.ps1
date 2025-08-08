# Iniciar Sistema Comprae - Completo
param(
    [switch]$Build,
    [switch]$Logs,
    [switch]$Background
)

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "     Sistema E-Commerce Comprae     " -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Funcao para verificar se o Docker esta rodando
function Test-DockerRunning {
    try {
        docker ps | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Verificar Docker
Write-Host "Verificando Docker..." -ForegroundColor Yellow
if (-not (Test-DockerRunning)) {
    Write-Host "Docker nao esta em execucao!" -ForegroundColor Red
    Write-Host "Iniciando Docker Desktop..." -ForegroundColor Blue
    
    $dockerPath = "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dockerPath) {
        Start-Process $dockerPath
        Write-Host "Aguardando Docker inicializar (30 segundos)..." -ForegroundColor Yellow
        Start-Sleep 30
        
        if (-not (Test-DockerRunning)) {
            Write-Host "Nao foi possivel iniciar o Docker automaticamente!" -ForegroundColor Red
            Write-Host "Inicie o Docker Desktop manualmente e execute este script novamente." -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "Docker Desktop nao encontrado!" -ForegroundColor Red
        Write-Host "Instale o Docker Desktop e execute novamente." -ForegroundColor Yellow
        exit 1
    }
}
Write-Host "Docker esta rodando!" -ForegroundColor Green

# Validar configuracao
Write-Host "Validando configuracao..." -ForegroundColor Yellow
try {
    docker-compose config --quiet
    Write-Host "Configuracao valida!" -ForegroundColor Green
}
catch {
    Write-Host "Erro na configuracao do docker-compose.yml!" -ForegroundColor Red
    Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Parar containers existentes
Write-Host "Parando containers existentes..." -ForegroundColor Yellow
docker-compose down

# Limpar containers orfaos
Write-Host "Limpando containers orfaos..." -ForegroundColor Yellow
docker-compose down --remove-orphans

# Comando base
$dockerCmd = "docker-compose up"

if ($Build) {
    Write-Host "Incluindo rebuild das imagens..." -ForegroundColor Blue
    $dockerCmd += " --build"
}

if ($Background) {
    Write-Host "Executando em background..." -ForegroundColor Blue
    $dockerCmd += " -d"
}

# Iniciar servicos
Write-Host ""
Write-Host "Iniciando Sistema Comprae..." -ForegroundColor Green
Write-Host "Comando: $dockerCmd" -ForegroundColor Gray
Write-Host ""

# Mostrar informacoes dos servicos
Write-Host "Servicos que serao iniciados:" -ForegroundColor Cyan
Write-Host "   PostgreSQL        : localhost:5432" -ForegroundColor White
Write-Host "   Redis             : localhost:6379" -ForegroundColor White
Write-Host "   Zookeeper         : localhost:2181" -ForegroundColor White
Write-Host "   Kafka             : localhost:9092" -ForegroundColor White
Write-Host "   Config Server     : localhost:8888" -ForegroundColor White
Write-Host "   Eureka Server     : localhost:8761" -ForegroundColor White
Write-Host "   API Gateway       : localhost:8080" -ForegroundColor White
Write-Host "   Produto Service   : localhost:8082" -ForegroundColor White
Write-Host "   Usuario Service   : localhost:8081" -ForegroundColor White
Write-Host "   Prometheus        : localhost:9090" -ForegroundColor White
Write-Host "   Grafana           : localhost:3000" -ForegroundColor White
Write-Host "   Elasticsearch     : localhost:9200" -ForegroundColor White
Write-Host "   Kibana            : localhost:5601" -ForegroundColor White
Write-Host "   Kafka UI          : localhost:8090" -ForegroundColor White
Write-Host "   Zipkin            : localhost:9411" -ForegroundColor White
Write-Host ""

# Executar comando
try {
    Invoke-Expression $dockerCmd
    
    if ($Background) {
        Write-Host ""
        Write-Host "Sistema iniciado em background!" -ForegroundColor Green
        Write-Host "Para ver logs: docker-compose logs -f" -ForegroundColor Yellow
        Write-Host "Para parar: docker-compose down" -ForegroundColor Yellow
        
        Start-Sleep 10
        Write-Host ""
        Write-Host "Status dos containers:" -ForegroundColor Cyan
        docker-compose ps
    }
}
catch {
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
Write-Host "Sistema Comprae inicializado com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "Comandos uteis:" -ForegroundColor Cyan
Write-Host "   Ver status: docker-compose ps" -ForegroundColor White
Write-Host "   Ver logs: docker-compose logs -f [servico]" -ForegroundColor White
Write-Host "   Parar sistema: docker-compose down" -ForegroundColor White
Write-Host "   Reiniciar servico: docker-compose restart [servico]" -ForegroundColor White
Write-Host ""
