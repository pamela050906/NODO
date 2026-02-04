from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from typing import Annotated

from app.core.database import get_db
from app.schemas.auth import Token, UsuarioResponse
from app.services.auth_service import AuthService
from app.api.dependencies import get_current_active_user
from app.models.usuario import Usuario

router = APIRouter(prefix="/auth", tags=["Autenticación"])


@router.post("/login", response_model=Token)
def login(
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
    db: Session = Depends(get_db)
):
    """
    Login de usuario.
    
    Retorna un token JWT para autenticación.
    
    Ejemplo:
    ```
    POST /api/v1/auth/login
    Content-Type: application/x-www-form-urlencoded
    
    username=admin&password=secreto123
    ```
    """
    auth_service = AuthService(db)
    token = auth_service.login(form_data.username, form_data.password)
    return token


@router.get("/me", response_model=UsuarioResponse)
def get_me(
    current_user: Annotated[Usuario, Depends(get_current_active_user)]
):
    """
    Obtener información del usuario actual.
    
    Requiere autenticación con token JWT.
    """
    return current_user
