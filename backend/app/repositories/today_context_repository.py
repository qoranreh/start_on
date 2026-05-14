from dataclasses import dataclass
from datetime import datetime
from typing import Any

from app.schemas.reminder import ReminderStatus
from app.schemas.task import TaskStatus


_TODAY_TASK_COLUMNS = "id, status, due_at, estimated_minutes"
_TODAY_REMINDER_COLUMNS = "id, status, remind_at"
_OPEN_TASK_STATUSES = {
    TaskStatus.TODO.value,
    TaskStatus.DOING.value,
    TaskStatus.PAUSED.value,
}


@dataclass(frozen=True)
class TodayContextCounts:
    today_task_count: int
    today_estimated_minutes: int
    today_reminder_count: int


class SupabaseTodayContextRepository:
    def __init__(self, client: Any) -> None:
        self._client = client

    def get_today_context_counts(
        self,
        *,
        user_id: str,
        day_start: datetime,
        day_end: datetime,
    ) -> TodayContextCounts:
        task_rows = self._list_today_task_rows(
            user_id=user_id,
            day_start=day_start,
            day_end=day_end,
        )
        open_task_rows = [
            row for row in task_rows if row.get("status") in _OPEN_TASK_STATUSES
        ]
        reminder_rows = self._list_today_reminder_rows(
            user_id=user_id,
            day_start=day_start,
            day_end=day_end,
        )

        return TodayContextCounts(
            today_task_count=len(open_task_rows),
            today_estimated_minutes=sum(
                _non_negative_int(row.get("estimated_minutes"))
                for row in open_task_rows
            ),
            today_reminder_count=len(reminder_rows),
        )

    def _list_today_task_rows(
        self,
        *,
        user_id: str,
        day_start: datetime,
        day_end: datetime,
    ) -> list[dict[str, Any]]:
        response = (
            self._client.table("tasks")
            .select(_TODAY_TASK_COLUMNS)
            .eq("user_id", user_id)
            .gte("due_at", day_start.isoformat())
            .lt("due_at", day_end.isoformat())
            .execute()
        )
        return response.data or []

    def _list_today_reminder_rows(
        self,
        *,
        user_id: str,
        day_start: datetime,
        day_end: datetime,
    ) -> list[dict[str, Any]]:
        response = (
            self._client.table("reminders")
            .select(_TODAY_REMINDER_COLUMNS)
            .eq("user_id", user_id)
            .eq("status", ReminderStatus.SCHEDULED.value)
            .gte("remind_at", day_start.isoformat())
            .lt("remind_at", day_end.isoformat())
            .execute()
        )
        return response.data or []


def _non_negative_int(value: Any) -> int:
    if value is None:
        return 0
    parsed = int(value)
    return max(0, parsed)
