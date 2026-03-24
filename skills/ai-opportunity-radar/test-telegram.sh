#!/bin/bash
#
# AI Opportunity Radar - Telegram Test Script
# Testa a conexão com o Telegram com credenciais fornecidas
#
# Uso:
#   ./test-telegram.sh                    # Usa variáveis de ambiente
#   ./test-telegram.sh <bot_token> <chat_id>  # Usa credenciais fornecidas
#

set +e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   TESTE DE CONEXÃO TELEGRAM - RADAR IA${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Obter credenciais
if [ -n "$1" ] && [ -n "$2" ]; then
    BOT_TOKEN="$1"
    CHAT_ID="$2"
    echo -e "${YELLOW}Usando credenciais fornecidas via argumentos${NC}"
else
    BOT_TOKEN="${RADAR_TELEGRAM_BOT_TOKEN:-}"
    CHAT_ID="${RADAR_TELEGRAM_CHAT_ID:-}"
    echo -e "${YELLOW}Usando variáveis de ambiente${NC}"
fi

echo ""

# Validar credenciais
if [ -z "$BOT_TOKEN" ]; then
    echo -e "${RED}✗ BOT_TOKEN não fornecido${NC}"
    echo ""
    echo "Uso:"
    echo "  export RADAR_TELEGRAM_BOT_TOKEN=<token>"
    echo "  $0"
    echo ""
    echo "Ou:"
    echo "  $0 <bot_token> <chat_id>"
    exit 1
fi

if [ -z "$CHAT_ID" ]; then
    echo -e "${RED}✗ CHAT_ID não fornecido${NC}"
    exit 1
fi

echo -e "Bot Token: ${BOT_TOKEN:0:15}..."
echo -e "Chat ID: $CHAT_ID"
echo ""

# 1. Verificar se o bot é válido
echo -e "${YELLOW}[1/3] Verificando bot...${NC}"
BOT_INFO=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getMe")

if echo "$BOT_INFO" | jq -e '.ok' > /dev/null 2>&1; then
    BOT_NAME=$(echo "$BOT_INFO" | jq -r '.result.first_name')
    BOT_USERNAME=$(echo "$BOT_INFO" | jq -r '.result.username')
    echo -e "${GREEN}✓ Bot válido: $BOT_NAME (@$BOT_USERNAME)${NC}"
else
    ERROR=$(echo "$BOT_INFO" | jq -r '.description // .error_code // "Unknown error"')
    echo -e "${RED}✗ Token inválido${NC}"
    echo -e "  Erro: $ERROR"
    exit 1
fi

# 2. Verificar se o chat é acessível
echo ""
echo -e "${YELLOW}[2/3] Verificando chat...${NC}"
CHAT_INFO=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getChat?chat_id=${CHAT_ID}")

if echo "$CHAT_INFO" | jq -e '.ok' > /dev/null 2>&1; then
    CHAT_TYPE=$(echo "$CHAT_INFO" | jq -r '.result.type')
    if [ "$CHAT_TYPE" = "private" ]; then
        FIRST_NAME=$(echo "$CHAT_INFO" | jq -r '.result.first_name // "Unknown"')
        echo -e "${GREEN}✓ Chat acessível: $FIRST_NAME ($CHAT_TYPE)${NC}"
    else
        CHAT_TITLE=$(echo "$CHAT_INFO" | jq -r '.result.title // "Unknown"')
        echo -e "${GREEN}✓ Chat acessível: $CHAT_TITLE ($CHAT_TYPE)${NC}"
    fi
else
    ERROR=$(echo "$CHAT_INFO" | jq -r '.description // "Unknown error"')
    echo -e "${RED}✗ Chat não encontrado${NC}"
    echo -e "  Erro: $ERROR"
    echo ""
    echo -e "${YELLOW}Solução:${NC}"
    echo "  1. Abra o Telegram"
    echo "  2. Procure por @$BOT_USERNAME"
    echo "  3. Clique em 'Start' para iniciar uma conversa"
    echo "  4. Descubra seu chat_id correto usando @userinfobot"
    exit 1
fi

# 3. Enviar mensagem de teste
echo ""
echo -e "${YELLOW}[3/3] Enviando mensagem de teste...${NC}"

TEST_MESSAGE="🤖 Radar IA Brasil - Teste de Conexão

✅ Conexão estabelecida com sucesso!
📅 $(date '+%d/%m/%Y às %H:%M:%S')

Se você recebeu esta mensagem, o radar está configurado corretamente."

RESPONSE=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -H "Content-Type: application/json" \
    -d "{\"chat_id\": \"${CHAT_ID}\", \"text\": $(echo "$TEST_MESSAGE" | jq -Rs .), \"parse_mode\": \"HTML\", \"disable_web_page_preview\": true}")

if echo "$RESPONSE" | jq -e '.ok' > /dev/null 2>&1; then
    MESSAGE_ID=$(echo "$RESPONSE" | jq -r '.result.message_id')
    echo -e "${GREEN}✓ Mensagem enviada com sucesso! (ID: $MESSAGE_ID)${NC}"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}   TUDO CONFIGURADO CORRETAMENTE!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
else
    ERROR=$(echo "$RESPONSE" | jq -r '.description // "Unknown error"')
    echo -e "${RED}✗ Falha ao enviar mensagem${NC}"
    echo -e "  Erro: $ERROR"
    exit 1
fi

exit 0
