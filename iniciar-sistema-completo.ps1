# Iniciar Sistema Compraê - Completo
# Este script inicia todo o ecossistema Compraê com Docker Compose

param(
    [switch]$Build,
    [switch]$Logs,
    [switch]$Background
)

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "     Sistema E-Commerce Compraê     " -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Função para verificar se o Docker está rodando
function Test-DockerRunning {
    try {
        docker ps > $null 2>&1
        return $true
    }
    catch {
        return $false
    }
}

# Verificar Docker
Write-Host "🔍 Verificando Docker..." -ForegroundColor Yellow
if (-not (Test-DockerRunning)) {
    Write-Host "❌ Docker não está em execução!" -ForegroundColor Red
    Write-Host "📋 Iniciando Docker Desktop..." -ForegroundColor Blue
    
    # Tentar iniciar Docker Desktop
    $dockerPath = "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dockerPath) {
        Start-Process $dockerPath
        Write-Host "⏳ Aguardando Docker inicializar (30 segundos)..." -ForegroundColor Yellow
        Start-Sleep 30
        
        # Verificar novamente
        if (-not (Test-DockerRunning)) {
            Write-Host "❌ Não foi possível iniciar o Docker automaticamente!" -ForegroundColor Red
            Write-Host "📋 Inicie o Docker Desktop manualmente e execute este script novamente." -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "❌ Docker Desktop não encontrado!" -ForegroundColor Red
        Write-Host "📋 Instale o Docker Desktop e execute novamente." -ForegroundColor Yellow
        exit 1
    }
}
Write-Host "✅ Docker está rodando!" -ForegroundColor Green

# Validar configuração
Write-Host "🔍 Validando configuração..." -ForegroundColor Yellow
try {
    docker-compose config --quiet
    Write-Host "✅ Configuração válida!" -ForegroundColor Green
}
catch {
    Write-Host "❌ Erro na configuração do docker-compose.yml!" -ForegroundColor Red
    Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Parar containers existentes
Write-Host "🛑 Parando containers existentes..." -ForegroundColor Yellow
docker-compose down

# Limpar containers órfãos
Write-Host "🧹 Limpando containers órfãos..." -ForegroundColor Yellow
docker-compose down --remove-orphans

# Comando base
$dockerCmd = "docker-compose up"

if ($Build) {
    Write-Host "🔨 Incluindo rebuild das imagens..." -ForegroundColor Blue
    $dockerCmd += " --build"
}

if ($Background) {
    Write-Host "🔄 Executando em background..." -ForegroundColor Blue
    $dockerCmd += " -d"
}

# Iniciar serviços
Write-Host ""
Write-Host "🚀 Iniciando Sistema Compraê..." -ForegroundColor Green
Write-Host "📋 Comando: $dockerCmd" -ForegroundColor Gray
Write-Host ""

# Mostrar informações dos serviços
Write-Host "📋 Serviços que serão iniciados:" -ForegroundColor Cyan
Write-Host "   🗄️  PostgreSQL        : localhost:5432" -ForegroundColor White
Write-Host "   🔴 Redis             : localhost:6379" -ForegroundColor White
Write-Host "   📡 Zookeeper         : localhost:2181" -ForegroundColor White
Write-Host "   📬 Kafka             : localhost:9092" -ForegroundColor White
Write-Host "   🔧 Config Server     : localhost:8888" -ForegroundColor White
Write-Host "   🌐 Eureka Server     : localhost:8761" -ForegroundColor White
Write-Host "   🔀 API Gateway       : localhost:8080" -ForegroundColor White
Write-Host "   📦 Produto Service   : localhost:8082" -ForegroundColor White
Write-Host "   👤 Usuário Service   : localhost:8081" -ForegroundColor White
Write-Host "   📊 Prometheus        : localhost:9090" -ForegroundColor White
Write-Host "   📈 Grafana           : localhost:3000" -ForegroundColor White
Write-Host "   🔍 Elasticsearch     : localhost:9200" -ForegroundColor White
Write-Host "   📊 Kibana            : localhost:5601" -ForegroundColor White
Write-Host "   🎛️  Kafka UI          : localhost:8090" -ForegroundColor White
Write-Host "   🕵️  Zipkin           : localhost:9411" -ForegroundColor White
Write-Host ""

# Executar comando
try {
    Invoke-Expression $dockerCmd
    
    if ($Background) {
        Write-Host ""
        Write-Host "✅ Sistema iniciado em background!" -ForegroundColor Green
        Write-Host "📋 Para ver logs: docker-compose logs -f" -ForegroundColor Yellow
        Write-Host "📋 Para parar: docker-compose down" -ForegroundColor Yellow
        
        # Aguardar um pouco e verificar status
        Start-Sleep 10
        Write-Host ""
        Write-Host "📊 Status dos containers:" -ForegroundColor Cyan
        docker-compose ps
    }
}
catch {
    Write-Host "❌ Erro ao iniciar o sistema!" -ForegroundColor Red
    Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if ($Logs) {
    Write-Host ""
    Write-Host "📋 Mostrando logs..." -ForegroundColor Blue
    docker-compose logs -f
}

Write-Host ""
Write-Host "🎉 Sistema Compraê inicializado com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Comandos úteis:" -ForegroundColor Cyan
Write-Host "   • Ver status: docker-compose ps" -ForegroundColor White
Write-Host "   • Ver logs: docker-compose logs -f [serviço]" -ForegroundColor White
Write-Host "   • Parar sistema: docker-compose down" -ForegroundColor White
Write-Host "   • Reiniciar serviço: docker-compose restart [serviço]" -ForegroundColor White
Write-Host ""
