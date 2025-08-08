# 🚀 Compraê - Infraestrutura E-Commerce

Sistema completo de e-commerce baseado em microserviços com Spring Boot, Apache Kafka e Docker.

## ⚡ Início Rápido

### 1. Pré-requisitos
- Docker Desktop 4.0+ instalado e rodando
- 8GB+ RAM disponível
- PowerShell (Windows) ou Bash (Linux/macOS)

### 2. Executar Sistema
```powershell
# Windows PowerShell
.\iniciar-sistema-completo.ps1

# Ou em background
.\iniciar-sistema-completo.ps1 -Background
```

```bash
# Linux/macOS
chmod +x *.sh
./start-ecosystem.sh
```

### 3. Verificar Sistema
```powershell
# Windows
.\verificar-sistema.ps1

# Detalhado
.\verificar-sistema.ps1 -Detailed
```

### 4. Acessar Serviços
- **API Gateway**: http://localhost:8080
- **Eureka Dashboard**: http://localhost:8761
- **Produto Service**: http://localhost:8082/swagger-ui.html
- **Grafana**: http://localhost:3000 (admin/admin123)
- **Kafka UI**: http://localhost:8090

## 🏗️ Arquitetura

### Infraestrutura
- **PostgreSQL** (5432) - Banco principal
- **Redis** (6379) - Cache
- **Apache Kafka** (9092) - Mensageria
- **Elasticsearch** (9200) - Busca e logs

### Microserviços
- **Config Server** (8888) - Configuração centralizada
- **Eureka Server** (8761) - Service Discovery
- **API Gateway** (8080) - Gateway de entrada
- **Produto Service** (8082) - Gestão de produtos
- **Usuário Service** (8081) - Gestão de usuários

### Monitoramento
- **Prometheus** (9090) - Métricas
- **Grafana** (3000) - Dashboards
- **Kibana** (5601) - Logs
- **Zipkin** (9411) - Tracing

## 🎛️ Scripts Disponíveis

### Windows PowerShell
- `iniciar-sistema-completo.ps1` - Inicia todo o sistema
- `verificar-sistema.ps1` - Verifica saúde dos serviços
- `start-basic.bat` - Inicia serviços básicos

### Linux/macOS
- `start-ecosystem.sh` - Inicia o ecossistema
- `check-system.sh` - Verifica o sistema
- `setup.sh` - Configuração inicial

### Parâmetros Úteis
```powershell
# Iniciar com rebuild
.\iniciar-sistema-completo.ps1 -Build

# Monitoramento contínuo
.\verificar-sistema.ps1 -Continuous -Interval 30

# Ver logs durante inicialização
.\iniciar-sistema-completo.ps1 -Logs
```

## 🔧 Comandos Docker

```bash
# Iniciar sistema
docker-compose up -d

# Ver status
docker-compose ps

# Ver logs
docker-compose logs -f

# Parar sistema
docker-compose down

# Rebuild completo
docker-compose up --build -d
```

## 🏥 Health Checks

Todos os serviços possuem health checks configurados:

```bash
curl http://localhost:8080/actuator/health  # API Gateway
curl http://localhost:8888/actuator/health  # Config Server
curl http://localhost:8082/actuator/health  # Produto Service
```

## 🐛 Solução de Problemas

### Docker não está rodando
```powershell
# Verificar se Docker está instalado
docker --version

# Iniciar Docker Desktop manualmente se necessário
```

### Portas em uso
```bash
# Verificar portas ocupadas
netstat -tulpn | grep :8080

# Parar containers
docker-compose down
```

### Logs de erro
```bash
# Ver logs de serviço específico
docker-compose logs -f produto-service

# Ver todos os logs
docker-compose logs -f

# Logs das últimas 100 linhas
docker-compose logs --tail=100
```

### Problemas de memória
```bash
# Verificar uso de recursos
docker stats

# Limpar recursos
docker system prune -f
```

## 📱 Interfaces Web Principais

| Serviço | URL | Credenciais |
|---------|-----|-------------|
| API Gateway | http://localhost:8080 | - |
| Swagger Produto | http://localhost:8082/swagger-ui.html | - |
| Eureka Dashboard | http://localhost:8761 | - |
| Grafana | http://localhost:3000 | admin/admin123 |
| Kafka UI | http://localhost:8090 | - |

## 🔄 Desenvolvimento

### Adicionar Novo Microserviço
1. Criar estrutura Spring Boot
2. Adicionar configuração no `docker-compose.yml`
3. Configurar health check
4. Atualizar documentação

### Build Local
```bash
# Build do serviço
mvn clean package -DskipTests

# Build da imagem
docker build -t comprae/service-name:latest .

# Restart
docker-compose restart service-name
```

## 📊 Bancos de Dados

O PostgreSQL cria automaticamente os seguintes bancos:
- `comprae_usuarios`
- `comprae_produtos` 
- `comprae_categorias`
- `comprae_estoque`
- `comprae_pedidos`
- `comprae_pagamentos`
- `comprae_entregas`
- `comprae_avaliacoes`

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch (`git checkout -b feature/nova-feature`)
3. Commit as mudanças (`git commit -m 'Add nova feature'`)
4. Push (`git push origin feature/nova-feature`)
5. Abra um Pull Request

## 📄 Licença

MIT License - veja [LICENSE](LICENSE) para detalhes.

---

**💡 Dica**: Use o script `verificar-sistema.ps1 -Continuous` para monitoramento em tempo real do sistema!
