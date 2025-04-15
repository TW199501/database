--範例
--EXEC dbo.sp_update_customer
--    @email = N'testuser@example.com',
--    @full_name = N'小王八蛋',
--    @password = N'NewPassword@123',         -- 新密碼
--    @new_full_name = N'南傑測試用';          -- 修改名稱為新名字
---- ✅ 修改會員資訊：修改密碼與姓名（排除不可修改欄位）
CREATE OR ALTER PROCEDURE dbo.sp_update_customer
    @email NVARCHAR(100),             -- 原帳號（必填）
    @full_name NVARCHAR(50),          -- 原姓名（必填）
    @password NVARCHAR(255) = NULL,   -- 新密碼（可選）
    @new_full_name NVARCHAR(50) = NULL -- 新姓名（可選）
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @customer_id UNIQUEIDENTIFIER;

    SELECT @customer_id = customer_id FROM dbo.customer
    WHERE email = @email AND full_name = @full_name;

    IF @customer_id IS NULL
    BEGIN
        RAISERROR('查無此帳號與姓名配對，無法修改。', 16, 1);
        RETURN;
    END

    UPDATE dbo.customer
    SET
        password = ISNULL(@password, password),
        full_name = ISNULL(@new_full_name, full_name)
    WHERE customer_id = @customer_id;

    UPDATE dbo.customer_profile
    SET
        full_name = ISNULL(@new_full_name, full_name)
    WHERE customer_id = @customer_id;
END;
GO
