USE AIRSET_ACC; -- 切換到你的資料庫

-- 判斷當前節點是否為主要節點
IF (SELECT role_desc FROM sys.dm_hadr_availability_replica_states WHERE is_local = 1) = 'PRIMARY'
BEGIN

DECLARE @sql NVARCHAR(MAX) = N'';
DECLARE @ErrorMessage NVARCHAR(4000);
DECLARE @ErrorSeverity INT;
DECLARE @ErrorState INT;
DECLARE @BatchSize INT = 10; -- 每批次處理 10 個索引
DECLARE @Counter INT = 0;
DECLARE @TotalIndexes INT;
-------------------------------
-- 1. 重建索引
-------------------------------
BEGIN TRY
    -- 計算需要重建的索引總數
    SELECT @TotalIndexes = COUNT(*)
    FROM sys.indexes i
    JOIN sys.tables t ON i.object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    JOIN sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
        ON i.object_id = ips.object_id AND i.index_id = ips.index_id
    WHERE i.type > 0 -- 排除堆表（type = 0）
      AND i.is_disabled = 0 -- 排除被禁用的索引
      AND t.is_ms_shipped = 0 -- 排除系統表
      AND ips.avg_fragmentation_in_percent > 30; -- 僅重建碎片化嚴重的索引

    -- 批次處理索引重建
    WHILE @Counter < @TotalIndexes
    BEGIN
        SET @sql = N''; -- 重置 SQL 腳本變數

        -- 生成當前批次的索引重建語句
        SELECT @sql += 'ALTER INDEX ' + QUOTENAME(IndexName) + ' ON ' + QUOTENAME(SchemaName) + '.' + QUOTENAME(TableName) +
                       ' REBUILD WITH (DATA_COMPRESSION = PAGE);' + CHAR(13) + CHAR(10)
        FROM (
            SELECT i.name AS IndexName, s.name AS SchemaName, t.name AS TableName,
                   ROW_NUMBER() OVER (ORDER BY i.name) AS RowNum
            FROM sys.indexes i
            JOIN sys.tables t ON i.object_id = t.object_id
            JOIN sys.schemas s ON t.schema_id = s.schema_id
            JOIN sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
                ON i.object_id = ips.object_id AND i.index_id = ips.index_id
            WHERE i.type > 0
              AND i.is_disabled = 0
              AND t.is_ms_shipped = 0
              AND ips.avg_fragmentation_in_percent > 30
        ) AS IndexList
        WHERE RowNum BETWEEN @Counter + 1 AND @Counter + @BatchSize;

        -- 執行當前批次的索引重建
        EXEC sp_executesql @sql;

        -- 更新計數器
        SET @Counter += @BatchSize;

        PRINT '已處理 ' + CAST(@Counter AS NVARCHAR) + ' 個索引，剩餘 ' + CAST(@TotalIndexes - @Counter AS NVARCHAR) + ' 個索引待處理。';
    END;

    PRINT '索引重建完成，共處理 ' + CAST(@TotalIndexes AS NVARCHAR) + ' 個索引。';
END TRY
BEGIN CATCH
    -- 捕捉錯誤訊息
    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    -- 輸出錯誤訊息
    PRINT '錯誤發生: ' + @ErrorMessage;
    PRINT '錯誤嚴重性: ' + CAST(@ErrorSeverity AS NVARCHAR);
    PRINT '錯誤狀態: ' + CAST(@ErrorState AS NVARCHAR);

    -- 可選擇將錯誤記錄到日誌表中
     INSERT INTO AIR0_ErrorLog (ErrorMessage, ErrorSeverity, ErrorState, ErrorTime)
     VALUES (@ErrorMessage, @ErrorSeverity, @ErrorState, GETDATE());
END CATCH;

-------------------------------
-- 2. 更新統計資料
-------------------------------
USE AIRSET_ACC; -- 切換到你的資料庫

