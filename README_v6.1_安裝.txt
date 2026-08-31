客戶名單總表 v6.1

本次修正：
- 推薦新增後自動進入「經營」名單。
- 推薦人轉客戶後，仍永久掛在原推薦人的樹狀關係下面；再推薦會繼續往下一層。
- 樹狀圖會自動往上找到最上層推薦來源，不再把同一位成交客戶拆成兩個根節點。
- 經營紀錄只保留日期，不顯示幾點幾分。
- 經營備註 / 內容可逐筆儲存與查詢。
- 保單繳費新增「月繳」。
- 主約新增「主約滿期日」。
- 新增「主約滿期後仍有附約需要繳費」開關。
- 一張主約可用「＋新增附約」增加不限筆數附約。
- 每個附約可輸入：名稱、保額、年/半年/季/月繳、每期保費、繳費年期/說明、滿期日、備註。

先執行 Supabase：004_customer_list_v6_1_migration.txt

Codespaces 覆蓋：
rm -rf lib
unzip -o customer-list-master-v6.1.zip
flutter clean
flutter pub get
flutter analyze
flutter run -d web-server --web-port 8080 --release

確認正常後：
git add .
git commit -m "Customer List Master v6.1"
git push origin main
