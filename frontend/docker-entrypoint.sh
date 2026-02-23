#!/bin/sh
# Script de entrada para Docker que configura las variables de entorno
# React necesita que REACT_APP_* estén disponibles cuando se ejecuta npm start

# Crear archivo .env con las variables de entorno
echo "Configurando variables de entorno para React..."
echo "REACT_APP_API_URL=${REACT_APP_API_URL:-http://localhost:8000}" > /app/.env
echo "CHOKIDAR_USEPOLLING=${CHOKIDAR_USEPOLLING:-true}" >> /app/.env

echo "Variables configuradas:"
cat /app/.env

# Ejecutar el comando original
exec "$@"
