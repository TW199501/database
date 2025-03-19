-- Description: 檢查資料庫健康狀態，並將檢查結果記錄到 database_health_log 表中
-- Usage: EXEC check_db_result
-- db_name: datable_health_log
-- ========================================

-------------------------------
-- 資料庫健康狀態日誌表
-------------------------------
CREATE TABLE database_health_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    check_type NVARCHAR(50), -- 檢查類型（例如：索引碎片化、統計資料、備份狀態等）
    database_name NVARCHAR(128), -- 資料庫名稱
    table_name NVARCHAR(128), -- 表名
    index_name NVARCHAR(128), -- 索引名
    statistic_name NVARCHAR(128), -- 統計資料名
    backup_type NVARCHAR(50), -- 備份類型
    fragmentation FLOAT, -- 索引碎片化百分比
    last_updated DATETIME, -- 統計資料最後更新時間
    backup_start_time DATETIME, -- 備份開始時間
    backup_finish_time DATETIME, -- 備份完成時間
    is_damaged BIT, -- 備份是否損壞
    check_db_result NVARCHAR(MAX), -- DBCC CHECKDB 結果
    file_name NVARCHAR(128), -- 文件名
    file_type NVARCHAR(50), -- 文件類型
    size_mb INT, -- 文件大小（MB）
    used_mb INT, -- 已使用空間（MB）
    free_mb INT, -- 剩餘空間（MB）
    log_time DATETIME DEFAULT GETDATE() -- 記錄時間
);
EXEC sp_addextendedproperty  -- 為資料表添加註釋
    @name = N'MS_Description', 
    @value = N'資料庫健康狀態日誌表，用於記錄索引、統計資料、備份等檢查結果。', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE', @level1name = N'database_health_log';

EXEC sp_addextendedproperty  -- 為欄位添加註釋
    @name = N'MS_Description', 
    @value = N'檢查類型（例如：索引碎片化、統計資料、備份狀態等）', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE', @level1name = N'database_health_log', 
    @level2type = N'COLUMN', @level2name = N'check_type';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'資料庫名稱（）', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE', @level1name = N'database_health_log', 
    @level2type = N'COLUMN', @level2name = N'database_name';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'表名（）', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE', @level1name = N'database_health_log', 
    @level2type = N'COLUMN', @level2name = N'table_name';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'索引名（）', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE', @level1name = N'database_health_log', 
    @level2type = N'COLUMN', @level2name = N'index_name';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'統計資料名（）', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE', @level1name = N'database_health_log', 
    @level2type = N'COLUMN', @level2name = N'statistic_name';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'備份類型（）', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE', @level1name = N'database_health_log', 
    @level2type = N'COLUMN', @level2name = N'backup_type';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'索引碎片化百分比', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE', @level1name = N'database_health_log', 
    @level2type = N'COLUMN', @level2name = N'fragmentation';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'統計資料最後更新時間', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE', @level1name = N'database_health_log', 
    @level2type = N'COLUMN', @level2name = N'last_updated';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'備份開始時間', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE', @level1name = N'database_health_log', 
    @level2type = N'COLUMN', @level2name = N'backup_start_time';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'備份完成時間', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE', @level1name = N'database_health_log', 
    @level2type = N'COLUMN', @level2name = N'backup_finish_time';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'備份是否損壞', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE', @level1name = N'database_health_log', 
    @level2type = N'COLUMN', @level2name = N'is_damaged';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'DBCC CHECKDB 結果', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE', @level1name = N'database_health_log', 
    @level2type = N'COLUMN', @level2name = N'check_db_result';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'文件名（）', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE', @level1name = N'database_health_log', 
    @level2type = N'COLUMN', @level2name = N'file_name';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'文件類型（）', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE', @level1name = N'database_health_log', 
    @level2type = N'COLUMN', @level2name = N'file_type';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'文件大小（MB）', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE', @level1name = N'database_health_log', 
    @level2type = N'COLUMN', @level2name = N'size_mb';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'已使用空間（MB）', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE', @level1name = N'database_health_log', 
    @level2type = N'COLUMN', @level2name = N'used_mb';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'剩餘空間（MB）', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE', @level1name = N'database_health_log', 
    @level2type = N'COLUMN', @level2name = N'free_mb';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'記錄時間', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE', @level1name = N'database_health_log', 
    @level2type = N'COLUMN', @level2name = N'log_time';

-------------------------------
-- 檢查資料庫健康狀態
-------------------------------
USE AIRSET_SZ_2; -- 切換到你的資料庫

DECLARE @check_db_result NVARCHAR(MAX);

-- 1. 檢查索引碎片化情況
INSERT INTO database_health_log (check_type, table_name, index_name, fragmentation, log_time)
SELECT 
    'index_fragmentation' AS check_type, 
    OBJECT_NAME(ips.object_id) AS table_name,
    i.name AS index_name,
    ips.avg_fragmentation_in_percent AS fragmentation,
    GETDATE() AS log_time
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 10 -- 僅顯示碎片化超過 10% 的索引
  AND i.is_disabled = 0 -- 排除被禁用的索引
  AND OBJECTPROPERTY(ips.object_id, 'IsMsShipped') = 0; -- 排除系統表

-- 2. 檢查統計資料的最後更新時間
INSERT INTO database_health_log (check_type, table_name, statistic_name, last_updated, log_time)
SELECT 
    'statistics_update' AS check_type, 
    OBJECT_NAME(s.object_id) AS table_name,
    s.name AS statistic_name,
    STATS_DATE(s.object_id, s.stats_id) AS last_updated,
    GETDATE() AS log_time
FROM sys.stats s
JOIN sys.tables t ON s.object_id = t.object_id
WHERE t.is_ms_shipped = 0; -- 排除系統表

-- 3. 檢查備份健康狀態
INSERT INTO database_health_log (check_type, database_name, backup_type, backup_start_time, backup_finish_time, is_damaged, log_time)
SELECT 
    'backup_health' AS check_type, 
    database_name AS database_name,
    CASE type
        WHEN 'D' THEN 'full_backup' 
        WHEN 'I' THEN 'differential_backup' 
        WHEN 'L' THEN 'log_backup' 
    END AS backup_type,
    backup_start_date AS backup_start_time,
    backup_finish_date AS backup_finish_time,
    is_damaged AS is_damaged,
    GETDATE() AS log_time
FROM msdb.dbo.backupset
WHERE database_name = DB_NAME(); -- 僅檢查當前資料庫

-- 4. 檢查資料庫一致性
BEGIN TRY
    DBCC CHECKDB WITH NO_INFOMSGS, ALL_ERRORMSGS;
    SET @check_db_result = 'no_errors_found'; 
END TRY
BEGIN CATCH
    SET @check_db_result = ERROR_MESSAGE();
END CATCH;

INSERT INTO database_health_log (check_type, check_db_result, log_time)
VALUES ('dbcc_checkdb', @check_db_result, GETDATE()); 

-- 5. 檢查資料庫空間使用情況
INSERT INTO database_health_log (check_type, file_name, file_type, size_mb, used_mb, free_mb, log_time)
SELECT 
    'space_usage' AS check_type, 
    name AS file_name,
    type_desc AS file_type,
    size * 8 / 1024 AS size_mb, -- 將頁數轉換為 MB
    FILEPROPERTY(name, 'SpaceUsed') * 8 / 1024 AS used_mb, -- 已使用空間
    (size - FILEPROPERTY(name, 'SpaceUsed')) * 8 / 1024 AS free_mb, -- 剩餘空間
    GETDATE() AS log_time
FROM sys.database_files;