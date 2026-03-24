#!/bin/bash
#
# AI Opportunity Radar - Find Chat ID
# Ajuda a descobrir o chat_id correto do Telegram
#
# Uso:
#   ./find-chat-id.sh                    # Usa RADAR_TELEGRAM_BOT_TOKEN
#   ./find-chat-id.sh <bot_token>        # Usa token fornecido
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
echo -e "${BLUE}   DESCobRIR CHAT ID DO TELEGRAM${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Obter token
if [ -n "$1" ]; then
    BOT_TOKEN="$1"
else
    BOT_TOKEN="${RADAR_TELEGRAM_BOT_TOKEN:-}"
fi

if [ -z "$BOT_TOKEN" ]; then
    echo -e "${RED}✗ BOT_TOKEN não fornecido${NC}"
    echo ""
    echo "Uso:"
    echo "  export RADAR_TELEGRAM_BOT_TOKEN=<token>"
    echo "  $0"
    echo ""
    echo "Ou:"
    echo "  $0 <bot_token>"
    exit 1
fi

# Verificar se o bot é válido
echo -e "${YELLOW}Verificando bot...${NC}"
BOT_INFO=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getMe")

if echo "$BOT_INFO" | jq -e '.ok' > /dev/null 2>&1; then
    BOT_NAME=$(echo "$BOT_INFO" | jq -r '.result.first_name')
    BOT_USERNAME=$(echo "$BOT_INFO" | jq -r '.result.username')
    echo -e "${GREEN}✓ Bot: $BOT_NAME (@$BOT_USERNAME)${NC}"
else
    echo -e "${RED}✗ Token inválido${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}   INSTRUÇÕES PARA DESCOBRIR SEU CHAT ID${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}MÉTODO 1: Interagir com o bot${NC}"
echo ""
echo "  1. Abra o Telegram no seu celular ou desktop"
echo "  2. Procure por ${GREEN}@$BOT_USERNAME${NC}"
echo "  3. Clique no bot e depois em ${GREEN}'Start'${NC}"
echo "  4. Envie qualquer mensagem para o bot"
echo "  5. Execute este script novamente"
echo ""
echo -e "${YELLOW}MÉTODO 2: Usar @userinfobot${NC}"
echo ""
echo "  1. No Telegram, procure por ${GREEN}@userinfobot${NC}"
echo "  2. Clique em 'Start'"
echo "  3. Ele vai responder com seu ID (um número como 123456789)"
echo "  4. Use esse número como CHAT_ID"
echo ""
echo -e "${YELLOW}MÉTODO 3: URL direta${NC}"
echo ""
echo "  Acesse esta URL no navegador (substitua <TOKEN>):"
echo "  ${CYAN}https://api.telegram.org/bot<TOKEN>/getUpdates${NC}"
echo ""
echo "  Depois de enviar uma mensagem ao bot, procure por:"
echo "  ${GREEN}\"chat\":{\"id\":SEU_CHAT_ID${NC}"
echo ""

# Verificar se há updates
echo -e "${YELLOW}Verificando mensagens recentes...${NC}"
UPDATES=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates")

if echo "$UPDATES" | jq -e '.result | length > 0' > /dev/null 2>&1; then
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}   CHAT IDs ENCONTRADOS${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Extrair chats únicos
    echo "$UPDATES" | jq -r '.result[] | .message.chat | "  \(.id) - \(.first_name // .title // "Unknown") (\(.type))"' | sort -u
    
    echo ""
    echo -e "${CYAN}Configure o CHAT_ID correto:${NC}"
    echo "  export RADAR_TELEGRAM_CHAT_ID=<seu_chat_id>"
    echo ""
    echo -e "${CYAN}Ou adicione aos secrets do GitHub:${NC}"
    echo "  AGENT_LLM_RADAR_TELEGRAM_CHAT_ID=<seu_chat_id>"
else
    echo -e "${YELLOW}Nenhuma mensagem encontrada.${NC}"
    echo ""
    echo "Siga as instruções acima para descobrir seu chat_id."
fi

echo ""
exit 0
