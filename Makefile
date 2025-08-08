.PHONY: help start stop restart logs status dev prod build clean health

# Default target
help: ## Mostra esta ajuda
	@echo "======================================"
	@echo "   COMPRAE INFRASTRUCTURE MANAGER"
	@echo "======================================"
	@echo ""
	@echo "Targets disponíveis:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

start: ## Inicia todos os serviços
	@echo "Iniciando todos os serviços..."
	@docker-compose up -d
	@echo "✅ Serviços iniciados!"
	@echo "Acesse:"
	@echo "  - API Gateway: http://localhost:8080"
	@echo "  - Eureka: http://localhost:8761"
	@echo "  - Kafka UI: http://localhost:8080"
	@echo "  - Grafana: http://localhost:3000"
	@echo "  - Kibana: http://localhost:5601"
	@echo "  - Zipkin: http://localhost:9411"

stop: ## Para todos os serviços
	@echo "Parando todos os serviços..."
	@docker-compose down
	@echo "✅ Serviços parados!"

restart: ## Reinicia todos os serviços
	@echo "Reiniciando todos os serviços..."
	@docker-compose down
	@docker-compose up -d
	@echo "✅ Serviços reiniciados!"

logs: ## Mostra logs dos serviços
	@docker-compose logs -f

status: ## Mostra status dos containers
	@echo "Status dos containers:"
	@docker-compose ps
	@echo ""
	@echo "Uso de recursos:"
	@docker stats --no-stream

dev: ## Inicia ambiente de desenvolvimento
	@echo "Iniciando ambiente de desenvolvimento..."
	@docker-compose -f docker-compose.dev.yml up -d
	@echo "✅ Ambiente de desenvolvimento iniciado!"
	@echo "Acesse:"
	@echo "  - PostgreSQL: localhost:5433"
	@echo "  - Redis: localhost:6380"
	@echo "  - Kafka UI: http://localhost:8081"
	@echo "  - Elasticsearch: http://localhost:9201"
	@echo "  - Adminer: http://localhost:8082"
	@echo "  - MailHog: http://localhost:8025"

prod: ## Inicia ambiente de produção
	@echo "Iniciando ambiente de produção..."
	@docker-compose up -d
	@echo "✅ Ambiente de produção iniciado!"

build: ## Constrói todas as imagens
	@echo "Construindo todas as imagens..."
	@if [ -d "../comprae-config-server" ]; then \
		echo "Construindo Config Server..."; \
		cd ../comprae-config-server && docker build -t comprae/config-server:latest .; \
	fi
	@if [ -d "../comprae-eureka-server" ]; then \
		echo "Construindo Eureka Server..."; \
		cd ../comprae-eureka-server && docker build -t comprae/eureka-server:latest .; \
	fi
	@if [ -d "../comprae-api-gateway" ]; then \
		echo "Construindo API Gateway..."; \
		cd ../comprae-api-gateway && docker build -t comprae/api-gateway:latest .; \
	fi
	@if [ -d "../comprae-user-service" ]; then \
		echo "Construindo User Service..."; \
		cd ../comprae-user-service && docker build -t comprae/user-service:latest .; \
	fi
	@if [ -d "../comprae-product-service" ]; then \
		echo "Construindo Product Service..."; \
		cd ../comprae-product-service && docker build -t comprae/product-service:latest .; \
	fi
	@if [ -d "../comprae-order-service" ]; then \
		echo "Construindo Order Service..."; \
		cd ../comprae-order-service && docker build -t comprae/order-service:latest .; \
	fi
	@if [ -d "../comprae-payment-service" ]; then \
		echo "Construindo Payment Service..."; \
		cd ../comprae-payment-service && docker build -t comprae/payment-service:latest .; \
	fi
	@if [ -d "../comprae-notification-service" ]; then \
		echo "Construindo Notification Service..."; \
		cd ../comprae-notification-service && docker build -t comprae/notification-service:latest .; \
	fi
	@echo "✅ Todas as imagens foram construídas!"

clean: ## Remove containers, volumes e imagens
	@echo "⚠️  ATENÇÃO: Isso removerá TODOS os containers, volumes e imagens do Compraê!"
	@read -p "Tem certeza? (s/N): " confirm && [ "$$confirm" = "s" ] || exit 1
	@echo "Removendo containers..."
	@docker-compose down -v --remove-orphans
	@docker-compose -f docker-compose.dev.yml down -v --remove-orphans
	@echo "Removendo imagens..."
	@docker rmi comprae/config-server:latest 2>/dev/null || true
	@docker rmi comprae/eureka-server:latest 2>/dev/null || true
	@docker rmi comprae/api-gateway:latest 2>/dev/null || true
	@docker rmi comprae/user-service:latest 2>/dev/null || true
	@docker rmi comprae/product-service:latest 2>/dev/null || true
	@docker rmi comprae/order-service:latest 2>/dev/null || true
	@docker rmi comprae/payment-service:latest 2>/dev/null || true
	@docker rmi comprae/notification-service:latest 2>/dev/null || true
	@echo "Removendo volumes órfãos..."
	@docker volume prune -f
	@echo "✅ Ambiente limpo!"

health: ## Verifica saúde dos serviços
	@echo "Verificando saúde dos serviços..."
	@docker-compose ps
