from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Konfigurācija no vides mainīgajiem (K3, 4. sadaļa: atslēgas tikai vidē)."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "sqlite:///./kopsumma.db"
    jwt_secret: str = Field(min_length=32)  # tikai no vides (JWT_SECRET)
    access_token_minutes: int = 15
    refresh_token_days: int = 30
    upload_dir: str = "./uploads"
    max_upload_bytes: int = 10 * 1024 * 1024
    max_failed_logins: int = 5
    lockout_minutes: int = 15


@lru_cache
def get_settings() -> Settings:
    return Settings()
