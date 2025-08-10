# Status do Sistema Comprae
Write-Host "=== STATUS DO ECOSSISTEMA COMPRAÊ ===" -ForegroundColor Cyan
Write-Host ""

# Verificar se Docker está rodando
try {
    docker ps | Out-Null
    Write-Host "✅ INFRAESTRUTURA INICIADA COM SUCESSO!" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker não está funcionando!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📊 Serviços em execução:" -ForegroundColor Yellow

# Verificar cada serviço
$services = @(
    @{Name="PostgreSQL"; Port=5432; Url="localhost:5432"},
    @{Name="Redis"; Port=6379; Url="localhost:6379"},
    @{Name="Zookeeper"; Port=2181; Url="localhost:2181"},
    @{Name="Kafka"; Port=9092; Url="localhost:9092"},
    @{Name="Kafka UI"; Port=8090; Url="localhost:8090"},
    @{Name="Elasticsearch"; Port=9200; Url="localhost:9200"},
    @{Name="Kibana"; Port=5601; Url="localhost:5601"},
    @{Name="Prometheus"; Port=9090; Url="localhost:9090"},
    @{Name="Grafana"; Port=3000; Url="localhost:3000 (admin/admin123)"},
    @{Name="Zipkin"; Port=9411; Url="localhost:9411"}
)

foreach ($service in $services) {
    $container = docker ps --filter "expose=$($service.Port)" --format "{{.Names}}" | Where-Object { $_ -match "comprae" }
    if ($container) {
        Write-Host "   ✅ $($service.Name.PadRight(15)) : http://$($service.Url)" -ForegroundColor Green
    } else {
        Write-Host "   ❌ $($service.Name.PadRight(15)) : Não encontrado" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "⚠️  MICROSERVIÇOS PENDENTES:" -ForegroundColor Yellow
Write-Host "   - Config Server (precisa fazer build da imagem)" -ForegroundColor Gray
Write-Host "   - Produto Service (precisa fazer build da imagem)" -ForegroundColor Gray

Write-Host ""
Write-Host "💡 API Gateway:" -ForegroundColor Cyan
Write-Host "   - Comentado temporariamente para simplificar desenvolvimento" -ForegroundColor Gray
Write-Host "   - Descomente quando tiver múltiplos microserviços" -ForegroundColor Gray

Write-Host ""
Write-Host "🔧 Próximos passos:" -ForegroundColor Cyan
Write-Host "   1. Fazer build das imagens Docker dos microserviços" -ForegroundColor White
Write-Host "   2. Executar: docker-compose up" -ForegroundColor White
Write-Host "   3. Acessar Produto Service diretamente: http://localhost:8082" -ForegroundColor White
