from sqlalchemy import Column, Integer, ForeignKey, DateTime, CheckConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base


class Inventario(Base):
    """
    Modelo de Inventario.
    Mantiene el stock de cada variante de producto.
    IMPORTANTE: Los triggers de PostgreSQL manejan la lógica de actualización.
    
    ALINEADO con docs/almacen_db.sql
    """
    
    __tablename__ = "inventario"
    
    id = Column(Integer, primary_key=True, index=True)
    variante_id = Column(
        Integer, 
        ForeignKey("variantes_producto.id"), 
        nullable=False, 
        unique=True,
        index=True
    )
    
    # Stock actual (ALINEADO: docs/almacen_db.sql usa 'stock' no 'cantidad')
    stock = Column(Integer, nullable=False, default=0)
    
    # Timestamp de última actualización
    actualizado_en = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Restricción: stock no puede ser negativo
    __table_args__ = (
        CheckConstraint('stock >= 0', name='inventario_stock_check'),
    )
    
    # Relaciones (NOTA: FK name changed to variante_id)
    variante = relationship("VarianteProducto", back_populates="inventario")
