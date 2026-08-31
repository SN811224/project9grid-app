客戶名單總表 v6.6.7 — Email Rate Limit 改善

本版維持「Email 驗證」註冊流程，不取消驗證。

已修改前端：
1. Email rate limit exceeded 改為中文提示。
2. 遇到 Rate Limit 後，前端暫停重複送出 60 秒，避免一直按造成限制更嚴重。
3. 常見登入錯誤改為中文：帳號已存在、帳密錯誤、Email 尚未驗證。

重要：Supabase 的真正寄信額度屬於「伺服器端設定」，不能只靠 Flutter/GitHub Pages 程式碼提高。

請到 Supabase Dashboard 進行：
A. Authentication → Rate Limits
   - 提高 Email sending / signup 相關限制（可依目前方案可調範圍設定）。
B. Authentication → SMTP Settings
   - 建議設定自有 SMTP。使用自有 SMTP 後，寄信能力與限制會比內建測試寄信服務更適合正式使用。

建議正式環境：保留 Email 驗證 + 自有 SMTP + 合理提高 Rate Limit。
