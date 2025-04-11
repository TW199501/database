# 包裹到貨模組（Packages）

本模組為 ELFExpress 跨站點集運資料整併系統的核心組件，負責記錄每筆發貨單及其入倉明細。資料來自各地站點如 AIRSET_HKG、AIRSET_JP 等，最終整合至中央資料庫 `ELFExpress_ConsolidationDB`。

---

## 📦 資料表結構

### 1️⃣ `package`（主表）
- **功能**：每一筆集運發貨單的主紀錄
- **欄位摘要**：
  - `package_id`：主鍵，自增
  - `customer_id`：對應 `customer.customer_id`
  - `email`：客戶帳號
  - `site_code`：集貨站代碼（如 HKG、JPN）
  - `created_at`：建立時間
  - `payment_type` / `delivery_type`：付款與配送方式代碼
  - `receiver_name` / `receiver_phone` / `receiver_address`
  - `total_weight` / `shipping_fee`
  - `status`：狀態
  - `external_id`：來源系統發貨單號（唯一值）

---

### 2️⃣ `package_entry`（子表）
- **功能**：記錄主單內部每一件實際包裹明細
- **欄位摘要**：
  - `entry_id`：主鍵，自增
  - `package_id`：對應主單 ID
  - `courier_number`：快遞單號
  - `courier_name`：快遞公司名稱
  - `product_name`：商品名稱
  - `quantity`：數量
  - `weight` / `volume_weight`
  - `measured_at`：測量時間

---

## 🔁 同步邏輯說明

系統透過排程執行預存程序 `sp_sync_package_all_sites_v2` 自動同步來自各站點資料，邏輯包含：

- 遍歷所有 AIRSET_ 開頭的資料庫
- 以 `發貨完成日 > @LastSyncTime` 為條件擷取資料
- 使用 `NOT EXISTS` 避免重複寫入
- `external_id` ➝ `package_id` 建立關聯
- 明細表缺失時自動跳過處理

---

## 🧩 主明細整併查詢範例

```sql
SELECT
    p.package_id,
    p.external_id AS 發貨單號,
    p.email AS 客戶帳號,
    p.site_code AS 集貨站,
    p.created_at AS 建立時間,
    p.receiver_name AS 收件人,
    p.receiver_phone,
    p.receiver_address,
    p.total_weight,
    p.shipping_fee,
    p.status,
    e.entry_id,
    e.courier_number,
    e.courier_name,
    e.product_name,
    e.quantity,
    e.weight,
    e.volume_weight,
    e.measured_at
FROM dbo.package p
LEFT JOIN dbo.package_entry e ON e.package_id = p.package_id
ORDER BY p.package_id, e.entry_id;
```

---

## 📌 備註與擴充性
- 適合對應國際集運站點多源資料收斂
- 可與 `customer` 表連結，以追蹤客戶歷史紀錄
- 建議搭配 `sp_sync_metadata_all.sql` 同步 schema metadata

---

開發者：王南傑（@tw202415）  
最後更新：2025 年 4 月
