-- Project 9Grid CRM Final v3.0
-- 可重複執行。會補齊缺少的資料表、欄位、索引與 RLS Policy。

create extension if not exists pgcrypto;

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  phone text,
  line_id text,
  birthday date,
  occupation text,
  company text,
  family_status text,
  annual_premium numeric not null default 0,
  closed_date date,
  priority integer not null default 3,
  notes text,
  created_at timestamptz not null default now()
);

alter table public.customers add column if not exists line_id text;
alter table public.customers add column if not exists birthday date;
alter table public.customers add column if not exists family_status text;
alter table public.customers add column if not exists annual_premium numeric not null default 0;
alter table public.customers add column if not exists closed_date date;
alter table public.customers add column if not exists priority integer not null default 3;
alter table public.customers add column if not exists notes text;
alter table public.customers add column if not exists created_at timestamptz not null default now();

create table if not exists public.contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  customer_id uuid references public.customers(id) on delete cascade,
  name text not null,
  category text not null,
  status text not null default '未聯絡',
  phone text,
  occupation text,
  company text,
  notes text,
  created_at timestamptz not null default now()
);

alter table public.contacts add column if not exists customer_id uuid references public.customers(id) on delete cascade;
alter table public.contacts add column if not exists status text not null default '未聯絡';
alter table public.contacts add column if not exists phone text;
alter table public.contacts add column if not exists occupation text;
alter table public.contacts add column if not exists company text;
alter table public.contacts add column if not exists notes text;
alter table public.contacts add column if not exists created_at timestamptz not null default now();

create table if not exists public.todos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  customer_id uuid references public.customers(id) on delete set null,
  title text not null,
  description text,
  due_at timestamptz,
  status text not null default '待處理',
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.todos add column if not exists customer_id uuid references public.customers(id) on delete set null;
alter table public.todos add column if not exists description text;
alter table public.todos add column if not exists due_at timestamptz;
alter table public.todos add column if not exists status text not null default '待處理';
alter table public.todos add column if not exists completed_at timestamptz;
alter table public.todos add column if not exists created_at timestamptz not null default now();

create table if not exists public.policies (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  product_name text not null,
  policy_type text not null,
  insurer text,
  annual_premium numeric not null default 0,
  coverage_amount numeric not null default 0,
  effective_date date,
  payment_method text,
  notes text,
  created_at timestamptz not null default now()
);

alter table public.policies add column if not exists effective_date date;
alter table public.policies add column if not exists payment_method text;
alter table public.policies add column if not exists notes text;
alter table public.policies add column if not exists created_at timestamptz not null default now();

create table if not exists public.follow_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  contact_id uuid references public.contacts(id) on delete set null,
  contacted_at timestamptz not null default now(),
  channel text not null default '電話',
  summary text not null,
  next_follow_up timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists customers_user_id_idx on public.customers(user_id);
create index if not exists contacts_user_id_idx on public.contacts(user_id);
create index if not exists contacts_customer_id_idx on public.contacts(customer_id);
create index if not exists todos_user_id_idx on public.todos(user_id);
create index if not exists policies_user_id_idx on public.policies(user_id);
create index if not exists policies_customer_id_idx on public.policies(customer_id);
create index if not exists follow_logs_user_id_idx on public.follow_logs(user_id);
create index if not exists follow_logs_customer_id_idx on public.follow_logs(customer_id);

alter table public.customers enable row level security;
alter table public.contacts enable row level security;
alter table public.todos enable row level security;
alter table public.policies enable row level security;
alter table public.follow_logs enable row level security;

drop policy if exists "customers own rows" on public.customers;
create policy "customers own rows" on public.customers
for all to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "contacts own rows" on public.contacts;
create policy "contacts own rows" on public.contacts
for all to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "todos own rows" on public.todos;
create policy "todos own rows" on public.todos
for all to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "policies own rows" on public.policies;
create policy "policies own rows" on public.policies
for all to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "follow_logs own rows" on public.follow_logs;
create policy "follow_logs own rows" on public.follow_logs
for all to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
