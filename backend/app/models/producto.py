from sqlalchemy import Column, Integer, String, Numeric, ForeignKey, DateTime, CheckConstraint, Boolean, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base


class Producto(Base):
    """Modelo de Producto base."""
    
    __tablename__ = "productos"
    
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(150), nullable=False)
    descripcion = Column(Text)
    categoria = Column(String(100))
    marca = Column(String(100))
    activo = Column(Boolean, default=True)
    creado_en = Column(DateTime(timezone=True), server_default=func.now())
    actualizado_en = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relaciones
    variantes = relationship("VarianteProducto", back_populates="producto")


class VarianteProducto(Base):
    """
    Modelo de Variante de Producto.
    Cada variante tiene código de barras único y precios diferenciados.
    
    ALINEADO con almacen_db.sql
    """
    
    __tablename__ = "variantes_producto"
    
    id = Column(Integer, primary_key=True, index=True)
    producto_id = Column(Integer, ForeignKey("productos.id"), nullable=False)
    sku = Column(String(50), unique=True, nullable=False, index=True)
    codigo_barras = Column(String(100), unique=True, nullable=False, index=True)
    
    # Atributos de variante (ALINEADO: talla y color como campos separados)
    talla = Column(String(20))  # ej: "M", "XL", "XXL"
    color = Column(String(30))  # ej: "Negro", "Rojo", "Azul"
    
    # Precios diferenciados (ALINEADO: menudeo y mayoreo separados)
    precio_menudeo = Column(Numeric(10, 2), nullable=False)
    precio_mayoreo = Column(Numeric(10, 2), nullable=False)
    
    activo = Column(Boolean, default=True)
    
    # Restricciones de precios
    __table_args__ = (
        CheckConstraint('precio_menudeo >= 0', name='variantes_producto_precio_menudeo_check'),
        CheckConstraint('precio_mayoreo >= 0', name='variantes_producto_precio_mayoreo_check'),
    )
    
    # Relaciones
    producto = relationship("Producto", back_populates="variantes")
    inventario = relationship("Inventario", back_populates="variante", uselist=False)
