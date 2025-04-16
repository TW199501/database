
/***************************************************************************************
 模組名稱：儲存程序公版模板（Stored Procedure Template）
 說明用途：建立一致格式的 SP 架構，供 CRUD、封裝邏輯等用途，支援錯誤控制與交易機制
 建立者：請填入
 建立日期：請填入
***************************************************************************************/

CREATE OR ALTER PROCEDURE [dbo].[sp_功能名稱_描述用途]
(
    @param1 NVARCHAR(100),  -- 📌 請替換參數名稱與型別
    @param2 INT = NULL      -- 📌 可加預設值
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        /***********************************
         📌 請在此撰寫主要邏輯區塊
         EX: INSERT、UPDATE、DELETE、MERGE、SELECT
        ************************************/
        
        -- 範例：
        -- INSERT INTO log_table (msg, created_at)
        -- VALUES ('test', GETDATE());

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;

        -- ⛔ 錯誤訊息統一輸出
        DECLARE @errmsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @errnum INT = ERROR_NUMBER();
        DECLARE @errproc NVARCHAR(200) = ERROR_PROCEDURE();
        DECLARE @errline INT = ERROR_LINE();

        PRINT '錯誤位置：' + ISNULL(@errproc, '(未知)') + ' 第 ' + CAST(@errline AS NVARCHAR) + ' 行';
        PRINT '錯誤訊息：' + ISNULL(@errmsg, '(無錯誤訊息)');
    END CATCH
END;
GO
