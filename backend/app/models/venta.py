from sqlalchemy import Column, Integer, String, Numeric, ForeignKey, DateTime, CheckConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import enum


class EstadoVentaEnum(str, enum.Enum):
    """Estados de una venta (ALINEADO con BD)."""
    ABIERTA = "ABIERTA"
    CERRADA = "CERRADA"
    CANCELADA = "CANCELADA"


class Venta(Base):
    """
    Modelo de Venta (cabecera).
    Representa una transacción de venta completa.
    
    ALINEADO con docs/almacen_db.sql + migración 001
    """
    
    __tablename__ = "ventas"
    
    id = Column(Integer, primary_key=True, index=True)
    
    # Punto de venta (ALINEADO: docs/almacen_db.sql tiene punto_venta_id)
    punto_venta_id = Column(Integer, ForeignKey("puntos_venta.id"), nullable=False)
    
    # Usuario que registra la venta
    usuario_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False)
    
    # Totales (ALINEADO: agregados via migración)
    subtotal = Column(Numeric(12, 2), default=0)
    descuento = Column(Numeric(12, 2), default=0)
    impuesto = Column(Numeric(12, 2), default=0)
    total = Column(Numeric(12, 2), nullable=False, default=0)
    
    # Estado y método de pago
    estado = Column(String(20), default='ABIERTA')  # ABIERTA, CERRADA, CANCELADA
    metodo_pago = Column(String(20), nullable=False)  # EFECTIVO, TARJETA
    
    # Auditoría (ALINEADO: docs/almacen_db.sql usa creada_en)
    creada_en = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    completed_at = Column(DateTime(timezone=True))
    
    # Constraints
    __table_args__ = (
        CheckConstraint("metodo_pago IN ('EFECTIVO', 'TARJETA')", name='ventas_metodo_pago_check'),
        CheckConstraint('total >= 0', name='ventas_total_check'),
    )
    
    # Relaciones
    detalles = relationship("VentaDetalle", back_populates="venta", cascade="all, delete-orphan")


class VentaDetalle(Base):
    """
    Modelo de Detalle de Venta.
    Cada línea de producto en una venta.
    
    ALINEADO con docs/almacen_db.sql
    """
    
    __tablename__ = "venta_detalle"
    
    id = Column(Integer, primary_key=True, index=True)
    venta_id = Column(Integer, ForeignKey("ventas.id"), nullable=False, index=True)
    variante_id = Column(Integer, ForeignKey("variantes_producto.id"), nullable=False)
    
    # Cantidades y precios (ALINEADO: docs/almacen_db.sql NO tiene descuento en detalle)
    cantidad = Column(Integer, nullable=False)
    precio_unitario = Column(Numeric(10, 2), nullable=False)
    subtotal = Column(Numeric(12, 2), nullable=False)
    
    # Constraints
    __table_args__ = (
        CheckConstraint('cantidad > 0', name='venta_detalle_cantidad_check'),
        CheckConstraint('precio_unitario >= 0', name='venta_detalle_precio_unitario_check'),
        CheckConstraint('subtotal >= 0', name='venta_detalle_subtotal_check'),
    )
    
    # Relaciones
    venta = relationship("Venta", back_populates="detalles")
