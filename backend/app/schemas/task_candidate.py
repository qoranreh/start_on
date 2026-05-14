from datetime import datetime
from enum import StrEnum
from typing import Any
from uuid import UUID

from pydantic import BaseModel, Field

from app.schemas.reminder import ReminderType


class TaskPriority(StrEnum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class TaskEnergyRequired(StrEnum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class TaskDifficulty(StrEnum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class TaskCandidateStatus(StrEnum):
    DRAFT = "draft"
    ACCEPTED = "accepted"
    EDITED = "edited"
    REJECTED = "rejected"
    COMMITTED = "committed"


class CandidateSubtaskResponse(BaseModel):
    id: UUID = Field(..., description="Candidate subtask id.")
    candidate_id: UUID = Field(..., description="Parent candidate id.")
    title: str = Field(..., min_length=1, max_length=200, description="Suggested subtask title.")
    order_index: int = Field(..., ge=0, description="Sort order inside the candidate.")
    estimated_minutes: int | None = Field(
        default=None,
        ge=0,
        description="Estimated minutes for this subtask.",
    )
    is_next_action: bool = Field(
        default=False,
        description="Whether this subtask is the smallest immediate next action.",
    )
    energy_required: TaskEnergyRequired | None = Field(
        default=None,
        description="Estimated energy required.",
    )
    created_at: datetime | None = Field(default=None, description="Creation timestamp.")
    updated_at: datetime | None = Field(default=None, description="Last update timestamp.")


class CandidateReminderResponse(BaseModel):
    id: UUID = Field(..., description="Candidate reminder id.")
    candidate_id: UUID = Field(..., description="Parent candidate id.")
    remind_at: datetime | None = Field(default=None, description="Suggested reminder time.")
    message: str = Field(..., min_length=1, description="Suggested reminder message.")
    type: ReminderType = Field(default=ReminderType.START, description="Reminder type.")
    escalation_level: int = Field(default=0, ge=0, description="Escalation level for repeated nudges.")
    created_at: datetime | None = Field(default=None, description="Creation timestamp.")
    updated_at: datetime | None = Field(default=None, description="Last update timestamp.")


class TaskCandidateResponse(BaseModel):
    id: UUID = Field(..., description="Task candidate id.")
    user_id: UUID = Field(..., description="Authenticated Supabase user id.")
    raw_input_id: UUID = Field(..., description="Raw input id this candidate came from.")
    mediator_run_id: UUID | None = Field(
        default=None,
        description="Mediator run id that produced this candidate.",
    )
    title: str = Field(..., min_length=1, max_length=200, description="Candidate task title.")
    description: str | None = Field(default=None, description="Optional candidate description.")
    due_at: datetime | None = Field(default=None, description="Detected or suggested due date.")
    priority: TaskPriority | None = Field(default=None, description="Suggested priority.")
    estimated_minutes: int | None = Field(
        default=None,
        ge=0,
        description="Estimated total minutes.",
    )
    energy_required: TaskEnergyRequired | None = Field(
        default=None,
        description="Estimated energy required.",
    )
    difficulty: TaskDifficulty | None = Field(default=None, description="Suggested difficulty.")
    next_action: str | None = Field(default=None, description="Smallest immediate next action.")
    recommended_today: bool = Field(
        default=False,
        description="Whether the policy layer recommends doing this today.",
    )
    today_reason: str | None = Field(default=None, description="Reason for today's recommendation.")
    overload_warning: str | None = Field(default=None, description="Overload or capacity warning.")
    confidence: float | None = Field(default=None, ge=0, le=1, description="Model confidence.")
    status: TaskCandidateStatus = Field(
        default=TaskCandidateStatus.DRAFT,
        description="Candidate lifecycle status.",
    )
    model_payload: dict[str, Any] = Field(
        default_factory=dict,
        description="Raw or normalized mediator payload used to create the candidate.",
    )
    subtasks: list[CandidateSubtaskResponse] = Field(default_factory=list)
    reminders: list[CandidateReminderResponse] = Field(default_factory=list)
    created_at: datetime | None = Field(default=None, description="Creation timestamp.")
    updated_at: datetime | None = Field(default=None, description="Last update timestamp.")
