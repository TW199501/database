--範例
--EXEC dbo.sp_delete_customer
--    @email = N'testuser@example.com',
--    @full_name = N'南傑測試用';  -- 若前面已改名
-- ✅ 軟刪除會員：將 is_locked 設為 1
CREATE OR ALTER PROCEDURE dbo.sp_delete_customer
    @email NVARCHAR(100),
    @full_name NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.customer
    SET is_locked = 1
    WHERE email = @email AND full_name = @full_name;
END;
GO
