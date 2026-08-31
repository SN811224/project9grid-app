-- 客戶名單總表 v6.6.0

-- 推薦人脈「已聯絡」改為「經營中」
update public.contacts
set status = '經營中'
where status = '已聯絡';

alter table public.contacts
  drop constraint if exists contacts_status_check;

alter table public.contacts
  add constraint contacts_status_check
  check (status in ('未聯絡', '經營中', '待追蹤', '已成交'));

-- 經營增加「誰推薦的」
alter table public.prospects
  add column if not exists referred_by_name text;

update public.prospects
set status = '經營中'
where status = '已聯絡';

update public.prospects p
set referred_by_name = c.name
from public.customers c
where p.source_customer_id = c.id
  and (p.referred_by_name is null or p.referred_by_name = '');

update public.prospects
set source_category = '自行新增',
    referred_by_name = '自行新增'
where source_customer_id is null
  and source_contact_id is null
  and (source_category is null or source_category = '');

-- 增員增加來源類型與「誰推薦的」
alter table public.recruitments
  add column if not exists source_type text;

alter table public.recruitments
  add column if not exists referred_by_name text;

update public.recruitments r
set source_type = '成交客戶',
    referred_by_name = c.name
from public.customers c
where r.source_customer_id = c.id
  and (
    r.source_type is null or r.source_type = ''
    or r.referred_by_name is null or r.referred_by_name = ''
  );

update public.recruitments
set source_type = '自行新增',
    referred_by_name = '自行新增'
where source_customer_id is null
  and (source_type is null or source_type = '');

notify pgrst, 'reload schema';
