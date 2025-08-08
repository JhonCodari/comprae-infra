# Configuração do CI/CD Pipeline - GitHub Actions

## ⚠️ Configurações Necessárias no GitHub

Para que o pipeline CI/CD funcione corretamente, você precisa configurar alguns **secrets** e **environments** no seu repositório GitHub.

### 🔐 **1. Configurar Secrets do Repositório**

Vá em: **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

#### Secrets Necessários:

| Nome | Descrição | Exemplo |
|------|-----------|---------|
| `DOCKER_USERNAME` | Usuário do Docker Hub | `jonatassilvadev` |
| `DOCKER_PASSWORD` | Token de acesso do Docker Hub | `dckr_pat_xxxxxxxxxxxxx` |
| `SLACK_WEBHOOK_URL` | URL do webhook do Slack (opcional) | `https://hooks.slack.com/services/...` |

#### Como obter o Docker Hub Token:
1. Acesse [Docker Hub](https://hub.docker.com)
2. Vá em **Account Settings** → **Security** → **New Access Token**
3. Crie um token com permissões de `Read, Write, Delete`
4. Use esse token como `DOCKER_PASSWORD`

### 🌍 **2. Configurar Environments**

Vá em: **Settings** → **Environments** → **New environment**

#### Environments para criar:

1. **staging**
   - Nome: `staging`
   - URL: `https://staging.comprae.com` (ou sua URL de staging)
   - Protection rules: Opcional (pode configurar aprovações)

2. **production**
   - Nome: `production`
   - URL: `https://comprae.com` (ou sua URL de produção)
   - Protection rules: **Recomendado** (exigir aprovação manual)

### 📝 **3. Habilitar Environments no CI/CD**

Após criar os environments no GitHub, descomente as linhas no arquivo `ci-cd.yml`:

```yaml
# De:
# environment:
#   name: staging
#   url: https://staging.comprae.com

# Para:
environment:
  name: staging
  url: https://staging.comprae.com
```

### 🔔 **4. Configurar Notificação Slack (Opcional)**

Se quiser receber notificações no Slack:

1. Crie um **Incoming Webhook** no seu workspace Slack
2. Adicione a URL como secret `SLACK_WEBHOOK_URL`
3. Descomente a seção de notificação no `ci-cd.yml`

### ✅ **5. Verificar Configuração**

Após configurar tudo:

1. Faça um push para a branch `develop` ou `main`
2. Verifique na aba **Actions** se o pipeline está executando
3. Os primeiros deploys podem falhar até você configurar a infraestrutura real

---

## 🚀 **Fluxo do Pipeline**

### Branch `develop`:
1. **Validação** → **Testes** → **Segurança** → **Build** → **Deploy Staging**

### Branch `main`:
1. **Validação** → **Testes** → **Segurança** → **Build** → **Deploy Production**

### Pull Requests:
1. **Validação** → **Testes** → **Segurança**

---

## 🛠️ **Troubleshooting**

### Erro: "Context access might be invalid"
- **Causa**: Secret não configurado no GitHub
- **Solução**: Configurar o secret correspondente nas configurações do repositório

### Erro: "Value 'staging' is not valid"
- **Causa**: Environment não criado no GitHub
- **Solução**: Criar o environment nas configurações ou comentar a linha `environment:`

### Erro: "No such file or directory ../comprae-*"
- **Causa**: Repositórios dos microserviços não estão na estrutura esperada
- **Solução**: Ajustar os caminhos no job `build` ou organizar os repositórios conforme esperado

---

## 📁 **Estrutura Esperada dos Repositórios**

```
projeto-comprae/
├── comprae-infra/           # Este repositório
├── comprae-config-server/   # Repositório do Config Server
├── comprae-eureka-server/   # Repositório do Eureka
├── comprae-api-gateway/     # Repositório do API Gateway
├── comprae-user-service/    # Repositório do User Service
├── comprae-produto-service/ # Repositório do Product Service
├── comprae-order-service/   # Repositório do Order Service
├── comprae-payment-service/ # Repositório do Payment Service
└── comprae-notification-service/ # Repositório do Notification Service
```

Se sua estrutura for diferente, ajuste os caminhos no job `build` do arquivo `ci-cd.yml`.
