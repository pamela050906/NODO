"""
Cliente de ejemplo para el API del POS.
Demuestra el uso del endpoint principal POST /sales/{id}/item.

Uso:
    python examples/test_client.py
"""

import requests
from typing import Optional
import json


class POSClient:
    """Cliente para interactuar con el API del POS."""
    
    def __init__(self, base_url: str = "http://localhost:8000"):
        self.base_url = base_url
        self.api_url = f"{base_url}/api/v1"
        self.token: Optional[str] = None
    
    def login(self, username: str, password: str) -> bool:
        """Login y obtener token JWT."""
        url = f"{self.api_url}/auth/login"
        data = {
            "username": username,
            "password": password
        }
        
        response = requests.post(url, data=data)
        
        if response.status_code == 200:
            self.token = response.json()["access_token"]
            print(f"✓ Login exitoso como {username}")
            return True
        else:
            print(f"✗ Login falló: {response.json()}")
            return False
    
    def _get_headers(self) -> dict:
        """Obtener headers con autenticación."""
        return {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json"
        }
    
    def crear_venta_vacia(self, cliente_nombre: str, metodo_pago: str = "EFECTIVO") -> Optional[int]:
        """Crear una venta vacía en estado PENDIENTE."""
        url = f"{self.api_url}/sales"
        data = {
            "cliente_nombre": cliente_nombre,
            "metodo_pago": metodo_pago,
            "descuento_general": 0,
            "detalles": []
        }
        
        response = requests.post(url, json=data, headers=self._get_headers())
        
        if response.status_code == 201:
            venta_id = response.json()["id"]
            print(f"✓ Venta creada con ID: {venta_id}")
            return venta_id
        else:
            print(f"✗ Error al crear venta: {response.json()}")
            return None
    
    def agregar_item(
        self,
        venta_id: int,
        codigo_barras: str,
        cantidad: int,
        descuento: float = 0
    ) -> bool:
        """
        ⭐ ENDPOINT PRINCIPAL: Agregar ítem a venta.
        
        POST /sales/{id}/item
        
        Este método demuestra el uso del endpoint principal solicitado.
        Usa transacción ACID con SELECT FOR UPDATE para garantizar
        consistencia en operaciones concurrentes.
        """
        url = f"{self.api_url}/sales/{venta_id}/item"
        data = {
            "codigo_barras": codigo_barras,
            "cantidad": cantidad,
            "descuento": descuento
        }
        
        print(f"\n→ Agregando ítem: {codigo_barras} x{cantidad}")
        
        response = requests.post(url, json=data, headers=self._get_headers())
        
        if response.status_code == 200:
            venta = response.json()
            print(f"✓ Ítem agregado exitosamente")
            print(f"  Subtotal: ${venta['subtotal']}")
            print(f"  Total: ${venta['total']}")
            print(f"  Total ítems: {len(venta['detalles'])}")
            return True
        else:
            error = response.json()
            print(f"✗ Error: {error.get('detail', 'Error desconocido')}")
            return False
    
    def obtener_venta(self, venta_id: int) -> Optional[dict]:
        """Obtener información completa de una venta."""
        url = f"{self.api_url}/sales/{venta_id}"
        
        response = requests.get(url, headers=self._get_headers())
        
        if response.status_code == 200:
            return response.json()
        else:
            print(f"✗ Error al obtener venta: {response.json()}")
            return None
    
    def completar_venta(self, venta_id: int) -> bool:
        """Completar una venta (cambiar estado a COMPLETADA)."""
        url = f"{self.api_url}/sales/{venta_id}/complete"
        
        response = requests.post(url, headers=self._get_headers())
        
        if response.status_code == 200:
            print(f"✓ Venta {venta_id} completada")
            return True
        else:
            print(f"✗ Error al completar venta: {response.json()}")
            return False
    
    def listar_ventas(self, limit: int = 10) -> list:
        """Listar ventas recientes."""
        url = f"{self.api_url}/sales?limit={limit}"
        
        response = requests.get(url, headers=self._get_headers())
        
        if response.status_code == 200:
            return response.json()
        else:
            print(f"✗ Error al listar ventas: {response.json()}")
            return []


