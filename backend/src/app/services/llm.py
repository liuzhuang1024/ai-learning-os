"""LLM client abstraction.

Single entry point so we can: (a) swap backends, (b) add caching, (c) meter
tokens per user against the daily budget.

Backends:
- `ollama` (default): local, free, slower. Uses /api/chat. No API key needed.
- `anthropic`: cloud, fast, costs $$. Used when llm_backend=anthropic.

The call signature is the same for both. Token counts are best-effort:
Ollama reports prompt_eval_count / eval_count; Anthropic reports usage.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass

import httpx

from app.config import get_settings

log = logging.getLogger(__name__)


@dataclass
class LLMResponse:
    text: str
    input_tokens: int
    output_tokens: int
    model: str


class _OllamaBackend:
    """Works for both local Ollama and Ollama Cloud (same /api/chat protocol).

    Cloud usage: set OLLAMA_BASE_URL=https://ollama.com and OLLAMA_API_KEY=...
    Local usage: leave defaults, no key needed.
    """

    def __init__(self, base_url: str, model: str, timeout_s: int, api_key: str = "") -> None:
        self.base_url = base_url.rstrip("/")
        self.model = model
        self.timeout = timeout_s
        self.headers = {"Authorization": f"Bearer {api_key}"} if api_key else {}

    async def complete(
        self, system: str, messages: list[dict], max_tokens: int
    ) -> LLMResponse:
        payload = {
            "model": self.model,
            "messages": [{"role": "system", "content": system}, *messages],
            "stream": False,
            "options": {"num_predict": max_tokens},
        }
        async with httpx.AsyncClient(timeout=self.timeout, headers=self.headers) as client:
            resp = await client.post(f"{self.base_url}/api/chat", json=payload)
            resp.raise_for_status()
            data = resp.json()

        return LLMResponse(
            text=data["message"]["content"],
            input_tokens=data.get("prompt_eval_count", 0),
            output_tokens=data.get("eval_count", 0),
            model=self.model,
        )


class _AnthropicBackend:
    def __init__(self, api_key: str, model: str) -> None:
        # Lazy import so projects running ollama-only don't pay the import cost.
        from anthropic import AsyncAnthropic

        self.client = AsyncAnthropic(api_key=api_key)
        self.model = model

    async def complete(
        self, system: str, messages: list[dict], max_tokens: int
    ) -> LLMResponse:
        resp = await self.client.messages.create(
            model=self.model,
            system=system,
            messages=messages,
            max_tokens=max_tokens,
        )
        text = "".join(block.text for block in resp.content if block.type == "text")
        return LLMResponse(
            text=text,
            input_tokens=resp.usage.input_tokens,
            output_tokens=resp.usage.output_tokens,
            model=self.model,
        )


class LLMClient:
    def __init__(self) -> None:
        self.settings = get_settings()
        backend_name = self.settings.llm_backend.lower()

        if backend_name == "ollama":
            self.backend = _OllamaBackend(
                self.settings.ollama_base_url,
                self.settings.ollama_model,
                self.settings.ollama_timeout_s,
                self.settings.ollama_api_key,
            )
            mode = "cloud" if self.settings.ollama_api_key else "local"
            log.info("LLM backend: ollama-%s (%s @ %s)", mode, self.settings.ollama_model, self.settings.ollama_base_url)
        elif backend_name == "anthropic":
            if not self.settings.anthropic_api_key:
                raise RuntimeError("llm_backend=anthropic but ANTHROPIC_API_KEY is empty")
            self.backend = _AnthropicBackend(
                self.settings.anthropic_api_key, self.settings.anthropic_model
            )
            log.info("LLM backend: anthropic (%s)", self.settings.anthropic_model)
        else:
            raise ValueError(f"unknown llm_backend: {backend_name!r}")

    async def complete(
        self,
        system: str,
        messages: list[dict],
        max_tokens: int = 1024,
        user_id: str | None = None,
    ) -> LLMResponse:
        # TODO: per-user daily token budget check using user_id.
        return await self.backend.complete(system, messages, max_tokens)


_client: LLMClient | None = None


def get_llm() -> LLMClient:
    global _client
    if _client is None:
        _client = LLMClient()
    return _client
