from datetime import datetime
from enum import StrEnum
from typing import Any
from uuid import UUID

from pydantic import BaseModel, Field


class FeedbackEventType(StrEnum):
    TASK_CREATED = "task_created"
    CANDIDATE_ACCEPTED = "candidate_accepted"
    CANDIDATE_EDITED = "candidate_edited"
    CANDIDATE_REJECTED = "candidate_rejected"
    TASK_COMPLETED = "task_completed"
    TASK_SNOOZED = "task_snoozed"
    TASK_OVERDUE = "task_overdue"
    REMINDER_IGNORED = "reminder_ignored"
    REMINDER_HELPFUL = "reminder_helpful"
    SUBTASK_COMPLETED = "subtask_completed"


class FeedbackEventRequest(BaseModel):
    event_type: FeedbackEventType = Field(..., description="Feedback event type.")
    task_id: UUID | None = Field(default=None, description="Related final task id.")
    candidate_id: UUID | None = Field(default=None, description="Related candidate id.")
    event_payload: dict[str, Any] = Field(default_factory=dict)


class FeedbackEventResponse(BaseModel):
    id: UUID = Field(..., description="Feedback event id.")
    user_id: UUID = Field(..., description="Authenticated Supabase user id.")
    task_id: UUID | None = Field(default=None, description="Related final task id.")
    candidate_id: UUID | None = Field(default=None, description="Related candidate id.")
    event_type: FeedbackEventType = Field(..., description="Feedback event type.")
    event_payload: dict[str, Any] = Field(default_factory=dict)
    created_at: datetime = Field(..., description="Event creation timestamp.")
