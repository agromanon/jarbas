# AI Opportunity Radar - Guia de Configuração

## Status: ✅ FUNCIONANDO

O radar foi testado com sucesso em 2026-03-24. A mensagem de teste foi enviada para o Telegram corretamente.

## ⚠️ AÇÃO NECESSÁRIA: Configurar GitHub Secrets

Para que o radar funcione automaticamente (via cron job), você precisa configurar as variáveis de ambiente como **GitHub Secrets**.

### Passo 1: Obter credenciais

Você já tem:
- **Bot Token**: `8470965695:AAHOOrl_o0K8bWHgT9ZyQt53eSjeKgZEZMM`
- **Chat ID**: `5121600266`
- **Bot Username**: `@Radariabr_bot`

### Passo 2: Configurar GitHub Secrets

1. Acesse seu repositório no GitHub
2. Vá em **Settings** → **Secrets and variables** → **Actions**
3. Clique em **New repository secret**
4. Adicione os seguintes secrets:

```
Nome: AGENT_LLM_RADAR_TELEGRAM_BOT_TOKEN
Valor: 8470965695:AAHOOrl_o0K8bWHgT9ZyQt53eSjeKgZEZMM

Nome: AGENT_LLM_RADAR_TELEGRAM_CHAT_ID
Valor: 5121600266
```

### Passo 3: Verificar configuração

Depois de configurar os secrets, execute:

```bash
# Via chat com o agente
"Teste o radar de oportunidades IA"
```

Ou execute manualmente:

```bash
bash skills/ai-opportunity-radar/radar.sh
```

## Como Funciona

1. **Cron Job**: Executa automaticamente às 9h nas segundas e sextas-feiras
2. **Coleta**: Busca produtos de 4 fontes (There's An AI For That, Product Hunt, Reddit, Future Tools)
3. **Análise**: Aplica 9 critérios de scoring (0-100) e filtros eliminatórios
4. **Envio**: Formata relatório TOP 10 e envia via Telegram

## Testes Realizados (2026-03-24)

### ✅ Teste 1: Bot válido
```json
{
  "ok": true,
  "result": {
    "id": 8470965695,
    "first_name": "Radar IA Brasil",
    "username": "Radariabr_bot"
  }
}
```

### ✅ Teste 2: Envio direto
```bash
curl "https://api.telegram.org/bot8470965695:AAHOOrl_o0K8bWHgT9ZyQt53eSjeKgZEZMM/sendMessage?chat_id=5121600266&text=TESTE"
# Resultado: {"ok":true}
```

### ✅ Teste 3: Script da skill
```bash
bash skills/ai-opportunity-radar/telegram.sh /tmp/test-report.md
# Resultado: Message sent successfully
```

## Estrutura de Arquivos

```
skills/ai-opportunity-radar/
├── SKILL.md              # Documentação principal
├── SETUP.md              # Este arquivo
├── radar.sh              # Script principal
├── analyze.sh            # Análise e scoring
├── telegram.sh           # Envio via Telegram
├── diagnose.sh           # Diagnóstico de problemas
├── test-telegram.sh      # Teste de conexão
├── find-chat-id.sh       # Descobrir chat_id
└── sources/              # Scripts de coleta
    ├── theresanaiforthat.sh
    ├── producthunt.sh
    ├── reddit.sh
    └── futuretools.sh
```

## Troubleshooting

### Erro: "chat not found"
**Causa**: O usuário ainda não iniciou o bot
**Solução**: 
1. Abra o Telegram
2. Procure por `@Radariabr_bot`
3. Clique em **Start**

### Erro: "variável não definida"
**Causa**: GitHub Secrets não configurados
**Solução**: Siga os passos acima para configurar os secrets

### Erro: "BOT_TOKEN not set"
**Causa**: Variável de ambiente não disponível
**Solução**: 
- Verifique se os secrets têm o prefixo `AGENT_LLM_`
- Reinicie o container após adicionar os secrets

## Comandos Úteis

```bash
# Diagnóstico completo
bash skills/ai-opportunity-radar/diagnose.sh

# Descobrir chat_id
bash skills/ai-opportunity-radar/find-chat-id.sh

# Testar conexão Telegram
bash skills/ai-opportunity-radar/test-telegram.sh

# Executar radar completo
bash skills/ai-opportunity-radar/radar.sh

# Apenas coletar dados
bash skills/ai-opportunity-radar/radar.sh --collect-only

# Apenas enviar relatório existente
bash skills/ai-opportunity-radar/radar.sh --send-only /path/to/report.md
```

## Próximos Passos

1. ✅ Bot criado e configurado
2. ✅ Skill implementada e testada
3. ⏳ **CONFIGURAR GITHUB SECRETS** (necessário)
4. ⏳ Aguardar próximo cron (segunda/sexta 9h) ou testar manualmente

---

**Última atualização**: 2026-03-24
**Status**: ✅ Funcionando (requer configuração de secrets)
