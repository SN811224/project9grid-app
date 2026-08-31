推薦互動程式 v5.3

本次修改：
- 移除九宮格頁面最上方「成交客戶」選擇卡。
- 成交客戶改成只從九宮格中央格點選。
- 尚未選客戶時，中央顯示「點此選擇／成交客戶」。
- 選定後中央直接顯示客戶姓名。
- 中央下方保留「推薦 X 人」統計。
- 周圍 8 格仍只顯示該成交客戶推薦的人數。
- 未選成交客戶時，周圍 8 格仍不開放查看/新增。
- 其他 v5.2/PWA 功能維持不變。

覆蓋方式：
rm -rf lib
unzip -o recommendation-interaction-app-v5.3.zip
flutter clean
flutter pub get
flutter run -d web-server --web-port 8080 --release

正常後：
git add .
git commit -m "Simplify customer selection in 9Grid v5.3"
git push origin main
