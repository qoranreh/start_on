import json
from datetime import date, datetime
from enum import StrEnum
from typing import Any
from uuid import UUID

from pydantic import BaseModel

from app.schemas.mediator import MediatorOutput
from app.schemas.task_candidate import (
    CandidateReminderResponse,
    CandidateSubtaskResponse,
    TaskCandidateResponse,
    TaskCandidateStatus,
)


_TASK_CANDIDATE_COLUMNS = (
    "id, user_id, profile_id, raw_input_id, mediator_run_id, title, description, "
    "due_at, priority, estimated_minutes, energy_required, difficulty, next_action, "
    "recommended_today, today_reason, overload_warning, confidence, status, "
    "model_payload, created_at, updated_at"
)
_CANDIDATE_SUBTASK_COLUMNS = (
    "id, candidate_id, user_id, title, order_index, estimated_minutes, "
    "is_next_action, energy_required, created_at, updated_at"
)
_CANDIDATE_REMINDER_COLUMNS = (
    "id, candidate_id, user_id, remind_at, message, type, escalation_level, "
    "created_at, updated_at"
)
_ALLOWED_CANDIDATE_STATUSES = {status.value for status in TaskCandidateStatus}


class SupabaseTaskCandidateRepository:
    def __init__(self, client: Any) -> None:
        self._client = client

    def create_from_mediator_output(
        self,
        *,
        user_id: str,
        raw_input_id: str,
        mediator_run_id: str | None,
        output: MediatorOutput,
        profile_id: str | None = None,
    ) -> TaskCandidateResponse:
        title = output.task_title.strip()
        if not title:
            raise ValueError("Candidate title must not be empty.")

        today_reasons = [reason.strip() for reason in output.recommended_today if reason.strip()]
        candidate_payload = {
            "user_id": user_id,
            "profile_id": profile_id,
            "raw_input_id": raw_input_id,
            "mediator_run_id": mediator_run_id,
            "title": title,
            "description": _optional_text(output.description),
            "due_at": _datetime_value(output.due_at),
            "priority": _enum_value(output.priority),
            "estimated_minutes": output.estimated_minutes,
            "energy_required": _enum_value(output.energy_required),
            "difficulty": _enum_value(output.difficulty),
            "next_action": _optional_text(output.next_action),
            "recommended_today": bool(today_reasons),
            "today_reason": "\n".join(today_reasons) if today_reasons else None,
            "overload_warning": _optional_text(output.overload_warning),
            "confidence": output.confidence,
            "status": TaskCandidateStatus.DRAFT.value,
            "model_payload": _json_object(output.model_dump(mode="json")),
        }
        response = (
            self._client.table("task_candidates")
            .insert(candidate_payload)
            .select(_TASK_CANDIDATE_COLUMNS)
            .execute()
        )
        candidate_row = _single_row(
            response,
            "Task candidate creation did not return a row.",
        )
        candidate_id = candidate_row["id"]

        subtask_rows = self._create_subtasks(
            user_id=user_id,
            candidate_id=candidate_id,
            output=output,
        )
        reminder_rows = self._create_reminders(
            user_id=user_id,
            candidate_id=candidate_id,
            output=output,
        )

        return _map_task_candidate_response(
            candidate_row,
            subtask_rows=subtask_rows,
            reminder_rows=reminder_rows,
        )

    def get(self, *, user_id: str, candidate_id: str) -> TaskCandidateResponse:
        candidate_response = (
            self._client.table("task_candidates")
            .select(_TASK_CANDIDATE_COLUMNS)
            .eq("user_id", user_id)
            .eq("id", candidate_id)
            .limit(1)
            .execute()
        )
        candidate_row = _single_row(
            candidate_response,
            "Task candidate was not found for the given user_id.",
        )
        subtask_rows = self._list_subtasks(
            user_id=user_id,
            candidate_id=candidate_id,
        )
        reminder_rows = self._list_reminders(
            user_id=user_id,
            candidate_id=candidate_id,
        )
        return _map_task_candidate_response(
            candidate_row,
            subtask_rows=subtask_rows,
            reminder_rows=reminder_rows,
        )

    def update_status(
        self,
        *,
        user_id: str,
        candidate_id: str,
        status: TaskCandidateStatus | str,
    ) -> TaskCandidateResponse:
        status_value = _candidate_status_value(status)
        response = (
            self._client.table("task_candidates")
            .update({"status": status_value})
            .eq("user_id", user_id)
            .eq("id", candidate_id)
            .execute()
        )
        _ensure_mutation_succeeded(
            response,
            "Task candidate status update did not affect any rows.",
        )
        return self.get(user_id=user_id, candidate_id=candidate_id)

    def mark_accepted(self, *, user_id: str, candidate_id: str) -> TaskCandidateResponse:
        return self.update_status(
            user_id=user_id,
            candidate_id=candidate_id,
            status=TaskCandidateStatus.ACCEPTED,
        )

    def mark_edited(self, *, user_id: str, candidate_id: str) -> TaskCandidateResponse:
        return self.update_status(
            user_id=user_id,
            candidate_id=candidate_id,
            status=TaskCandidateStatus.EDITED,
        )

    def mark_rejected(self, *, user_id: str, candidate_id: str) -> TaskCandidateResponse:
        return self.update_status(
            user_id=user_id,
            candidate_id=candidate_id,
            status=TaskCandidateStatus.REJECTED,
        )

    def mark_committed(self, *, user_id: str, candidate_id: str) -> TaskCandidateResponse:
        return self.update_status(
            user_id=user_id,
            candidate_id=candidate_id,
            status=TaskCandidateStatus.COMMITTED,
        )

    def _create_subtasks(
        self,
        *,
        user_id: str,
        candidate_id: str,
        output: MediatorOutput,
    ) -> list[dict[str, Any]]:
        payloads = []
        for index, subtask in enumerate(output.subtasks):
            title = subtask.title.strip()
            if not title:
                raise ValueError("Candidate subtask title must not be empty.")
            payloads.append(
                {
                    "candidate_id": candidate_id,
                    "user_id": user_id,
                    "title": title,
                    "order_index": index,
                    "estimated_minutes": subtask.estimated_minutes,
                    "is_next_action": subtask.is_next_action,
                    "energy_required": _enum_value(subtask.energy_required),
                }
            )

        if not payloads:
            return []

        response = (
            self._client.table("candidate_subtasks")
            .insert(payloads)
            .select(_CANDIDATE_SUBTASK_COLUMNS)
            .execute()
        )
        return response.data or []

    def _create_reminders(
        self,
        *,
        user_id: str,
        candidate_id: str,
        output: MediatorOutput,
    ) -> list[dict[str, Any]]:
        payloads = []
        for reminder in output.reminders:
            message = reminder.message.strip()
            if not message:
                raise ValueError("Candidate reminder message must not be empty.")
            payloads.append(
                {
                    "candidate_id": candidate_id,
                    "user_id": user_id,
                    "remind_at": _datetime_value(reminder.remind_at),
                    "message": message,
                    "type": _enum_value(reminder.type),
                    "escalation_level": 0,
                }
            )

        if not payloads:
            return []

        response = (
            self._client.table("candidate_reminders")
            .insert(payloads)
            .select(_CANDIDATE_REMINDER_COLUMNS)
            .execute()
        )
        return _sort_reminder_rows(response.data or [])

    def _list_subtasks(self, *, user_id: str, candidate_id: str) -> list[dict[str, Any]]:
        response = (
            self._client.table("candidate_subtasks")
            .select(_CANDIDATE_SUBTASK_COLUMNS)
            .eq("user_id", user_id)
            .eq("candidate_id", candidate_id)
            .order("order_index")
            .execute()
        )
        return response.data or []

    def _list_reminders(self, *, user_id: str, candidate_id: str) -> list[dict[str, Any]]:
        response = (
            self._client.table("candidate_reminders")
            .select(_CANDIDATE_REMINDER_COLUMNS)
            .eq("user_id", user_id)
            .eq("candidate_id", candidate_id)
            .order("remind_at")
            .execute()
        )
        return _sort_reminder_rows(response.data or [])


