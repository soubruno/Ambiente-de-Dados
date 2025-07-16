from airflow.decorators import dag, task
from airflow.operators.bash import BashOperator
from datetime import datetime
import psycopg2
import os

default_args = {
    'owner': 'data_team',
    'start_date': datetime(2024, 1, 1),
    'retries': 1,
}

@dag(
    dag_id='steam_etl_simple',
    default_args=default_args,
    schedule=None,
    catchup=False,
    description='Pipeline ETL completo: copia dados source -> staging -> dimensões -> fatos -> bridges + testes',
    tags=['steam', 'etl', 'dbt', 'star-schema', 'dw-completo']
)
def steam_etl_pipeline():

    @task
    def copy_source_data():
        """Copia dados REAIS do banco source para o schema steam_source no DW"""
        
        import logging
        logger = logging.getLogger(__name__)
        
        source_conn = None
        dw_conn = None
        
        try:
            # Conectar no banco SOURCE
            logger.info("🔌 Conectando ao banco SOURCE...")
            source_conn = psycopg2.connect(
                host=os.getenv('POSTGRES_HOST', 'postgres'),
                database=os.getenv('POSTGRES_DB', 'steam_games'),
                user=os.getenv('POSTGRES_USER', 'postgres'),
                password=os.getenv('POSTGRES_PASSWORD', 'steampassword'),
                port=5432  # Porta interna do container sempre é 5432
            )
            
            # Conectar no banco DESTINO (DW)
            logger.info("🔌 Conectando ao banco DESTINO (DW)...")
            dw_conn = psycopg2.connect(
                host=os.getenv('DW_HOST', 'postgres-dw'),
                database=os.getenv('DW_DB', 'data_warehouse'),
                user=os.getenv('DW_USER', 'dw_user'),
                password=os.getenv('DW_PASSWORD', 'dw_password123'),
                port=5432  # Porta interna do container sempre é 5432
            )
            
            source_cursor = source_conn.cursor()
            dw_cursor = dw_conn.cursor()
            
            # Criar schema steam_source se não existe
            logger.info("🏗️ Criando schema steam_source...")
            dw_cursor.execute("CREATE SCHEMA IF NOT EXISTS steam_source;")
            dw_conn.commit()
            
            # Lista de tabelas para copiar
            tables = [
                'games', 'categories', 'developers', 'genres', 'publishers', 'tags', 
                'languages', 'media', 'game_categories', 'game_developers', 'game_genres',
                'game_publishers', 'game_tags', 'game_full_audio_languages', 'game_supported_languages'
            ]
            
            for table in tables:
                logger.info(f"📊 Copiando tabela {table}...")
                
                try:
                    # 1. Buscar estrutura da tabela no source
                    source_cursor.execute(f"""
                        SELECT column_name, data_type, is_nullable, column_default
                        FROM information_schema.columns 
                        WHERE table_name = '{table}' AND table_schema = 'public'
                        ORDER BY ordinal_position;
                    """)
                    columns_info = source_cursor.fetchall()
                    
                    if not columns_info:
                        logger.warning(f"⚠️ Tabela {table} não encontrada no source, pulando...")
                        continue
                    
                    # 2. Criar DDL da tabela no steam_source
                    create_sql = f"CREATE TABLE IF NOT EXISTS steam_source.{table} ("
                    column_defs = []
                    for col_name, data_type, is_nullable, col_default in columns_info:
                        col_def = f"{col_name} {data_type}"
                        if is_nullable == 'NO':
                            col_def += " NOT NULL"
                        if col_default:
                            col_def += f" DEFAULT {col_default}"
                        column_defs.append(col_def)
                    
                    create_sql += ", ".join(column_defs) + ");"
                    
                    # 3. Dropar e recriar tabela
                    dw_cursor.execute(f"DROP TABLE IF EXISTS steam_source.{table};")
                    dw_cursor.execute(create_sql)
                    
                    # 4. Copiar dados usando fetchall + executemany (para volumes pequenos/médios)
                    source_cursor.execute(f"SELECT * FROM public.{table};")
                    rows = source_cursor.fetchall()
                    
                    if rows:
                        # Preparar INSERT
                        columns = [col[0] for col in columns_info]
                        placeholders = ", ".join(["%s"] * len(columns))
                        insert_sql = f"INSERT INTO steam_source.{table} ({', '.join(columns)}) VALUES ({placeholders})"
                        
                        # Inserir dados em lotes
                        batch_size = 1000
                        for i in range(0, len(rows), batch_size):
                            batch = rows[i:i + batch_size]
                            dw_cursor.executemany(insert_sql, batch)
                        
                        logger.info(f"✅ {len(rows)} registros copiados para steam_source.{table}")
                    else:
                        logger.warning(f"⚠️ Tabela {table} está vazia no source")
                    
                    dw_conn.commit()
                    
                except Exception as e:
                    logger.error(f"❌ Erro ao copiar {table}: {e}")
                    dw_conn.rollback()
            
            logger.info("✅ Cópia de dados concluída! Schema steam_source populado com dados reais.")
            
        except Exception as e:
            logger.error(f"❌ Erro durante a cópia de dados: {e}")
            if dw_conn:
                dw_conn.rollback()
            if source_conn:
                source_conn.rollback()
            raise
        finally:
            # Fechar conexões mesmo em caso de erro
            if source_conn:
                try:
                    source_conn.close()
                except:
                    pass
            if dw_conn:
                try:
                    dw_conn.close()
                except:
                    pass

    # Tasks
    copy_data = copy_source_data()
    
    # DBT Tasks - Pipeline completa
    dbt_deps = BashOperator(
        task_id='dbt_deps',
        bash_command="""
            cd /opt/airflow/dbt && \
            echo "📦 Instalando dependências do DBT..." && \
            dbt deps --profiles-dir /opt/airflow/dbt && \
            echo "✅ Dependências instaladas com sucesso!"
        """,
    )
    
    dbt_run_staging = BashOperator(
        task_id='dbt_run_staging',
        bash_command="""
            cd /opt/airflow/dbt && \
            echo "🔄 Executando modelos staging..." && \
            dbt run --select "staging.*" --target destination --profiles-dir /opt/airflow/dbt && \
            echo "✅ Modelos staging executados com sucesso!"
        """,
    )
    
    dbt_run_dimensions = BashOperator(
        task_id='dbt_run_dimensions',
        bash_command="""
            cd /opt/airflow/dbt && \
            echo "🏗️ Criando dimensões..." && \
            dbt run --select "marts.dim_*" --target destination --profiles-dir /opt/airflow/dbt && \
            echo "✅ Dimensões criadas com sucesso!"
        """,
    )
    
    dbt_run_facts = BashOperator(
        task_id='dbt_run_facts',
        bash_command="""
            cd /opt/airflow/dbt && \
            echo "📊 Criando tabelas fato..." && \
            dbt run --select "marts.fact_*" --target destination --profiles-dir /opt/airflow/dbt && \
            echo "✅ Fatos criados com sucesso!"
        """,
    )
    
    dbt_test_all = BashOperator(
        task_id='dbt_test_all',
        bash_command="""
            cd /opt/airflow/dbt && \
            echo "🧪 Executando todos os testes..." && \
            dbt test --target destination --profiles-dir /opt/airflow/dbt && \
            echo "✅ Todos os testes passaram!"
        """,
    )

    # Dependencies - Pipeline sequencial completa
    copy_data >> dbt_deps >> dbt_run_staging >> dbt_run_dimensions >> dbt_run_facts >> dbt_test_all

steam_etl_simple = steam_etl_pipeline()
