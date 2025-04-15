
-- =============================================
-- 名稱：sp_login_full_process
-- 功能：會員登入流程 + 寫入登入日誌
-- 調用語法
--EXEC dbo.sp_login_full_process
--    @email = N'testuser@example.com',
--    @password = N'Abcd1234!',
--    @ip_address = N'192.168.1.88',
--    @device_info = N'Chrome on Windows 11';

-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_login_full_process
    @email NVARCHAR(100),
    @password NVARCHAR(255),
    @ip_address VARCHAR(50),
    @device_info NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @customer_id UNIQUEIDENTIFIER;
    DECLARE @full_name NVARCHAR(50);

    IF NOT EXISTS (
        SELECT 1 FROM dbo.customer
        WHERE email = @email
    )
    BEGIN
        SELECT NULL AS customer_id, @email AS email, NULL AS full_name,
               0 AS login_result, '帳號不存在' AS message;
        RETURN;
    END

    IF EXISTS (
        SELECT 1 FROM dbo.customer
        WHERE email = @email AND is_locked = 1
    )
    BEGIN
        SELECT NULL AS customer_id, @email AS email, NULL AS full_name,
               0 AS login_result, '帳號已鎖定' AS message;
        RETURN;
    END

    SELECT TOP 1
        @customer_id = customer_id,
        @full_name = full_name
    FROM dbo.customer
    WHERE email = @email AND password = @password;

    IF @customer_id IS NULL
    BEGIN
        SELECT NULL AS customer_id, @email AS email, NULL AS full_name,
               0 AS login_result, '密碼錯誤' AS message;
        RETURN;
    END

    -- ✅ 登入成功，寫入登入日誌
    INSERT INTO dbo.customer_login_log (
        customer_id, login_at, ip_address, device_info
    )
    VALUES (
        @customer_id, GETDATE(), @ip_address, @device_info
    );

    -- ✅ 回傳成功資料
    SELECT @customer_id AS customer_id, @email AS email, @full_name AS full_name,
           1 AS login_result, '登入成功' AS message;
END;
GO
