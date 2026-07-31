# Project 9Grid CRM — 3.0 Sprint 1 Alpha

Flutter + Supabase 的保險轉介紹 CRM。

## Sprint 1 已完成

- Email／密碼註冊、登入、登出
- Supabase 雲端連線與 Auth Gate
- CRM 戰情室統計
- 客戶即時列表與搜尋
- 新增、編輯、刪除成交客戶
- 九宮格正式分類介面
- Material 3 手機介面
- Supabase RLS 資料隔離架構

## 第一次執行

本交付包含 Flutter 原始碼；因交付環境沒有 Flutter SDK，`ios/`、`android/`、`web/` 平台目錄需在有 Flutter 的環境建立一次：

```bash
flutter create . --platforms=ios,android,web
flutter pub get
flutter run -d chrome
```

Supabase URL 與 Publishable Key 已設定為預設值，也可用 `--dart-define` 覆寫。

## Supabase Authentication

在 Supabase Dashboard 確認：

1. Authentication → Providers → Email 已啟用。
2. 測試期若希望註冊後立即登入，可暫時關閉 Confirm email；正式使用建議開啟。

## 上傳 GitHub

將本資料夾的內容上傳到 `project9grid-app` repository 根目錄。不要只上傳 ZIP 檔。

## Sprint 2

- 每位客戶的互動九宮格
- 人脈新增／編輯／追蹤
- 聯絡紀錄 Timeline
- 待辦與生日提醒
- 一鍵成交並建立新九宮格
