CREATE TABLE dbo.package_entry (
    entry_id INT IDENTITY(1,1) PRIMARY KEY,                       -- 明細編號
    package_id INT NOT NULL,                                      -- 對應主表 package_id
    courier_number VARCHAR(50),                                   -- 快遞單號
    courier_name NVARCHAR(50),                                    -- 快遞公司名稱
    product_name NVARCHAR(50),                                    -- 商品名稱
    quantity INT,                                                 -- 數量
    weight DECIMAL(10,2),                                         -- 重量
    volume_weight DECIMAL(10,2),                                  -- 材積重
    measured_at DATETIME,                                         -- 測量時間
    CONSTRAINT fk_package_entry FOREIGN KEY (package_id) REFERENCES dbo.package(package_id)
);
GO

-- 加入欄位註解

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'集運單編號（主鍵，自增）',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'package',
    @level2type = N'COLUMN', @level2name = N'package_id';

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'對應 customer.customer_id',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'package',
    @level2type = N'COLUMN', @level2name = N'customer_id';

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'客戶 Email',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'package',
    @level2type = N'COLUMN', @level2name = N'email';

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'集貨站代碼',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'package',
    @level2type = N'COLUMN', @level2name = N'site_code';

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'建立時間',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'package',
    @level2type = N'COLUMN', @level2name = N'created_at';

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'付款方式代碼',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'package',
    @level2type = N'COLUMN', @level2name = N'payment_type';

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'配送方式代碼',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'package',
    @level2type = N'COLUMN', @level2name = N'delivery_type';

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'收件人姓名',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'package',
    @level2type = N'COLUMN', @level2name = N'receiver_name';

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'收件人電話',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'package',
    @level2type = N'COLUMN', @level2name = N'receiver_phone';

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'收件人地址',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'package',
    @level2type = N'COLUMN', @level2name = N'receiver_address';

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'總重量（公斤）',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'package',
    @level2type = N'COLUMN', @level2name = N'total_weight';

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'運費金額',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'package',
    @level2type = N'COLUMN', @level2name = N'shipping_fee';

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'狀態',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'package',
    @level2type = N'COLUMN', @level2name = N'status';

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'舊系統發貨單號',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'package',
    @level2type = N'COLUMN', @level2name = N'external_id';

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'明細編號（主鍵）',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'package_entry',
    @level2type = N'COLUMN', @level2name = N'entry_id';

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'對應 package.package_id',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'package_entry',
    @level2type = N'COLUMN', @level2name = N'package_id';

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'快遞單號',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'package_entry',
    @level2type = N'COLUMN', @level2name = N'courier_number';

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'快遞公司名稱',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'package_entry',
    @level2type = N'COLUMN', @level2name = N'courier_name';

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'商品名稱',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'package_entry',
    @level2type = N'COLUMN', @level2name = N'product_name';

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'數量',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'package_entry',
    @level2type = N'COLUMN', @level2name = N'quantity';

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'重量（公斤）',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'package_entry',
    @level2type = N'COLUMN', @level2name = N'weight';

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'材積重（公斤）',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'package_entry',
    @level2type = N'COLUMN', @level2name = N'volume_weight';

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'到站 / 測量時間',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = N'package_entry',
    @level2type = N'COLUMN', @level2name = N'measured_at';