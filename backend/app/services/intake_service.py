from app.repositories.raw_input_repository import SupabaseRawInputRepository
from app.schemas.task_intake import (
    RawTaskInputStatus,
    TaskIntakeRequest,
    TaskIntakeResponse,
)
from app.services.mediator_service import MediatorService


class IntakeService:
    def __init__(
        self,
        *,
        raw_input_repository: SupabaseRawInputRepository,
        mediator_service: MediatorService,
    ) -> None:
        self._raw_input_repository = raw_input_repository
        self._mediator_service = mediator_service

    def handle_intake(
        self,
        *,
        user_id: str,
        request: TaskIntakeRequest,
        profile_id: str | None = None,
    ) -> TaskIntakeResponse:
        raw_input = self._raw_input_repository.create(
            user_id=user_id,
            raw_text=request.text,
            source=request.source,
            client_timezone=request.client_timezone,
            client_metadata=request.client_metadata,
        )
        candidate = self._mediator_service.create_candidate(
            user_id=user_id,
            profile_id=profile_id,
            raw_input_id=raw_input.id,
            client_timezone=request.client_timezone,
            user_context=request.user_context,
        )
        return TaskIntakeResponse(
            raw_input_id=raw_input.id,
            candidate_id=candidate.id,
            status=RawTaskInputStatus.CANDIDATE_READY,
            candidate=candidate,
        )
