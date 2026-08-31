-- 客戶名單總表 v6.5.6
-- 修正九宮格「目前狀態 = 待追蹤」無法儲存
-- 原因：contacts_status_check 沒有允許「待追蹤」

alter table public.contacts
  drop constraint if exists contacts_status_check;

alter table public.contacts
  add constraint contacts_status_check
  check (status in ('未聯絡', '已聯絡', '待追蹤', '已成交'));

-- 將空白狀態補成未聯絡
update public.contacts
set status = '未聯絡'
where status is null or status = '';
