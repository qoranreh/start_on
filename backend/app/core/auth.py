from dataclasses import dataclass

from fastapi import HTTPException, Request, Security, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.supabase import get_supabase_admin_client
from app.schemas.common import ErrorDetail


@dataclass(frozen=True)
class AuthenticatedUser:
    id: str
    email: str | None


supabase_bearer_scheme = HTTPBearer(
    scheme_name="SupabaseAccessToken",
    bearerFormat="JWT",
    description="Supabase access token in the form `Bearer <token>`.",
    auto_error=False,
)


def get_current_user(
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Security(supabase_bearer_scheme),
) -> AuthenticatedUser:
    authorization = request.headers.get("Authorization")
    if not authorization:
        raise _auth_error("missing_authorization", "Authorization header is required.")

    if (
        credentials is None
        or credentials.scheme.lower() != "bearer"
        or not credentials.credentials.strip()
    ):
        raise _auth_error(
            "invalid_authorization",
            "Authorization header must use the Bearer scheme.",
        )

    token = credentials.credentials.strip()
    try:
        response = get_supabase_admin_client().auth.get_user(token)
    except Exception as error:
        raise _auth_error("invalid_token", "Supabase access token validation failed.") from error

    user = getattr(response, "user", None)
    user_id = getattr(user, "id", None)
    if not user_id:
        raise _auth_error("invalid_token", "Supabase access token is invalid or expired.")

    return AuthenticatedUser(
        id=str(user_id),
        email=getattr(user, "email", None),
    )


def _auth_error(code: str, message: str) -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=ErrorDetail(code=code, message=message).model_dump(),
        headers={"WWW-Authenticate": "Bearer"},
    )
