from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from typing import Annotated

from app.core.database import get_db
from app.core.security import decode_access_token
from app.models.usuario import Usuario
from app.services.auth_service import AuthService

# OAuth2 scheme
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    db: Session = Depends(get_db)
) -> Usuario:
    """
    Dependency para obtener el usuario actual desde el token JWT.
    
    Valida el token y retorna el usuario.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="No se pudo validar las credenciales",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    # Decodificar token
    payload = decode_access_token(token)
    
    if payload is None:
        raise credentials_exception
    
    username: str = payload.get("sub")
    
    if username is None:
        raise credentials_exception
    
    # Obtener usuario
    auth_service = AuthService(db)
    usuario = auth_service.get_current_user(username)
    
    return usuario


def get_current_active_user(
    current_user: Annotated[Usuario, Depends(get_current_user)]
) -> Usuario:
    """Dependency para validar que el usuario está activo."""
    if not current_user.activo:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Usuario inactivo"
        )
    return current_user


def require_admin(
    current_user: Annotated[Usuario, Depends(get_current_active_user)]
) -> Usuario:
    """Dependency para requerir rol ADMIN."""
    if current_user.rol_id != 1:  # 1 = ADMIN según tu BD
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tiene permisos suficientes"
        )
    return current_user


def require_cajero_or_admin(
    current_user: Annotated[Usuario, Depends(get_current_active_user)]
) -> Usuario:
    """Dependency para requerir rol CAJERO o ADMIN."""
    if current_user.rol_id not in [1, 2]:  # 1=ADMIN, 2=CAJERO según tu BD
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tiene permisos suficientes"
        )
    return current_user
