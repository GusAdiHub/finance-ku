"""Core configuration module."""
from typing import Optional
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import computed_field


class Settings(BaseSettings):
    """Application settings and database configuration."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    APP_ENV: str = "development"
    APP_NAME: str = "Personal & Family Finance Tracker"
    DEBUG: bool = True
    API_V1_PREFIX: str = "/api/v1"

    # Database settings
    DB_HOST: str = "localhost"
    DB_PORT: int = 5432
    DB_USER: str = "postgres"
    DB_PASSWORD: str = ""
    DB_NAME: str = "finance_tracker"
    DATABASE_URL: Optional[str] = None

    # Security settings
    SECRET_KEY: str = "change_this_to_a_super_secret_key_in_production"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 1 day
    JWT_ALGORITHM: str = "HS256"

    # CORS settings
    CORS_ORIGINS: list[str] = [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
    ]

    # Storage settings
    UPLOAD_DIR: str = "private_uploads"
    MAX_UPLOAD_SIZE_MB: int = 10

    # OCR settings
    TESSERACT_CMD: Optional[str] = None

    @computed_field
    def sync_database_url(self) -> str:
        """Returns the synchronized SQLAlchemy PostgreSQL database URL."""
        if self.DATABASE_URL:
            # Ensure psycopg driver is specified if a raw postgresql:// is provided
            if self.DATABASE_URL.startswith("postgresql://"):
                return self.DATABASE_URL.replace("postgresql://", "postgresql+psycopg://", 1)
            return self.DATABASE_URL
        # Build URL from individual components
        if self.DB_PASSWORD:
            return (
                f"postgresql+psycopg://{self.DB_USER}:{self.DB_PASSWORD}@"
                f"{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"
            )
        return (
            f"postgresql+psycopg://{self.DB_USER}@"
            f"{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"
        )


settings = Settings()
