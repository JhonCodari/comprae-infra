# Script para inicializar o Ecossistema Comprae completo
param(
    [switch]$Build,
    [switch]$Logs,
    [switch]$Background
)

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "     Comprae Docker Ecosystem       " -ForegroundColor Cyan
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
    exit 1
}
Write-Host "Docker esta rodando!" -ForegroundColor Green

# Verificar se as imagens existem
Write-Host "Verificando imagens Docker..." -ForegroundColor Yellow
$configImage = docker images -q comprae/config-server:latest
$produtoImage = docker images -q comprae/produto-service:latest

if (-not $configImage) {
    Write-Host "Imagem comprae/config-server:latest nao encontrada!" -ForegroundColor Red
    Write-Host "Execute: docker build -t comprae/config-server:latest . no diretorio comprae-config-server/config-server" -ForegroundColor Yellow
    exit 1
}

if (-not $produtoImage) {
    Write-Host "Imagem comprae/produto-service:latest nao encontrada!" -ForegroundColor Red
    Write-Host "Execute: docker build -t comprae/produto-service:latest . no diretorio comprae-produto-service-new" -ForegroundColor Yellow
    exit 1
}

Write-Host "Todas as imagens estao disponíveis!" -ForegroundColor Green

# Parar containers existentes
Write-Host "Parando containers existentes..." -ForegroundColor Yellow
docker-compose down

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

# Mostrar informacoes dos servicos
Write-Host ""
Write-Host "Servicos que serao iniciados:" -ForegroundColor Cyan
Write-Host "   PostgreSQL        : localhost:5432" -ForegroundColor White
Write-Host "   Redis             : localhost:6379" -ForegroundColor White
Write-Host "   Kafka             : localhost:9092" -ForegroundColor White
Write-Host "   Config Server     : localhost:8888" -ForegroundColor White
Write-Host "   Produto Service   : localhost:8082" -ForegroundColor White
Write-Host "   Elasticsearch     : localhost:9200" -ForegroundColor White
Write-Host "   Kibana            : localhost:5601" -ForegroundColor White
Write-Host "   Grafana           : localhost:3000 (admin/admin123)" -ForegroundColor White
Write-Host "   Prometheus        : localhost:9090" -ForegroundColor White
Write-Host "   Kafka UI          : localhost:8090" -ForegroundColor White
Write-Host "   Zipkin            : localhost:9411" -ForegroundColor White
Write-Host ""

# Executar comando
Write-Host "Iniciando Ecossistema Comprae..." -ForegroundColor Green
Write-Host "Comando: $dockerCmd" -ForegroundColor Gray
Write-Host ""

try {
    Invoke-Expression $dockerCmd
    
    if ($Background) {
        Write-Host ""
        Write-Host "Sistema iniciado em background!" -ForegroundColor Green
        
        # Aguardar os servicos iniciarem
        Write-Host "Aguardando servicos iniciarem..." -ForegroundColor Yellow
        Start-Sleep 30
        
        Write-Host ""
        Write-Host "Status dos containers:" -ForegroundColor Cyan
        docker-compose ps
        
        Write-Host ""
        Write-Host "Testando endpoints:" -ForegroundColor Cyan
        
        # Testar Config Server
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8888/actuator/health" -TimeoutSec 5
            Write-Host "   Config Server: ONLINE" -ForegroundColor Green
        } catch {
            Write-Host "   Config Server: OFFLINE" -ForegroundColor Red
        }
        
        # Testar Produto Service
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8082/api/produtos/health" -TimeoutSec 5
            Write-Host "   Produto Service: ONLINE" -ForegroundColor Green
        } catch {
            Write-Host "   Produto Service: OFFLINE" -ForegroundColor Red
        }
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
Write-Host "Ecossistema Comprae inicializado com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "Endpoints para teste:" -ForegroundColor Cyan
Write-Host "   Config Server     : http://localhost:8888/actuator/health" -ForegroundColor White
Write-Host "   Produto Health    : http://localhost:8082/api/produtos/health" -ForegroundColor White
Write-Host "   Produto API       : http://localhost:8082/api/produtos" -ForegroundColor White
Write-Host "   Spring Actuator   : http://localhost:8082/actuator/health" -ForegroundColor White
Write-Host ""
Write-Host "Comandos uteis:" -ForegroundColor Cyan
Write-Host "   Ver status: docker-compose ps" -ForegroundColor White
Write-Host "   Ver logs: docker-compose logs -f [servico]" -ForegroundColor White
Write-Host "   Parar sistema: docker-compose down" -ForegroundColor White
Write-Host "   Reiniciar servico: docker-compose restart [servico]" -ForegroundColor White
Write-Host ""
