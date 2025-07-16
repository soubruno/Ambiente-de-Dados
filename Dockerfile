# Baseado na imagem oficial do Node.js
FROM node:20

# Instala pgloader
RUN apt-get update && apt-get install -y pgloader

# Cria a pasta app dentro do container
WORKDIR /app

# Copia os arquivos de configuração do Node.js
COPY package*.json ./

# Instala as dependências do Node.js
RUN npm install

# Copia o restante dos arquivos da aplicação
COPY . .

CMD ["npm", "run", "start"]