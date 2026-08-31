客戶名單總表 v6.5.5

本版修正：
1. 九宮格「目前狀態」儲存
   - 儲存後本地立即更新畫面。
   - 同步更新 contacts 與對應經營來源。
   - 成功會顯示「目前狀態已更新」。
   - 若資料庫寫入失敗，會直接顯示錯誤原因，不再像沒有反應。

2. 經營名單
   - 姓名前保留紅黃綠燈。
   - 頭像旁的第二顆燈移除，避免重複。
   - 姓名右側直接顯示「未聯絡／已聯絡／待追蹤／已成交」狀態。
   - 詳細頁增加目前狀態欄。

3. 增員名單
   - 姓名前保留紅黃綠燈。
   - 頭像旁的重複燈號移除。

不需要新增 Supabase SQL。

Codespaces：
rm -rf lib
unzip -o customer-list-master-v6.5.5-status-lightfix.zip
flutter clean
flutter pub get
flutter analyze
