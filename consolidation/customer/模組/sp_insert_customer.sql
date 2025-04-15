
-- =============================================
-- 名稱：sp_insert_customer
-- 功能：註冊會員（customer + customer_profile），支援所有基本欄位
-- 用途：提供前端註冊介面 / API 直接調用
--範例
--EXEC dbo.sp_insert_customer
--    @email = N'testuser@example.com',
--    @password = N'Abcd1234!',
--    @full_name = N'小王八蛋',
--    @mobile = N'0937277473',
--    @zipcode = N'106',
--    @district = N'台北市大安區',
--    @address = N'和平東路二段101號',
--    @id_number = N'A123456789',
--    @gender = N'M',
--    @birthday = '1990-08-01';
-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_insert_customer
    @email NVARCHAR(100),         -- 登入帳號（必填）
    @password NVARCHAR(255),      -- 密碼（必填）
    @full_name NVARCHAR(50),      -- 中文姓名（必填）
    @mobile NVARCHAR(50),         -- 手機號碼（必填）
    @zipcode NVARCHAR(10) = NULL, -- 郵遞區號（可選）
    @district NVARCHAR(50) = NULL,-- 縣市鄉鎮（可選）
    @address NVARCHAR(200) = NULL,-- 詳細地址（可選）
    @id_number NVARCHAR(20) = NULL, -- 身分證字號（可選）
    @gender CHAR(1) = NULL,       -- 性別 M/F（可選）
    @birthday DATE = NULL         -- 出生日期（可選）
AS
BEGIN
    SET NOCOUNT ON;

    -- 檢查帳號是否重複
    IF EXISTS (SELECT 1 FROM dbo.customer WHERE email = @email)
    BEGIN
        RAISERROR('此帳號已存在，請使用其他帳號', 16, 1);
        RETURN;
    END

    -- 建立 GUID 主鍵
    DECLARE @customer_id UNIQUEIDENTIFIER = NEWID();
    DECLARE @f_tenant_id VARCHAR(50) = '0'; -- 系統預設

    -- 新增 customer（主表）
    INSERT INTO dbo.customer (
        customer_id, email, password, full_name, is_locked, created_at,
        f_tenant_id
    )
    VALUES (
        @customer_id, @email, @password, @full_name, 0, GETDATE(),
        @f_tenant_id
    );

    -- 新增 customer_profile（擴充資料）
    INSERT INTO dbo.customer_profile (
        customer_id, full_name, mobile, zipcode, district, address,
        id_number, gender, birthday, f_tenant_id
    )
    VALUES (
        @customer_id, @full_name, @mobile, @zipcode, @district, @address,
        @id_number, @gender, @birthday, @f_tenant_id
    );
END;
GO
