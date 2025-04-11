CREATE TABLE dbo.customer (
    customer_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), -- 客戶唯一識別碼（GUID）
    email NVARCHAR(100),           -- 登入帳號（Email）
    password NVARCHAR(255),        -- 密碼
    is_locked BIT DEFAULT 0,       -- 是否鎖定
    created_at DATETIME DEFAULT GETDATE(), -- 建立時間
    full_name NVARCHAR(50)         -- 中文姓名
);
GO

-- 建立 customer_profile 表（個資含聯絡資訊）