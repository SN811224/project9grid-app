-- 客戶名單總表 v6.1 migration
-- 在 Supabase SQL Editor 執行一次，可重複執行

-- 推薦進來的人，自動對應到經營名單
alter table public.prospects
  add column if not exists source_customer_id uuid references public.customers(id) on delete set null;
alter table public.prospects
  add column if not exists source_contact_id uuid references public.contacts(id) on delete set null;
alter table public.prospects
  add column if not exists source_category text;

create unique index if not exists prospects_source_contact_unique_idx
  on public.prospects(source_contact_id)
  where source_contact_id is not null;

-- 經營紀錄只顯示日期，不需要時間
alter table public.engagement_logs
  add column if not exists engaged_on date;
update public.engagement_logs
set engaged_on = coalesce(engaged_on, engaged_at::date)
where engaged_on is null;
alter table public.engagement_logs
  alter column engaged_on set default current_date;

-- 主約滿期與「滿期後附約仍需繳費」
alter table public.policies
  add column if not exists maturity_date date;
alter table public.policies
  add column if not exists riders_continue_after_maturity boolean not null default false;

-- 附約：一張主約可有不限筆數附約
create table if not exists public.policy_riders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  policy_id uuid not null references public.policies(id) on delete cascade,
  name text not null,
  coverage_amount numeric not null default 0,
  payment_frequency text not null default '年繳',
  premium_amount numeric not null default 0,
  annual_premium numeric not null default 0,
  payment_term text,
  maturity_date date,
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists policy_riders_user_id_idx on public.policy_riders(user_id);
create index if not exists policy_riders_policy_id_idx on public.policy_riders(policy_id);

alter table public.policy_riders enable row level security;
drop policy if exists "policy_riders own rows" on public.policy_riders;
create policy "policy_riders own rows" on public.policy_riders
for all to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- 補舊推薦資料到經營名單：只補尚未有 source_contact_id 對應者
insert into public.prospects (
  user_id, name, phone, occupation, company, notes, status,
  source_customer_id, source_contact_id, source_category
)
select
  c.user_id, c.name, c.phone, c.occupation, c.company, c.notes,
  case when c.converted_customer_id is null then '經營中' else '已轉客戶' end,
  c.customer_id, c.id, c.category
from public.contacts c
where not exists (
  select 1 from public.prospects p where p.source_contact_id = c.id
);

-- 已成交推薦同步 converted_customer_id
update public.prospects p
set status='已轉客戶', converted_customer_id=c.converted_customer_id
from public.contacts c
where p.source_contact_id=c.id
  and c.converted_customer_id is not null
  and (p.converted_customer_id is distinct from c.converted_customer_id or p.status <> '已轉客戶');
