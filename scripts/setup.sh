#!/bin/bash

# ===========================================
# COMPRAE INFRASTRUCTURE SETUP SCRIPT
# ===========================================
# Script para configuração inicial do ambiente Compraê

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de log
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar pré-requisitos
check_prerequisites() {
    log_info "Verificando pré-requisitos..."
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker não está instalado!"
        exit 1
    fi
    log_success "Docker encontrado: $(docker --version)"
    
    # Verificar Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose não está instalado!"
        exit 1
    fi
    log_success "Docker Compose encontrado: $(docker-compose --version)"
    
    # Verificar Git
    if ! command -v git &> /dev/null; then
        log_error "Git não está instalado!"
        exit 1
    fi
    log_success "Git encontrado: $(git --version)"
    
    # Verificar se Docker está rodando
    if ! docker info &> /dev/null; then
        log_error "Docker não está rodando! Inicie o Docker e tente novamente."
        exit 1
    fi
    log_success "Docker está rodando!"
}

# Configurar arquivo de ambiente
setup_environment() {
    log_info "Configurando arquivo de ambiente..."
    
    if [ ! -f "$PROJECT_ROOT/.env" ]; then
        cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env"
        log_success "Arquivo .env criado a partir do .env.example"
        log_warning "Edite o arquivo .env para personalizar as configurações"
    else
        log_warning "Arquivo .env já existe"
    fi
}

