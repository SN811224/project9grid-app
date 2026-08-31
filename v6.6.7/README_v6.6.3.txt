客戶名單總表 v6.6.3

1. 客戶／經營／增員名單顯示統一：
   第一行：燈號 + 姓名 + 民國生日
   例如：● 王聖恩　70.12.24
   第二行：電話
   經營／增員再下一行顯示來源。

2. 生日顯示統一：
   民國 YY.MM.DD / YYY.MM.DD
   不補前導 0，例如民國 81 年就是 81.12.24。

3. 新增／編輯生日欄：
   「生日（民國YYY-MM-DD）」
   可輸入 81-12-24、081-12-24 或 1981-12-24。
   儲存時自動轉成資料庫使用的西元 YYYY-MM-DD。

4. 表單輸入錯誤：
   姓名未填、手機格式錯誤、生日格式錯誤或不存在日期，
   都會跳出「輸入資料有誤」警示，不會再直接沒反應。

5. 不需要新增 SQL。

Codespaces：
rm -rf lib
unzip -o customer-list-master-v6.6.3-birthday-unified-validation.zip
flutter clean
flutter pub get
flutter analyze
