#!/bin/bash
#
# AI Opportunity Radar - Diagnostic Tool
# Ajuda a identificar problemas de configuração
#

set +e  # Não parar em erros

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   AI OPPORTUNITY RADAR - DIAGNÓSTICO${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 1. Verificar variáveis de ambiente
echo -e "${YELLOW}[1/5] Verificando variáveis de ambiente...${NC}"
echo ""

MISSING_VARS=()

if [ -z "$RADAR_TELEGRAM_BOT_TOKEN" ]; then
    echo -e "  ${RED}✗ RADAR_TELEGRAM_BOT_TOKEN não definida${NC}"
    MISSING_VARS+=("RADAR_TELEGRAM_BOT_TOKEN")
else
    echo -e "  ${GREEN}✓ RADAR_TELEGRAM_BOT_TOKEN definida${NC}"
    echo -e "    Valor: ${RADAR_TELEGRAM_BOT_TOKEN:0:15}..."
fi

if [ -z "$RADAR_TELEGRAM_CHAT_ID" ]; then
    echo -e "  ${RED}✗ RADAR_TELEGRAM_CHAT_ID não definida${NC}"
    MISSING_VARS+=("RADAR_TELEGRAM_CHAT_ID")
else
    echo -e "  ${GREEN}✓ RADAR_TELEGRAM_CHAT_ID definida${NC}"
    echo -e "    Valor: $RADAR_TELEGRAM_CHAT_ID"
fi

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠ Variáveis faltando! Configure nos secrets do GitHub:${NC}"
    echo -e "  AGENT_LLM_RADAR_TELEGRAM_BOT_TOKEN=<seu-token>"
    echo -e "  AGENT_LLM_RADAR_TELEGRAM_CHAT_ID=<seu-chat-id>"
    echo ""
fi

# 2. Verificar se o bot token é válido
echo ""
echo -e "${YELLOW}[2/5] Verificando token do bot...${NC}"
echo ""

if [ -n "$RADAR_TELEGRAM_BOT_TOKEN" ]; then
    BOT_INFO=$(curl -s "https://api.telegram.org/bot${RADAR_TELEGRAM_BOT_TOKEN}/getMe")
    
    if echo "$BOT_INFO" | jq -e '.ok' > /dev/null 2>&1; then
        BOT_NAME=$(echo "$BOT_INFO" | jq -r '.result.first_name')
        BOT_USERNAME=$(echo "$BOT_INFO" | jq -r '.result.username')
        echo -e "  ${GREEN}✓ Bot válido${NC}"
        echo -e "    Nome: $BOT_NAME"
        echo -e "    Username: @$BOT_USERNAME"
    else
        ERROR=$(echo "$BOT_INFO" | jq -r '.description // .error_code')
        echo -e "  ${RED}✗ Token inválido${NC}"
        echo -e "    Erro: $ERROR"
    fi
else
    echo -e "  ${RED}✗ Token não disponível para teste${NC}"
fi

# 3. Verificar se o chat_id é acessível
echo ""
echo -e "${YELLOW}[3/5] Verificando acesso ao chat...${NC}"
echo ""

if [ -n "$RADAR_TELEGRAM_BOT_TOKEN" ] && [ -n "$RADAR_TELEGRAM_CHAT_ID" ]; then
    CHAT_INFO=$(curl -s "https://api.telegram.org/bot${RADAR_TELEGRAM_BOT_TOKEN}/getChat?chat_id=${RADAR_TELEGRAM_CHAT_ID}")
    
    if echo "$CHAT_INFO" | jq -e '.ok' > /dev/null 2>&1; then
        CHAT_TYPE=$(echo "$CHAT_INFO" | jq -r '.result.type')
        echo -e "  ${GREEN}✓ Chat acessível${NC}"
        echo -e "    Tipo: $CHAT_TYPE"
    else
        ERROR=$(echo "$CHAT_INFO" | jq -r '.description')
        echo -e "  ${RED}✗ Chat não encontrado${NC}"
        echo -e "    Erro: $ERROR"
        echo ""
        echo -e "${YELLOW}Para resolver:${NC}"
        echo "  1. Abra o Telegram"
        echo "  2. Procure pelo bot (use o username mostrado acima)"
        echo "  3. Clique em 'Start' para iniciar uma conversa"
        echo "  4. Execute este script novamente para descobrir o chat_id correto"
    fi
else
    echo -e "  ${RED}✗ Variáveis não disponíveis para teste${NC}"
fi

# 4. Verificar dependências
echo ""
echo -e "${YELLOW}[4/5] Verificando dependências...${NC}"
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

# 5. Verificar estrutura de arquivos
echo ""
echo -e "${YELLOW}[5/5] Verificando estrutura de arquivos...${NC}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/radar.sh" ]; then
    echo -e "  ${GREEN}✓ radar.sh encontrado${NC}"