# Criar diretórios necessários
create_directories() {
    log_info "Criando diretórios necessários..."
    
    directories=(
        "$PROJECT_ROOT/logs"
        "$PROJECT_ROOT/volumes/postgres"
        "$PROJECT_ROOT/volumes/redis"
        "$PROJECT_ROOT/volumes/kafka"
        "$PROJECT_ROOT/volumes/elasticsearch"
        "$PROJECT_ROOT/volumes/grafana"
        "$PROJECT_ROOT/volumes/prometheus"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log_success "Diretório criado: $dir"
        fi
    done
}

# Tornar scripts executáveis
make_scripts_executable() {
    log_info "Tornando scripts executáveis..."
    
    find "$SCRIPT_DIR" -name "*.sh" -exec chmod +x {} \;
    log_success "Scripts tornados executáveis"
}

# Validar arquivos Docker Compose
validate_compose_files() {
    log_info "Validando arquivos Docker Compose..."
    
    cd "$PROJECT_ROOT"
    
    # Validar docker-compose.yml
    if docker-compose -f docker-compose.yml config > /dev/null 2>&1; then
        log_success "docker-compose.yml válido"
    else
        log_error "docker-compose.yml inválido!"
        exit 1
    fi
    
    # Validar docker-compose.dev.yml
    if docker-compose -f docker-compose.dev.yml config > /dev/null 2>&1; then
        log_success "docker-compose.dev.yml válido"
    else
        log_error "docker-compose.dev.yml inválido!"
        exit 1
    fi
    
    # Validar docker-compose.test.yml
    if docker-compose -f docker-compose.test.yml config > /dev/null 2>&1; then
        log_success "docker-compose.test.yml válido"
    else
        log_error "docker-compose.test.yml inválido!"
        exit 1
    fi
}

# Baixar imagens base
pull_base_images() {
    log_info "Baixando imagens base..."
    
    images=(
        "postgres:15-alpine"
        "redis:7-alpine"
        "confluentinc/cp-kafka:latest"
        "confluentinc/cp-zookeeper:latest"
        "docker.elastic.co/elasticsearch/elasticsearch:8.11.0"
        "docker.elastic.co/kibana/kibana:8.11.0"
        "prom/prometheus:latest"
        "grafana/grafana:latest"
        "openzipkin/zipkin:latest"
        "mailhog/mailhog:latest"
        "adminer:latest"
    )
    
    for image in "${images[@]}"; do
        log_info "Baixando $image..."
        docker pull "$image"
    done
    
    log_success "Todas as imagens base foram baixadas!"
}

# Configurar redes Docker
setup_networks() {
    log_info "Configurando redes Docker..."
    
    # Criar rede principal se não existir
    if ! docker network ls | grep -q "comprae-network"; then
        docker network create comprae-network
        log_success "Rede comprae-network criada"
    else
        log_warning "Rede comprae-network já existe"
    fi
    
    # Criar rede de desenvolvimento se não existir
    if ! docker network ls | grep -q "comprae-dev-network"; then
        docker network create comprae-dev-network
        log_success "Rede comprae-dev-network criada"
    else
        log_warning "Rede comprae-dev-network já existe"
    fi
}

# Teste básico do ambiente
test_environment() {
    log_info "Testando ambiente básico..."
    
    cd "$PROJECT_ROOT"
    
    # Iniciar apenas os serviços de infraestrutura para teste
    log_info "Iniciando serviços de infraestrutura para teste..."
    docker-compose up -d postgres redis zookeeper kafka
    
    # Aguardar serviços ficarem prontos
    log_info "Aguardando serviços ficarem prontos..."
    sleep 30
    
    # Verificar se serviços estão funcionando
    if docker-compose exec -T postgres pg_isready -U comprae_user > /dev/null 2>&1; then
        log_success "PostgreSQL está funcionando"
    else
        log_error "PostgreSQL não está funcionando!"
    fi
    
    if docker-compose exec -T redis redis-cli ping | grep -q "PONG"; then
        log_success "Redis está funcionando"
    else
        log_error "Redis não está funcionando!"
    fi
    
    # Parar serviços de teste
    log_info "Parando serviços de teste..."
    docker-compose down
}

# Menu interativo
show_menu() {
    echo ""
    echo "=================================="
    echo "  COMPRAE INFRASTRUCTURE SETUP"
    echo "=================================="
    echo ""
    echo "Escolha uma opção:"
    echo "1) Setup completo (recomendado)"
    echo "2) Verificar pré-requisitos apenas"
    echo "3) Configurar ambiente apenas"
    echo "4) Baixar imagens apenas"
    echo "5) Testar ambiente"
    echo "6) Sair"
    echo ""
    read -p "Digite sua opção [1-6]: " choice
}

# Função principal
main() {
    case $1 in
        --full)
            check_prerequisites
            setup_environment
            create_directories
            make_scripts_executable
            validate_compose_files
            setup_networks
            pull_base_images
            test_environment
            ;;
        --check)
            check_prerequisites
            ;;
        --env)
            setup_environment
            ;;
        --images)
            pull_base_images
            ;;
        --test)
            test_environment
            ;;
        *)
            show_menu
            case $choice in
                1)
                    log_info "Executando setup completo..."
                    check_prerequisites
                    setup_environment
                    create_directories
                    make_scripts_executable
                    validate_compose_files
                    setup_networks
                    pull_base_images
                    test_environment
                    log_success "Setup completo finalizado!"
                    ;;
                2)
                    check_prerequisites
                    ;;
                3)
                    setup_environment
                    create_directories
                    make_scripts_executable
                    ;;
                4)
                    pull_base_images
                    ;;
                5)
                    test_environment
                    ;;
                6)
                    log_info "Saindo..."
                    exit 0
                    ;;
                *)
                    log_error "Opção inválida!"
                    exit 1
                    ;;
            esac
            ;;
    esac
    
    echo ""
    log_success "Setup concluído!"
    echo ""
    echo "Próximos passos:"
    echo "1. Edite o arquivo .env se necessário"
    echo "2. Execute: ./scripts/manage.ps1 dev (para desenvolvimento)"
    echo "3. Execute: ./scripts/manage.ps1 start (para produção)"
    echo "4. Acesse: http://localhost:8080 (API Gateway)"
    echo ""
}

# Executar função principal
main "$@"
