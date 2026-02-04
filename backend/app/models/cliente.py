from sqlalchemy import Column, Integer, String, Numeric, Boolean, DateTime, Text, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base


class Cliente(Base):
    """
    Modelo de Cliente.
    Para ventas a crédito y facturación.
    """
    
    __tablename__ = "clientes"
    
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(200), nullable=False)
    rfc = Column(String(13), index=True)
    telefono = Column(String(15))
    email = Column(String(150))
    direccion = Column(Text)
    limite_credito = Column(Numeric(12, 2), default=0)
    activo = Column(Boolean, default=True)
    creado_en = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relaciones (temporalmente comentada para evitar error de SQLAlchemy)
    # cuentas = relationship("CuentaPorCobrar", back_populates="cliente")


class CuentaPorCobrar(Base):
    """
    Modelo de Cuenta por Cobrar.
    Representa una venta a crédito pendiente de pago.
    """
    
    __tablename__ = "cuentas_por_cobrar"
    
    id = Column(Integer, primary_key=True, index=True)
    venta_id = Column(Integer, ForeignKey("ventas.id"), nullable=False, index=True)
    cliente_id = Column(Integer, ForeignKey("clientes.id"), nullable=False, index=True)
    monto_total = Column(Numeric(12, 2), nullable=False)
    monto_pagado = Column(Numeric(12, 2), default=0)
    saldo_pendiente = Column(Numeric(12, 2), nullable=False)
    fecha_vencimiento = Column(DateTime(timezone=True))
    estado = Column(String(20), default='PENDIENTE')  # PENDIENTE, PAGADA, VENCIDA
    creada_en = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relaciones (sin back_populates temporalmente)
    cliente = relationship("Cliente")  # back_populates="cuentas" comentado temporalmente
    pagos = relationship("PagoCuenta", back_populates="cuenta")


class PagoCuenta(Base):
    """
    Modelo de Pago/Abono a Cuenta.
    Representa un pago parcial o total de una cuenta por cobrar.
    """
    
    __tablename__ = "pagos_cuenta"
    
    id = Column(Integer, primary_key=True, index=True)
    cuenta_id = Column(Integer, ForeignKey("cuentas_por_cobrar.id"), nullable=False, index=True)
    monto = Column(Numeric(12, 2), nullable=False)
    metodo_pago = Column(String(20), nullable=False)  # EFECTIVO, TARJETA, TRANSFERENCIA, CHEQUE
    referencia = Column(String(100))
    notas = Column(Text)
    usuario_id = Column(Integer)
    creado_en = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relaciones
    cuenta = relationship("CuentaPorCobrar", back_populates="pagos")
