-- 客戶名單總表 v6.0 migration
-- Supabase SQL Editor 執行一次；可重複執行。

alter table public.contacts
  add column if not exists converted_customer_id uuid references public.customers(id) on delete set null;
alter table public.contacts
  add column if not exists converted_at timestamptz;

alter table public.policies
  add column if not exists premium_amount numeric not null default 0;
alter table public.policies
  alter column policy_type drop not null;

create table if not exists public.prospects (
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
  status text not null default '經營中',
  source_customer_id uuid references public.customers(id) on delete set null,
  source_contact_id uuid references public.contacts(id) on delete set null,
  converted_customer_id uuid references public.customers(id) on delete set null,
  converted_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.management_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  prospect_id uuid not null references public.prospects(id) on delete cascade,
  managed_at timestamptz not null default now(),
  content text not null,
  created_at timestamptz not null default now()
);

create index if not exists contacts_converted_customer_id_idx
  on public.contacts(converted_customer_id);
create index if not exists prospects_user_id_idx
  on public.prospects(user_id);
create index if not exists prospects_converted_customer_id_idx
  on public.prospects(converted_customer_id);
create index if not exists management_logs_user_id_idx
  on public.management_logs(user_id);
create index if not exists management_logs_prospect_id_idx
  on public.management_logs(prospect_id);

alter table public.prospects enable row level security;
alter table public.management_logs enable row level security;

drop policy if exists "prospects own rows" on public.prospects;
create policy "prospects own rows" on public.prospects
for all to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "management_logs own rows" on public.management_logs;
create policy "management_logs own rows" on public.management_logs
for all to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

update public.policies
set premium_amount = annual_premium
where premium_amount = 0 and annual_premium is not null;
