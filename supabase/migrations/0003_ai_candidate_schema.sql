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

create table if not exists public.task_candidates (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users (id) on delete cascade,
    profile_id uuid references public.users_profile (id) on delete set null,
    raw_input_id uuid not null references public.raw_task_inputs (id) on delete cascade,
    mediator_run_id uuid references public.mediator_runs (id) on delete set null,
    title text not null,
    description text,
    due_at timestamptz,
    priority text,
    estimated_minutes integer check (estimated_minutes is null or estimated_minutes >= 0),
    energy_required text,
    difficulty text,
    next_action text,
    recommended_today boolean not null default false,
    today_reason text,
    overload_warning text,
    confidence numeric check (confidence is null or (confidence >= 0 and confidence <= 1)),
    status text not null default 'draft',
    model_payload jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint task_candidates_priority_check check (
        priority is null or priority in ('low', 'medium', 'high')
    ),
    constraint task_candidates_energy_required_check check (
        energy_required is null or energy_required in ('low', 'medium', 'high')
    ),
    constraint task_candidates_difficulty_check check (
        difficulty is null or difficulty in ('low', 'medium', 'high')
    ),
    constraint task_candidates_status_check check (
        status in ('draft', 'accepted', 'edited', 'rejected', 'committed')
    )
);

create index if not exists task_candidates_user_id_created_at_idx
    on public.task_candidates (user_id, created_at desc);

create index if not exists task_candidates_user_id_status_idx
    on public.task_candidates (user_id, status, created_at desc);

create index if not exists task_candidates_raw_input_id_idx
    on public.task_candidates (raw_input_id, created_at desc);

create index if not exists task_candidates_mediator_run_id_idx
    on public.task_candidates (mediator_run_id);

create table if not exists public.candidate_subtasks (
    id uuid primary key default gen_random_uuid(),
    candidate_id uuid not null references public.task_candidates (id) on delete cascade,
    user_id uuid not null references auth.users (id) on delete cascade,
    title text not null,
    order_index integer not null check (order_index >= 0),
    estimated_minutes integer check (estimated_minutes is null or estimated_minutes >= 0),
    is_next_action boolean not null default false,
    energy_required text,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint candidate_subtasks_energy_required_check check (
        energy_required is null or energy_required in ('low', 'medium', 'high')
    )
);

create unique index if not exists candidate_subtasks_candidate_id_order_idx
    on public.candidate_subtasks (candidate_id, order_index);

create index if not exists candidate_subtasks_user_id_created_at_idx
    on public.candidate_subtasks (user_id, created_at desc);

create table if not exists public.candidate_reminders (
    id uuid primary key default gen_random_uuid(),
    candidate_id uuid not null references public.task_candidates (id) on delete cascade,
    user_id uuid not null references auth.users (id) on delete cascade,
    remind_at timestamptz,
    message text not null,
    type text not null default 'start',
    escalation_level integer not null default 0 check (escalation_level >= 0),
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint candidate_reminders_type_check check (
        type in ('start', 'deadline', 'nudge', 'replan')
    )
);

create index if not exists candidate_reminders_candidate_id_idx
    on public.candidate_reminders (candidate_id, remind_at);

create index if not exists candidate_reminders_user_id_remind_at_idx
    on public.candidate_reminders (user_id, remind_at);

drop trigger if exists set_task_candidates_updated_at on public.task_candidates;
create trigger set_task_candidates_updated_at
before update on public.task_candidates
for each row
execute function public.set_updated_at();

drop trigger if exists set_candidate_subtasks_updated_at on public.candidate_subtasks;
create trigger set_candidate_subtasks_updated_at
before update on public.candidate_subtasks
for each row
execute function public.set_updated_at();

drop trigger if exists set_candidate_reminders_updated_at on public.candidate_reminders;
create trigger set_candidate_reminders_updated_at
before update on public.candidate_reminders
for each row
execute function public.set_updated_at();

alter table public.task_candidates enable row level security;
alter table public.candidate_subtasks enable row level security;
alter table public.candidate_reminders enable row level security;

comment on table public.task_candidates is
'Stores mediator-generated task candidates before user confirmation. Final task rows are created only after confirm.';

comment on table public.candidate_subtasks is
'Stores suggested subtasks for a task candidate, including the single smallest next action when available.';

comment on table public.candidate_reminders is
'Stores suggested reminders for a task candidate before the user confirms which reminders to create.';
