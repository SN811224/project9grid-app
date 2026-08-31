客戶名單總表 v6.6.5

修正 v6.6.4 的編譯錯誤。

原因：
v6.6.4 把姓名／手機／生日驗證誤加到兩個沒有這些輸入欄位的畫面：
1. 客戶詳細頁的聯絡紀錄編輯
2. 九宮格推薦轉成交客戶確認視窗

本版已修正：
- 上述兩處恢復原本功能，不再引用不存在的 name / phone / birthday。
- 真正的客戶、經營、增員新增／編輯表單仍保留驗證。
- 輸入錯誤時仍停留在原表單，不會關閉。
- 已輸入內容仍保留。

不需要 SQL。

Codespaces：
rm -rf lib
unzip -o customer-list-master-v6.6.5-validation-scope-fix.zip
flutter clean
flutter pub get
flutter analyze
