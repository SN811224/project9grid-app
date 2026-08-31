-- 客戶名單總表 v6.0 migration
create extension if not exists pgcrypto;

alter table public.customers add column if not exists referred_by_customer_id uuid references public.customers(id) on delete set null;
alter table public.customers add column if not exists source_contact_id uuid references public.contacts(id) on delete set null;
alter table public.customers add column if not exists source_prospect_id uuid;
alter table public.contacts add column if not exists converted_customer_id uuid references public.customers(id) on delete set null;

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
  converted_customer_id uuid references public.customers(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.engagement_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  prospect_id uuid not null references public.prospects(id) on delete cascade,
  engaged_at timestamptz not null default now(),
  status_note text,
  content text not null,
  created_at timestamptz not null default now()
);

create index if not exists prospects_user_id_idx on public.prospects(user_id);
create index if not exists engagement_logs_user_id_idx on public.engagement_logs(user_id);
create index if not exists engagement_logs_prospect_id_idx on public.engagement_logs(prospect_id);
create index if not exists customers_referred_by_idx on public.customers(referred_by_customer_id);
create index if not exists contacts_converted_customer_idx on public.contacts(converted_customer_id);

alter table public.prospects enable row level security;
alter table public.engagement_logs enable row level security;

drop policy if exists "prospects own rows" on public.prospects;
create policy "prospects own rows" on public.prospects for all to authenticated
using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "engagement_logs own rows" on public.engagement_logs;
create policy "engagement_logs own rows" on public.engagement_logs for all to authenticated
using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table public.policies add column if not exists payment_frequency text;
alter table public.policies add column if not exists premium_amount numeric not null default 0;
alter table public.policies alter column policy_type drop not null;

update public.policies
set payment_frequency = coalesce(nullif(payment_frequency,''),nullif(payment_method,''),'年繳')
where payment_frequency is null or payment_frequency='';

update public.policies
set premium_amount=annual_premium
where premium_amount=0 and annual_premium is not null;
