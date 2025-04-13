USE msdb;
GO

-- ================================================
-- 0. 刪除舊 Job（如存在）
-- ================================================
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'AutoDelete_Acc0Daily')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N'AutoDelete_Acc0Daily', @delete_unused_schedule = 1;
    PRINT N' 舊 Job AutoDelete_Acc0Daily 已刪除';
END
GO

-- ================================================
-- 1. 刪除重複排程（名為 每天23:50）
-- ================================================
DECLARE @sid INT;

DECLARE cur CURSOR FOR
SELECT schedule_id
FROM msdb.dbo.sysschedules
WHERE name = N'每天23:50';

OPEN cur;
FETCH NEXT FROM cur INTO @sid;

WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC msdb.dbo.sp_delete_schedule @schedule_id = @sid;
    PRINT N'舊排程 每天23:50 已刪除一筆';
    FETCH NEXT FROM cur INTO @sid;
END

CLOSE cur;
DEALLOCATE cur;
GO

-- ================================================
-- 2. 建立新的排程：每天 23:50 執行
-- ================================================
EXEC msdb.dbo.sp_add_schedule 
    @schedule_name = N'每天23:50',
    @enabled = 1,
    @freq_type = 4,               -- 每日
    @freq_interval = 1,           -- 每 1 天
    @active_start_time = 235000;  -- 23:50:00
GO

-- ================================================
-- 3. 建立 Job 本體
-- ================================================
EXEC msdb.dbo.sp_add_job 
    @job_name = N'AutoDelete_Acc0Daily', 
    @enabled = 1,
    @description = N'每天23:50 刪除 Acc0其他付款 符合條件資料（僅限 Primary 節點）',
    @start_step_id = 1;
GO

-- ================================================
-- 4. 加入 Job 步驟：判斷 Primary 並備份 + 刪除
-- ================================================
EXEC msdb.dbo.sp_add_jobstep 
    @job_name = N'AutoDelete_Acc0Daily',
    @step_name = N'刪除符合條件資料',
    @subsystem = N'TSQL',
    @database_name = N'AIRSET_ACC',  -- 請確認你的實際資料庫名稱
    @command = N'
IF (
    SELECT TOP 1 ars.role_desc
    FROM sys.dm_hadr_availability_replica_states ars
    JOIN sys.availability_replicas ar
        ON ars.replica_id = ar.replica_id
    WHERE ars.is_local = 1
) = N''PRIMARY''
BEGIN
    -- 備份資料
    IF OBJECT_ID(N''dbo.Acc0刪除其他付款備份紀錄'', N''U'') IS NULL
    BEGIN
        SELECT TOP 0 *
        INTO [dbo].[Acc0刪除其他付款備份紀錄]
        FROM [dbo].[Acc0其他付款];
    END

    INSERT INTO [dbo].[Acc0刪除其他付款備份紀錄]
    SELECT *
    FROM [dbo].[Acc0其他付款]
    WHERE 
        (
            [品項] LIKE N''%集貨幣提現%'' 
            OR [品項] LIKE N''%調稅補收%''
        )
        AND [轉帳狀態] = N''未匯出'';

    -- 刪除資料
    DELETE FROM [dbo].[Acc0其他付款]
    WHERE 
        (
            [品項] LIKE N''%集貨幣提現%'' 
            OR [品項] LIKE N''%調稅補收%''
        )
        AND [轉帳狀態] = N''未匯出'';

    PRINT N'' 資料刪除成功（限主節點）'';
END
ELSE
BEGIN
    PRINT N'' 非主節點，略過刪除動作'';
END
',
    @on_success_action = 1,
    @on_fail_action = 2;
GO

-- ================================================
-- 5. 將排程綁定到 Job
-- ================================================
EXEC msdb.dbo.sp_attach_schedule 
    @job_name = N'AutoDelete_Acc0Daily',
    @schedule_name = N'每天23:50';
GO

-- ================================================
-- 6. 將 Job 附加到本機 SQL Server 執行
-- ================================================
EXEC msdb.dbo.sp_add_jobserver 
    @job_name = N'AutoDelete_Acc0Daily';
GO

PRINT N' 作業 AutoDelete_Acc0Daily 安裝完成，每日 23:50 僅主節點將自動執行資料備份與刪除';
