#!/bin/bash
#
# AI Opportunity Radar - Verificação de Configuração
# Verifica se todas as variáveis necessárias estão configuradas
#

set +e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   VERIFICAÇÃO DE CONFIGURAÇÃO - AI OPPORTUNITY RADAR${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Verificar variáveis de ambiente
echo -e "${YELLOW}[1/4] Verificando variáveis de ambiente...${NC}"
echo ""

BOT_TOKEN="${RADAR_TELEGRAM_BOT_TOKEN:-${TELEGRAM_BOT_TOKEN:-}}"
CHAT_ID="${RADAR_TELEGRAM_CHAT_ID:-${TELEGRAM_CHAT_ID:-}}"

if [ -n "$BOT_TOKEN" ]; then
    echo -e "  ${GREEN}✓ RADAR_TELEGRAM_BOT_TOKEN configurada${NC}"
    echo -e "    Token: ${BOT_TOKEN:0:10}..."
else
    echo -e "  ${RED}✗ RADAR_TELEGRAM_BOT_TOKEN não configurada${NC}"
fi

if [ -n "$CHAT_ID" ]; then
    echo -e "  ${GREEN}✓ RADAR_TELEGRAM_CHAT_ID configurada${NC}"
    echo -e "    Chat ID: $CHAT_ID"
else
    echo -e "  ${RED}✗ RADAR_TELEGRAM_CHAT_ID não configurada${NC}"
fi

echo ""

# Verificar se o bot está acessível
echo -e "${YELLOW}[2/4] Verificando conexão com bot...${NC}"
echo ""

if [ -n "$BOT_TOKEN" ]; then
    BOT_INFO=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getMe")
    
    if echo "$BOT_INFO" | jq -e '.ok' > /dev/null 2>&1; then
        BOT_NAME=$(echo "$BOT_INFO" | jq -r '.result.first_name')
        BOT_USERNAME=$(echo "$BOT_INFO" | jq -r '.result.username')
        echo -e "  ${GREEN}✓ Bot acessível${NC}"
        echo -e "    Nome: $BOT_NAME"
        echo -e "    Username: @$BOT_USERNAME"
    else
        echo -e "  ${RED}✗ Bot inacessível ou token inválido${NC}"
    fi
else
    echo -e "  ${YELLOW}⊘ Skipped (token não configurado)${NC}"
fi

echo ""

# Verificar se pode enviar mensagem
echo -e "${YELLOW}[3/4] Verificando permissão de envio...${NC}"
echo ""

if [ -n "$BOT_TOKEN" ] && [ -n "$CHAT_ID" ]; then
    TEST_RESPONSE=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" \
        -d "text=🔍 Verificação de configuração do Radar IA" \
        -d "parse_mode=HTML")
    
    if echo "$TEST_RESPONSE" | jq -e '.ok' > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Mensagem de teste enviada com sucesso${NC}"
        echo -e "    Verifique seu Telegram para confirmar recebimento"
    else
        ERROR=$(echo "$TEST_RESPONSE" | jq -r '.description // "Erro desconhecido"')
        echo -e "  ${RED}✗ Falha ao enviar mensagem${NC}"
        echo -e "    Erro: $ERROR"
        
        if echo "$ERROR" | grep -q "chat not found"; then
            echo ""
            echo -e "  ${CYAN}Solução:${NC}"
            echo -e "    1. Abra o Telegram"
            echo -e "    2. Procure por @Radariabr_bot"
            echo -e "    3. Clique em 'Start' para iniciar uma conversa"
        fi
    fi
else
    echo -e "  ${YELLOW}⊘ Skipped (variáveis não configuradas)${NC}"
fi

echo ""

# Verificar dependências
echo -e "${YELLOW}[4/4] Verificando dependências...${NC}"
echo ""

DEPS_OK=true

if command -v curl &> /dev/null; then
    echo -e "  ${GREEN}✓ curl instalado${NC}"
else
    echo -e "  ${RED}✗ curl não encontrado${NC}"
    DEPS_OK=false
fi

if command -v jq &> /dev/null; then
    echo -e "  ${GREEN}✓ jq instalado${NC}"
else
    echo -e "  ${RED}✗ jq não encontrado${NC}"
    DEPS_OK=false
fi

if command -v grep &> /dev/null; then
    echo -e "  ${GREEN}✓ grep instalado${NC}"
else
    echo -e "  ${RED}✗ grep não encontrado${NC}"
    DEPS_OK=false
fi

echo ""

# Resumo
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   RESUMO${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ -n "$BOT_TOKEN" ] && [ -n "$CHAT_ID" ]; then
    echo -e "${GREEN}✓ Configuração completa${NC}"
    echo ""
    echo "O radar está pronto para uso!"
    echo ""
    echo "Para testar:"
    echo "  bash skills/ai-opportunity-radar/radar.sh"
else
    echo -e "${RED}✗ Configuração incompleta${NC}"
    echo ""
    echo -e "${CYAN}Para configurar, adicione os seguintes GitHub Secrets:${NC}"
    echo ""
    echo "  AGENT_LLM_RADAR_TELEGRAM_BOT_TOKEN=8470965695:AAHOOrl_o0K8bWHgT9ZyQt53eSjeKgZEZMM"
    echo "  AGENT_LLM_RADAR_TELEGRAM_CHAT_ID=5121600266"
    echo ""
    echo "Consulte skills/ai-opportunity-radar/SETUP.md para instruções detalhadas."
fi

echo ""
exit 0
