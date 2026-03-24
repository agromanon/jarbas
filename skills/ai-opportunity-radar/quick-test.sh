#!/bin/bash
#
# Quick Test - AI Opportunity Radar
# Teste rápido para verificar se o Telegram está configurado corretamente
#
# Uso:
#   ./quick-test.sh                    # Usa variáveis de ambiente
#   ./quick-test.sh <bot_token> <chat_id>  # Usa credenciais fornecidas
#

set +e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   TESTE RÁPIDO - RADAR IA BRASIL${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Obter credenciais
if [ -n "$1" ] && [ -n "$2" ]; then
    BOT_TOKEN="$1"
    CHAT_ID="$2"
else
    BOT_TOKEN="${RADAR_TELEGRAM_BOT_TOKEN:-${TELEGRAM_BOT_TOKEN:-}}"
    CHAT_ID="${RADAR_TELEGRAM_CHAT_ID:-${TELEGRAM_CHAT_ID:-}}"
fi

# Verificar se credenciais existem
if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
    echo -e "${RED}✗ Credenciais não fornecidas${NC}"
    echo ""
    echo "Configure as variáveis de ambiente:"
    echo "  export RADAR_TELEGRAM_BOT_TOKEN=<seu-token>"
    echo "  export RADAR_TELEGRAM_CHAT_ID=<seu-chat-id>"
    echo ""
    echo "Ou passe como argumentos:"
    echo "  $0 <bot_token> <chat_id>"
    exit 1
fi

echo -e "${YELLOW}Testando conexão...${NC}"
echo ""

# Teste 1: Verificar bot
BOT_INFO=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getMe")

if ! echo "$BOT_INFO" | jq -e '.ok' > /dev/null 2>&1; then
    echo -e "${RED}✗ Bot token inválido${NC}"
    exit 1
fi

BOT_NAME=$(echo "$BOT_INFO" | jq -r '.result.first_name')
BOT_USERNAME=$(echo "$BOT_INFO" | jq -r '.result.username')
echo -e "${GREEN}✓ Bot: $BOT_NAME (@$BOT_USERNAME)${NC}"

# Teste 2: Verificar chat
CHAT_INFO=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getChat?chat_id=${CHAT_ID}")

if ! echo "$CHAT_INFO" | jq -e '.ok' > /dev/null 2>&1; then
    ERROR=$(echo "$CHAT_INFO" | jq -r '.description // "Unknown error"')
    echo -e "${RED}✗ Chat não autorizado: $ERROR${NC}"
    echo ""
    echo -e "${YELLOW}Para resolver:${NC}"
    echo "  1. Abra o Telegram"
    echo "  2. Procure por @$BOT_USERNAME"
    echo "  3. Clique em 'Start'"
    echo "  4. Use @userinfobot para descobrir seu chat_id"
    exit 1
fi

CHAT_TYPE=$(echo "$CHAT_INFO" | jq -r '.result.type')
echo -e "${GREEN}✓ Chat autorizado ($CHAT_TYPE)${NC}"

# Teste 3: Enviar mensagem
TEST_MSG="✅ Radar IA Brasil - Teste OK

📅 $(date '+%d/%m/%Y às %H:%M:%S')
🤖 Bot: $BOT_NAME
💬 Chat: $CHAT_ID

Tudo configurado corretamente!"

RESPONSE=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -H "Content-Type: application/json" \
    -d "{\"chat_id\": \"${CHAT_ID}\", \"text\": $(echo "$TEST_MSG" | jq -Rs .), \"parse_mode\": \"HTML\"}")

if echo "$RESPONSE" | jq -e '.ok' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Mensagem enviada com sucesso!${NC}"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}   ✅ TUDO FUNCIONANDO!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Verifique seu Telegram para confirmar o recebimento."
else
    ERROR=$(echo "$RESPONSE" | jq -r '.description // "Unknown error"')
    echo -e "${RED}✗ Erro ao enviar: $ERROR${NC}"
    exit 1
fi

exit 0
