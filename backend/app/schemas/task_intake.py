from enum import StrEnum
from typing import Any
from uuid import UUID

from pydantic import BaseModel, Field, model_validator

from app.schemas.task import TaskSource
from app.schemas.task_candidate import TaskCandidateResponse, TaskEnergyRequired


class RawTaskInputStatus(StrEnum):
    RECEIVED = "received"
    PROCESSING = "processing"
    CANDIDATE_READY = "candidate_ready"
    FAILED = "failed"
    ARCHIVED = "archived"


class UserContext(BaseModel):
    energy_now: TaskEnergyRequired | None = Field(default=None)
    available_minutes_today: int | None = Field(default=None, ge=0)
    extra: dict[str, Any] = Field(
        default_factory=dict,
        description="Additional client context for the mediator.",
    )


class TaskIntakeRequest(BaseModel):
    text: str = Field(..., min_length=1, description="Raw user input text.")
    source: TaskSource = Field(default=TaskSource.MANUAL)
    client_timezone: str = Field(default="Asia/Seoul", min_length=1)
    user_context: UserContext = Field(default_factory=UserContext)
    client_metadata: dict[str, Any] = Field(
        default_factory=dict,
        description="Non-planning client metadata such as OCR source or local ids.",
    )

    @model_validator(mode="after")
    def validate_text(self) -> "TaskIntakeRequest":
        if not self.text.strip():
            raise ValueError("text must not be empty.")
        return self


class TaskIntakeResponse(BaseModel):
    raw_input_id: UUID = Field(..., description="Stored raw input id.")
    candidate_id: UUID | None = Field(default=None, description="Generated candidate id.")
    status: RawTaskInputStatus = Field(..., description="Raw input processing status.")
    candidate: TaskCandidateResponse | None = Field(
        default=None,
        description="Generated candidate when the mediator succeeded.",
    )
