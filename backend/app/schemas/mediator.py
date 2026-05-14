from datetime import datetime
from enum import StrEnum

from pydantic import BaseModel, Field, model_validator

from app.schemas.reminder import ReminderType
from app.schemas.task_candidate import (
    TaskDifficulty,
    TaskEnergyRequired,
    TaskPriority,
)


class MediatorRunStatus(StrEnum):
    STARTED = "started"
    SUCCEEDED = "succeeded"
    FAILED = "failed"


class MediatorSubtask(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    estimated_minutes: int | None = Field(default=None, ge=0)
    is_next_action: bool = Field(default=False)
    energy_required: TaskEnergyRequired = Field(default=TaskEnergyRequired.MEDIUM)


class MediatorReminder(BaseModel):
    remind_at: datetime | None = Field(default=None)
    message: str = Field(..., min_length=1)
    type: ReminderType = Field(default=ReminderType.START)


class ADHDReasoning(BaseModel):
    detected_risks: list[str] = Field(default_factory=list)
    intervention_used: list[str] = Field(default_factory=list)
    explanation_for_user: str = Field(..., min_length=1)


class MediatorOutput(BaseModel):
    task_title: str = Field(..., min_length=1, max_length=200)
    description: str | None = Field(default=None)
    due_at: datetime | None = Field(default=None)
    priority: TaskPriority = Field(default=TaskPriority.MEDIUM)
    estimated_minutes: int | None = Field(default=None, ge=0)
    difficulty: TaskDifficulty = Field(default=TaskDifficulty.MEDIUM)
    energy_required: TaskEnergyRequired = Field(default=TaskEnergyRequired.MEDIUM)
    next_action: str = Field(..., min_length=1, max_length=200)
    subtasks: list[MediatorSubtask] = Field(default_factory=list)
    recommended_today: list[str] = Field(default_factory=list)
    reminders: list[MediatorReminder] = Field(default_factory=list)
    overload_warning: str | None = Field(default=None)
    clarification_questions: list[str] = Field(default_factory=list)
    adhd_reasoning: ADHDReasoning
    confidence: float = Field(..., ge=0, le=1)

    @model_validator(mode="after")
    def validate_next_action(self) -> "MediatorOutput":
        if not self.next_action.strip():
            raise ValueError("next_action must not be empty.")
        return self
