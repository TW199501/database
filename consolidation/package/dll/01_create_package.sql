CREATE TABLE dbo.package (
    package_id INT IDENTITY(1,1) PRIMARY KEY,                     -- 集運單編號（主鍵，自增）
    customer_id UNIQUEIDENTIFIER NOT NULL,                        -- 對應 customer.customer_id
    email NVARCHAR(100),                                          -- 客戶 Email
    site_code VARCHAR(10),                                        -- 集貨站代碼
    created_at DATETIME DEFAULT GETDATE(),                        -- 建立時間
    payment_type INT,                                             -- 付款方式代碼
    delivery_type INT,                                            -- 配送方式代碼
    receiver_name NVARCHAR(50),                                   -- 收件人姓名
    receiver_phone NVARCHAR(50),                                  -- 收件人電話
    receiver_address NVARCHAR(200),                               -- 收件人地址
    total_weight DECIMAL(10,2),                                   -- 總重量（公斤）
    shipping_fee DECIMAL(10,2),                                   -- 運費金額
    status VARCHAR(20),                                           -- 狀態
    external_id INT NULL                                          -- 舊系統發貨單號
);
GO

-- 建立 package_entry 子表