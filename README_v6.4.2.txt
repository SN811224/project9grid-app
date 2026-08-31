客戶名單總表 v6.4.2

本版調整：
1. 所有「新增」類型的 BottomSheet 右上角新增 X 關閉。
2. 已輸入內容時按 X，會先詢問是否放棄未儲存資料。
3. 首頁「人脈成交」改為「增員名單」。
4. 首頁增員名單數字改為 recruitments 資料筆數。
5. 點首頁「增員名單」卡片可直接進入增員名單。
6. 不需要新增 Supabase SQL。

安裝：
rm -rf lib
unzip -o customer-list-master-v6.4.2-ui.zip
flutter clean
flutter pub get
flutter analyze

沒有紅色 error 後：
flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
