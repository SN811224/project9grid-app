客戶名單總表 v6.5.6

本版修正：
1. 九宮格待追蹤無法儲存
   - 需先執行 007_contacts_status_fix.txt
   - contacts.status 正式允許：未聯絡、已聯絡、待追蹤、已成交

2. 客戶名單也加入跟進燈
   - 規則比經營多 15 天：
     綠：30 天內有聯絡
     黃：31–40 天未聯絡
     紅：41 天以上未聯絡
   - 只有姓名前方一顆燈
   - 自動排序：紅 → 黃 → 綠；同色越久沒聯絡越前面
   - 客戶詳細頁顯示最近聯絡日期及燈號

3. 詳細頁底部主選單不消失
   - 客戶、九宮格人脈、經營、增員等詳細頁保留底部導覽
   - 在增員詳細頁直接按「經營」可切去經營首頁
   - 在增員詳細頁再按一次「增員」會回增員首頁
   - 客戶、九宮格、經營也採同樣行為

安裝：
先到 Supabase SQL Editor 執行 007_contacts_status_fix.txt

再於 Codespaces：
rm -rf lib
unzip -o customer-list-master-v6.5.6-customer-light-navfix.zip
flutter clean
flutter pub get
flutter analyze
