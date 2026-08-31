客戶名單總表 v6.5 整合修復版

本次不是只改最新兩項，而是把前面尚未真正完成的問題一起整合：

1. 推薦樹狀圖重新排版
   - 同一個成交的人只顯示一次姓名
   - 不再先顯示「王聖恩推薦人」再重複顯示「王聖恩客戶」
   - 第一行只顯示姓名，右側顯示狀態
   - 第二行顯示關係、推薦人數、下層人數
   - 經營中的推薦人顯示為橘色狀態
   - 成交客戶顯示為綠色狀態
   - 完整往下顯示所有推薦層級

2. 大型樹狀圖
   - 深層預設精簡
   - 可單節點展開／收合
   - 右上可全部展開／恢復精簡
   - 新增姓名搜尋
   - 最大顯示寬度限制，iPad/電腦不會拉太散

3. 修正「已成交」Dropdown 畫面崩潰
   - 推薦編輯狀態選單正式加入「已成交」
   - 不再出現 There should be exactly one item... Assertion error

4. 修正 \n 被當文字顯示
   - 經營／增員等紀錄的多行內容改為正常換行

5. 保留 v6.4.2 功能
   - 首頁「人脈成交」→「增員名單」
   - 所有新增視窗右上角 X
   - 有未儲存內容時關閉會詢問確認
   - 保單放在客戶資料
   - 經營、增員、成交互相採複製而非移轉

6. 聯絡紀錄資料庫修復
   - ZIP 內附 006_v6_5_integrated_fix.txt
   - 若你已經成功執行過 006，可以不用再跑
   - 若還沒跑或仍出現 follow_logs channel 錯誤，貼到 Supabase SQL Editor 執行一次

Codespaces：
rm -rf lib
unzip -o customer-list-master-v6.5-integrated-fixes.zip
flutter clean
flutter pub get
flutter analyze
