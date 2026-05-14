from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Any
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from app.repositories.today_context_repository import (
    SupabaseTodayContextRepository,
    TodayContextCounts,
)
from app.schemas.mediator import MediatorOutput


DEFAULT_TIMEZONE = "Asia/Seoul"
MAX_RECOMMENDED_TASKS_TODAY = 3
MAX_RECOMMENDED_MINUTES_TODAY = 90
OVERLOAD_WARNING_MINUTES = 180
LARGE_TASK_MINUTES = 120

TASK_COUNT_LIMIT_WARNING = (
    "오늘 추천할 항목이 이미 충분해서 이 일은 Inbox에 두는 것을 추천합니다."
)
CURRENT_MINUTES_LIMIT_WARNING = (
    "오늘 계획 시간이 이미 많아서 이 일은 오늘 추천하지 않습니다."
)
PROJECTED_MINUTES_LIMIT_WARNING = (
    "이 일을 더하면 오늘 계획 시간이 너무 많아져서 오늘은 Inbox에 두는 것을 추천합니다."
)
OVERLOAD_LIMIT_WARNING = (
    "오늘 계획 시간이 이미 많습니다. 이 일은 Inbox에 두고 오늘은 이미 정한 항목만 처리하는 것을 추천합니다."
)
LARGE_TASK_TODAY_REASON = (
    "전체가 아니라 첫 1~2단계만 오늘 시작하는 것을 추천합니다."
)
LARGE_TASK_WARNING = (
    "큰 작업은 한 번에 끝내기보다 첫 1~2단계만 잡는 것이 현실적입니다."
)


@dataclass(frozen=True)
class TodayContext:
    timezone: str
    today_date: str
    day_start: str
    day_end: str
    today_task_count: int
    today_estimated_minutes: int
    today_reminder_count: int

    def to_prompt_context(self) -> dict[str, Any]:
        return {
            "timezone": self.timezone,
            "today_date": self.today_date,
            "day_start": self.day_start,
            "day_end": self.day_end,
            "today_task_count": self.today_task_count,
            "today_estimated_minutes": self.today_estimated_minutes,
            "today_reminder_count": self.today_reminder_count,
        }


class TodayPlanningService:
    def __init__(self, today_context_repository: SupabaseTodayContextRepository) -> None:
        self._today_context_repository = today_context_repository

    def get_today_context(
        self,
        *,
        user_id: str,
        timezone: str = DEFAULT_TIMEZONE,
        now: datetime | None = None,
    ) -> TodayContext:
        timezone_name, timezone_info = _resolve_timezone(timezone)
        local_now = _local_now(timezone_info, now)
        day_start = local_now.replace(hour=0, minute=0, second=0, microsecond=0)
        day_end = day_start + timedelta(days=1)
        counts = self._today_context_repository.get_today_context_counts(
            user_id=user_id,
            day_start=day_start,
            day_end=day_end,
        )
        return _build_today_context(
            timezone_name=timezone_name,
            day_start=day_start,
            day_end=day_end,
            counts=counts,
        )

    def apply_capacity_guard(
        self,
        *,
        output: MediatorOutput,
        today_context: TodayContext,
    ) -> MediatorOutput:
        today_task_count = _non_negative_int(today_context.today_task_count)
        today_minutes = _non_negative_int(today_context.today_estimated_minutes)
        candidate_minutes = _non_negative_optional_int(output.estimated_minutes)
        projected_minutes = (
            today_minutes + candidate_minutes
            if candidate_minutes is not None
            else None
        )

        recommended_today = _unique_texts(output.recommended_today)
        policy_warnings: list[str] = []

        if today_minutes >= OVERLOAD_WARNING_MINUTES:
            recommended_today = []
            policy_warnings.append(OVERLOAD_LIMIT_WARNING)
        elif today_task_count >= MAX_RECOMMENDED_TASKS_TODAY:
            recommended_today = []
            policy_warnings.append(TASK_COUNT_LIMIT_WARNING)
        elif today_minutes >= MAX_RECOMMENDED_MINUTES_TODAY:
            recommended_today = []
            policy_warnings.append(CURRENT_MINUTES_LIMIT_WARNING)
        elif candidate_minutes is not None and candidate_minutes > LARGE_TASK_MINUTES:
            recommended_today = _append_unique(
                recommended_today,
                LARGE_TASK_TODAY_REASON,
            )
            policy_warnings.append(LARGE_TASK_WARNING)
        elif (
            projected_minutes is not None
            and projected_minutes > MAX_RECOMMENDED_MINUTES_TODAY
        ):
            recommended_today = []
            policy_warnings.append(PROJECTED_MINUTES_LIMIT_WARNING)

        return output.model_copy(
            update={
                "recommended_today": recommended_today,
                "overload_warning": _combine_warnings(
                    policy_warnings,
                    output.overload_warning,
                ),
            }
        )


def _resolve_timezone(timezone_name: str | None) -> tuple[str, ZoneInfo]:
    name = (timezone_name or DEFAULT_TIMEZONE).strip() or DEFAULT_TIMEZONE
    try:
        return name, ZoneInfo(name)
    except ZoneInfoNotFoundError:
        return DEFAULT_TIMEZONE, ZoneInfo(DEFAULT_TIMEZONE)


def _local_now(timezone_info: ZoneInfo, now: datetime | None) -> datetime:
    if now is None:
        return datetime.now(timezone_info)
    if now.tzinfo is None:
        return now.replace(tzinfo=timezone_info)
    return now.astimezone(timezone_info)


def _build_today_context(
    *,
    timezone_name: str,
    day_start: datetime,
    day_end: datetime,
    counts: TodayContextCounts,
) -> TodayContext:
    return TodayContext(
        timezone=timezone_name,
        today_date=day_start.date().isoformat(),
        day_start=day_start.isoformat(),
        day_end=day_end.isoformat(),
        today_task_count=counts.today_task_count,
        today_estimated_minutes=counts.today_estimated_minutes,
        today_reminder_count=counts.today_reminder_count,
    )


def _non_negative_int(value: int) -> int:
    return max(0, int(value))


def _non_negative_optional_int(value: int | None) -> int | None:
    if value is None:
        return None
    return max(0, int(value))


def _unique_texts(values: list[str]) -> list[str]:
    unique_values: list[str] = []
    seen: set[str] = set()
    for value in values:
        stripped = value.strip()
        if not stripped or stripped in seen:
            continue
        unique_values.append(stripped)
        seen.add(stripped)
    return unique_values


def _append_unique(values: list[str], value: str) -> list[str]:
    return _unique_texts([*values, value])


def _combine_warnings(
    policy_warnings: list[str],
    existing_warning: str | None,
) -> str | None:
    warnings = _unique_texts([*policy_warnings, existing_warning or ""])
    if not warnings:
        return None
    return "\n".join(warnings)
