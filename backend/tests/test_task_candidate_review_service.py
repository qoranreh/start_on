import unittest
from typing import Any

from app.schemas.task_candidate import (
    TaskCandidateResponse,
    TaskCandidateRevisionType,
    TaskCandidateStatus,
    TaskDifficulty,
    TaskEnergyRequired,
    TaskPriority,
)
from app.services.task_candidate_review_service import (
    TaskCandidateReviewError,
    TaskCandidateReviewService,
)


USER_ID = "00000000-0000-4000-8000-000000000001"
CANDIDATE_ID = "00000000-0000-4000-8000-000000000002"
RAW_INPUT_ID = "00000000-0000-4000-8000-000000000003"
MEDIATOR_RUN_ID = "00000000-0000-4000-8000-000000000004"


def make_candidate(
    *,
    status: TaskCandidateStatus = TaskCandidateStatus.DRAFT,
) -> TaskCandidateResponse:
    return TaskCandidateResponse(
        id=CANDIDATE_ID,
        user_id=USER_ID,
        raw_input_id=RAW_INPUT_ID,
        mediator_run_id=MEDIATOR_RUN_ID,
        title="컴퓨터비전 과제 제출 준비",
        description="요구사항을 확인하고 첫 단계만 시작한다.",
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
        status=status,
        model_payload={"source": "manual"},
    )


class FakeTaskCandidateRepository:
    def __init__(self, candidate: TaskCandidateResponse | None) -> None:
        self.candidate = candidate
        self.get_calls: list[dict[str, str]] = []
        self.update_candidate_calls: list[dict[str, Any]] = []

    def get(self, *, user_id: str, candidate_id: str) -> TaskCandidateResponse:
        self.get_calls.append({"user_id": user_id, "candidate_id": candidate_id})
        if self.candidate is None:
            raise ValueError("not found")
        return self.candidate

    def update_candidate(
        self,
        *,
        user_id: str,
        candidate_id: str,
        fields: dict[str, Any],
        model_payload: dict[str, Any],
    ) -> TaskCandidateResponse:
        self.update_candidate_calls.append(
            {
                "user_id": user_id,
                "candidate_id": candidate_id,
                "fields": fields,
                "model_payload": model_payload,
            }
        )
        if self.candidate is None:
            raise ValueError("not found")
        update = {**fields, "model_payload": model_payload}
        if "status" in update:
            update["status"] = TaskCandidateStatus(update["status"])
        if "priority" in update and update["priority"] is not None:
            update["priority"] = TaskPriority(update["priority"])
        if "energy_required" in update and update["energy_required"] is not None:
            update["energy_required"] = TaskEnergyRequired(update["energy_required"])
        if "difficulty" in update and update["difficulty"] is not None:
            update["difficulty"] = TaskDifficulty(update["difficulty"])
        self.candidate = self.candidate.model_copy(update=update)
        return self.candidate


