FROM python

RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev && mkdir -p /mnt/dbt

COPY requirements.txt /app/requirements.txt
COPY dbt_project.yml /mnt/dbt/dbt_project.yml

RUN pip install --no-cache-dir -r /app/requirements.txt

COPY . /app

WORKDIR /app

CMD ["python", "your-script.py"]