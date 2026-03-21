FROM node:20-bookworm-slim

WORKDIR /app

# Instala dependências do sistema
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3 make g++ curl git ca-certificates jq && \
    rm -rf /var/lib/apt/lists/*

# Copia package.json e instala dependências
COPY package*.json ./
RUN npm install

# Copia o resto do projeto
COPY . .

# Faz o build
RUN npm run build

# Expõe a porta
EXPOSE 3000

# Inicia o servidor
CMD ["npm", "run", "start"]
