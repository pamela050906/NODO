from sqlalchemy.orm import Session
from typing import Optional
from datetime import timedelta
from fastapi import HTTPException, status

from app.models.usuario import Usuario
from app.repositories.usuario_repository import UsuarioRepository
from app.core.security import verify_password, create_access_token
from app.core.config import settings
from app.schemas.auth import Token


class AuthService:
    """Servicio de autenticación."""
    
    def __init__(self, db: Session):
        self.db = db
        self.usuario_repo = UsuarioRepository(db)
    
    def authenticate_user(self, username: str, password: str) -> Optional[Usuario]:
        """
        Autenticar usuario con username y password.
        
        Args:
            username: Username del usuario
            password: Password en texto plano
            
        Returns:
            Usuario si las credenciales son correctas, None en caso contrario
        """
        usuario = self.usuario_repo.get_by_username(username)
        
        if not usuario:
            return None
        
        if not verify_password(password, usuario.password_hash):
            return None
        
        return usuario
    
    def login(self, username: str, password: str) -> Token:
        """
        Login de usuario.
        
        Args:
            username: Username del usuario
            password: Password en texto plano
            
        Returns:
            Token JWT
            
        Raises:
            HTTPException: Si las credenciales son incorrectas
        """
        usuario = self.authenticate_user(username, password)
        
        if not usuario:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Usuario o contraseña incorrectos",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # Crear token (usar nombre como username y rol_id)
        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": usuario.nombre, "rol_id": usuario.rol_id},
            expires_delta=access_token_expires
        )
        
        return Token(access_token=access_token, token_type="bearer")
    
    def get_current_user(self, username: str) -> Usuario:
        """
        Obtener usuario actual desde token.
        
        Args:
            username: Username extraído del token
            
        Returns:
            Usuario
            
        Raises:
            HTTPException: Si el usuario no existe
        """
        usuario = self.usuario_repo.get_by_username(username)
        
        if not usuario:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Usuario no encontrado",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        return usuario
