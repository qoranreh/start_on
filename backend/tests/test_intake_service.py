import unittest

from app.repositories.raw_input_repository import RawTaskInputRecord
from app.schemas.task import TaskSource
from app.schemas.task_candidate import (
    TaskCandidateResponse,
    TaskCandidateStatus,
    TaskDifficulty,
    TaskEnergyRequired,
    TaskPriority,
)
from app.schemas.task_intake import (
    RawTaskInputStatus,
    TaskIntakeRequest,
    UserContext,
)
from app.services.intake_service import IntakeService


USER_ID = "00000000-0000-4000-8000-000000000001"
PROFILE_ID = "00000000-0000-4000-8000-000000000002"
RAW_INPUT_ID = "00000000-0000-4000-8000-000000000003"
CANDIDATE_ID = "00000000-0000-4000-8000-000000000004"
MEDIATOR_RUN_ID = "00000000-0000-4000-8000-000000000005"


def make_raw_input_record() -> RawTaskInputRecord:
    return RawTaskInputRecord(
        id=RAW_INPUT_ID,
        user_id=USER_ID,
        profile_id=PROFILE_ID,
        raw_text="컴비전 과제 해야 함",
        source=TaskSource.MANUAL.value,
        status=RawTaskInputStatus.RECEIVED.value,
        client_timezone="Asia/Seoul",
        client_metadata={"entry": "quick-add"},
        error_message=None,
        created_at=None,
        updated_at=None,
    )


def make_candidate_response() -> TaskCandidateResponse:
    return TaskCandidateResponse(
        id=CANDIDATE_ID,
        user_id=USER_ID,
        raw_input_id=RAW_INPUT_ID,
        mediator_run_id=MEDIATOR_RUN_ID,
        title="컴퓨터비전 과제 제출 준비",
        description="과제 요구사항을 확인하고 첫 단계만 시작한다.",
        due_at=None,
        priority=TaskPriority.MEDIUM,
        estimated_minutes=60,
        energy_required=TaskEnergyRequired.MEDIUM,
        difficulty=TaskDifficulty.MEDIUM,
        next_action="과제 파일 열기",
        recommended_today=True,
        today_reason="첫 단계만 오늘 시작 가능",
        overload_warning=None,
        confidence=0.82,
        status=TaskCandidateStatus.DRAFT,
        model_payload={"source": "test"},
        subtasks=[],
        reminders=[],
    )


class FakeRawInputRepository:
    def __init__(self) -> None:
        self.create_calls: list[dict[str, object]] = []
        self.status_updates: list[dict[str, object]] = []

    def create(
        self,
        *,
        user_id: str,
        raw_text: str,
        source: TaskSource | str = TaskSource.MANUAL,
        client_timezone: str | None = None,
        client_metadata: dict[str, object] | None = None,
    ) -> RawTaskInputRecord:
        self.create_calls.append(
            {
                "user_id": user_id,
                "raw_text": raw_text,
                "source": source,
                "client_timezone": client_timezone,
                "client_metadata": client_metadata,
            }
        )
        return make_raw_input_record()

    def update_status(self, **kwargs: object) -> RawTaskInputRecord:
        self.status_updates.append(kwargs)
        return make_raw_input_record()


class FakeMediatorService:
    def __init__(self, *, error: Exception | None = None) -> None:
        self.error = error
        self.create_calls: list[dict[str, object]] = []

    def create_candidate(
        self,
        *,
        user_id: str,
        raw_input_id: str,
        client_timezone: str | None = None,
        user_context: UserContext | dict[str, object] | None = None,
        profile_id: str | None = None,
    ) -> TaskCandidateResponse:
        self.create_calls.append(
            {
                "user_id": user_id,
                "raw_input_id": raw_input_id,
                "client_timezone": client_timezone,
                "user_context": user_context,
                "profile_id": profile_id,
            }
        )
        if self.error is not None:
            raise self.error
        return make_candidate_response()


class IntakeServiceTest(unittest.TestCase):
    def test_handle_intake_stores_raw_input_before_creating_candidate(self) -> None:
        raw_input_repository = FakeRawInputRepository()
        mediator_service = FakeMediatorService()
        service = IntakeService(
            raw_input_repository=raw_input_repository,
            mediator_service=mediator_service,
        )
        request = TaskIntakeRequest(
            text="컴비전 과제 해야 함",
            source=TaskSource.MANUAL,
            client_timezone="Asia/Seoul",
            user_context=UserContext(
                energy_now=TaskEnergyRequired.MEDIUM,
                available_minutes_today=60,
                extra={"screen": "quick_add"},
            ),
            client_metadata={"entry": "quick-add"},
        )

        response = service.handle_intake(
            user_id=USER_ID,
            profile_id=PROFILE_ID,
            request=request,
        )

        self.assertEqual(len(raw_input_repository.create_calls), 1)
        raw_call = raw_input_repository.create_calls[0]
        self.assertEqual(raw_call["user_id"], USER_ID)
        self.assertEqual(raw_call["raw_text"], request.text)
        self.assertEqual(raw_call["source"], request.source)
        self.assertEqual(raw_call["client_timezone"], "Asia/Seoul")
        self.assertEqual(raw_call["client_metadata"], {"entry": "quick-add"})

        self.assertEqual(len(mediator_service.create_calls), 1)
        mediator_call = mediator_service.create_calls[0]
        self.assertEqual(mediator_call["user_id"], USER_ID)
        self.assertEqual(mediator_call["profile_id"], PROFILE_ID)
        self.assertEqual(mediator_call["raw_input_id"], RAW_INPUT_ID)
        self.assertEqual(mediator_call["client_timezone"], "Asia/Seoul")
        self.assertIs(mediator_call["user_context"], request.user_context)

        self.assertEqual(str(response.raw_input_id), RAW_INPUT_ID)
        self.assertEqual(str(response.candidate_id), CANDIDATE_ID)
        self.assertEqual(response.status, RawTaskInputStatus.CANDIDATE_READY)
        self.assertEqual(response.candidate, make_candidate_response())

    def test_handle_intake_reraises_mediator_error_without_status_override(self) -> None:
        raw_input_repository = FakeRawInputRepository()
        mediator_service = FakeMediatorService(error=RuntimeError("mediator down"))
        service = IntakeService(
            raw_input_repository=raw_input_repository,
            mediator_service=mediator_service,
        )
        request = TaskIntakeRequest(text="컴비전 과제 해야 함")

        with self.assertRaisesRegex(RuntimeError, "mediator down"):
            service.handle_intake(user_id=USER_ID, request=request)

        self.assertEqual(len(raw_input_repository.create_calls), 1)
        self.assertEqual(len(mediator_service.create_calls), 1)
        self.assertEqual(raw_input_repository.status_updates, [])


if __name__ == "__main__":
    unittest.main()
