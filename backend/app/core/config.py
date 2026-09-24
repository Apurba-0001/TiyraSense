from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import field_validator


class Settings(BaseSettings):
    # Application Info
    APP_NAME: str = "TiyraSense"
    APP_ENV: str = "development"
    APP_URL: str = "http://localhost:8000"
    BACKEND_HOST: str = "0.0.0.0"
    BACKEND_PORT: int = 8000
    BACKEND_LOG_LEVEL: str = "info"
    DATA_LABEL: str = "LIVE"

    # Database (loaded strictly from .env)
    DATABASE_URL: str = ""

    # JWT Authentication (loaded strictly from environment variable or .env)
    AUTH_SECRET_KEY: str = ""
    AUTH_ALGORITHM: str = "HS256"
    AUTH_ACCESS_TOKEN_EXPIRE_MINUTES: int = 10080  # 7 days default
    AUTH_ISSUER: str = "tiyrasense"
    AUTH_AUDIENCE: str = "tiyrasense_clients"

    # Rate Limiting Controls
    RATE_LIMIT_LOGIN_PER_MINUTE: int = 20
    RATE_LIMIT_REGISTER_PER_MINUTE: int = 10
    RATE_LIMIT_API_PER_MINUTE: int = 120

    # CORS: enumerate exact allowed origins. Never use ["*"] in production.
    CORS_ORIGINS: List[str] = [
        "http://localhost:5173",
        "http://localhost:3000",
        "http://127.0.0.1:5173",
        "http://127.0.0.1:3000",
        "https://tiyrasense.onrender.com",
        "https://tiyrasense-web.pages.dev",
    ]

    # Cloudinary Image & Evidence Storage (loaded strictly from .env)
    CLOUDINARY_CLOUD_NAME: str = ""
    CLOUDINARY_API_KEY: str = ""
    CLOUDINARY_API_SECRET: str = ""
    CLOUDINARY_UPLOAD_PRESET: str = "tiyrasense_evidence"

    # Supabase Live Cloud Database (loaded strictly from .env)
    SUPABASE_URL: str = ""
    SUPABASE_KEY: str = ""
    SUPABASE_ANON_KEY: str = ""
    SUPABASE_SERVICE_ROLE_KEY: str = ""

    # LLM / AI Advisory (loaded strictly from .env if configured)
    LLM_PROVIDER: str = "gemini"
    LLM_API_KEY: str = ""
    LLM_MODEL: str = "gemini-3.5-flash-lite"

    # Traffic & Navigation (loaded from .env)
    TRAFFIC_PROVIDER: str = "osrm_baseline"
    TRAFFIC_API_KEY: str = ""

    # Push Notifications (loaded from .env)
    NOTIFICATIONS_PROVIDER: str = "fcm"
    NOTIFICATIONS_API_KEY: str = ""
    FIREBASE_PROJECT_ID: str = ""

    # Model Configuration
    model_config = SettingsConfigDict(
        env_file=(".env", "../.env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    @field_validator("AUTH_SECRET_KEY")
    @classmethod
    def secret_key_must_be_strong(cls, v: str, info) -> str:
        """Validate that a strong JWT secret key is provided.

        Zero private keys or secret values are committed to source control.
        In production, a strong random key (at least 32 characters) must be
        supplied via the AUTH_SECRET_KEY environment variable.

        In development/test environments without an explicit key in .env, an
        ephemeral in-memory key is generated automatically.
        """
        env = info.data.get("APP_ENV", "production")
        if not v:
            if env in ("development", "test"):
                import secrets
                return secrets.token_hex(32)
            raise ValueError(
                "AUTH_SECRET_KEY is required and cannot be empty in production. "
                "Set a strong random key via the AUTH_SECRET_KEY environment variable."
            )
        if len(v) < 32:
            raise ValueError(
                "AUTH_SECRET_KEY must be at least 32 characters. "
                "Generate one with: openssl rand -hex 64"
            )
        return v


settings = Settings()
