# Script para testar o Ecossistema Comprae no Docker
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "     Teste Ecossistema Comprae      " -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se os containers estao rodando
Write-Host "Verificando containers..." -ForegroundColor Yellow
$containers = docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | findstr "comprae"

if ($containers) {
    Write-Host "Containers em execucao:" -ForegroundColor Green
    $containers | ForEach-Object { Write-Host "   $_" -ForegroundColor White }
} else {
    Write-Host "Nenhum container Comprae em execucao!" -ForegroundColor Red
    Write-Host "Execute: .\iniciar-docker-completo.ps1 -Background" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Testando endpoints..." -ForegroundColor Yellow

# Funcao para testar endpoint
function Test-Endpoint {
    param($name, $url)
    try {
        $response = Invoke-WebRequest -Uri $url -TimeoutSec 10 -UseBasicParsing
        Write-Host "   $name : " -NoNewline -ForegroundColor White
        Write-Host "ONLINE " -NoNewline -ForegroundColor Green
        Write-Host "($($response.StatusCode))" -ForegroundColor Gray
        return $true
    }
    catch {
        Write-Host "   $name : " -NoNewline -ForegroundColor White
        Write-Host "OFFLINE " -NoNewline -ForegroundColor Red
        Write-Host "($($_.Exception.Message))" -ForegroundColor Gray
        return $false
    }
}

# Testar infraestrutura
Write-Host "Infraestrutura:" -ForegroundColor Cyan
Test-Endpoint "PostgreSQL" "http://localhost:5432" | Out-Null
Test-Endpoint "Redis" "http://localhost:6379" | Out-Null
Test-Endpoint "Elasticsearch" "http://localhost:9200"
Test-Endpoint "Kafka UI" "http://localhost:8090"
Test-Endpoint "Grafana" "http://localhost:3000"
Test-Endpoint "Prometheus" "http://localhost:9090"
Test-Endpoint "Kibana" "http://localhost:5601"
Test-Endpoint "Zipkin" "http://localhost:9411"

Write-Host ""
Write-Host "Microservicos:" -ForegroundColor Cyan
$configOk = Test-Endpoint "Config Server" "http://localhost:8888/actuator/health"
$produtoOk = Test-Endpoint "Produto Service" "http://localhost:8082/actuator/health"

Write-Host ""
Write-Host "APIs do Produto Service:" -ForegroundColor Cyan
if ($produtoOk) {
    Test-Endpoint "Health Check" "http://localhost:8082/api/produtos/health"
    Test-Endpoint "Lista Produtos" "http://localhost:8082/api/produtos"
} else {
    Write-Host "   Produto Service offline - pule testes de API" -ForegroundColor Red
}

Write-Host ""
if ($configOk -and $produtoOk) {
    Write-Host "Sistema Comprae: " -NoNewline -ForegroundColor White
    Write-Host "FUNCIONANDO COMPLETAMENTE!" -ForegroundColor Green
} elseif ($configOk -or $produtoOk) {
    Write-Host "Sistema Comprae: " -NoNewline -ForegroundColor White
    Write-Host "PARCIALMENTE FUNCIONANDO" -ForegroundColor Yellow
} else {
    Write-Host "Sistema Comprae: " -NoNewline -ForegroundColor White
    Write-Host "OFFLINE" -ForegroundColor Red
}

Write-Host ""
Write-Host "Comandos uteis:" -ForegroundColor Cyan
Write-Host "   Ver logs: docker-compose logs -f [servico]" -ForegroundColor White
Write-Host "   Reiniciar: docker-compose restart [servico]" -ForegroundColor White
Write-Host "   Parar tudo: docker-compose down" -ForegroundColor White
Write-Host ""
