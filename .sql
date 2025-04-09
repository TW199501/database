-- .清除所有記錄
TRUNCATE TABLE {資料表名稱}
TRUNCATE TABLE schema_foreign_keys; -- 清除所有外鍵資料
TRUNCATE TABLE schema_columns; -- 清除所有欄位資料
TRUNCATE TABLE schema_tables;      -- 清除所有表格資料

-- 執行預存函數
EXEC {函數名稱};
EXEC sp_sync_tables;
EXEC sp_sync_table_columns;
EXEC sp_sync_foreign_keys;