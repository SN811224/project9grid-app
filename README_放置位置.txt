把 ZIP 上傳到 Codespaces 專案最上層（能看到 android、ios、lib、web、pubspec.yaml 的位置）。

終端機依序執行：
unzip -o project9grid-crm-v1.2-complete.zip
flutter pub get
flutter run -d web-server --web-port 8080

重要：
1. 不要解壓到 lib 裡。
2. 不要把 flutter run 指令貼到 main.dart。
3. ZIP 會自動覆蓋 lib/main.dart 與 pubspec.yaml。
