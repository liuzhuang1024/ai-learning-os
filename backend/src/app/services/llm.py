"""Thin LLM client abstraction.

Single entry point so we can: (a) swap models, (b) add caching, (c) meter
tokens per user against the daily budget, (d) fall back to Qwen on Anthropic
errors or budget overruns.

For v0 this is a stub that wraps Anthropic only. Token metering and Qwen
fallback are TODOs — kept as explicit hooks so the call sites don't change.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass

from anthropic import AsyncAnthropic

from app.config import get_settings

log = logging.getLogger(__name__)


@dataclass
class LLMResponse:
    text: str
    input_tokens: int
    output_tokens: int
    model: str


class LLMClient:
    def __init__(self) -> None:
        self.settings = get_settings()
        self._anthropic: AsyncAnthropic | None = None
        if self.settings.anthropic_api_key:
            self._anthropic = AsyncAnthropic(api_key=self.settings.anthropic_api_key)

    async def complete(
        self,
        system: str,
        messages: list[dict],
        max_tokens: int = 1024,
        user_id: str | None = None,
    ) -> LLMResponse:
        """One-shot completion. `messages` is the Anthropic message format."""
        # TODO: check user_id token budget before calling; fall back to Qwen if exceeded.
        if not self._anthropic:
            # Dev mode fallback so the server runs without an API key.
            log.warning("ANTHROPIC_API_KEY not set; returning canned response")
            return LLMResponse(
                text="[dev stub] ANTHROPIC_API_KEY not configured.",
                input_tokens=0,
                output_tokens=0,
                model="stub",
            )

        resp = await self._anthropic.messages.create(
            model=self.settings.anthropic_model,
            system=system,
            messages=messages,
            max_tokens=max_tokens,
        )
        text = "".join(block.text for block in resp.content if block.type == "text")
        return LLMResponse(
            text=text,
            input_tokens=resp.usage.input_tokens,
            output_tokens=resp.usage.output_tokens,
            model=self.settings.anthropic_model,
        )


_client: LLMClient | None = None


def get_llm() -> LLMClient:
    global _client
    if _client is None:
        _client = LLMClient()
    return _client
