import json
from dataclasses import dataclass
from datetime import date, datetime
from enum import StrEnum
from typing import Any
from uuid import UUID

from pydantic import BaseModel

from app.schemas.task_candidate import (
    TaskCandidateResponse,
    TaskCandidateRevisionType,
    TaskCandidateStatus,
    TaskDifficulty,
    TaskEnergyRequired,
    TaskPriority,
)


_EDITABLE_CANDIDATE_FIELDS = {
    "title",
    "description",
    "due_at",
    "priority",
    "estimated_minutes",
    "energy_required",
    "difficulty",
    "next_action",
    "recommended_today",
    "today_reason",
    "overload_warning",
}
_REVISABLE_STATUSES = {
    TaskCandidateStatus.DRAFT.value,
    TaskCandidateStatus.ACCEPTED.value,
    TaskCandidateStatus.EDITED.value,
}
_REJECTABLE_STATUSES = {
    TaskCandidateStatus.DRAFT.value,
    TaskCandidateStatus.ACCEPTED.value,
    TaskCandidateStatus.EDITED.value,
    TaskCandidateStatus.REJECTED.value,
}
_PRIORITY_VALUES = {item.value for item in TaskPriority}
_ENERGY_VALUES = {item.value for item in TaskEnergyRequired}
_DIFFICULTY_VALUES = {item.value for item in TaskDifficulty}
_REVISION_TYPE_VALUES = {item.value for item in TaskCandidateRevisionType}


@dataclass(frozen=True)
class TaskCandidateReviewError(Exception):
    code: str
    message: str

    def __str__(self) -> str:
        return self.message


class TaskCandidateReviewService:
    def __init__(self, *, task_candidate_repository: Any) -> None:
        self._task_candidate_repository = task_candidate_repository

    def revise_candidate(
        self,
        *,
        user_id: str,
        candidate_id: str,
        revision_type: TaskCandidateRevisionType | str,
        edited_fields: dict[str, Any] | None = None,
        note: str | None = None,
    ) -> TaskCandidateResponse:
        candidate = self._get_candidate(user_id=user_id, candidate_id=candidate_id)
        self._ensure_revisable(candidate)

        revision_type_value = _revision_type_value(revision_type)
        edits = _validated_edited_fields(edited_fields or {})
        if revision_type_value == TaskCandidateRevisionType.MANUAL_EDIT.value and not edits:
            raise TaskCandidateReviewError(
                "invalid_candidate_revision",
                "manual_edit revision requires at least one edited field.",
            )

        model_payload = _with_review_metadata(
            candidate.model_payload,
            action="revise",
            revision_type=revision_type_value,
            edited_fields=edits,
            note=note,
        )
        return self._update_candidate(
            user_id=user_id,
            candidate_id=str(candidate.id),
            fields={
                **edits,
                "status": TaskCandidateStatus.EDITED.value,
            },
            model_payload=model_payload,
        )

    def reject_candidate(
        self,
        *,
        user_id: str,
        candidate_id: str,
        reason: str | None = None,
    ) -> TaskCandidateResponse:
        candidate = self._get_candidate(user_id=user_id, candidate_id=candidate_id)
        self._ensure_rejectable(candidate)

        model_payload = _with_review_metadata(
            candidate.model_payload,
            action="reject",
            reason=reason,
        )
        return self._update_candidate(
            user_id=user_id,
            candidate_id=str(candidate.id),
            fields={"status": TaskCandidateStatus.REJECTED.value},
            model_payload=model_payload,
        )

    def _get_candidate(self, *, user_id: str, candidate_id: str) -> TaskCandidateResponse:
        try:
            return self._task_candidate_repository.get(
                user_id=user_id,
                candidate_id=candidate_id,
            )
        except ValueError as error:
            raise TaskCandidateReviewError(
                "candidate_not_found",
                "Task candidate was not found.",
            ) from error

    def _update_candidate(
        self,
        *,
        user_id: str,
        candidate_id: str,
        fields: dict[str, Any],
        model_payload: dict[str, Any],
    ) -> TaskCandidateResponse:
        try:
            return self._task_candidate_repository.update_candidate(
                user_id=user_id,
                candidate_id=candidate_id,
                fields=fields,
                model_payload=model_payload,
            )
        except ValueError as error:
            raise TaskCandidateReviewError(
                "candidate_not_found",
                "Task candidate was not found.",
            ) from error

    def _ensure_revisable(self, candidate: TaskCandidateResponse) -> None:
        candidate_status = _enum_value(candidate.status)
        if candidate_status == TaskCandidateStatus.COMMITTED.value:
            raise TaskCandidateReviewError(
                "candidate_already_committed",
                "Committed task candidates cannot be revised.",
            )
        if candidate_status not in _REVISABLE_STATUSES:
            raise TaskCandidateReviewError(
                "candidate_not_revisable",
                f"Task candidate with status '{candidate_status}' cannot be revised.",
            )

    def _ensure_rejectable(self, candidate: TaskCandidateResponse) -> None:
        candidate_status = _enum_value(candidate.status)
        if candidate_status == TaskCandidateStatus.COMMITTED.value:
            raise TaskCandidateReviewError(
                "candidate_already_committed",
                "Committed task candidates cannot be rejected.",
            )
        if candidate_status not in _REJECTABLE_STATUSES:
            raise TaskCandidateReviewError(
                "candidate_not_rejectable",
                f"Task candidate with status '{candidate_status}' cannot be rejected.",
            )


