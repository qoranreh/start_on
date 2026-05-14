create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = timezone('utc', now());
    return new;
end;
$$;

create table if not exists public.tasks (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users (id) on delete cascade,
    profile_id uuid references public.users_profile (id) on delete set null,
    candidate_id uuid references public.task_candidates (id) on delete set null,
    raw_input_id uuid references public.raw_task_inputs (id) on delete set null,
    mediator_run_id uuid references public.mediator_runs (id) on delete set null,
    title text not null,
    description text,
    status text not null default 'todo',
    priority text,
    due_at timestamptz,
    estimated_minutes integer check (estimated_minutes is null or estimated_minutes >= 0),
    energy_required text,
    difficulty text,
    next_action text,
    source text not null default 'ai',
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    completed_at timestamptz,
    constraint tasks_status_check check (
        status in ('todo', 'doing', 'done', 'paused', 'cancelled')
    ),
    constraint tasks_priority_check check (
        priority is null or priority in ('low', 'medium', 'high')
    ),
    constraint tasks_energy_required_check check (
        energy_required is null or energy_required in ('low', 'medium', 'high')
    ),
    constraint tasks_difficulty_check check (
        difficulty is null or difficulty in ('low', 'medium', 'high')
    ),
    constraint tasks_source_check check (
        source in ('manual', 'ocr', 'notion', 'voice', 'email', 'ai', 'migration')
    )
);

create unique index if not exists tasks_candidate_id_idx
    on public.tasks (candidate_id)
    where candidate_id is not null;

create index if not exists tasks_user_id_status_idx
    on public.tasks (user_id, status, created_at desc);

create index if not exists tasks_user_id_due_at_idx
    on public.tasks (user_id, due_at)
    where due_at is not null;

create index if not exists tasks_raw_input_id_idx
    on public.tasks (raw_input_id, created_at desc);

create index if not exists tasks_mediator_run_id_idx
    on public.tasks (mediator_run_id);

create table if not exists public.subtasks (
    id uuid primary key default gen_random_uuid(),
    task_id uuid not null references public.tasks (id) on delete cascade,
    user_id uuid not null references auth.users (id) on delete cascade,
    candidate_subtask_id uuid references public.candidate_subtasks (id) on delete set null,
    title text not null,
    order_index integer not null check (order_index >= 0),
    estimated_minutes integer check (estimated_minutes is null or estimated_minutes >= 0),
    status text not null default 'todo',
    is_next_action boolean not null default false,
    energy_required text,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    completed_at timestamptz,
    constraint subtasks_status_check check (
        status in ('todo', 'doing', 'done', 'skipped')
    ),
    constraint subtasks_energy_required_check check (
        energy_required is null or energy_required in ('low', 'medium', 'high')
    )
);

create unique index if not exists subtasks_task_id_order_idx
    on public.subtasks (task_id, order_index);

create index if not exists subtasks_user_id_status_idx
    on public.subtasks (user_id, status, created_at desc);

create index if not exists subtasks_candidate_subtask_id_idx
    on public.subtasks (candidate_subtask_id)
    where candidate_subtask_id is not null;

create table if not exists public.reminders (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users (id) on delete cascade,
    task_id uuid not null references public.tasks (id) on delete cascade,
    candidate_reminder_id uuid references public.candidate_reminders (id) on delete set null,
    remind_at timestamptz not null,
    message text not null,
    type text not null default 'start',
    status text not null default 'scheduled',
    escalation_level integer not null default 0 check (escalation_level >= 0),
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    sent_at timestamptz,
    constraint reminders_type_check check (
        type in ('start', 'deadline', 'nudge', 'replan')
    ),
    constraint reminders_status_check check (
        status in ('scheduled', 'sent', 'snoozed', 'cancelled')
    )
);

create index if not exists reminders_task_id_idx
    on public.reminders (task_id, remind_at);

create index if not exists reminders_user_id_status_remind_at_idx
    on public.reminders (user_id, status, remind_at);

create index if not exists reminders_candidate_reminder_id_idx
    on public.reminders (candidate_reminder_id)
    where candidate_reminder_id is not null;

drop trigger if exists set_tasks_updated_at on public.tasks;
create trigger set_tasks_updated_at
before update on public.tasks
for each row
execute function public.set_updated_at();

drop trigger if exists set_subtasks_updated_at on public.subtasks;
create trigger set_subtasks_updated_at
before update on public.subtasks
for each row
execute function public.set_updated_at();

drop trigger if exists set_reminders_updated_at on public.reminders;
create trigger set_reminders_updated_at
before update on public.reminders
for each row
execute function public.set_updated_at();

alter table public.tasks enable row level security;
alter table public.subtasks enable row level security;
alter table public.reminders enable row level security;

comment on table public.tasks is
'Final AI planning task table. Confirmed task_candidates are committed here instead of the legacy quests table.';

comment on table public.subtasks is
'Final executable subtask rows attached to tasks after candidate confirmation.';

comment on table public.reminders is
'Final scheduled reminder rows attached to tasks after candidate confirmation.';
