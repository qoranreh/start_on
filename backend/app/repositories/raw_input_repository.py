from dataclasses import dataclass
from enum import StrEnum
from typing import Any

from app.schemas.task import TaskSource
from app.schemas.task_intake import RawTaskInputStatus


_RAW_INPUT_COLUMNS = (
    "id, user_id, profile_id, raw_text, source, status, client_timezone, "
    "client_metadata, error_message, created_at, updated_at"
)
_ALLOWED_RAW_INPUT_SOURCES = {
    TaskSource.MANUAL.value,
    TaskSource.OCR.value,
    TaskSource.NOTION.value,
    TaskSource.VOICE.value,
    TaskSource.EMAIL.value,
}


@dataclass(frozen=True)
class RawTaskInputRecord:
    id: str
    user_id: str
    profile_id: str | None
    raw_text: str
    source: str
    status: str
    client_timezone: str | None
    client_metadata: dict[str, Any]
    error_message: str | None
    created_at: str | None
    updated_at: str | None


class SupabaseRawInputRepository:
    def __init__(self, client: Any) -> None:
        self._client = client

    def create(
        self,
        *,
        user_id: str,
        raw_text: str,
        source: TaskSource | str = TaskSource.MANUAL,
        client_timezone: str | None = None,
        client_metadata: dict[str, Any] | None = None,
    ) -> RawTaskInputRecord:
        cleaned_text = raw_text.strip()
        if not cleaned_text:
            raise ValueError("raw_text must not be empty.")

        source_value = _source_value(source)
        payload = {
            "user_id": user_id,
            "raw_text": cleaned_text,
            "source": source_value,
            "status": RawTaskInputStatus.RECEIVED.value,
            "client_timezone": client_timezone,
            "client_metadata": client_metadata or {},
        }
        response = (
            self._client.table("raw_task_inputs")
            .insert(payload)
            .select(_RAW_INPUT_COLUMNS)
            .execute()
        )
        return _map_raw_task_input_row(
            _single_row(response, "Raw task input creation did not return a row.")
        )

    def get(self, *, user_id: str, raw_input_id: str) -> RawTaskInputRecord:
        response = (
            self._client.table("raw_task_inputs")
            .select(_RAW_INPUT_COLUMNS)
            .eq("user_id", user_id)
            .eq("id", raw_input_id)
            .limit(1)
            .execute()
        )
        return _map_raw_task_input_row(
            _single_row(response, "Raw task input was not found for the given user_id.")
        )

    def update_status(
        self,
        *,
        user_id: str,
        raw_input_id: str,
        status: RawTaskInputStatus | str,
        error_message: str | None = None,
    ) -> RawTaskInputRecord:
        payload = {
            "status": _enum_value(status),
            "error_message": error_message,
        }
        response = (
            self._client.table("raw_task_inputs")
            .update(payload)
            .eq("user_id", user_id)
            .eq("id", raw_input_id)
            .execute()
        )
        _ensure_mutation_succeeded(
            response,
            "Raw task input status update did not affect any rows.",
        )
        return self.get(user_id=user_id, raw_input_id=raw_input_id)


def _source_value(source: TaskSource | str) -> str:
    value = _enum_value(source)
    if value not in _ALLOWED_RAW_INPUT_SOURCES:
        raise ValueError(f"Unsupported raw task input source: {value}")
    return value


def _enum_value(value: StrEnum | str) -> str:
    if isinstance(value, StrEnum):
        return value.value
    return value


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


def _map_raw_task_input_row(row: dict[str, Any]) -> RawTaskInputRecord:
    client_metadata = row.get("client_metadata") or {}
    if not isinstance(client_metadata, dict):
        client_metadata = {"value": client_metadata}

    return RawTaskInputRecord(
        id=row["id"],
        user_id=row["user_id"],
        profile_id=row.get("profile_id"),
        raw_text=row["raw_text"],
        source=row["source"],
        status=row["status"],
        client_timezone=row.get("client_timezone"),
        client_metadata=client_metadata,
        error_message=row.get("error_message"),
        created_at=row.get("created_at"),
        updated_at=row.get("updated_at"),
    )