else
    echo -e "  ${RED}✗ radar.sh não encontrado${NC}"
fi

if [ -f "$SCRIPT_DIR/analyze.sh" ]; then
    echo -e "  ${GREEN}✓ analyze.sh encontrado${NC}"
else
    echo -e "  ${RED}✗ analyze.sh não encontrado${NC}"
fi

if [ -f "$SCRIPT_DIR/telegram.sh" ]; then
    echo -e "  ${GREEN}✓ telegram.sh encontrado${NC}"
else
    echo -e "  ${RED}✗ telegram.sh não encontrado${NC}"
fi

if [ -d "$SCRIPT_DIR/sources" ]; then
    SOURCE_COUNT=$(ls -1 "$SCRIPT_DIR/sources"/*.sh 2>/dev/null | wc -l)
    echo -e "  ${GREEN}✓ sources/ encontrado ($SOURCE_COUNT scripts)${NC}"
else
    echo -e "  ${RED}✗ sources/ não encontrado${NC}"
fi

# Resumo
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   RESUMO${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ ${#MISSING_VARS[@]} -eq 0 ] && [ -n "$RADAR_TELEGRAM_BOT_TOKEN" ] && [ -n "$RADAR_TELEGRAM_CHAT_ID" ]; then
    # Tentar enviar mensagem de teste
    echo -e "${YELLOW}Tentando enviar mensagem de teste...${NC}"
    
    TEST_RESPONSE=$(curl -s "https://api.telegram.org/bot${RADAR_TELEGRAM_BOT_TOKEN}/sendMessage" \
        -H "Content-Type: application/json" \
        -d "{\"chat_id\": \"${RADAR_TELEGRAM_CHAT_ID}\", \"text\": \"🤖 Radar IA - Teste de diagnóstico OK!\"}")
    
    if echo "$TEST_RESPONSE" | jq -e '.ok' > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Mensagem de teste enviada com sucesso!${NC}"
        echo ""
        echo -e "${GREEN}Tudo configurado corretamente!${NC}"
    else
        ERROR=$(echo "$TEST_RESPONSE" | jq -r '.description')
        echo -e "  ${RED}✗ Falha ao enviar mensagem${NC}"
        echo -e "    Erro: $ERROR"
    fi
else
    echo -e "${YELLOW}Ação necessária:${NC}"
    echo ""
    echo "1. Configure as variáveis de ambiente nos secrets do GitHub:"
    echo "   - AGENT_LLM_RADAR_TELEGRAM_BOT_TOKEN"
    echo "   - AGENT_LLM_RADAR_TELEGRAM_CHAT_ID"
    echo ""
    echo "2. Para descobrir seu chat_id:"
    echo "   a. Abra o Telegram e inicie conversa com o bot"
    echo "   b. Acesse: https://api.telegram.org/bot<TOKEN>/getUpdates"
    echo "   c. Procure por 'chat\":{\"id\":<SEU_CHAT_ID>}"
    echo ""
    echo "3. Ou use o @userinfobot no Telegram para descobrir seu ID"
fi

echo ""
exit 0
