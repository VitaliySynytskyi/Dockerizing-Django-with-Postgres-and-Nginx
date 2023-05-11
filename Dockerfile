FROM python:3.9
ENV PYTHONUNBUFFERED 1

# Робочий каталог у Docker-образі
WORKDIR /app

# Копіюємо файли в Docker-образ
COPY sample-django /app

# Встановлюємо залежності Python
RUN pip install --no-cache-dir -r requirements.txt

# Копіюємо файли у контейнер
COPY . /app/

# Порт, на якому працює додаток
EXPOSE 8080

# Команда запуску додатку в Docker-образі
CMD ["python", "manage.py", "runserver", "0.0.0.0:8080"]