def _map_task_candidate_response(
    row: dict[str, Any],
    *,
    subtask_rows: list[dict[str, Any]],
    reminder_rows: list[dict[str, Any]],
) -> TaskCandidateResponse:
    return TaskCandidateResponse(
        id=row["id"],
        user_id=row["user_id"],
        raw_input_id=row["raw_input_id"],
        mediator_run_id=row.get("mediator_run_id"),
        title=row["title"],
        description=row.get("description"),
        due_at=row.get("due_at"),
        priority=row.get("priority"),
        estimated_minutes=row.get("estimated_minutes"),
        energy_required=row.get("energy_required"),
        difficulty=row.get("difficulty"),
        next_action=row.get("next_action"),
        recommended_today=row.get("recommended_today") or False,
        today_reason=row.get("today_reason"),
        overload_warning=row.get("overload_warning"),
        confidence=_optional_float(row.get("confidence")),
        status=row.get("status") or TaskCandidateStatus.DRAFT.value,
        model_payload=_json_object(row.get("model_payload") or {}),
        subtasks=[_map_candidate_subtask_response(item) for item in subtask_rows],
        reminders=[_map_candidate_reminder_response(item) for item in reminder_rows],
        created_at=row.get("created_at"),
        updated_at=row.get("updated_at"),
    )


def _map_candidate_subtask_response(row: dict[str, Any]) -> CandidateSubtaskResponse:
    return CandidateSubtaskResponse(
        id=row["id"],
        candidate_id=row["candidate_id"],
        title=row["title"],
        order_index=row["order_index"],
        estimated_minutes=row.get("estimated_minutes"),
        is_next_action=row.get("is_next_action") or False,
        energy_required=row.get("energy_required"),
        created_at=row.get("created_at"),
        updated_at=row.get("updated_at"),
    )


def _map_candidate_reminder_response(row: dict[str, Any]) -> CandidateReminderResponse:
    return CandidateReminderResponse(
        id=row["id"],
        candidate_id=row["candidate_id"],
        remind_at=row.get("remind_at"),
        message=row["message"],
        type=row.get("type") or "start",
        escalation_level=row.get("escalation_level") or 0,
        created_at=row.get("created_at"),
        updated_at=row.get("updated_at"),
    )


def _candidate_status_value(status: TaskCandidateStatus | str) -> str:
    value = _enum_value(status)
    if value not in _ALLOWED_CANDIDATE_STATUSES:
        raise ValueError(f"Unsupported task candidate status: {value}")
    return value


def _enum_value(value: StrEnum | str | None) -> str | None:
    if value is None:
        return None
    if isinstance(value, StrEnum):
        return value.value
    return value


def _datetime_value(value: datetime | None) -> str | None:
    if value is None:
        return None
    return value.isoformat()


def _optional_text(value: str | None) -> str | None:
    if value is None:
        return None
    cleaned = value.strip()
    return cleaned or None


def _optional_float(value: Any) -> float | None:
    if value is None:
        return None
    return float(value)


def _json_object(value: Any) -> dict[str, Any]:
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


def _sort_reminder_rows(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return sorted(
        rows,
        key=lambda row: (
            row.get("remind_at") is None,
            row.get("remind_at") or "",
        ),
    )
