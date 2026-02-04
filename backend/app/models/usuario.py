from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.core.database import Base


class Usuario(Base):
    """Modelo de Usuario para autenticación y autorización."""
    
    __tablename__ = "usuarios"
    
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), nullable=False)  # Cambiado de username a nombre
    email = Column(String(150), unique=True, nullable=False, index=True)
    password_hash = Column(String, nullable=False)  # Cambiado de hashed_password a password_hash
    rol_id = Column(Integer, ForeignKey('roles.id'), nullable=False)  # Relación con tabla roles
    activo = Column(Boolean, default=True)  # Boolean en lugar de Integer
    creado_en = Column(DateTime(timezone=True), server_default=func.now())  # Cambiado de created_at
    
    # Relación con tabla roles (opcional pero útil)
    # rol_rel = relationship("Rol", backref="usuarios")
