/*
==============================================
檔案名稱: reset_schemafull.sql
所屬模組: meta schema
用途: 重置 schema metadata 架構（清除觸發器 + 預存程序 + 資料）
預存程序：同步 acc0_schema_tables（來自 MS_Description）         
建立日期: 2025-04-09
建立者: 楊清雲（@eddie）
適用環境: SQL Server 2022 - ELF 資料庫
==============================================
*/
-- 移除建表觸發器
IF EXISTS (
    SELECT * FROM sys.triggers WHERE name = 'trg_AuditTableCreation'
)
BEGIN
    DECLARE @sql NVARCHAR(MAX) = 'DROP TRIGGER trg_AuditTableCreation ON DATABASE';
    EXEC sp_executesql @sql;
END;
GO

-- 移除所有同步用預存程序
DROP PROCEDURE IF EXISTS sp_sync_tables;
DROP PROCEDURE IF EXISTS sp_sync_table_columns;
DROP PROCEDURE IF EXISTS sp_sync_foreign_keys;
DROP PROCEDURE IF EXISTS sp_sync_column_descriptions;
DROP PROCEDURE IF EXISTS sp_sync_metadata_all;
GO

-- 清空三張 schema 主控資料表
DELETE FROM schema_foreign_keys;
DELETE FROM schema_columns;
DELETE FROM schema_tables;
CHECKPOINT;
GO