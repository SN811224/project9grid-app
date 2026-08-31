-- 客戶名單總表 v6.5 整合修復
-- 若先前已執行過 006，也可以重複執行，不會刪資料。

alter table public.follow_logs
  add column if not exists channel text;

update public.follow_logs
set channel = '其他'
where channel is null or channel = '';

alter table public.follow_logs enable row level security;
