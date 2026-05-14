import unittest

from fastapi import Depends, FastAPI
from fastapi.testclient import TestClient

from app.core.auth import AuthenticatedUser, get_current_user


def make_protected_app() -> FastAPI:
    app = FastAPI()

    @app.get("/protected")
    def protected(
        current_user: AuthenticatedUser = Depends(get_current_user),
    ) -> dict[str, str]:
        return {"user_id": current_user.id}

    return app


class AuthOpenApiTest(unittest.TestCase):
    def test_current_user_dependency_declares_bearer_security_scheme(self) -> None:
        schema = make_protected_app().openapi()

        security_schemes = schema["components"]["securitySchemes"]
        scheme = security_schemes["SupabaseAccessToken"]
        self.assertEqual(scheme["type"], "http")
        self.assertEqual(scheme["scheme"], "bearer")
        self.assertEqual(scheme["bearerFormat"], "JWT")

        operation = schema["paths"]["/protected"]["get"]
        self.assertIn({"SupabaseAccessToken": []}, operation["security"])
        self.assertFalse(
            any(
                parameter.get("name") == "Authorization"
                for parameter in operation.get("parameters", [])
            )
        )

    def test_missing_authorization_keeps_custom_401_response(self) -> None:
        response = TestClient(make_protected_app()).get("/protected")

        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.json()["detail"]["code"], "missing_authorization")
        self.assertEqual(response.headers["www-authenticate"], "Bearer")

    def test_invalid_authorization_keeps_custom_401_response(self) -> None:
        response = TestClient(make_protected_app()).get(
            "/protected",
            headers={"Authorization": "Basic token"},
        )

        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.json()["detail"]["code"], "invalid_authorization")
        self.assertEqual(response.headers["www-authenticate"], "Bearer")


if __name__ == "__main__":
    unittest.main()