DECLARE @sql NVARCHAR(MAX) = N'';
DECLARE @ErrorMessage NVARCHAR(4000);
DECLARE @ErrorSeverity INT;
DECLARE @ErrorState INT;
DECLARE @BatchSize INT = 10; -- 每批次處理 10 個表
DECLARE @Counter INT = 0;
DECLARE @TotalTables INT;

BEGIN TRY
    -- 計算需要更新統計資料的表總數
    SELECT @TotalTables = COUNT(DISTINCT t.object_id)
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    JOIN sys.stats st ON t.object_id = st.object_id
    WHERE t.is_ms_shipped = 0 -- 排除系統表
      AND STATS_DATE(st.object_id, st.stats_id) < DATEADD(DAY, -7, GETDATE()); -- 僅更新過舊的統計資料

    -- 批次處理更新統計資料
    WHILE @Counter < @TotalTables
    BEGIN
        SET @sql = N''; -- 重置 SQL 腳本變數

        -- 生成當前批次的更新統計資料語句
        SELECT @sql += 'UPDATE STATISTICS ' + QUOTENAME(SchemaName) + '.' + QUOTENAME(TableName) + ';' + CHAR(13) + CHAR(10)
        FROM (
            SELECT DISTINCT t.object_id, s.name AS SchemaName, t.name AS TableName,
                   ROW_NUMBER() OVER (ORDER BY t.name) AS RowNum
            FROM sys.tables t
            JOIN sys.schemas s ON t.schema_id = s.schema_id
            JOIN sys.stats st ON t.object_id = st.object_id
            WHERE t.is_ms_shipped = 0
              AND STATS_DATE(st.object_id, st.stats_id) < DATEADD(DAY, -7, GETDATE())
        ) AS TableList
        WHERE RowNum BETWEEN @Counter + 1 AND @Counter + @BatchSize;

        -- 執行當前批次的更新統計資料
        EXEC sp_executesql @sql;

        -- 更新計數器
        SET @Counter += @BatchSize;

        PRINT '已處理 ' + CAST(@Counter AS NVARCHAR) + ' 個表，剩餘 ' + CAST(@TotalTables - @Counter AS NVARCHAR) + ' 個表待處理。';
    END;

    PRINT '統計資料更新完成，共處理 ' + CAST(@TotalTables AS NVARCHAR) + ' 個表。';
END TRY
BEGIN CATCH
    -- 捕捉錯誤訊息
    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    -- 輸出錯誤訊息
    PRINT '錯誤發生: ' + @ErrorMessage;
    PRINT '錯誤嚴重性: ' + CAST(@ErrorSeverity AS NVARCHAR);
    PRINT '錯誤狀態: ' + CAST(@ErrorState AS NVARCHAR);

    -- 可選擇將錯誤記錄到日誌表中
     INSERT INTO error_Log (ErrorMessage, ErrorSeverity, ErrorState, ErrorTime)
     VALUES (@ErrorMessage, @ErrorSeverity, @ErrorState, GETDATE());
END CATCH;

-------------------------------
-- 3. 執行後的檢查
-------------------------------
USE AIRSET_ACC; -- 切換到你的資料庫

-- 1. 查詢是否還有碎片化的索引
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent AS Fragmentation
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 10 -- 僅檢查碎片化超過 10% 的索引
  AND i.is_disabled = 0 -- 排除被禁用的索引
  AND OBJECTPROPERTY(ips.object_id, 'IsMsShipped') = 0 -- 排除系統表
ORDER BY Fragmentation DESC;

-- 2. 確認統計資料是否已更新
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    s.name AS StatisticName,
    STATS_DATE(s.object_id, s.stats_id) AS LastUpdated
FROM sys.stats s
JOIN sys.tables t ON s.object_id = t.object_id
WHERE t.is_ms_shipped = 0 -- 排除系統表
  AND STATS_DATE(s.object_id, s.stats_id) >= DATEADD(DAY, -7, GETDATE()) -- 僅顯示最近 7 天內更新的統計資料
ORDER BY LastUpdated DESC;

END
ELSE
BEGIN
    PRINT '當前節點不是主要節點，跳過維護作業。';
END