class TaskCandidateReviewServiceTest(unittest.TestCase):
    def test_revise_candidate_updates_fields_and_marks_edited(self) -> None:
        repository = FakeTaskCandidateRepository(make_candidate())
        service = TaskCandidateReviewService(task_candidate_repository=repository)

        result = service.revise_candidate(
            user_id=USER_ID,
            candidate_id=CANDIDATE_ID,
            revision_type=TaskCandidateRevisionType.MANUAL_EDIT,
            edited_fields={
                "title": "컴비전 과제 1차 진행",
                "estimated_minutes": 45,
            },
            note="오늘 가능한 크기로 줄임",
        )

        self.assertEqual(result.status, TaskCandidateStatus.EDITED)
        self.assertEqual(result.title, "컴비전 과제 1차 진행")
        self.assertEqual(result.estimated_minutes, 45)
        call = repository.update_candidate_calls[0]
        self.assertEqual(
            call["fields"],
            {
                "title": "컴비전 과제 1차 진행",
                "estimated_minutes": 45,
                "status": TaskCandidateStatus.EDITED.value,
            },
        )
        self.assertEqual(call["model_payload"]["review"]["last_action"], "revise")
        self.assertEqual(
            call["model_payload"]["review"]["revision_type"],
            TaskCandidateRevisionType.MANUAL_EDIT.value,
        )
        self.assertEqual(call["model_payload"]["review"]["note"], "오늘 가능한 크기로 줄임")

    def test_make_smaller_revision_can_mark_edited_with_note_only(self) -> None:
        repository = FakeTaskCandidateRepository(make_candidate())
        service = TaskCandidateReviewService(task_candidate_repository=repository)

        result = service.revise_candidate(
            user_id=USER_ID,
            candidate_id=CANDIDATE_ID,
            revision_type=TaskCandidateRevisionType.MAKE_SMALLER,
            note="5분 단위로 더 작게",
        )

        self.assertEqual(result.status, TaskCandidateStatus.EDITED)
        call = repository.update_candidate_calls[0]
        self.assertEqual(call["fields"], {"status": TaskCandidateStatus.EDITED.value})
        self.assertEqual(
            call["model_payload"]["review"]["revision_type"],
            TaskCandidateRevisionType.MAKE_SMALLER.value,
        )

    def test_manual_edit_without_fields_fails(self) -> None:
        service = TaskCandidateReviewService(
            task_candidate_repository=FakeTaskCandidateRepository(make_candidate()),
        )

        with self.assertRaises(TaskCandidateReviewError) as context:
            service.revise_candidate(
                user_id=USER_ID,
                candidate_id=CANDIDATE_ID,
                revision_type=TaskCandidateRevisionType.MANUAL_EDIT,
            )

        self.assertEqual(context.exception.code, "invalid_candidate_revision")

    def test_unknown_edited_field_fails(self) -> None:
        repository = FakeTaskCandidateRepository(make_candidate())
        service = TaskCandidateReviewService(task_candidate_repository=repository)

        with self.assertRaises(TaskCandidateReviewError) as context:
            service.revise_candidate(
                user_id=USER_ID,
                candidate_id=CANDIDATE_ID,
                revision_type=TaskCandidateRevisionType.MANUAL_EDIT,
                edited_fields={"user_id": "other"},
            )

        self.assertEqual(context.exception.code, "invalid_edited_fields")
        self.assertEqual(repository.update_candidate_calls, [])

    def test_committed_candidate_revise_fails(self) -> None:
        service = TaskCandidateReviewService(
            task_candidate_repository=FakeTaskCandidateRepository(
                make_candidate(status=TaskCandidateStatus.COMMITTED),
            ),
        )

        with self.assertRaises(TaskCandidateReviewError) as context:
            service.revise_candidate(
                user_id=USER_ID,
                candidate_id=CANDIDATE_ID,
                revision_type=TaskCandidateRevisionType.MAKE_SMALLER,
            )

        self.assertEqual(context.exception.code, "candidate_already_committed")

    def test_rejected_candidate_revise_fails(self) -> None:
        service = TaskCandidateReviewService(
            task_candidate_repository=FakeTaskCandidateRepository(
                make_candidate(status=TaskCandidateStatus.REJECTED),
            ),
        )

        with self.assertRaises(TaskCandidateReviewError) as context:
            service.revise_candidate(
                user_id=USER_ID,
                candidate_id=CANDIDATE_ID,
                revision_type=TaskCandidateRevisionType.MAKE_SMALLER,
            )

        self.assertEqual(context.exception.code, "candidate_not_revisable")

    def test_reject_candidate_marks_rejected(self) -> None:
        repository = FakeTaskCandidateRepository(make_candidate())
        service = TaskCandidateReviewService(task_candidate_repository=repository)

        result = service.reject_candidate(
            user_id=USER_ID,
            candidate_id=CANDIDATE_ID,
            reason="지금 저장할 일이 아님",
        )

        self.assertEqual(result.status, TaskCandidateStatus.REJECTED)
        call = repository.update_candidate_calls[0]
        self.assertEqual(call["fields"], {"status": TaskCandidateStatus.REJECTED.value})
        self.assertEqual(call["model_payload"]["review"]["last_action"], "reject")
        self.assertEqual(call["model_payload"]["review"]["reason"], "지금 저장할 일이 아님")

    def test_already_rejected_candidate_reject_is_idempotent(self) -> None:
        service = TaskCandidateReviewService(
            task_candidate_repository=FakeTaskCandidateRepository(
                make_candidate(status=TaskCandidateStatus.REJECTED),
            ),
        )

        result = service.reject_candidate(user_id=USER_ID, candidate_id=CANDIDATE_ID)

        self.assertEqual(result.status, TaskCandidateStatus.REJECTED)

    def test_committed_candidate_reject_fails(self) -> None:
        service = TaskCandidateReviewService(
            task_candidate_repository=FakeTaskCandidateRepository(
                make_candidate(status=TaskCandidateStatus.COMMITTED),
            ),
        )

        with self.assertRaises(TaskCandidateReviewError) as context:
            service.reject_candidate(user_id=USER_ID, candidate_id=CANDIDATE_ID)

        self.assertEqual(context.exception.code, "candidate_already_committed")

    def test_missing_candidate_maps_to_not_found(self) -> None:
        service = TaskCandidateReviewService(
            task_candidate_repository=FakeTaskCandidateRepository(None),
        )

        with self.assertRaises(TaskCandidateReviewError) as context:
            service.reject_candidate(user_id=USER_ID, candidate_id=CANDIDATE_ID)

        self.assertEqual(context.exception.code, "candidate_not_found")


if __name__ == "__main__":
    unittest.main()
