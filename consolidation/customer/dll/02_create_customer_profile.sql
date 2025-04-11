CREATE TABLE dbo.customer_profile (
    profile_id INT IDENTITY(1,1) PRIMARY KEY,              -- 個資編號
    customer_id UNIQUEIDENTIFIER NOT NULL,                -- 對應 customer
    full_name NVARCHAR(50),                               -- 中文姓名
    gender NVARCHAR(2),                                   -- 性別（男/女）
    id_number NVARCHAR(20),                               -- 身分證字號
    zipcode CHAR(5),                                      -- 郵遞區號
    district NVARCHAR(50),                                -- 縣市鄉鎮
    address NVARCHAR(80),                                 -- 地址
    phone NVARCHAR(50),                                   -- 聯絡電話
    mobile NVARCHAR(50),                                  -- 手機號碼
    birthday DATETIME,                                    -- 出生日期
    warehouse_code CHAR(5),                               -- 入倉代號
    warehouse_name NVARCHAR(50),                          -- 入倉名稱
    created_at DATETIME DEFAULT GETDATE(),                -- 建立時間
    CONSTRAINT fk_customer_profile FOREIGN KEY (customer_id) REFERENCES dbo.customer(customer_id)
);
GO

-- 建立 customer_login_log 表（登入紀錄）