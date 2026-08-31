客戶名單總表 v6.6.4

修正「輸入資料有誤時表單被關閉」：

- 按儲存後，先在目前新增／編輯視窗內驗證。
- 姓名未填、手機格式錯誤、生日格式錯誤時：
  1. 顯示警示。
  2. 按「確定」只關閉警示。
  3. 原新增／編輯視窗保持開啟。
  4. 已輸入的其他內容保留。
  5. 使用者可直接修改後再次儲存。
- 只有所有欄位驗證正確後，才會關閉表單並執行儲存。
- 右上角 X 仍可由使用者自行關閉表單。

Codespaces：
rm -rf lib
unzip -o customer-list-master-v6.6.4-validation-stay-on-form.zip
flutter clean
flutter pub get
flutter analyze
