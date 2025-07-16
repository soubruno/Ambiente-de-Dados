#!/bin/bash
set -e

# Configurações padrão
LOG_DIR="/var/lib/pgbadger/log"
OUTPUT_DIR="/var/lib/pgbadger/outdir"
OUTPUT_FILE="$OUTPUT_DIR/postgresql.html"

# Criar diretórios se não existirem
mkdir -p "$LOG_DIR" "$OUTPUT_DIR"

echo "Iniciando pgBadger..."
echo "Diretório de logs: $LOG_DIR"
echo "Diretório de saída: $OUTPUT_DIR"

# Função para processar logs
process_logs() {
    # Procurar especificamente pelo log do PostgreSQL
    POSTGRES_LOG="$LOG_DIR/postgresql-postgres.log"
    
    if [ -f "$POSTGRES_LOG" ] && [ -s "$POSTGRES_LOG" ]; then
        echo "Processando log do PostgreSQL: $POSTGRES_LOG"
        echo "Tamanho do arquivo: $(stat -c%s "$POSTGRES_LOG") bytes"
        
        # Processar com formato stderr (usando opções que funcionaram no teste)
        pgbadger -v \
                 -f stderr \
                 --sample 5 \
                 -o "$OUTPUT_FILE" \
                 "$POSTGRES_LOG"
        
        if [ $? -eq 0 ]; then
            echo "Relatório gerado com sucesso em: $OUTPUT_FILE"
        else
            echo "Erro ao processar log. Verificando conteúdo..."
            echo "Primeiras 10 linhas do log:"
            head -10 "$POSTGRES_LOG"
        fi
    else
        echo "Log do PostgreSQL não encontrado ou vazio: $POSTGRES_LOG"
        echo "Arquivos disponíveis em $LOG_DIR:"
        ls -la "$LOG_DIR/" || echo "Diretório vazio ou inacessível"
        echo "Aguardando logs..."
    fi
}

# Processar logs inicialmente
process_logs

# Servidor web simples para servir o relatório
if command -v python3 &> /dev/null; then
    cd "$OUTPUT_DIR"
    echo "Iniciando servidor web na porta 5000..."
    python3 -m http.server 5000
else
    echo "Python3 não encontrado. Mantendo container em execução..."
    tail -f /dev/null
fi

