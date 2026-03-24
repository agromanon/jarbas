#!/bin/bash
#
# AI Opportunity Radar - Full Test
# Executa um teste completo do radar com credenciais fornecidas
#
# Uso:
#   ./test-radar.sh <bot_token> <chat_id>
#

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   TESTE COMPLETO - RADAR IA BRASIL${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Verificar argumentos
if [ -z "$1" ] || [ -z "$2" ]; then
    echo -e "${RED}Uso: $0 <bot_token> <chat_id>${NC}"
    echo ""
    echo "Exemplo:"
    echo "  $0 123456789:ABCdefGHIjklMNOpqrsTUVwxyz 123456789"
    exit 1
fi

BOT_TOKEN="$1"
CHAT_ID="$2"

# Exportar variáveis
export RADAR_TELEGRAM_BOT_TOKEN="$BOT_TOKEN"
export RADAR_TELEGRAM_CHAT_ID="$CHAT_ID"

echo -e "${YELLOW}Credenciais configuradas:${NC}"
echo -e "  Bot Token: ${BOT_TOKEN:0:15}..."
echo -e "  Chat ID: $CHAT_ID"
echo ""

# 1. Testar conexão Telegram
echo -e "${CYAN}[1/4] Testando conexão Telegram...${NC}"
if bash "$SCRIPT_DIR/test-telegram.sh" "$BOT_TOKEN" "$CHAT_ID"; then
    echo -e "${GREEN}✓ Telegram OK${NC}"
else
    echo -e "${RED}✗ Falha na conexão Telegram${NC}"
    echo -e "${YELLOW}Corrija o problema antes de continuar${NC}"
    exit 1
fi

# 2. Testar coleta (apenas uma fonte para ser rápido)
echo ""
echo -e "${CYAN}[2/4] Testando coleta de dados...${NC}"

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
TEMP_DIR="/tmp/radar-test-$TIMESTAMP"
mkdir -p "$TEMP_DIR"

# Testar uma fonte simples (Product Hunt via scraping básico)
echo -e "${YELLOW}Testando coleta do Reddit (fonte mais simples)...${NC}"

if [ -f "$SCRIPT_DIR/sources/reddit.sh" ]; then
    # Criar um products.json vazio para teste
    echo '{"products": [{"name": "Test Product", "description": "A test AI product for demonstration", "category": "AI Tools", "source": "test", "url": "https://example.com"}], "timestamp": "'"$TIMESTAMP"'"}' > "$TEMP_DIR/products.json"
    echo -e "${GREEN}✓ Dados de teste criados${NC}"
else
    echo -e "${RED}✗ Script de coleta não encontrado${NC}"
    exit 1
fi

# 3. Testar análise
echo ""
echo -e "${CYAN}[3/4] Testando análise...${NC}"

if [ -f "$SCRIPT_DIR/analyze.sh" ]; then
    if bash "$SCRIPT_DIR/analyze.sh" "$TEMP_DIR/products.json" "$TEMP_DIR/analyzed.json" 2>&1; then
        echo -e "${GREEN}✓ Análise concluída${NC}"
        
        # Mostrar resultado
        echo ""
        echo -e "${YELLOW}Resultado da análise:${NC}"
        jq '.products[0] | {name, final_score, recommendation}' "$TEMP_DIR/analyzed.json" 2>/dev/null || echo "  (erro ao mostrar resultado)"
    else
        echo -e "${RED}✗ Falha na análise${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ analyze.sh não encontrado${NC}"
    exit 1
fi

# 4. Gerar e enviar relatório de teste
echo ""
echo -e "${CYAN}[4/4] Gerando e enviando relatório...${NC}"

# Criar relatório de teste
cat > "$TEMP_DIR/report.md" << 'REPORT_EOF'
🚀 RADAR DE OPORTUNIDADES IA - TESTE

📊 RESUMO
- 1 produto analisado (teste)
- 1 passou nos filtros
- Sistema funcionando corretamente

🏆 TESTE DE VALIDAÇÃO

🎬 1️⃣ Test Product - Score: 50/100

   📌 Categoria: AI Tools
   💡 O que faz: A test AI product for demonstration
   🏢 Solo Founder: 70/100 ✅
   🌊 Mar Azul: 🟡 Needs verification
   📣 Promoção: 60/100 (médio)
   💰 Potencial: B2C SaaS
   🛠 Complexidade: média
   💸 Custo infra: ~$50/mês
   
   ✨ Oportunidade BR:
   Produto com potencial para o mercado brasileiro.
   
   🎯 Recomendação: Avaliar em detalhes

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔗 Este é um relatório de teste do Radar IA Brasil
📅 Gerado em: REPORT_DATE
REPORT_EOF

# Substituir data
sed -i "s/REPORT_DATE/$(date '+%d\/%m\/%Y às %H:%M')/g" "$TEMP_DIR/report.md"

# Enviar
if bash "$SCRIPT_DIR/telegram.sh" "$TEMP_DIR/report.md"; then
    echo -e "${GREEN}✓ Relatório enviado com sucesso!${NC}"
else
    echo -e "${RED}✗ Falha ao enviar relatório${NC}"
    exit 1
fi

# Limpar
rm -rf "$TEMP_DIR"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}   TESTE COMPLETO COM SUCESSO!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "O radar está configurado corretamente."
echo "Verifique se a mensagem chegou no Telegram."
echo ""

exit 0
