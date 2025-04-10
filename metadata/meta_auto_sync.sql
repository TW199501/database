/*
==============================================
檔案名稱: meta_auto_sync.sql
所屬模組: meta schema
用途: 建表修表同步結構          
建立日期: 2025-04-09
建立者: 楊清雲（@eddie）
適用環境: SQL Server 2022 - ELF 資料庫
==============================================
### 含以下元件
|`trg_AuditTableCreation`      | 建表即時記錄來源與說明 |
|`sp_sync_tables`              | 從 `sys.tables` 補錄歷史表 |
|`sp_sync_table_columns`       | 同步欄位結構（PK、預設、型別、索引） |
|`sp_sync_foreign_keys`        | 同步外鍵資料 |
|`sp_sync_column_descriptions` | 自動補入欄位的 `MS_Description` 中文說明 |
|`sp_sync_metadata_all`        | 總控程序，執行所有同步 |

### 完整同步指令：
```sql
EXEC sp_sync_tables;
EXEC sp_sync_table_columns;
EXEC sp_sync_foreign_keys;
EXEC sp_sync_column_descriptions;
*/

-- ================================================
-- 觸發器：建立資料表觸發器
-- ================================================

IF EXISTS (
    SELECT * FROM sys.triggers 
    WHERE name = 'trg_AuditTableCreation' AND parent_class_desc = 'DATABASE'
)
BEGIN
    DECLARE @sql NVARCHAR(MAX) = 'DROP TRIGGER trg_AuditTableCreation ON DATABASE';
    EXEC sp_executesql @sql;
END
GO

CREATE TRIGGER trg_AuditTableCreation
ON DATABASE
FOR CREATE_TABLE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @event XML = EVENTDATA();
    DECLARE @schema NVARCHAR(128) = @event.value('(/EVENT_INSTANCE/SchemaName)[1]', 'NVARCHAR(128)');
    DECLARE @table NVARCHAR(128) = @event.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(128)');
    DECLARE @login NVARCHAR(128) = @event.value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(128)');
    DECLARE @host NVARCHAR(128) = HOST_NAME();
    DECLARE @app NVARCHAR(128) = APP_NAME();
    DECLARE @ts DATETIME = GETDATE();

    DECLARE @desc NVARCHAR(500) = CONCAT(
        N'由 ', @login,
        N'（App: ', @app,
        N', Host: ', @host,
        N'）於 ', CONVERT(NVARCHAR, @ts, 120), N' 建立'
    );

    IF NOT EXISTS (
        SELECT 1 FROM schema_tables
        WHERE table_schema = @schema AND table_name = @table
    )
    BEGIN
        INSERT INTO schema_tables (table_schema, table_name, table_description)
        VALUES (@schema, @table, @desc);
    END
END;
GO

-- ====================================================
-- 預存程序：同步 schematables 表資料(接受任何來源定序)
-- ====================================================
IF OBJECT_ID('sp_sync_tables', 'P') IS NOT NULL
    DROP PROCEDURE sp_sync_tables;
GO

CREATE PROCEDURE sp_sync_tables
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO schema_tables (table_schema, table_name, table_description)
    SELECT
        s.name COLLATE Latin1_General_100_CI_AS_SC_UTF8, 
        t.name COLLATE Latin1_General_100_CI_AS_SC_UTF8,
        ISNULL(CAST(ep.value AS NVARCHAR(500)), N'（補錄）存在於系統但未由觸發器建立')
           COLLATE Latin1_General_100_CI_AS_SC_UTF8
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    LEFT JOIN sys.extended_properties ep 
        ON ep.major_id = t.object_id AND ep.name = 'MS_Description' AND ep.minor_id = 0
    WHERE NOT EXISTS (
        SELECT 1 FROM schema_tables m
        WHERE 
            m.table_schema = s.name COLLATE Latin1_General_100_CI_AS_SC_UTF8 AND
            m.table_name = t.name COLLATE Latin1_General_100_CI_AS_SC_UTF8
    );
END;
GO

-- =============================================================
-- 預存程序：同步 schema_foreign_keys 外鍵資料(接受任何來源定序)
-- =============================================================
IF OBJECT_ID('sp_sync_foreign_keys', 'P') IS NOT NULL DROP PROCEDURE sp_sync_foreign_keys;
GO
CREATE PROCEDURE sp_sync_foreign_keys
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO schema_foreign_keys (
        constraint_name, table_schema, table_name, column_name,
        referenced_schema, referenced_table, referenced_column,
        on_delete_action, on_update_action
    )
    SELECT
        fk.name COLLATE Latin1_General_100_CI_AS_SC_UTF8, 
        sch1.name COLLATE Latin1_General_100_CI_AS_SC_UTF8, 
        tab1.name COLLATE Latin1_General_100_CI_AS_SC_UTF8, 
        col1.name COLLATE Latin1_General_100_CI_AS_SC_UTF8,
        sch2.name COLLATE Latin1_General_100_CI_AS_SC_UTF8, 
        tab2.name COLLATE Latin1_General_100_CI_AS_SC_UTF8, 
        col2.name COLLATE Latin1_General_100_CI_AS_SC_UTF8,
        'NO ACTION', 'NO ACTION'
    FROM sys.foreign_keys fk
    JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
    JOIN sys.tables tab1 ON fk.parent_object_id = tab1.object_id
    JOIN sys.schemas sch1 ON tab1.schema_id = sch1.schema_id
    JOIN sys.columns col1 ON tab1.object_id = col1.object_id AND fkc.parent_column_id = col1.column_id
    JOIN sys.tables tab2 ON fk.referenced_object_id = tab2.object_id
    JOIN sys.schemas sch2 ON tab2.schema_id = sch2.schema_id
    JOIN sys.columns col2 ON tab2.object_id = col2.object_id AND fkc.referenced_column_id = col2.column_id
    WHERE NOT EXISTS (
        SELECT 1 FROM schema_foreign_keys m 
        WHERE m.constraint_name = fk.name COLLATE Latin1_General_100_CI_AS_SC_UTF8
    );
