from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import AnyHttpUrl


class Settings(BaseSettings):
    # Application Info
    APP_NAME: str = "TiyraSense"
    APP_ENV: str = "development"
    APP_URL: str = "http://localhost:8000"
    BACKEND_HOST: str = "0.0.0.0"
    BACKEND_PORT: int = 8000
    BACKEND_LOG_LEVEL: str = "info"
    DATA_LABEL: str = "LIVE"

    # Database
    DATABASE_URL: str = (
        "postgresql+asyncpg://tiyrasense_user:tiyrasense_secure_pass_2026@localhost:5432/tiyrasense_db"
    )

    # JWT Authentication
    AUTH_SECRET_KEY: str = "tiyrasense_jwt_dev_secret_key_2026_ner_logistics"
    AUTH_ALGORITHM: str = "HS256"
    AUTH_ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    AUTH_ISSUER: str = "tiyrasense"
    AUTH_AUDIENCE: str = "tiyrasense_clients"

    # CORS
    CORS_ORIGINS: List[str] = [
        "http://localhost:5173",
        "http://localhost:3000",
        "http://127.0.0.1:5173",
        "http://127.0.0.1:3000",
    ]

    # Model Configuration
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()
