#!/bin/bash

# Script de testing para el API del POS
# Uso: ./test_api.sh

BASE_URL="http://localhost:8000"
API_URL="$BASE_URL/api/v1"

echo "================================"
echo "Testing POS Backend API"
echo "================================"
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Health Check
echo -e "${YELLOW}1. Health Check${NC}"
curl -s "$BASE_URL/health" | jq .
echo -e "\n"

# 2. Login como admin
echo -e "${YELLOW}2. Login como admin${NC}"
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123")

TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.access_token')

if [ "$TOKEN" != "null" ] && [ ! -z "$TOKEN" ]; then
    echo -e "${GREEN}✓ Login exitoso${NC}"
    echo "Token: ${TOKEN:0:50}..."
else
    echo -e "${RED}✗ Login falló${NC}"
    echo $LOGIN_RESPONSE | jq .
    exit 1
fi
echo ""

# 3. Obtener info de usuario actual
echo -e "${YELLOW}3. Usuario actual (GET /auth/me)${NC}"
curl -s -X GET "$API_URL/auth/me" \
  -H "Authorization: Bearer $TOKEN" | jq .
echo -e "\n"

# 4. Crear una venta vacía (PENDIENTE)
echo -e "${YELLOW}4. Crear venta pendiente (POST /sales)${NC}"
VENTA_RESPONSE=$(curl -s -X POST "$API_URL/sales" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "cliente_nombre": "Juan Pérez Test",
    "cliente_documento": "12345678",
    "metodo_pago": "EFECTIVO",
    "descuento_general": 0,
    "detalles": []
  }')

VENTA_ID=$(echo $VENTA_RESPONSE | jq -r '.id')

if [ "$VENTA_ID" != "null" ] && [ ! -z "$VENTA_ID" ]; then
    echo -e "${GREEN}✓ Venta creada con ID: $VENTA_ID${NC}"
    echo $VENTA_RESPONSE | jq .
else
    echo -e "${RED}✗ Error al crear venta${NC}"
    echo $VENTA_RESPONSE | jq .
fi
echo ""

# 5. Agregar ítem a la venta (POST /sales/{id}/item) ⭐
echo -e "${YELLOW}5. Agregar ítem a venta (POST /sales/$VENTA_ID/item) ⭐${NC}"
ITEM_RESPONSE=$(curl -s -X POST "$API_URL/sales/$VENTA_ID/item" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "codigo_barras": "7501234567891",
    "cantidad": 2,
    "descuento": 10.00
  }')

echo $ITEM_RESPONSE | jq .

if echo $ITEM_RESPONSE | jq -e '.id' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Ítem agregado exitosamente${NC}"
else
    echo -e "${RED}✗ Error al agregar ítem${NC}"
fi
echo ""

# 6. Agregar otro ítem
echo -e "${YELLOW}6. Agregar segundo ítem${NC}"
ITEM2_RESPONSE=$(curl -s -X POST "$API_URL/sales/$VENTA_ID/item" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "codigo_barras": "7501234567892",
    "cantidad": 1,
    "descuento": 0
  }')

echo $ITEM2_RESPONSE | jq .
echo ""

# 7. Obtener la venta completa
echo -e "${YELLOW}7. Obtener venta completa (GET /sales/$VENTA_ID)${NC}"
curl -s -X GET "$API_URL/sales/$VENTA_ID" \
  -H "Authorization: Bearer $TOKEN" | jq .
echo ""

# 8. Listar todas las ventas
echo -e "${YELLOW}8. Listar ventas (GET /sales)${NC}"
curl -s -X GET "$API_URL/sales?limit=5" \
  -H "Authorization: Bearer $TOKEN" | jq .
echo ""

# 9. Completar la venta
echo -e "${YELLOW}9. Completar venta (POST /sales/$VENTA_ID/complete)${NC}"
curl -s -X POST "$API_URL/sales/$VENTA_ID/complete" \
  -H "Authorization: Bearer $TOKEN" | jq .
echo ""

# 10. Intentar agregar ítem a venta completada (debe fallar)
echo -e "${YELLOW}10. Intentar agregar ítem a venta completada (debe fallar)${NC}"
ERROR_RESPONSE=$(curl -s -X POST "$API_URL/sales/$VENTA_ID/item" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "codigo_barras": "7501234567891",
    "cantidad": 1,
    "descuento": 0
  }')

echo $ERROR_RESPONSE | jq .

if echo $ERROR_RESPONSE | jq -e '.detail' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Error capturado correctamente${NC}"
else
    echo -e "${RED}✗ Debería haber retornado error${NC}"
fi
echo ""

# 11. Intentar con código de barras inexistente
echo -e "${YELLOW}11. Buscar producto inexistente (debe fallar)${NC}"
VENTA2_ID=$((VENTA_ID + 1))
curl -s -X POST "$API_URL/sales" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "cliente_nombre": "Test Error",
    "metodo_pago": "EFECTIVO",
    "descuento_general": 0,
    "detalles": []
  }' > /dev/null

ERROR2_RESPONSE=$(curl -s -X POST "$API_URL/sales/$VENTA2_ID/item" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "codigo_barras": "9999999999999",
    "cantidad": 1,
    "descuento": 0
  }')

echo $ERROR2_RESPONSE | jq .
echo ""

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Testing completado${NC}"
echo -e "${GREEN}================================${NC}"