END;
GO

-- =======================================================
-- sp_sync_table_columns（防止主鍵衝突）(接受任何來源定序)
-- =======================================================

IF OBJECT_ID('sp_sync_table_columns', 'P') IS NOT NULL
    DROP PROCEDURE sp_sync_table_columns;
GO

CREATE PROCEDURE sp_sync_table_columns
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO schema_columns (
        table_schema, table_name, column_name, ordinal_position, data_type,
        is_nullable, column_default, is_primary_key, is_unique, is_indexed, column_description
    )
    SELECT DISTINCT
        s.name COLLATE Latin1_General_100_CI_AS_SC_UTF8,
        t.name COLLATE Latin1_General_100_CI_AS_SC_UTF8, 
        c.name COLLATE Latin1_General_100_CI_AS_SC_UTF8, 
        c.column_id,
        TYPE_NAME(c.system_type_id) + 
            CASE 
                WHEN TYPE_NAME(c.system_type_id) IN ('varchar','nvarchar','char','nchar') 
                    THEN '(' + CAST(c.max_length AS NVARCHAR) + ')'
                ELSE '' 
            END,
        c.is_nullable,
        dc.definition,
        ISNULL(pk.is_primary_key, 0),
        ISNULL(i.is_unique, 0),
        ISNULL(ix.is_indexed, 0),
        NULL
    FROM sys.columns c
    INNER JOIN sys.tables t ON c.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    LEFT JOIN sys.default_constraints dc ON c.default_object_id = dc.object_id
    LEFT JOIN (
        SELECT ic.object_id, ic.column_id, 1 AS is_primary_key
        FROM sys.index_columns ic
        JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
        WHERE i.is_primary_key = 1
    ) pk ON c.object_id = pk.object_id AND c.column_id = pk.column_id
    LEFT JOIN (
        SELECT ic.object_id, ic.column_id, 1 AS is_unique
        FROM sys.index_columns ic
        JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
        WHERE i.is_unique = 1
    ) i ON c.object_id = i.object_id AND c.column_id = i.column_id
    LEFT JOIN (
        SELECT ic.object_id, ic.column_id, 1 AS is_indexed
        FROM sys.index_columns ic
        GROUP BY ic.object_id, ic.column_id
    ) ix ON c.object_id = ix.object_id AND c.column_id = ix.column_id
    WHERE NOT EXISTS (
        SELECT 1 FROM schema_columns m
        WHERE 
           m.table_schema = s.name COLLATE Latin1_General_100_CI_AS_SC_UTF8 AND 
           m.table_name = t.name COLLATE Latin1_General_100_CI_AS_SC_UTF8 AND 
           m.column_name = c.name COLLATE Latin1_General_100_CI_AS_SC_UTF8
    );
END;
GO

-- ==========================================================================
-- 預存程序：描述schema_columns 尚未寫入或者更新 MS_Description(接受任何來源定序)
-- ==========================================================================

IF OBJECT_ID('sp_sync_column_descriptions', 'P') IS NOT NULL
    DROP PROCEDURE sp_sync_column_descriptions;
GO

CREATE PROCEDURE sp_sync_column_descriptions
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE c
    SET c.column_description = CAST(ep.value AS NVARCHAR(1000))
    FROM schema_columns c
    JOIN sys.extended_properties ep 
        ON ep.name = 'MS_Description'
        AND ep.class = 1
    JOIN sys.columns sc 
        ON ep.major_id = sc.object_id AND ep.minor_id = sc.column_id
    JOIN sys.tables t 
        ON sc.object_id = t.object_id
    JOIN sys.schemas s 
        ON t.schema_id = s.schema_id
    WHERE 
        c.table_schema = s.name COLLATE Latin1_General_100_CI_AS_SC_UTF8 AND
        c.table_name = t.name COLLATE Latin1_General_100_CI_AS_SC_UTF8 AND
        c.column_name = sc.name COLLATE Latin1_General_100_CI_AS_SC_UTF8 AND
        (
            c.column_description IS NULL OR 
            c.column_description <> CAST(ep.value AS NVARCHAR(1000))
        );
END;
GO

-- ================================================
-- 📌 總控程序：sp_sync_metadata_all（整合同步）
-- ================================================

IF OBJECT_ID('sp_sync_metadata_all', 'P') IS NOT NULL
    DROP PROCEDURE sp_sync_metadata_all;
GO

CREATE PROCEDURE sp_sync_metadata_all
AS
BEGIN
    SET NOCOUNT ON;
    EXEC sp_sync_tables;
    EXEC sp_sync_table_columns;
    EXEC sp_sync_foreign_keys;
    EXEC sp_sync_column_descriptions;
END;
GO


-- ✅ 自動同步一次（可重複執行）
EXEC sp_sync_metadata_all;
GO