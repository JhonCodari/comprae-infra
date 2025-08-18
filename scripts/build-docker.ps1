# Script para build das imagens Docker dos microserviços Compraê

# Lista de serviços e caminhos para Dockerfile
$servicos = @(
    @{ nome = "config-server"; caminho = "..\comprae-config-server\config-server"; imagem = "comprae/config-server:latest" },
    @{ nome = "produto-service"; caminho = "..\comprae-produto-service"; imagem = "comprae/produto-service:latest" },
    @{ nome = "client-sdk"; caminho = "..\comprae-client-sdk"; imagem = "comprae/client-sdk:latest" }
    # Adicione outros microserviços/libs conforme necessário
)

foreach ($servico in $servicos) {
    Write-Host "\n🔨 Build da imagem Docker: $($servico.imagem)" -ForegroundColor Cyan
    try {
        docker build -t $servico.imagem $servico.caminho
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Imagem $($servico.imagem) criada com sucesso." -ForegroundColor Green
        } else {
            Write-Host "❌ Falha ao criar a imagem $($servico.imagem)." -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Erro ao executar o build da imagem $($servico.imagem)." -ForegroundColor Red
    }
}
