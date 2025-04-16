
/***************************************************************************************
 模組名稱：SQL Agent Job 建立模板（進階版）
 說明用途：一鍵建立排程任務，所有必要資訊皆為參數，方便重複使用與自動化
 建立者：請填入
 建立日期：請填入
 範例 : 
 -- ✅ 基本 Job 設定
DECLARE @JobName NVARCHAR(100)         = N'你的排程名稱';
DECLARE @JobDescription NVARCHAR(255)  = N'這支 Job 是做什麼的';
DECLARE @StepName NVARCHAR(100)        = N'步驟名稱';
DECLARE @JobCommand NVARCHAR(MAX)      = N'你要執行的 SQL 指令';

-- ✅ 排程設定
DECLARE @ScheduleName NVARCHAR(100)    = N'排程描述名稱';
DECLARE @FreqType INT                  = 4;         -- 1=一次性, 4=每日, 8=每週
DECLARE @FreqInterval INT              = 1;         -- 若每日就填 1；若每週就填星期幾（1~7）
DECLARE @ActiveStartTime INT           = 83000;     -- 執行時間（例如 08:30:00 = 83000）
***************************************************************************************/

-- ✅ 基本參數設定區（請依實際需求修改）
DECLARE @JobName NVARCHAR(100)         = N'job_功能名稱';
DECLARE @JobDescription NVARCHAR(255)  = N'此排程負責...';
DECLARE @StepName NVARCHAR(100)        = N'執行 SQL 任務';
DECLARE @JobCommand NVARCHAR(MAX)      = N'
-- 📌 在這裡撰寫你想執行的 SQL
-- 例如：EXEC sp_sync_metadata_all;
';

-- ✅ 排程參數設定區（可控制執行頻率與時間）
DECLARE @ScheduleName NVARCHAR(100)    = N'每日排程';
DECLARE @FreqType INT                  = 4;         -- 1=一次, 4=每日, 8=每週
DECLARE @FreqInterval INT              = 1;         -- 每日=1；每週=星期幾（例如 2=週一）
DECLARE @ActiveStartTime INT           = 10000;     -- 開始時間：格式為 HHMMSS（例：93000 = 09:30:00）

-- ✅ 刪除舊 job（如已存在）
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = @JobName)
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = @JobName;
END

-- ✅ 建立 Job
EXEC msdb.dbo.sp_add_job 
    @job_name = @JobName,
    @enabled = 1,
    @description = @JobDescription,
    @category_name = N'[Uncategorized (Local)]',
    @owner_login_name = SUSER_SNAME();

-- ✅ 加入步驟
EXEC msdb.dbo.sp_add_jobstep 
    @job_name = @JobName,
    @step_name = @StepName,
    @subsystem = N'TSQL',
    @command = @JobCommand,
    @retry_attempts = 1,
    @retry_interval = 5;

-- ✅ 設定排程
EXEC msdb.dbo.sp_add_jobschedule 
    @job_name = @JobName,
    @name = @ScheduleName,
    @freq_type = @FreqType,
    @freq_interval = @FreqInterval,
    @active_start_time = @ActiveStartTime;

-- ✅ 指定 server
EXEC msdb.dbo.sp_add_jobserver 
    @job_name = @JobName;
GO
