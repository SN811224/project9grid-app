客戶名單總表 v6.5.4

1. 九宮格目前狀態
- 儲存後同步至對應經營來源。
- 儲存後顯示更新提示。
- 樹狀圖顯示實際狀態。

2. 首頁九宮格平均完成度
- 每位成交客戶共 8 格。
- 該格至少 1 位人脈即算完成。
- 顯示百分比與完整進度條。

3. 經營／增員自動跟進燈
- 15天內有更新：綠色
- 16–25天：黃色
- 26天以上：紅色
- 無紀錄以名單建立日期計算
- 名字前與頭像旁顯示燈號
- 詳細頁顯示燈號與最近更新日期

4. 自動排序
- 紅 → 黃 → 綠
- 同色中越久未更新越前面
- 新增紀錄或重新整理後自動重排

不需要新增 Supabase SQL。

Codespaces：
rm -rf lib
unzip -o customer-list-master-v6.5.4-progress-gridfix.zip
flutter clean
flutter pub get
flutter analyze
