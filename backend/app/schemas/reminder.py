from datetime import datetime
from enum import StrEnum
from uuid import UUID

from pydantic import BaseModel, Field


class ReminderType(StrEnum):
    START = "start"
    DEADLINE = "deadline"
    NUDGE = "nudge"
    REPLAN = "replan"


class ReminderStatus(StrEnum):
    SCHEDULED = "scheduled"
    SENT = "sent"
    SNOOZED = "snoozed"
    CANCELLED = "cancelled"


class ReminderResponse(BaseModel):
    id: UUID = Field(..., description="Final reminder id.")
    user_id: UUID = Field(..., description="Authenticated Supabase user id.")
    task_id: UUID = Field(..., description="Final task id this reminder belongs to.")
    candidate_reminder_id: UUID | None = Field(
        default=None,
        description="Candidate reminder id this final reminder was committed from.",
    )
    remind_at: datetime = Field(..., description="Scheduled reminder timestamp.")
    message: str = Field(..., min_length=1, description="Reminder message shown to the user.")
    type: ReminderType = Field(default=ReminderType.START, description="Reminder type.")
    status: ReminderStatus = Field(
        default=ReminderStatus.SCHEDULED,
        description="Reminder dispatch status.",
    )
    escalation_level: int = Field(default=0, ge=0, description="Escalation level for repeated nudges.")
    created_at: datetime | None = Field(default=None, description="Creation timestamp.")
    updated_at: datetime | None = Field(default=None, description="Last update timestamp.")
    sent_at: datetime | None = Field(default=None, description="Dispatch timestamp when sent.")
