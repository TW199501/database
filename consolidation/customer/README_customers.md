# 客戶模組（Customers）

本模組負責管理平台所有客戶的資料結構與相關操作，支援帳號建立、個資維護、登入記錄追蹤等功能，並可延伸用於集運平台、物流身份綁定、稽核分析等場景。

---

## 📦 主要資料表結構

### 1️⃣ `customer`（客戶主資料）
- **功能**：記錄帳號資訊、註冊狀態
- **欄位說明**：
  - `customer_id` (GUID)：唯一識別碼
  - `email` (帳號)
  - `password` (加密後密碼)
  - `is_locked` (是否停權)
  - `created_at` (註冊時間)
  - `full_name` (使用者姓名)

---

### 2️⃣ `customer_profile`（個人資料表）
- **功能**：儲存中文姓名、聯絡資訊、身份證、倉庫綁定等
- **欄位範例**：
  - `gender`, `id_number`, `zipcode`, `address`
  - `phone`, `mobile`, `birthday`
  - `warehouse_code`, `warehouse_name`

---

### 3️⃣ `customer_login_log`（登入紀錄表）
- **功能**：記錄每次登入時間、IP、裝置資訊
- **欄位範例**：
  - `login_at`, `ip_address`, `device_info`

---

## 🧩 資料關聯與整併查詢

```sql
SELECT
    cu.customer_id,
    cu.email,
    cu.full_name AS 登入姓名,
    cu.created_at AS 註冊時間,
    cp.full_name AS 中文姓名,
    cp.gender, cp.id_number, cp.zipcode, cp.district, cp.address,
    cp.phone, cp.mobile, cp.birthday,
    cp.warehouse_code, cp.warehouse_name,
    cl.login_at AS 最近登入時間,
    cl.ip_address, cl.device_info
FROM dbo.customer cu
LEFT JOIN dbo.customer_profile cp ON cu.customer_id = cp.customer_id
LEFT JOIN dbo.customer_login_log cl ON cu.customer_id = cl.customer_id
ORDER BY cu.created_at DESC;
```

---

## 🛠️ 資料寫入建議

建議使用 Transaction 將主表與個資表同時寫入，確保資料一致性。

```sql
BEGIN TRANSACTION;
DECLARE @new_customer_id UNIQUEIDENTIFIER = NEWID();

INSERT INTO dbo.customer (...)
VALUES (@new_customer_id, ...);

INSERT INTO dbo.customer_profile (...)
VALUES (@new_customer_id, ...);

COMMIT;
```

---

## 🧱 開發備註
- 使用 `uniqueidentifier` 作為主鍵，可利於分散式系統同步
- 所有欄位已具備註解與描述，可與 metadata 結構自動連結
- 建議搭配 `sp_sync_metadata_all.sql` 同步欄位說明至 metadata 模組

---

開發者：王南傑（@tw202415）  
最後更新：2025 年 4 月
