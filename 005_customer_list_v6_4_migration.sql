-- 客戶名單總表 v6.4 migration
-- Supabase SQL Editor 執行一次；可重複執行

create extension if not exists pgcrypto;

create table if not exists public.recruitments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  phone text,
  line_id text,
  birthday date,
  occupation text,
  company text,
  family_status text,
  notes text,
  status text not null default '增員中',
  source_customer_id uuid references public.customers(id) on delete set null,
  converted_customer_id uuid references public.customers(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists recruitments_user_id_idx
  on public.recruitments(user_id);
create index if not exists recruitments_source_customer_id_idx
  on public.recruitments(source_customer_id);

alter table public.recruitments enable row level security;
drop policy if exists "recruitments own rows" on public.recruitments;
create policy "recruitments own rows" on public.recruitments
for all to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create table if not exists public.recruitment_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  recruitment_id uuid not null references public.recruitments(id) on delete cascade,
  recruited_on date not null default current_date,
  status_note text,
  content text not null,
  created_at timestamptz not null default now()
);

create index if not exists recruitment_logs_user_id_idx
  on public.recruitment_logs(user_id);
create index if not exists recruitment_logs_recruitment_id_idx
  on public.recruitment_logs(recruitment_id);

alter table public.recruitment_logs enable row level security;
drop policy if exists "recruitment_logs own rows" on public.recruitment_logs;
create policy "recruitment_logs own rows" on public.recruitment_logs
for all to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

alter table public.customers
  add column if not exists source_recruitment_id uuid
  references public.recruitments(id) on delete set null;
