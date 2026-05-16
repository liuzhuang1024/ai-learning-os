from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_env: str = "dev"
    log_level: str = "INFO"

    database_url: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/learning_os"

    anthropic_api_key: str = ""
    anthropic_model: str = "claude-sonnet-4-6"
    qwen_api_key: str = ""
    qwen_model: str = "qwen-plus"

    daily_token_budget_per_user: int = 20_000

    knowledge_path: Path = Path("../knowledge/nodes")

    jwt_secret: str = "change-me-in-prod"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 10080


@lru_cache
def get_settings() -> Settings:
    return Settings()
