"""
Servicio para gestión de productos y variantes.
"""
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from fastapi import HTTPException, status, UploadFile
from typing import List, Optional
import csv
import io

from app.models.producto import Producto, VarianteProducto
from app.models.inventario import Inventario
from app.repositories.producto_repository import ProductoRepository


class ProductoCreateRequest:
    """Request para crear producto."""
    def __init__(self, nombre: str, descripcion: str = None, categoria: str = None, marca: str = None):
        self.nombre = nombre
        self.descripcion = descripcion
        self.categoria = categoria
        self.marca = marca


class VarianteCreateRequest:
    """Request para crear variante."""
    def __init__(self, producto_id: int, sku: str, codigo_barras: str, 
                 talla: str = None, color: str = None,
                 precio_menudeo: float = 0, precio_mayoreo: float = 0,
                 stock_inicial: int = 0):
        self.producto_id = producto_id
        self.sku = sku
        self.codigo_barras = codigo_barras
        self.talla = talla
        self.color = color
        self.precio_menudeo = precio_menudeo
        self.precio_mayoreo = precio_mayoreo
        self.stock_inicial = stock_inicial


class ProductoService:
    """Servicio de gestión de productos."""
    
    def __init__(self, db: Session):
        self.db = db
        self.producto_repo = ProductoRepository(db)
    
    def crear_producto(self, producto_data: ProductoCreateRequest) -> Producto:
        """Crear un nuevo producto."""
        try:
            producto = Producto(
                nombre=producto_data.nombre,
                descripcion=producto_data.descripcion,
                categoria=producto_data.categoria,
                marca=producto_data.marca,
                activo=True
            )
            
            self.db.add(producto)
            self.db.commit()
            self.db.refresh(producto)
            
            return producto
            
        except IntegrityError as e:
            self.db.rollback()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Error al crear producto: {str(e)}"
            )
    
    def crear_variante(self, variante_data: VarianteCreateRequest) -> VarianteProducto:
        """
        Crear una nueva variante de producto.
        
        Si se proporciona stock_inicial, también crea el registro de inventario.
        """
        try:
            # Validar que el producto existe
            producto = self.db.query(Producto).filter(
                Producto.id == variante_data.producto_id
            ).first()
            
            if not producto:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Producto {variante_data.producto_id} no encontrado"
                )
            
            # Crear variante
            variante = VarianteProducto(
                producto_id=variante_data.producto_id,
                sku=variante_data.sku,
                codigo_barras=variante_data.codigo_barras,
                talla=variante_data.talla,
                color=variante_data.color,
                precio_menudeo=variante_data.precio_menudeo,
                precio_mayoreo=variante_data.precio_mayoreo,
                activo=True
            )
            
            self.db.add(variante)
            self.db.flush()  # Para obtener el ID
            
            # Crear registro de inventario si se proporciona stock inicial
            if variante_data.stock_inicial > 0:
                inventario = Inventario(
                    variante_id=variante.id,
                    stock=variante_data.stock_inicial
                )
                self.db.add(inventario)
            
            self.db.commit()
            self.db.refresh(variante)
            
            return variante
            
        except IntegrityError as e:
            self.db.rollback()
            if 'codigo_barras' in str(e):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Código de barras '{variante_data.codigo_barras}' ya existe"
                )
            elif 'sku' in str(e):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"SKU '{variante_data.sku}' ya existe"
                )
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Error al crear variante: {str(e)}"
            )
    
    def carga_masiva_csv(self, file: UploadFile) -> dict:
        """
        Carga masiva de productos desde archivo CSV.
        
        Formato CSV esperado:
        nombre,descripcion,categoria,marca,sku,codigo_barras,talla,color,precio_menudeo,precio_mayoreo,stock_inicial
        
        Returns:
            Diccionario con resultados de la carga
        """
        if not file.filename.endswith('.csv'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El archivo debe ser CSV"
            )
        
        try:
            # Leer contenido del archivo
            contents = file.file.read()
            decoded = contents.decode('utf-8')
            csv_reader = csv.DictReader(io.StringIO(decoded))
            
            productos_creados = 0
            variantes_creadas = 0
            errores = []
            
            # Procesar cada línea
            for idx, row in enumerate(csv_reader, start=2):  # Línea 2 (después del header)
                try:
                    # Buscar o crear producto
                    producto = self.db.query(Producto).filter(
                        Producto.nombre == row['nombre']
                    ).first()
                    
                    if not producto:
                        producto = Producto(
                            nombre=row['nombre'],
                            descripcion=row.get('descripcion'),
                            categoria=row.get('categoria'),
                            marca=row.get('marca'),
                            activo=True
                        )
                        self.db.add(producto)
                        self.db.flush()
                        productos_creados += 1
                    
                    # Crear variante
                    variante = VarianteProducto(
                        producto_id=producto.id,
                        sku=row['sku'],
                        codigo_barras=row['codigo_barras'],
                        talla=row.get('talla'),
                        color=row.get('color'),
                        precio_menudeo=float(row.get('precio_menudeo', 0)),
                        precio_mayoreo=float(row.get('precio_mayoreo', 0)),
                        activo=True
                    )
                    self.db.add(variante)
                    self.db.flush()
                    
                    # Crear inventario
                    stock_inicial = int(row.get('stock_inicial', 0))
                    if stock_inicial > 0:
                        inventario = Inventario(
                            variante_id=variante.id,
                            stock=stock_inicial
                        )
                        self.db.add(inventario)
                    
                    variantes_creadas += 1
                    
                except Exception as e:
                    errores.append({
                        'linea': idx,
                        'sku': row.get('sku', 'N/A'),
                        'error': str(e)
                    })
            
            # Commit si no hay errores críticos
            self.db.commit()
            
            return {
                'productos_creados': productos_creados,
                'variantes_creadas': variantes_creadas,
                'errores': errores,
                'exitoso': len(errores) == 0
            }
            
        except Exception as e:
            self.db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error procesando archivo CSV: {str(e)}"
            )
        finally:
            file.file.close()
    
    def actualizar_producto(self, producto_id: int, producto_data: dict) -> Producto:
        """Actualizar un producto existente."""
        producto = self.db.query(Producto).filter(Producto.id == producto_id).first()
        
        if not producto:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Producto {producto_id} no encontrado"
            )
        
        # Actualizar campos
        for key, value in producto_data.items():
            if hasattr(producto, key):
                setattr(producto, key, value)
        
        self.db.commit()
        self.db.refresh(producto)
        
        return producto
    
    def eliminar_producto(self, producto_id: int) -> bool:
        """Desactivar un producto (soft delete)."""
        producto = self.db.query(Producto).filter(Producto.id == producto_id).first()
        
        if not producto:
            return False
        
        producto.activo = False
        
        # Desactivar también sus variantes
        self.db.query(VarianteProducto).filter(
            VarianteProducto.producto_id == producto_id
        ).update({'activo': False})
        
        self.db.commit()
        return True