def ejemplo_flujo_completo():
    """
    Ejemplo completo del flujo de una venta usando el endpoint principal.
    
    Simula el proceso de un cajero escaneando productos.
    """
    print("=" * 60)
    print("EJEMPLO: Flujo Completo de Venta")
    print("=" * 60)
    
    # Crear cliente
    client = POSClient()
    
    # 1. Login
    print("\n1. Autenticación")
    if not client.login("admin", "admin123"):
        return
    
    # 2. Crear venta vacía
    print("\n2. Crear venta pendiente")
    venta_id = client.crear_venta_vacia("Cliente de Prueba", "EFECTIVO")
    
    if not venta_id:
        return
    
    # 3. Escanear productos (simulado)
    print("\n3. Escanear productos")
    print("-" * 60)
    
    # Escanear Mouse Logitech
    client.agregar_item(
        venta_id=venta_id,
        codigo_barras="7501234567891",
        cantidad=2,
        descuento=10.00
    )
    
    # Escanear Teclado Razer
    client.agregar_item(
        venta_id=venta_id,
        codigo_barras="7501234567892",
        cantidad=1,
        descuento=0
    )
    
    # Escanear Laptop Dell
    client.agregar_item(
        venta_id=venta_id,
        codigo_barras="7501234567890",
        cantidad=1,
        descuento=500.00
    )
    
    # 4. Ver venta completa
    print("\n4. Venta completa")
    print("-" * 60)
    venta = client.obtener_venta(venta_id)
    
    if venta:
        print(f"\nCliente: {venta['cliente_nombre']}")
        print(f"Estado: {venta['estado']}")
        print(f"Método de pago: {venta['metodo_pago']}")
        print(f"\nDetalles:")
        for detalle in venta['detalles']:
            print(f"  - {detalle['producto_nombre']}")
            print(f"    Cantidad: {detalle['cantidad']}")
            print(f"    Precio unitario: ${detalle['precio_unitario']}")
            print(f"    Subtotal: ${detalle['subtotal']}")
        print(f"\nSubtotal: ${venta['subtotal']}")
        print(f"Descuento: ${venta['descuento']}")
        print(f"Total: ${venta['total']}")
    
    # 5. Completar venta
    print("\n5. Completar venta")
    print("-" * 60)
    client.completar_venta(venta_id)
    
    # 6. Intentar agregar más ítems (debe fallar)
    print("\n6. Intentar agregar a venta completada (debe fallar)")
    print("-" * 60)
    client.agregar_item(
        venta_id=venta_id,
        codigo_barras="7501234567891",
        cantidad=1
    )
    
    print("\n" + "=" * 60)
    print("Ejemplo completado")
    print("=" * 60)


def ejemplo_manejo_errores():
    """
    Ejemplo de manejo de errores.
    """
    print("\n" + "=" * 60)
    print("EJEMPLO: Manejo de Errores")
    print("=" * 60)
    
    client = POSClient()
    
    if not client.login("admin", "admin123"):
        return
    
    venta_id = client.crear_venta_vacia("Test Errores")
    
    if not venta_id:
        return
    
    # Error 1: Producto no encontrado
    print("\n1. Producto no encontrado")
    print("-" * 60)
    client.agregar_item(
        venta_id=venta_id,
        codigo_barras="9999999999999",
        cantidad=1
    )
    
    # Error 2: Stock insuficiente
    print("\n2. Stock insuficiente")
    print("-" * 60)
    client.agregar_item(
        venta_id=venta_id,
        codigo_barras="7501234567890",  # Laptop (stock limitado)
        cantidad=999
    )
    
    # Error 3: Cantidad negativa o cero
    print("\n3. Cantidad inválida")
    print("-" * 60)
    # Esto fallará en la validación de Pydantic antes de llegar al servidor
    try:
        data = {
            "codigo_barras": "7501234567891",
            "cantidad": 0,  # Inválido
            "descuento": 0
        }
        response = requests.post(
            f"{client.api_url}/sales/{venta_id}/item",
            json=data,
            headers=client._get_headers()
        )
        print(f"✗ Error: {response.json()}")
    except Exception as e:
        print(f"✗ Error: {e}")
    
    print("\n" + "=" * 60)
    print("Ejemplos de errores completados")
    print("=" * 60)


if __name__ == "__main__":
    # Ejecutar ejemplos
    ejemplo_flujo_completo()
    ejemplo_manejo_errores()
    
    print("\n\n💡 NOTA:")
    print("Este cliente demuestra el endpoint principal POST /sales/{id}/item")
    print("que implementa transacciones ACID con SELECT FOR UPDATE.")
    print("\nPara más información, ver la documentación en:")
    print("http://localhost:8000/docs")
