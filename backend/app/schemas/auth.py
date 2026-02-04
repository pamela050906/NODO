from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime


class Login(BaseModel):
    """Schema para login."""
    username: str
    password: str


class Token(BaseModel):
    """Schema para respuesta de token JWT."""
    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    """Schema para datos decodificados del token."""
    username: Optional[str] = None
    rol: Optional[str] = None


class UsuarioResponse(BaseModel):
    """Schema para respuesta de datos de usuario."""
    id: int
    nombre: str  # Cambiado de username
    email: str
    rol_id: int  # Cambiado de rol
    activo: bool  # Cambiado de int a bool
    creado_en: datetime  # Cambiado de created_at
    
    class Config:
        from_attributes = True
