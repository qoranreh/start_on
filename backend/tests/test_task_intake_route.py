import unittest

from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.api.routes import task_intake as task_intake_route
from app.schemas.task import TaskSource
from app.schemas.task_candidate import (
    TaskCandidateResponse,
    TaskCandidateStatus,
    TaskDifficulty,
    TaskEnergyRequired,
    TaskPriority,
)
from app.schemas.task_intake import RawTaskInputStatus, TaskIntakeResponse


USER_ID = "00000000-0000-4000-8000-000000000001"
RAW_INPUT_ID = "00000000-0000-4000-8000-000000000003"
CANDIDATE_ID = "00000000-0000-4000-8000-000000000004"
MEDIATOR_RUN_ID = "00000000-0000-4000-8000-000000000005"


def make_candidate_response() -> TaskCandidateResponse:
    return TaskCandidateResponse(
        id=CANDIDATE_ID,
        user_id=USER_ID,
        raw_input_id=RAW_INPUT_ID,
        mediator_run_id=MEDIATOR_RUN_ID,
        title="컴퓨터비전 과제 제출 준비",
        description=None,
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


def make_intake_response() -> TaskIntakeResponse:
    return TaskIntakeResponse(
        raw_input_id=RAW_INPUT_ID,
        candidate_id=CANDIDATE_ID,
        status=RawTaskInputStatus.CANDIDATE_READY,
        candidate=make_candidate_response(),
    )


class FakeIntakeService:
    def __init__(self, *, error: Exception | None = None) -> None:
        self.error = error
        self.handle_calls: list[dict[str, object]] = []

    def handle_intake(self, *, user_id: str, request: object) -> TaskIntakeResponse:
        self.handle_calls.append({"user_id": user_id, "request": request})
        if self.error is not None:
            raise self.error
        return make_intake_response()


class TaskIntakeRouteTest(unittest.TestCase):
    def make_client(self, service: FakeIntakeService) -> TestClient:
        app = FastAPI()
        app.include_router(
            task_intake_route.router,
            prefix="/api/v1/task-intake",
        )
        app.dependency_overrides[task_intake_route.get_current_user_id] = lambda: USER_ID
        app.dependency_overrides[task_intake_route.get_intake_service] = lambda: service
        return TestClient(app)

    def test_create_task_intake_returns_candidate_envelope(self) -> None:
        service = FakeIntakeService()
        client = self.make_client(service)

        response = client.post(
            "/api/v1/task-intake",
            json={
                "text": "컴비전 과제 해야 함",
                "source": TaskSource.MANUAL.value,
                "client_timezone": "Asia/Seoul",
                "user_context": {
                    "energy_now": TaskEnergyRequired.MEDIUM.value,
                    "available_minutes_today": 60,
                    "extra": {"screen": "quick_add"},
                },
                "client_metadata": {"entry": "quick-add"},
            },
        )

        self.assertEqual(response.status_code, 201)
        payload = response.json()
        self.assertEqual(payload["success"], True)
        self.assertIsNone(payload["error"])
        self.assertEqual(payload["data"]["raw_input_id"], RAW_INPUT_ID)
        self.assertEqual(payload["data"]["candidate_id"], CANDIDATE_ID)
        self.assertEqual(payload["data"]["status"], "candidate_ready")
        self.assertEqual(
            payload["data"]["candidate"]["title"],
            "컴퓨터비전 과제 제출 준비",
        )

        self.assertEqual(len(service.handle_calls), 1)
        call = service.handle_calls[0]
        self.assertEqual(call["user_id"], USER_ID)
        self.assertEqual(call["request"].text, "컴비전 과제 해야 함")
        self.assertEqual(call["request"].source, TaskSource.MANUAL)

    def test_create_task_intake_maps_value_error_to_400(self) -> None:
        service = FakeIntakeService(error=ValueError("text is invalid"))
        client = self.make_client(service)

        response = client.post(
            "/api/v1/task-intake",
            json={"text": "컴비전 과제 해야 함"},
        )

        self.assertEqual(response.status_code, 400)
        detail = response.json()["detail"]
        self.assertEqual(detail["code"], "invalid_task_intake_request")
        self.assertEqual(detail["message"], "text is invalid")

    def test_create_task_intake_maps_unexpected_error_to_500(self) -> None:
        service = FakeIntakeService(error=RuntimeError("database unavailable"))
        client = self.make_client(service)

        response = client.post(
            "/api/v1/task-intake",
            json={"text": "컴비전 과제 해야 함"},
        )

        self.assertEqual(response.status_code, 500)
        detail = response.json()["detail"]
        self.assertEqual(detail["code"], "task_intake_failed")
        self.assertEqual(detail["message"], "Task intake failed unexpectedly.")


if __name__ == "__main__":
    unittest.main()
