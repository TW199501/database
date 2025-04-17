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

-- =============================================
-- 名稱：ALTER TABLE customer_profile 加入統一編號欄位
-- 說明：補上統一編號欄位 uniform_number，供前端註冊輸入
-- =============================================
ALTER TABLE dbo.customer_profile
ADD uniform_number NVARCHAR(20) NULL;
GO

-- ✅ 加上欄位說明
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'統一編號',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = 'customer_profile',
    @level2type = N'COLUMN', @level2name = 'uniform_number';

-- 建立 customer_login_log 表（登入紀錄）