def _validated_edited_fields(edited_fields: dict[str, Any]) -> dict[str, Any]:
    unknown_fields = set(edited_fields) - _EDITABLE_CANDIDATE_FIELDS
    if unknown_fields:
        raise TaskCandidateReviewError(
            "invalid_edited_fields",
            f"Unsupported edited field(s): {', '.join(sorted(unknown_fields))}.",
        )

    return {
        key: _validated_field_value(key, value)
        for key, value in edited_fields.items()
    }


def _validated_field_value(key: str, value: Any) -> Any:
    if key == "title":
        cleaned = _required_text(value, "Candidate title must not be empty.")
        if len(cleaned) > 200:
            raise TaskCandidateReviewError(
                "invalid_edited_fields",
                "Candidate title must be 200 characters or fewer.",
            )
        return cleaned
    if key in {"description", "next_action", "today_reason", "overload_warning"}:
        return _optional_text(value)
    if key == "priority":
        return _optional_enum_value(value, _PRIORITY_VALUES, key)
    if key == "energy_required":
        return _optional_enum_value(value, _ENERGY_VALUES, key)
    if key == "difficulty":
        return _optional_enum_value(value, _DIFFICULTY_VALUES, key)
    if key == "estimated_minutes":
        return _optional_non_negative_int(value, key)
    if key == "recommended_today":
        if not isinstance(value, bool):
            raise TaskCandidateReviewError(
                "invalid_edited_fields",
                "recommended_today must be a boolean.",
            )
        return value
    if key == "due_at":
        return _optional_datetime_value(value, key)
    return value


def _required_text(value: Any, message: str) -> str:
    if not isinstance(value, str):
        raise TaskCandidateReviewError("invalid_edited_fields", message)
    cleaned = value.strip()
    if not cleaned:
        raise TaskCandidateReviewError("invalid_edited_fields", message)
    return cleaned


def _optional_text(value: Any) -> str | None:
    if value is None:
        return None
    if not isinstance(value, str):
        raise TaskCandidateReviewError(
            "invalid_edited_fields",
            "Text fields must be strings.",
        )
    cleaned = value.strip()
    return cleaned or None


def _optional_enum_value(
    value: Any,
    allowed_values: set[str],
    field_name: str,
) -> str | None:
    if value is None:
        return None
    enum_value = _enum_value(value)
    if enum_value not in allowed_values:
        raise TaskCandidateReviewError(
            "invalid_edited_fields",
            f"{field_name} must be one of: {', '.join(sorted(allowed_values))}.",
        )
    return enum_value


def _optional_non_negative_int(value: Any, field_name: str) -> int | None:
    if value is None:
        return None
    if isinstance(value, bool) or not isinstance(value, int):
        raise TaskCandidateReviewError(
            "invalid_edited_fields",
            f"{field_name} must be a non-negative integer.",
        )
    if value < 0:
        raise TaskCandidateReviewError(
            "invalid_edited_fields",
            f"{field_name} must be a non-negative integer.",
        )
    return value


def _optional_datetime_value(value: Any, field_name: str) -> str | None:
    if value is None:
        return None
    if isinstance(value, datetime | date):
        return value.isoformat()
    if isinstance(value, str):
        cleaned = value.strip()
        return cleaned or None
    raise TaskCandidateReviewError(
        "invalid_edited_fields",
        f"{field_name} must be an ISO datetime string or null.",
    )


def _revision_type_value(value: TaskCandidateRevisionType | str) -> str:
    revision_type = _enum_value(value)
    if revision_type not in _REVISION_TYPE_VALUES:
        raise TaskCandidateReviewError(
            "invalid_candidate_revision",
            f"Unsupported revision type: {revision_type}.",
        )
    return revision_type


def _with_review_metadata(
    model_payload: dict[str, Any],
    *,
    action: str,
    revision_type: str | None = None,
    edited_fields: dict[str, Any] | None = None,
    note: str | None = None,
    reason: str | None = None,
) -> dict[str, Any]:
    payload = _json_object(model_payload)
    review = {"last_action": action}
    if revision_type is not None:
        review["revision_type"] = revision_type
    if edited_fields:
        review["edited_fields"] = _json_object(edited_fields)
    cleaned_note = _optional_review_text(note)
    if cleaned_note is not None:
        review["note"] = cleaned_note
    cleaned_reason = _optional_review_text(reason)
    if cleaned_reason is not None:
        review["reason"] = cleaned_reason
    payload["review"] = review
    return payload


def _optional_review_text(value: str | None) -> str | None:
    if value is None:
        return None
    cleaned = value.strip()
    return cleaned or None


def _enum_value(value: StrEnum | str | None) -> str | None:
    if value is None:
        return None
    if isinstance(value, StrEnum):
        return value.value
    return value


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
