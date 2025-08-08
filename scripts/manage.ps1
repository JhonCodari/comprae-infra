param(
    [Parameter(Position=0)]
    [string]$Command = "help",
    
    [Parameter(Position=1)]
    [string]$Service = ""
)

$ErrorActionPreference = "Stop"

function Show-Header {
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host "   COMPRAE INFRASTRUCTURE MANAGER" -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Help {
    Write-Host "Uso: .\manage.ps1 [comando] [serviço]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Comandos disponíveis:" -ForegroundColor Green
    Write-Host "  start     - Inicia todos os serviços" -ForegroundColor White
    Write-Host "  stop      - Para todos os serviços" -ForegroundColor White
    Write-Host "  restart   - Reinicia todos os serviços" -ForegroundColor White
    Write-Host "  logs      - Mostra logs dos serviços" -ForegroundColor White
    Write-Host "  status    - Mostra status dos containers" -ForegroundColor White
    Write-Host "  dev       - Inicia ambiente de desenvolvimento" -ForegroundColor White
    Write-Host "  prod      - Inicia ambiente de produção" -ForegroundColor White
    Write-Host "  build     - Constrói todas as imagens" -ForegroundColor White
    Write-Host "  clean     - Remove containers, volumes e imagens" -ForegroundColor White
    Write-Host "  health    - Verifica saúde dos serviços" -ForegroundColor White
    Write-Host "  scale     - Escala um serviço" -ForegroundColor White
    Write-Host "  help      - Mostra esta ajuda" -ForegroundColor White
    Write-Host ""
}

function Start-Services {
    Write-Host "Iniciando todos os serviços..." -ForegroundColor Yellow
    
    try {
        docker-compose up -d
        Write-Host "✅ Serviços iniciados com sucesso!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Acesse os serviços em:" -ForegroundColor Cyan
        Write-Host "  - API Gateway: http://localhost:8080" -ForegroundColor White
        Write-Host "  - Eureka: http://localhost:8761" -ForegroundColor White
        Write-Host "  - Kafka UI: http://localhost:8090" -ForegroundColor White
        Write-Host "  - Grafana: http://localhost:3000 (admin/admin123)" -ForegroundColor White
        Write-Host "  - Kibana: http://localhost:5601" -ForegroundColor White
        Write-Host "  - Prometheus: http://localhost:9090" -ForegroundColor White
        Write-Host "  - Zipkin: http://localhost:9411" -ForegroundColor White
    }
    catch {
        Write-Host "❌ Erro ao iniciar serviços: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Stop-Services {
    Write-Host "Parando todos os serviços..." -ForegroundColor Yellow
    
    try {
        docker-compose down
        Write-Host "✅ Serviços parados com sucesso!" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Erro ao parar serviços: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Restart-Services {
    Write-Host "Reiniciando todos os serviços..." -ForegroundColor Yellow
    
    try {
        docker-compose down
        docker-compose up -d
        Write-Host "✅ Serviços reiniciados com sucesso!" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Erro ao reiniciar serviços: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-Logs {
    if ($Service -eq "") {
        Write-Host "Mostrando logs de todos os serviços..." -ForegroundColor Yellow
        docker-compose logs -f
    } else {
        Write-Host "Mostrando logs do serviço $Service..." -ForegroundColor Yellow
        docker-compose logs -f $Service
    }
}

function Show-Status {
    Write-Host "Status dos containers:" -ForegroundColor Cyan
    docker-compose ps
    Write-Host ""
    Write-Host "Uso de recursos:" -ForegroundColor Cyan
    docker stats --no-stream
}

function Start-DevMode {
    Write-Host "Iniciando ambiente de desenvolvimento..." -ForegroundColor Yellow
    
    try {
        docker-compose -f docker-compose.dev.yml up -d
        Write-Host "✅ Ambiente de desenvolvimento iniciado!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Acesse os serviços de desenvolvimento em:" -ForegroundColor Cyan
        Write-Host "  - PostgreSQL: localhost:5433 (dev_user/dev_pass)" -ForegroundColor White
        Write-Host "  - Redis: localhost:6380" -ForegroundColor White
        Write-Host "  - Kafka: localhost:9093" -ForegroundColor White
        Write-Host "  - Kafka UI: http://localhost:8091" -ForegroundColor White
        Write-Host "  - Elasticsearch: http://localhost:9201" -ForegroundColor White
        Write-Host "  - Adminer: http://localhost:8081" -ForegroundColor White
        Write-Host "  - MailHog: http://localhost:8025" -ForegroundColor White
    }
    catch {
        Write-Host "❌ Erro ao iniciar ambiente de desenvolvimento: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Start-ProdMode {
    Write-Host "Iniciando ambiente de produção..." -ForegroundColor Yellow
    
    try {
        docker-compose up -d
        Write-Host "✅ Ambiente de produção iniciado!" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Erro ao iniciar ambiente de produção: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Build-Images {
    Write-Host "Construindo todas as imagens..." -ForegroundColor Yellow
    
    $services = @(
        @{Name="Config Server"; Path="../comprae-config-server"; Image="comprae/config-server:latest"},
        @{Name="Eureka Server"; Path="../comprae-eureka-server"; Image="comprae/eureka-server:latest"},
        @{Name="API Gateway"; Path="../comprae-api-gateway"; Image="comprae/api-gateway:latest"},
        @{Name="Usuário Service"; Path="../comprae-usuario-service"; Image="comprae/usuario-service:latest"},
        @{Name="Produto Service"; Path="../comprae-produto-service"; Image="comprae/produto-service:latest"},
        @{Name="Categoria Service"; Path="../comprae-categoria-service"; Image="comprae/categoria-service:latest"},
        @{Name="Estoque Service"; Path="../comprae-estoque-service"; Image="comprae/estoque-service:latest"},
        @{Name="Carrinho Service"; Path="../comprae-carrinho-service"; Image="comprae/carrinho-service:latest"},
        @{Name="Pedido Service"; Path="../comprae-pedido-service"; Image="comprae/pedido-service:latest"},
        @{Name="Pagamento Service"; Path="../comprae-pagamento-service"; Image="comprae/pagamento-service:latest"},
        @{Name="Entrega Service"; Path="../comprae-entrega-service"; Image="comprae/entrega-service:latest"},
        @{Name="Notificação Service"; Path="../comprae-notificacao-service"; Image="comprae/notificacao-service:latest"},
        @{Name="Avaliação Service"; Path="../comprae-avaliacao-service"; Image="comprae/avaliacao-service:latest"}
    )
    
    $currentPath = Get-Location
    
    foreach ($service in $services) {
        if (Test-Path $service.Path) {
            Write-Host "Construindo $($service.Name)..." -ForegroundColor Cyan
            Set-Location $service.Path
            docker build -t $service.Image .
            Set-Location $currentPath
            Write-Host "✅ $($service.Name) construído!" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Diretório $($service.Path) não encontrado. Pulando $($service.Name)." -ForegroundColor Yellow
        }
    }
    
    Write-Host "✅ Todas as imagens disponíveis foram construídas!" -ForegroundColor Green
}

function Clean-Environment {
    Write-Host "⚠️  ATENÇÃO: Isso removerá TODOS os containers, volumes e imagens do Compraê!" -ForegroundColor Red
    $confirm = Read-Host "Tem certeza? (s/N)"
    
    if ($confirm -eq "s" -or $confirm -eq "S") {
        Write-Host "Removendo containers..." -ForegroundColor Yellow
        docker-compose down -v --remove-orphans
        docker-compose -f docker-compose.dev.yml down -v --remove-orphans
        
        Write-Host "Removendo imagens..." -ForegroundColor Yellow
        $images = @(
            "comprae/config-server:latest",
            "comprae/eureka-server:latest",
            "comprae/api-gateway:latest",
            "comprae/usuario-service:latest",
            "comprae/produto-service:latest",
            "comprae/categoria-service:latest",
            "comprae/estoque-service:latest",
            "comprae/carrinho-service:latest",
            "comprae/pedido-service:latest",
            "comprae/pagamento-service:latest",
            "comprae/entrega-service:latest",
            "comprae/notificacao-service:latest",
            "comprae/avaliacao-service:latest"
        )
        
        foreach ($image in $images) {
            try {
                docker rmi $image
            } catch {
                # Ignorar erros se a imagem não existir
            }
        }
        
        Write-Host "Removendo volumes órfãos..." -ForegroundColor Yellow
        docker volume prune -f
        
        Write-Host "✅ Ambiente limpo!" -ForegroundColor Green
    } else {
        Write-Host "❌ Operação cancelada." -ForegroundColor Yellow
    }
}

function Check-Health {
    Write-Host "Verificando saúde dos serviços..." -ForegroundColor Yellow
    
    $services = docker-compose ps --services
    foreach ($service in $services) {
        $status = docker-compose ps $service
        if ($status -match "Up") {
            Write-Host "✅ $service: Saudável" -ForegroundColor Green
        } else {
            Write-Host "❌ $service: Com problemas" -ForegroundColor Red
        }
    }
}

function Scale-Service {
    if ($Service -eq "") {
        Write-Host "❌ Especifique um serviço para escalar." -ForegroundColor Red
        return
    }
    
    $replicas = Read-Host "Quantas réplicas para $Service?"
    
    try {
        docker-compose up -d --scale $Service=$replicas
        Write-Host "✅ Serviço $Service escalado para $replicas réplicas!" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Erro ao escalar serviço: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main script execution
Show-Header

switch ($Command.ToLower()) {
    "start" { Start-Services }
    "stop" { Stop-Services }
    "restart" { Restart-Services }
    "logs" { Show-Logs }
    "status" { Show-Status }
    "dev" { Start-DevMode }
    "prod" { Start-ProdMode }
    "build" { Build-Images }
    "clean" { Clean-Environment }
    "health" { Check-Health }
    "scale" { Scale-Service }
    default { Show-Help }
}
