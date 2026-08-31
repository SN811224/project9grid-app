客戶名單總表 v6.4

本版調整：
1. 底部「保單」選單改為「增員」。
2. 保單管理完整收進每一位客戶的客戶資料頁。
3. 客戶資料頁保留：推薦樹狀圖、九宮格推薦人脈、成交前經營紀錄、保單、聯絡紀錄。
4. 增員名單可新增／修改／刪除。
5. 增員紀錄與經營紀錄相同概念：日期、目前狀況、內容，可持續新增、修改、刪除。
6. 增員 → 成交客戶：採「複製」，增員資料不刪除。
7. 成交客戶 → 增員：採「複製」，客戶資料不刪除。
8. 同一成交客戶避免重複建立相同來源的增員資料。

先到 Supabase SQL Editor 執行：
005_customer_list_v6_4_migration.sql

再於 Codespaces：
rm -rf lib
unzip -o customer-list-master-v6.4.zip
flutter clean
flutter pub get
flutter analyze
