import unittest

from app.schemas.mediator import ADHDReasoning, MediatorOutput, MediatorSubtask
from app.schemas.task_candidate import (
    TaskDifficulty,
    TaskEnergyRequired,
    TaskPriority,
)
from app.services.today_planning_service import (
    CURRENT_MINUTES_LIMIT_WARNING,
    LARGE_TASK_TODAY_REASON,
    LARGE_TASK_WARNING,
    OVERLOAD_LIMIT_WARNING,
    PROJECTED_MINUTES_LIMIT_WARNING,
    TASK_COUNT_LIMIT_WARNING,
    TodayContext,
    TodayPlanningService,
)


class TodayPlanningServiceTest(unittest.TestCase):
    def setUp(self) -> None:
        self.service = TodayPlanningService(_UnusedTodayContextRepository())

    def test_clears_recommendation_when_today_task_count_reaches_limit(self) -> None:
        output = make_mediator_output(recommended_today=["오늘 첫 단계만 시작"])

        guarded = self.service.apply_capacity_guard(
            output=output,
            today_context=make_today_context(today_task_count=3),
        )

        self.assertEqual(guarded.recommended_today, [])
        self.assertEqual(guarded.overload_warning, TASK_COUNT_LIMIT_WARNING)

    def test_clears_recommendation_when_current_minutes_reach_limit(self) -> None:
        output = make_mediator_output(recommended_today=["오늘 할 수 있음"])

        guarded = self.service.apply_capacity_guard(
            output=output,
            today_context=make_today_context(today_estimated_minutes=90),
        )

        self.assertEqual(guarded.recommended_today, [])
        self.assertEqual(guarded.overload_warning, CURRENT_MINUTES_LIMIT_WARNING)

    def test_overload_minutes_use_strong_warning_before_other_limits(self) -> None:
        output = make_mediator_output(recommended_today=["오늘 할 수 있음"])

        guarded = self.service.apply_capacity_guard(
            output=output,
            today_context=make_today_context(
                today_task_count=3,
                today_estimated_minutes=180,
            ),
        )

        self.assertEqual(guarded.recommended_today, [])
        self.assertEqual(guarded.overload_warning, OVERLOAD_LIMIT_WARNING)

    def test_clears_recommendation_when_projected_minutes_exceed_limit(self) -> None:
        output = make_mediator_output(
            estimated_minutes=45,
            recommended_today=["오늘 할 수 있음"],
        )

        guarded = self.service.apply_capacity_guard(
            output=output,
            today_context=make_today_context(today_estimated_minutes=50),
        )

        self.assertEqual(guarded.recommended_today, [])
        self.assertEqual(guarded.overload_warning, PROJECTED_MINUTES_LIMIT_WARNING)

    def test_large_task_keeps_today_start_reason_for_first_steps_only(self) -> None:
        output = make_mediator_output(
            estimated_minutes=121,
            recommended_today=["오늘 첫 단계만 시작", LARGE_TASK_TODAY_REASON],
        )

        guarded = self.service.apply_capacity_guard(
            output=output,
            today_context=make_today_context(),
        )

        self.assertEqual(
            guarded.recommended_today,
            ["오늘 첫 단계만 시작", LARGE_TASK_TODAY_REASON],
        )
        self.assertEqual(guarded.overload_warning, LARGE_TASK_WARNING)

    def test_preserves_and_deduplicates_existing_today_reasons(self) -> None:
        output = make_mediator_output(
            recommended_today=[
                "  첫 단계만 오늘 시작  ",
                "첫 단계만 오늘 시작",
                "",
                "5분 안에 시작 가능",
            ],
        )

        guarded = self.service.apply_capacity_guard(
            output=output,
            today_context=make_today_context(),
        )

        self.assertEqual(
            guarded.recommended_today,
            ["첫 단계만 오늘 시작", "5분 안에 시작 가능"],
        )
        self.assertIsNone(guarded.overload_warning)

    def test_combines_policy_warning_with_existing_warning(self) -> None:
        output = make_mediator_output(
            recommended_today=["오늘 할 수 있음"],
            overload_warning="모델 경고",
        )

        guarded = self.service.apply_capacity_guard(
            output=output,
            today_context=make_today_context(today_task_count=3),
        )

        self.assertEqual(guarded.recommended_today, [])
        self.assertEqual(
            guarded.overload_warning,
            f"{TASK_COUNT_LIMIT_WARNING}\n모델 경고",
        )

    def test_skips_projected_minutes_when_candidate_minutes_are_unknown(self) -> None:
        output = make_mediator_output(
            estimated_minutes=None,
            recommended_today=["오늘 첫 단계만 시작"],
        )

        guarded = self.service.apply_capacity_guard(
            output=output,
            today_context=make_today_context(today_estimated_minutes=89),
        )

        self.assertEqual(guarded.recommended_today, ["오늘 첫 단계만 시작"])
        self.assertIsNone(guarded.overload_warning)

    def test_does_not_mutate_original_mediator_output(self) -> None:
        output = make_mediator_output(
            recommended_today=["오늘 할 수 있음"],
            overload_warning=None,
        )

        guarded = self.service.apply_capacity_guard(
            output=output,
            today_context=make_today_context(today_task_count=3),
        )

        self.assertIsNot(guarded, output)
        self.assertEqual(output.recommended_today, ["오늘 할 수 있음"])
        self.assertIsNone(output.overload_warning)
        self.assertEqual(guarded.recommended_today, [])
        self.assertEqual(guarded.overload_warning, TASK_COUNT_LIMIT_WARNING)


class _UnusedTodayContextRepository:
    pass


def make_today_context(
    *,
    today_task_count: int = 1,
    today_estimated_minutes: int = 30,
    today_reminder_count: int = 1,
) -> TodayContext:
    return TodayContext(
        timezone="Asia/Seoul",
        today_date="2026-05-16",
        day_start="2026-05-16T00:00:00+09:00",
        day_end="2026-05-17T00:00:00+09:00",
        today_task_count=today_task_count,
        today_estimated_minutes=today_estimated_minutes,
        today_reminder_count=today_reminder_count,
    )


def make_mediator_output(
    *,
    estimated_minutes: int | None = 60,
    recommended_today: list[str] | None = None,
    overload_warning: str | None = None,
) -> MediatorOutput:
    return MediatorOutput(
        task_title="컴퓨터비전 과제 제출 준비",
        description="과제 요구사항을 확인하고 첫 단계만 시작한다.",
        due_at=None,
        priority=TaskPriority.MEDIUM,
        estimated_minutes=estimated_minutes,
        difficulty=TaskDifficulty.MEDIUM,
        energy_required=TaskEnergyRequired.MEDIUM,
        next_action="과제 파일 열기",
        subtasks=[
            MediatorSubtask(
                title="과제 파일 열기",
                estimated_minutes=5,
                is_next_action=True,
                energy_required=TaskEnergyRequired.LOW,
            )
        ],
        recommended_today=recommended_today
        if recommended_today is not None
        else ["첫 단계만 오늘 시작 가능"],
        reminders=[],
        overload_warning=overload_warning,
        clarification_questions=[],
        adhd_reasoning=ADHDReasoning(
            detected_risks=[],
            intervention_used=["small_next_action"],
            explanation_for_user="작게 시작할 수 있도록 첫 행동을 잡았다.",
        ),
        confidence=0.82,
    )


if __name__ == "__main__":
    unittest.main()
