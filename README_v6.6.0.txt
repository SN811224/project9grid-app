客戶名單總表 v6.6.0

調整：
- 推薦人脈「已聯絡」改為「經營中」。
- 經營新增來源選單：自行新增、親戚、同學、鄰居、同事、前同事、家人、朋友、社團、其他。
- 增員新增來源選單：自行新增、成交客戶、情境、朋友、共電、其他。
- 經營與增員都增加「誰推薦的」欄位。
- 九宮格推薦自動加入經營時，會自動記住是哪位成交客戶推薦。
- 成交客戶複製到增員時，會自動記住該客戶姓名。
- 名單及詳細頁都改顯示「誰推薦的：XXX」。

先執行 Supabase：
008_source_referrer_and_status_fix.txt

再 Codespaces：
rm -rf lib
unzip -o customer-list-master-v6.6.0-source-referrer.zip
flutter clean
flutter pub get
flutter analyze
