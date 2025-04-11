CREATE TABLE dbo.customer_login_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,                 -- 登入紀錄編號
    customer_id UNIQUEIDENTIFIER NOT NULL,                -- 對應 customer
    login_at DATETIME DEFAULT GETDATE(),                  -- 登入時間
    ip_address VARCHAR(50),                               -- IP 位置
    device_info NVARCHAR(100),                            -- 裝置資訊
    CONSTRAINT fk_login_customer FOREIGN KEY (customer_id) REFERENCES dbo.customer(customer_id)
);
GO


-- 加入欄位說明（sp_addextendedproperty）


EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'客戶唯一識別碼（GUID）',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'customer',
    @level2type = N'COLUMN', @level2name = N'customer_id';


EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'登入帳號（Email）',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'customer',
    @level2type = N'COLUMN', @level2name = N'email';


EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'密碼',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'customer',
    @level2type = N'COLUMN', @level2name = N'password';


EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'是否鎖定',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'customer',
    @level2type = N'COLUMN', @level2name = N'is_locked';


EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'帳號建立時間',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'customer',
    @level2type = N'COLUMN', @level2name = N'created_at';


EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'中文姓名',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'customer',
    @level2type = N'COLUMN', @level2name = N'full_name';


EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'個資編號',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'customer_profile',
    @level2type = N'COLUMN', @level2name = N'profile_id';


EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'對應 customer',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'customer_profile',
    @level2type = N'COLUMN', @level2name = N'customer_id';


EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'中文姓名',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'customer_profile',
    @level2type = N'COLUMN', @level2name = N'full_name';


EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'性別（男/女）',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'customer_profile',
    @level2type = N'COLUMN', @level2name = N'gender';


EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'身分證字號',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'customer_profile',
    @level2type = N'COLUMN', @level2name = N'id_number';


EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'郵遞區號',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'customer_profile',
    @level2type = N'COLUMN', @level2name = N'zipcode';


EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'縣市鄉鎮',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'customer_profile',
    @level2type = N'COLUMN', @level2name = N'district';


EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'地址',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'customer_profile',
    @level2type = N'COLUMN', @level2name = N'address';


EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'聯絡電話',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'customer_profile',
    @level2type = N'COLUMN', @level2name = N'phone';


EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'手機號碼',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'customer_profile',
    @level2type = N'COLUMN', @level2name = N'mobile';


EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'出生日期',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'customer_profile',
    @level2type = N'COLUMN', @level2name = N'birthday';


EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'入倉代號',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'customer_profile',
    @level2type = N'COLUMN', @level2name = N'warehouse_code';


EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'入倉名稱',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'customer_profile',
    @level2type = N'COLUMN', @level2name = N'warehouse_name';


EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'建立時間',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'customer_profile',
    @level2type = N'COLUMN', @level2name = N'created_at';


EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'登入紀錄編號',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'customer_login_log',
    @level2type = N'COLUMN', @level2name = N'log_id';


EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'對應 customer',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'customer_login_log',
    @level2type = N'COLUMN', @level2name = N'customer_id';


EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'登入時間',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'customer_login_log',
    @level2type = N'COLUMN', @level2name = N'login_at';


EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'IP 位置',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'customer_login_log',
    @level2type = N'COLUMN', @level2name = N'ip_address';


EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'裝置資訊',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'customer_login_log',
    @level2type = N'COLUMN', @level2name = N'device_info';