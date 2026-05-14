import json
from dataclasses import dataclass
from datetime import date, datetime, timezone
from enum import StrEnum
from typing import Any
from uuid import UUID

from pydantic import BaseModel

from app.schemas.mediator import MediatorRunStatus


_MEDIATOR_RUN_COLUMNS = (
    "id, user_id, profile_id, raw_input_id, prompt_version_id, model_name, "
    "input_context, raw_model_output, parsed_output, status, error_message, "
    "started_at, completed_at, created_at, updated_at"
)


@dataclass(frozen=True)
class MediatorRunRecord:
    id: str
    user_id: str
    profile_id: str | None
    raw_input_id: str
    prompt_version_id: str | None
    model_name: str
    input_context: dict[str, Any]
    raw_model_output: dict[str, Any] | None
    parsed_output: dict[str, Any] | None
    status: str
    error_message: str | None
    started_at: str | None
    completed_at: str | None
    created_at: str | None
    updated_at: str | None


class SupabaseMediatorRunRepository:
    def __init__(self, client: Any) -> None:
        self._client = client

    def start(
        self,
        *,
        user_id: str,
        raw_input_id: str,
        model_name: str,
        input_context: dict[str, Any],
        profile_id: str | None = None,
        prompt_version_id: str | None = None,
    ) -> MediatorRunRecord:
        payload = {
            "user_id": user_id,
            "profile_id": profile_id,
            "raw_input_id": raw_input_id,
            "prompt_version_id": prompt_version_id,
            "model_name": model_name,
            "input_context": _json_object(input_context),
            "status": MediatorRunStatus.STARTED.value,
            "error_message": None,
        }
        response = (
            self._client.table("mediator_runs")
            .insert(payload)
            .select(_MEDIATOR_RUN_COLUMNS)
            .execute()
        )
        return _map_mediator_run_row(
            _single_row(response, "Mediator run creation did not return a row.")
        )

    def get(self, *, user_id: str, run_id: str) -> MediatorRunRecord:
        response = (
            self._client.table("mediator_runs")
            .select(_MEDIATOR_RUN_COLUMNS)
            .eq("user_id", user_id)
            .eq("id", run_id)
            .limit(1)
            .execute()
        )
        return _map_mediator_run_row(
            _single_row(response, "Mediator run was not found for the given user_id.")
        )

    def mark_succeeded(
        self,
        *,
        user_id: str,
        run_id: str,
        raw_model_output: dict[str, Any],
        parsed_output: dict[str, Any],
    ) -> MediatorRunRecord:
        payload = {
            "status": MediatorRunStatus.SUCCEEDED.value,
            "raw_model_output": _json_object(raw_model_output),
            "parsed_output": _json_object(parsed_output),
            "error_message": None,
            "completed_at": _utc_now_iso(),
        }
        self._update_run(user_id=user_id, run_id=run_id, payload=payload)
        return self.get(user_id=user_id, run_id=run_id)

    def mark_failed(
        self,
        *,
        user_id: str,
        run_id: str,
        error_message: str,
        raw_model_output: dict[str, Any] | None = None,
        parsed_output: dict[str, Any] | None = None,
    ) -> MediatorRunRecord:
        payload = {
            "status": MediatorRunStatus.FAILED.value,
            "error_message": error_message.strip() or "Mediator run failed.",
            "raw_model_output": _json_object(raw_model_output)
            if raw_model_output is not None
            else None,
            "parsed_output": _json_object(parsed_output)
            if parsed_output is not None
            else None,
            "completed_at": _utc_now_iso(),
        }
        self._update_run(user_id=user_id, run_id=run_id, payload=payload)
        return self.get(user_id=user_id, run_id=run_id)

    def _update_run(
        self,
        *,
        user_id: str,
        run_id: str,
        payload: dict[str, Any],
    ) -> None:
        response = (
            self._client.table("mediator_runs")
            .update(payload)
            .eq("user_id", user_id)
            .eq("id", run_id)
            .execute()
        )
        _ensure_mutation_succeeded(
            response,
            "Mediator run update did not affect any rows.",
        )


def _json_object(value: dict[str, Any]) -> dict[str, Any]:
    normalized = json.loads(
        json.dumps(
            value,
            ensure_ascii=False,
            default=_json_default,
        )
    )
    if not isinstance(normalized, dict):
        return {"value": normalized}
    return normalized


def _json_default(value: Any) -> Any:
    if isinstance(value, BaseModel):
        return value.model_dump(mode="json")
    if isinstance(value, datetime | date):
        return value.isoformat()
    if isinstance(value, UUID):
        return str(value)
    if isinstance(value, StrEnum):
        return value.value
    return str(value)


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _single_row(response: Any, message: str) -> dict[str, Any]:
    rows = response.data or []
    if not rows:
        raise ValueError(message)
    return rows[0]


def _ensure_mutation_succeeded(response: Any, message: str) -> None:
    if getattr(response, "data", None) is None:
        return
    if isinstance(response.data, list) and response.data == []:
        raise ValueError(message)


def _optional_json_object(value: Any) -> dict[str, Any] | None:
    if value is None:
        return None
    if isinstance(value, dict):
        return value
    return {"value": value}


def _map_mediator_run_row(row: dict[str, Any]) -> MediatorRunRecord:
    return MediatorRunRecord(
        id=row["id"],
        user_id=row["user_id"],
        profile_id=row.get("profile_id"),
        raw_input_id=row["raw_input_id"],
        prompt_version_id=row.get("prompt_version_id"),
        model_name=row["model_name"],
        input_context=_json_object(row.get("input_context") or {}),
        raw_model_output=_optional_json_object(row.get("raw_model_output")),
        parsed_output=_optional_json_object(row.get("parsed_output")),
        status=row["status"],
        error_message=row.get("error_message"),
        started_at=row.get("started_at"),
        completed_at=row.get("completed_at"),
        created_at=row.get("created_at"),
        updated_at=row.get("updated_at"),
    )
