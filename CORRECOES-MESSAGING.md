# Correções de Sistema de Mensageria - RabbitMQ → Kafka

## Visão Geral
Foram identificadas e corrigidas inconsistências no sistema de mensageria da infraestrutura Compraê. O projeto estava configurado incorretamente com RabbitMQ, mas deveria utilizar Apache Kafka para mensageria assíncrona.

## Arquivos Corrigidos

### 1. Arquivos Docker Compose
- ✅ `docker-compose.yml` - Configurações principais de produção
- ✅ `docker-compose.dev.yml` - Configurações de desenvolvimento  
- ✅ `docker-compose.test.yml` - Configurações de teste

**Alterações:**
- Substituição do serviço `rabbitmq` por `kafka` e `zookeeper`
- Atualização das variáveis de ambiente dos microserviços
- Correção das dependências entre serviços

### 2. Scripts de Automação
- ✅ `scripts/setup.sh` - Script de configuração Linux/macOS
- ✅ `scripts/setup.ps1` - Script de configuração Windows
- ✅ `scripts/manage.bat` - Script de gerenciamento Windows
- ✅ `scripts/healthcheck.sh` - Verificação de saúde Linux/macOS
- ✅ `scripts/healthcheck.ps1` - Verificação de saúde Windows

**Alterações:**
- Criação de diretórios para volumes Kafka em vez de RabbitMQ
- Download das imagens Confluent Kafka em vez de RabbitMQ
- Atualização dos testes de conectividade
- Correção das URLs de acesso aos serviços

### 3. Arquivos de Build e Deploy
- ✅ `Makefile` - Comandos de automação
- ✅ `.github/workflows/ci-cd.yml` - Pipeline CI/CD

**Alterações:**
- URLs de acesso corrigidas para Kafka UI
- Comandos de inicialização de testes atualizados

### 4. Documentação
- ✅ `README.md` - Documentação principal
- ✅ Diagramas de arquitetura atualizados

## Resumo das Mudanças

### Antes (RabbitMQ)
```yaml
# Configuração RabbitMQ
rabbitmq:
  image: rabbitmq:3-management-alpine
  ports:
    - "5672:5672"
    - "15672:15672"
```

### Depois (Kafka)
```yaml
# Configuração Kafka + Zookeeper
zookeeper:
  image: confluentinc/cp-zookeeper:latest
  environment:
    ZOOKEEPER_CLIENT_PORT: 2181

kafka:
  image: confluentinc/cp-kafka:latest
  ports:
    - "9092:9092"
  environment:
    KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
    KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
```

### Variáveis de Ambiente dos Serviços
```bash
# Antes
SPRING_RABBITMQ_HOST=rabbitmq
SPRING_RABBITMQ_USERNAME=guest
SPRING_RABBITMQ_PASSWORD=guest

# Depois  
SPRING_KAFKA_BOOTSTRAP_SERVERS=kafka:9092
```

## URLs de Acesso Atualizadas

### Ambiente de Produção
- ~~RabbitMQ Management: http://localhost:15672~~ ❌
- **Kafka UI: http://localhost:8080** ✅

### Ambiente de Desenvolvimento
- ~~RabbitMQ Management: http://localhost:15673~~ ❌
- **Kafka UI: http://localhost:8081** ✅

## Próximos Passos

1. **Testar a Configuração**
   ```bash
   # Linux/macOS
   ./scripts/setup.sh
   
   # Windows
   ./scripts/setup.ps1
   ```

2. **Verificar Conectividade**
   ```bash
   # Linux/macOS
   ./scripts/healthcheck.sh
   
   # Windows
   ./scripts/healthcheck.ps1
   ```

3. **Executar Testes de Integração**
   ```bash
   docker-compose -f docker-compose.test.yml up -d
   ```

## Impacto nos Microserviços

Os microserviços que usam mensageria (product-service, user-service, etc.) já estão configurados para usar Kafka através do Config Client SDK. As configurações serão aplicadas automaticamente via configuração centralizada.

## Notas Importantes

- ✅ Todas as referências ao RabbitMQ foram removidas
- ✅ Scripts de automação atualizados
- ✅ Documentação corrigida
- ✅ Pipelines CI/CD ajustados
- ✅ Healthchecks adaptados para Kafka

A infraestrutura está agora consistente e alinhada com a arquitetura planejada usando Apache Kafka para mensageria assíncrona.
