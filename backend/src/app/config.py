from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_env: str = "dev"
    log_level: str = "INFO"

    # SQLite by default — zero-setup. Switch to Postgres by overriding DATABASE_URL.
    database_url: str = "sqlite+aiosqlite:///./learning_os.db"

    # LLM backend: "ollama" (local, default) | "anthropic"
    llm_backend: str = "ollama"

    # Ollama — works for both local (http://localhost:11434, no key) and
    # Ollama Cloud (https://ollama.com, requires OLLAMA_API_KEY).
    ollama_base_url: str = "http://localhost:11434"
    ollama_model: str = "qwen2.5:7b"
    ollama_api_key: str = ""
    ollama_timeout_s: int = 120

    # Anthropic (cloud)
    anthropic_api_key: str = ""
    anthropic_model: str = "claude-sonnet-4-6"

    daily_token_budget_per_user: int = 20_000

    knowledge_path: Path = Path("../knowledge/nodes")

    jwt_secret: str = "change-me-in-prod"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 10080


@lru_cache
def get_settings() -> Settings:
    return Settings()
