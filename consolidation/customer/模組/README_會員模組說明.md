
# ELFExpress 會員模組 Stored Procedure 使用說明

本模組提供一套完整的會員系統基本操作流程，使用 SQL Server Stored Procedure 實作，支援：
- 會員註冊（含欄位驗證）
- 登入驗證（含登入紀錄）
- 查詢帳號是否存在
- 修改會員基本資料
- 軟刪除帳號（鎖定）

---

## 📌 1. 註冊會員 `sp_insert_customer`

建立一筆會員資料，寫入 `customer` 與 `customer_profile`：

```sql
EXEC dbo.sp_insert_customer
    @email = N'testuser@example.com',
    @password = N'StrongPass123!',
    @full_name = N'王小明',
    @mobile = N'0912345678',
    @zipcode = N'100',
    @district = N'台北市中正區',
    @address = N'重慶南路一段122號',
    @id_number = N'A123456789',
    @gender = N'M',
    @birthday = '1990-01-01';
```

---

## 🔐 2. 登入驗證（含登入紀錄）`sp_login_full_process`

登入帳號 + 密碼驗證，成功自動寫入 `customer_login_log`：

```sql
EXEC dbo.sp_login_full_process
    @email = N'testuser@example.com',
    @password = N'StrongPass123!',
    @ip_address = N'192.168.1.10',
    @device_info = N'Chrome on Windows 11';
```

成功會回傳：

| customer_id | email | full_name | login_result | message     |
|-------------|--------|-----------|---------------|-------------|
| (GUID)      | testuser@example.com | 王小明 | 1             | 登入成功     |

---

## 🔍 3. 查詢帳號是否存在 `sp_check_customer_exists`

```sql
EXEC dbo.sp_check_customer_exists
    @email = N'testuser@example.com';
```

回傳 `exists_flag = 1` 或 `0`

---

## ✏️ 4. 修改會員 `sp_update_customer`

僅會修改你有傳參數的欄位（其餘保留原值）：

```sql
EXEC dbo.sp_update_customer
    @email = N'testuser@example.com',
    @full_name = N'王小明',
    @password = N'NewPassword@456',            -- 更新密碼
    @new_full_name = N'王小明改名';             -- 改名（選填）
```

---

## 🗑️ 5. 軟刪除會員 `sp_delete_customer`

僅將該帳號 `is_locked = 1`，資料仍保留：

```sql
EXEC dbo.sp_delete_customer
    @email = N'testuser@example.com',
    @full_name = N'王小明改名';
```

---

## 📝 資料表相關：

- `customer`：帳號登入資訊
- `customer_profile`：個資與地址
- `customer_login_log`：登入紀錄

---

## ⚙️ 附註

- 所有 SP 使用 `email + full_name` 做為帳號查找依據
- 密碼為明碼儲存（可另加密）
- 系統欄位如 `f_tenant_id` 自動預設為 `'0'`，不提供修改
- 若帳號已存在，註冊會拋出錯誤

---

ELFExpress 系統 SQL 模組化建構完成 ✅
