# Script Master para Executar o Projeto Comprae Completo
# Baseado nos scripts individuais funcionais de cada repositório

param(
    [switch]$BuildImages,
    [switch]$ForceRebuild,
    [switch]$Logs,
    [switch]$Background,
    [switch]$SkipHealthCheck
)

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "         COMPRAE - PROJETO COMPLETO                   " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

# Função para verificar se o Docker está rodando
function Test-DockerRunning {
    try {
        docker ps | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Função para aguardar serviço ficar online
function Wait-ForService {
    param(
        [string]$Name,
        [string]$Url,
        [int]$TimeoutSeconds = 120
    )
    
    Write-Host "Aguardando $Name..." -ForegroundColor Yellow
    $elapsed = 0
    
    while ($elapsed -lt $TimeoutSeconds) {
        Start-Sleep -Seconds 3
        $elapsed += 3
        try {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                Write-Host "   ${Name}: ONLINE" -ForegroundColor Green
                return $true
            }
        } catch {}
        Write-Host "." -NoNewline
    }
    
    Write-Host ""
    Write-Host "   ${Name}: TIMEOUT" -ForegroundColor Red
    return $false
}

# Verificar Docker
Write-Host "🔍 Verificando Docker..." -ForegroundColor Yellow
if (-not (Test-DockerRunning)) {
    Write-Host "❌ Docker não está em execução!" -ForegroundColor Red
    Write-Host "Por favor, inicie o Docker Desktop e tente novamente." -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ Docker está rodando!" -ForegroundColor Green
Write-Host ""

# Build das imagens se necessário
if ($BuildImages -or $ForceRebuild) {
    Write-Host "🔨 Buildando imagens Docker..." -ForegroundColor Cyan
    
    Write-Host "   Buildando Config Server..." -ForegroundColor Yellow
    Push-Location "..\comprae-config-server\config-server"
    if ($ForceRebuild) {
        docker build --no-cache -t comprae/config-server:latest .
    } else {
        docker build -t comprae/config-server:latest .
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erro ao buildar Config Server!" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Pop-Location
    
    Write-Host "   Buildando Produto Service..." -ForegroundColor Yellow
    Push-Location "..\comprae-produto-service"
    if ($ForceRebuild) {
        docker build --no-cache -t comprae/produto-service:latest .
    } else {
        docker build -t comprae/produto-service:latest .
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erro ao buildar Produto Service!" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Pop-Location
    
    Write-Host "✅ Todas as imagens foram buildadas!" -ForegroundColor Green
    Write-Host ""
} else {
    # Verificar se as imagens existem
    Write-Host "🔍 Verificando imagens Docker..." -ForegroundColor Yellow
    $configImage = docker images -q comprae/config-server:latest
    $produtoImage = docker images -q comprae/produto-service:latest
    
    if (-not $configImage -or -not $produtoImage) {
        Write-Host "⚠️  Algumas imagens não foram encontradas. Executando build automático..." -ForegroundColor Yellow
        
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
    Write-Host "✅ Todas as imagens estão disponíveis!" -ForegroundColor Green
    Write-Host ""
}

# Parar containers existentes
Write-Host "🛑 Parando containers existentes..." -ForegroundColor Yellow
docker-compose down --remove-orphans
Write-Host ""

# Mostrar informações dos serviços
Write-Host "📋 Serviços que serão iniciados:" -ForegroundColor Cyan
Write-Host "   📊 PostgreSQL Config : localhost:5432 (configdb)" -ForegroundColor White
Write-Host "   📊 PostgreSQL Produto: localhost:5433 (comprae_produtos)" -ForegroundColor White
Write-Host "   🔄 Redis             : localhost:6379" -ForegroundColor White
Write-Host "   📨 Kafka             : localhost:9092" -ForegroundColor White
Write-Host "   ⚙️  Config Server     : localhost:8080" -ForegroundColor White
Write-Host "   🛍️  Produto Service   : localhost:8081" -ForegroundColor White
Write-Host "   🔍 Elasticsearch     : localhost:9200" -ForegroundColor White
Write-Host "   📈 Kibana            : localhost:5601" -ForegroundColor White
Write-Host "   📊 Grafana           : localhost:3000 (admin/admin123)" -ForegroundColor White
Write-Host "   📈 Prometheus        : localhost:9090" -ForegroundColor White
Write-Host "   📨 Kafka UI          : localhost:8090" -ForegroundColor White
Write-Host "   🔍 Zipkin            : localhost:9411" -ForegroundColor White
Write-Host ""

# Executar Docker Compose
$dockerCmd = "docker-compose up"
if ($Background) {
    $dockerCmd += " -d"
}

Write-Host "🚀 Iniciando Ecossistema Comprae..." -ForegroundColor Green
Write-Host "Comando: $dockerCmd" -ForegroundColor Gray
Write-Host ""

try {
    Invoke-Expression $dockerCmd
    
    if ($Background) {
        Write-Host ""
        Write-Host "✅ Sistema iniciado em background!" -ForegroundColor Green
        Write-Host ""
        
        if (-not $SkipHealthCheck) {
            Write-Host "🏥 Verificação de saúde dos serviços..." -ForegroundColor Cyan
            
            # Aguardar infraestrutura
            Write-Host "   Aguardando infraestrutura..." -ForegroundColor Yellow
            Start-Sleep 15
            
            # Testar serviços principais
            $configOk = Wait-ForService "Config Server" "http://localhost:8080/actuator/health" 60
            $produtoOk = Wait-ForService "Produto Service" "http://localhost:8081/actuator/health" 90
            
            Write-Host ""
            Write-Host "📊 Status dos containers:" -ForegroundColor Cyan
            docker-compose ps
            Write-Host ""
            
            if ($configOk -and $produtoOk) {
                Write-Host "🎉 Sistema completamente operacional!" -ForegroundColor Green
            } else {
                Write-Host "⚠️  Alguns serviços podem não estar respondendo ainda." -ForegroundColor Yellow
                Write-Host "   Use 'docker-compose logs [servico]' para verificar logs específicos." -ForegroundColor White
            }
        }
    }
}
catch {
    Write-Host "❌ Erro ao iniciar o sistema!" -ForegroundColor Red
    Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Dicas de troubleshooting:" -ForegroundColor Yellow
    Write-Host "   1. Verifique se o Docker Desktop está rodando" -ForegroundColor White
    Write-Host "   2. Execute 'docker-compose down' para limpar containers" -ForegroundColor White
    Write-Host "   3. Tente novamente com o parâmetro -BuildImages" -ForegroundColor White
    exit 1
}

if ($Logs) {
    Write-Host ""
    Write-Host "📋 Mostrando logs do sistema..." -ForegroundColor Blue
    docker-compose logs -f
}

Write-Host ""
Write-Host "🎯 Endpoints para teste:" -ForegroundColor Cyan
Write-Host "   ⚙️  Config Server Health : http://localhost:8080/actuator/health" -ForegroundColor White
Write-Host "   ⚙️  Config API           : http://localhost:8080/api/v1/configuracoes" -ForegroundColor White
Write-Host "   🛍️  Produto Health       : http://localhost:8081/actuator/health" -ForegroundColor White
Write-Host "   🛍️  Produto API          : http://localhost:8081/api/produtos" -ForegroundColor White
Write-Host "   🛍️  Produto Swagger      : http://localhost:8081/swagger-ui.html" -ForegroundColor White
Write-Host ""

Write-Host "🔧 Comandos úteis:" -ForegroundColor Cyan
Write-Host "   Ver status       : docker-compose ps" -ForegroundColor White
Write-Host "   Ver logs         : docker-compose logs -f [servico]" -ForegroundColor White
Write-Host "   Parar sistema    : docker-compose down" -ForegroundColor White
Write-Host "   Reiniciar serviço: docker-compose restart [servico]" -ForegroundColor White
Write-Host "   Limpar volumes   : docker-compose down -v" -ForegroundColor White
Write-Host ""

if ($Background) {
    Write-Host "🌟 Projeto Comprae está rodando em background!" -ForegroundColor Green
    Write-Host "   Use 'docker-compose logs -f' para acompanhar os logs" -ForegroundColor White
    Write-Host "   Use 'docker-compose down' para parar o sistema" -ForegroundColor White
}

Write-Host ""
Write-Host "✨ Sistema pronto para uso!" -ForegroundColor Green