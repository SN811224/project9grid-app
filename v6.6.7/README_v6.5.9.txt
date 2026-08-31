客戶名單總表 v6.5.9

本版重新從穩定版 v6.5.7 修改，避免 v6.5.8 的語法錯誤。

移除：
- 客戶姓名前的英文字母圓形頭像，例如 SN 前面的 S 圖示
- 經營名單姓名前的握手圓形圖示
- 增員名單姓名前的人物／增員圓形圖示
- 推薦樹狀圖姓名前的人物圓形圖示
- 客戶選擇清單姓名前的人像圖示

保留：
- 紅黃綠燈號
- 紅黃綠日期規則
- 紅 → 黃 → 綠自動排序
- 客戶／經營／增員詳細頁的狀態資訊
- v6.5.6 的待追蹤 SQL 修正與底部導覽功能

顯示方式會是：
🟢 SN
而不是：
(S) 🟢 SN

Codespaces：
rm -rf lib
unzip -o customer-list-master-v6.5.9-remove-name-avatars-fixed.zip
flutter clean
flutter pub get
flutter analyze
