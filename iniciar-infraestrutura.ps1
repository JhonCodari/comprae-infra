# Iniciar Infraestrutura Basica do Comprae
param(
    [switch]$Logs
)

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "   Infraestrutura Basica Comprae    " -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Parar containers existentes
Write-Host "Parando containers existentes..." -ForegroundColor Yellow
docker-compose down

# Servicos basicos (infraestrutura)
$basicServices = @(
    "postgres",
    "redis", 
    "zookeeper",
    "kafka",
    "elasticsearch",
    "kibana",
    "prometheus",
    "grafana",
    "zipkin",
    "kafka-ui"
)

Write-Host "Iniciando servicos de infraestrutura..." -ForegroundColor Green
Write-Host ""

Write-Host "Servicos que serao iniciados:" -ForegroundColor Cyan
Write-Host "   PostgreSQL    : localhost:5432" -ForegroundColor White
Write-Host "   Redis         : localhost:6379" -ForegroundColor White  
Write-Host "   Zookeeper     : localhost:2181" -ForegroundColor White
Write-Host "   Kafka         : localhost:9092" -ForegroundColor White
Write-Host "   Elasticsearch : localhost:9200" -ForegroundColor White
Write-Host "   Kibana        : localhost:5601" -ForegroundColor White
Write-Host "   Prometheus    : localhost:9090" -ForegroundColor White
Write-Host "   Grafana       : localhost:3000 (admin/admin123)" -ForegroundColor White
Write-Host "   Zipkin        : localhost:9411" -ForegroundColor White
Write-Host "   Kafka UI      : localhost:8090" -ForegroundColor White
Write-Host ""

# Iniciar servicos basicos
$servicesList = $basicServices -join " "
$command = "docker-compose up -d $servicesList"

Write-Host "Executando: $command" -ForegroundColor Gray
Write-Host ""

try {
    Invoke-Expression $command
    
    Write-Host ""
    Write-Host "Aguardando servicos iniciarem..." -ForegroundColor Yellow
    Start-Sleep 15
    
    Write-Host ""
    Write-Host "Status dos containers:" -ForegroundColor Cyan
    docker-compose ps
    
    Write-Host ""
    Write-Host "Infraestrutura basica iniciada!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Comandos uteis:" -ForegroundColor Cyan
    Write-Host "   Ver logs: docker-compose logs -f" -ForegroundColor White
    Write-Host "   Verificar saude: docker-compose ps" -ForegroundColor White
    Write-Host "   Parar: docker-compose down" -ForegroundColor White
    Write-Host ""
    
    if ($Logs) {
        Write-Host "Mostrando logs..." -ForegroundColor Blue
        docker-compose logs -f $servicesList
    }
}
catch {
    Write-Host "Erro ao iniciar infraestrutura!" -ForegroundColor Red
    Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
