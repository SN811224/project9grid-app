客戶名單總表 v6.6.2
- 生日移到姓名後方，例如：王聖恩　民國81年12月24日
- 生日顯示統一使用民國年。
- 名單下一行不重複顯示生日。
- 僅調整顯示格式，不改動資料庫既有生日原始值。
- 不需要新增 SQL。

安裝：
rm -rf lib
unzip -o customer-list-master-v6.6.2-roc-birthday.zip
flutter clean
flutter pub get
flutter analyze
