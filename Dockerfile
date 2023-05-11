FROM python:3.9

ENV PYTHONUNBUFFERED 1

# Робочий каталог у Docker-образі
WORKDIR /app

# Копіюємо файли в Docker-образ
COPY sample-django /app

# Встановлюємо залежності Python
RUN pip install --no-cache-dir -r requirements.txt

# Порт, на якому працює додаток
EXPOSE 8000