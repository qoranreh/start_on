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

create table if not exists public.raw_task_inputs (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users (id) on delete cascade,
    profile_id uuid references public.users_profile (id) on delete set null,
    raw_text text not null,
    source text not null,
    status text not null default 'received',
    client_timezone text,
    client_metadata jsonb not null default '{}'::jsonb,
    error_message text,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint raw_task_inputs_source_check check (
        source in ('manual', 'ocr', 'notion', 'voice', 'email')
    ),
    constraint raw_task_inputs_status_check check (
        status in ('received', 'processing', 'candidate_ready', 'failed', 'archived')
    )
);

create index if not exists raw_task_inputs_user_id_created_at_idx
    on public.raw_task_inputs (user_id, created_at desc);

create index if not exists raw_task_inputs_user_id_status_idx
    on public.raw_task_inputs (user_id, status, created_at desc);

create table if not exists public.prompt_versions (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    version text not null,
    prompt_text text not null,
    output_schema jsonb not null default '{}'::jsonb,
    model_name text not null,
    is_active boolean not null default false,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    unique (name, version)
);

create unique index if not exists prompt_versions_active_name_idx
    on public.prompt_versions (name)
    where is_active;

create table if not exists public.mediator_runs (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users (id) on delete cascade,
    profile_id uuid references public.users_profile (id) on delete set null,
    raw_input_id uuid not null references public.raw_task_inputs (id) on delete cascade,
    prompt_version_id uuid references public.prompt_versions (id) on delete set null,
    model_name text not null,
    input_context jsonb not null default '{}'::jsonb,
    raw_model_output jsonb,
    parsed_output jsonb,
    status text not null default 'started',
    error_message text,
    started_at timestamptz not null default timezone('utc', now()),
    completed_at timestamptz,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint mediator_runs_status_check check (
        status in ('started', 'succeeded', 'failed')
    )
);

create index if not exists mediator_runs_user_id_created_at_idx
    on public.mediator_runs (user_id, created_at desc);

create index if not exists mediator_runs_raw_input_id_idx
    on public.mediator_runs (raw_input_id, created_at desc);

drop trigger if exists set_raw_task_inputs_updated_at on public.raw_task_inputs;
create trigger set_raw_task_inputs_updated_at
before update on public.raw_task_inputs
for each row
execute function public.set_updated_at();

drop trigger if exists set_prompt_versions_updated_at on public.prompt_versions;
create trigger set_prompt_versions_updated_at
before update on public.prompt_versions
for each row
execute function public.set_updated_at();

drop trigger if exists set_mediator_runs_updated_at on public.mediator_runs;
create trigger set_mediator_runs_updated_at
before update on public.mediator_runs
for each row
execute function public.set_updated_at();

alter table public.raw_task_inputs enable row level security;
alter table public.prompt_versions enable row level security;
alter table public.mediator_runs enable row level security;

comment on table public.raw_task_inputs is
'Stores original user input immediately before Gemini or mediator processing so messy manual, OCR, Notion, voice, or email input is not lost.';

comment on table public.prompt_versions is
'Stores versioned mediator prompts, expected output schema, and model name for reproducible Gemini planning runs.';

comment on table public.mediator_runs is
'Audit table for ADHD mediator executions, including assembled context, raw model output, parsed output, status, and errors.';
