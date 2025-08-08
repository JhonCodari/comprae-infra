#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE comprae_usuarios;
    CREATE DATABASE comprae_produtos;
    CREATE DATABASE comprae_categorias;
    CREATE DATABASE comprae_estoque;
    CREATE DATABASE comprae_pedidos;
    CREATE DATABASE comprae_pagamentos;
    CREATE DATABASE comprae_entregas;
    CREATE DATABASE comprae_avaliacoes;
    
    GRANT ALL PRIVILEGES ON DATABASE comprae_usuarios TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE comprae_produtos TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE comprae_categorias TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE comprae_estoque TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE comprae_pedidos TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE comprae_pagamentos TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE comprae_entregas TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE comprae_avaliacoes TO $POSTGRES_USER;
    
    -- Bancos para desenvolvimento
    CREATE DATABASE comprae_usuarios_dev;
    CREATE DATABASE comprae_produtos_dev;
    CREATE DATABASE comprae_categorias_dev;
    CREATE DATABASE comprae_estoque_dev;
    CREATE DATABASE comprae_pedidos_dev;
    CREATE DATABASE comprae_pagamentos_dev;
    CREATE DATABASE comprae_entregas_dev;
    CREATE DATABASE comprae_avaliacoes_dev;
    
    GRANT ALL PRIVILEGES ON DATABASE comprae_usuarios_dev TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE comprae_produtos_dev TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE comprae_categorias_dev TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE comprae_estoque_dev TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE comprae_pedidos_dev TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE comprae_pagamentos_dev TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE comprae_entregas_dev TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE comprae_avaliacoes_dev TO $POSTGRES_USER;
EOSQL
