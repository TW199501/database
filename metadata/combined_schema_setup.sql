--請注意要加上要使用的DB 才能一鍵執行
USE ELFExpress_ConsolidationDB
-- ==============================
-- Begin: reset_schemafull.sql
-- ==============================
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
-- ====================================
-- ⛔️ 移除觸發器（若存在）
-- ====================================
IF EXISTS (
    SELECT * FROM sys.triggers WHERE name = 'trg_AuditTableCreation'
)
BEGIN
    DECLARE @sql NVARCHAR(MAX) = 'DROP TRIGGER trg_AuditTableCreation ON DATABASE';
    EXEC sp_executesql @sql;
END;
GO

-- ====================================
-- ⛔️ 移除同步用預存程序（如果存在）
-- ====================================
DROP PROCEDURE IF EXISTS sp_sync_tables;
DROP PROCEDURE IF EXISTS sp_sync_table_columns;
DROP PROCEDURE IF EXISTS sp_sync_foreign_keys;
DROP PROCEDURE IF EXISTS sp_sync_column_descriptions;
DROP PROCEDURE IF EXISTS sp_sync_metadata_all;
GO

-- ====================================
-- ⛔️ 清除 schema 資料表（若存在先刪除再重建）
-- ====================================
IF OBJECT_ID('schema_foreign_keys', 'U') IS NOT NULL
    DROP TABLE schema_foreign_keys;
IF OBJECT_ID('schema_columns', 'U') IS NOT NULL
    DROP TABLE schema_columns;
IF OBJECT_ID('schema_tables', 'U') IS NOT NULL
    DROP TABLE schema_tables;
GO

-- ✅ 如果你要重新建立這些表，可接著加上 CREATE TABLE 語句
-- 否則執行到這邊為止會把舊的資料全部清除掉

-- 強制資料寫入磁碟
CHECKPOINT;
GO

-- ==============================
-- Begin: schema_tables.sql
-- ==============================
/*
==============================================
檔案名稱: schema_columns.sql
所屬模組: meta schema
用途: 記錄資料表欄位結構與屬性（meta 設計用）         
建立日期: 2025-04-09
建立者: 楊清雲（@eddie）
適用環境: SQL Server 2022 - ELF 資料庫
==============================================
*/

-- ----------------------------
-- Table structure for schema_tables
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[schema_tables]') AND type IN ('U'))
	DROP TABLE [dbo].[schema_tables]
GO

CREATE TABLE [dbo].[schema_tables] (
  [table_schema] nvarchar(100) COLLATE Latin1_General_100_CI_AS_SC_UTF8  NOT NULL,
  [table_name] nvarchar(200) COLLATE Latin1_General_100_CI_AS_SC_UTF8  NOT NULL,
  [table_description] nvarchar(500) COLLATE Latin1_General_100_CI_AS_SC_UTF8  NULL
)
GO

ALTER TABLE [dbo].[schema_tables] SET (LOCK_ESCALATION = TABLE)
GO

EXEC sp_addextendedproperty
'MS_Description', N'一般為 ''dbo''',
'SCHEMA', N'dbo',
'TABLE', N'schema_tables',
'COLUMN', N'table_schema'
GO

EXEC sp_addextendedproperty
'MS_Description', N'表名稱',
'SCHEMA', N'dbo',
'TABLE', N'schema_tables',
'COLUMN', N'table_name'
GO

EXEC sp_addextendedproperty
'MS_Description', N'中文描述',
'SCHEMA', N'dbo',
'TABLE', N'schema_tables',
'COLUMN', N'table_description'
GO

EXEC sp_addextendedproperty
'MS_Description', N'記錄所有資料表的名稱與中文說明（meta 設計用）',
'SCHEMA', N'dbo',
'TABLE', N'schema_tables'
GO


-- ----------------------------
-- Primary Key structure for table schema_tables
-- ----------------------------
ALTER TABLE [dbo].[schema_tables] ADD CONSTRAINT [PK__acc0_sch__151BBDB81131EB37] PRIMARY KEY CLUSTERED ([table_schema], [table_name])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO

-- ==============================
-- Begin: schema_columns.sql
-- ==============================
/*
==============================================
檔案名稱: schema_columns.sql
所屬模組: meta schema
用途: 記錄資料表欄位結構與屬性（meta 設計用）         
建立日期: 2025-04-09
建立者: 楊清雲（@eddie）
適用環境: SQL Server 2022 - ELF 資料庫
==============================================
*/

-- ----------------------------
-- Table structure for schema_columns
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[schema_columns]') AND type IN ('U'))
	DROP TABLE [dbo].[schema_columns]
GO

CREATE TABLE [dbo].[schema_columns] (
  [table_schema] nvarchar(100) COLLATE Latin1_General_100_CI_AS_SC_UTF8  NOT NULL,
  [table_name] nvarchar(200) COLLATE Latin1_General_100_CI_AS_SC_UTF8  NOT NULL,
  [column_name] nvarchar(200) COLLATE Latin1_General_100_CI_AS_SC_UTF8  NOT NULL,
  [ordinal_position] int  NOT NULL,
  [data_type] nvarchar(100) COLLATE Latin1_General_100_CI_AS_SC_UTF8  NOT NULL,
  [is_nullable] bit  NOT NULL,
  [column_default] nvarchar(500) COLLATE Latin1_General_100_CI_AS_SC_UTF8  NULL,
  [is_primary_key] bit DEFAULT 0 NULL,
  [is_unique] bit DEFAULT 0 NULL,
  [is_indexed] bit DEFAULT 0 NULL,
  [column_description] nvarchar(1000) COLLATE Latin1_General_100_CI_AS_SC_UTF8  NULL
)
GO

ALTER TABLE [dbo].[schema_columns] SET (LOCK_ESCALATION = TABLE)
GO

EXEC sp_addextendedproperty
'MS_Description', N'資料所屬的 Schema 名稱（通常為 dbo）',
'SCHEMA', N'dbo',
'TABLE', N'schema_columns',
'COLUMN', N'table_schema'
GO

EXEC sp_addextendedproperty
'MS_Description', N'表格名稱',
'SCHEMA', N'dbo',
'TABLE', N'schema_columns',
'COLUMN', N'table_name'
GO

EXEC sp_addextendedproperty
'MS_Description', N'欄位名稱',
'SCHEMA', N'dbo',
'TABLE', N'schema_columns',
'COLUMN', N'column_name'
GO

EXEC sp_addextendedproperty
'MS_Description', N'欄位在資料表中的順序',
'SCHEMA', N'dbo',
'TABLE', N'schema_columns',
'COLUMN', N'ordinal_position'
GO

EXEC sp_addextendedproperty
'MS_Description', N'SQL Server 資料型別（含長度）',
'SCHEMA', N'dbo',
'TABLE', N'schema_columns',
'COLUMN', N'data_type'
GO

EXEC sp_addextendedproperty
'MS_Description', N'是否可為 NULL（0: 必填, 1: 可空）',
'SCHEMA', N'dbo',
'TABLE', N'schema_columns',
'COLUMN', N'is_nullable'
GO

EXEC sp_addextendedproperty
'MS_Description', N'預設值定義（如 newsequentialid()）',
'SCHEMA', N'dbo',
'TABLE', N'schema_columns',
'COLUMN', N'column_default'
GO

EXEC sp_addextendedproperty
'MS_Description', N'是否為主鍵欄位',
'SCHEMA', N'dbo',
'TABLE', N'schema_columns',
'COLUMN', N'is_primary_key'
GO

EXEC sp_addextendedproperty
'MS_Description', N'是否為唯一鍵欄位',
'SCHEMA', N'dbo',
'TABLE', N'schema_columns',
'COLUMN', N'is_unique'
GO

EXEC sp_addextendedproperty
'MS_Description', N'是否有索引',
'SCHEMA', N'dbo',
'TABLE', N'schema_columns',
'COLUMN', N'is_indexed'
GO

EXEC sp_addextendedproperty
'MS_Description', N'欄位用途說明／中文備註',
'SCHEMA', N'dbo',
'TABLE', N'schema_columns',
'COLUMN', N'column_description'
GO

EXEC sp_addextendedproperty
'MS_Description', N'記錄資料表欄位結構與屬性（meta 設計用）',
'SCHEMA', N'dbo',
'TABLE', N'schema_columns'
GO


-- ----------------------------
-- Primary Key structure for table schema_columns
-- ----------------------------
ALTER TABLE [dbo].[schema_columns] ADD CONSTRAINT [PK_schema_columns] PRIMARY KEY CLUSTERED ([table_schema], [table_name], [column_name])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO

-- ==============================
-- Begin: schema_foreign_keys.sql
-- ==============================
/*
==============================================
檔案名稱: schema_foreign_keys.sql
所屬模組: meta schema
用途: 記錄外鍵關聯（來源表 → 目標表）與行為條件      
建立日期: 2025-04-09
建立者: 楊清雲（@eddie）
適用環境: SQL Server 2022 - ELF 資料庫
==============================================
*/

-- ----------------------------
-- Table structure for schema_foreign_keys
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[schema_foreign_keys]') AND type IN ('U'))
	DROP TABLE [dbo].[schema_foreign_keys]
GO

CREATE TABLE [dbo].[schema_foreign_keys] (
  [constraint_name] nvarchar(200) COLLATE Latin1_General_100_CI_AS_SC_UTF8  NOT NULL,
  [table_schema] nvarchar(100) COLLATE Latin1_General_100_CI_AS_SC_UTF8  NOT NULL,
  [table_name] nvarchar(200) COLLATE Latin1_General_100_CI_AS_SC_UTF8  NOT NULL,
  [column_name] nvarchar(200) COLLATE Latin1_General_100_CI_AS_SC_UTF8  NOT NULL,
  [referenced_schema] nvarchar(100) COLLATE Latin1_General_100_CI_AS_SC_UTF8  NOT NULL,
  [referenced_table] nvarchar(200) COLLATE Latin1_General_100_CI_AS_SC_UTF8  NOT NULL,
  [referenced_column] nvarchar(200) COLLATE Latin1_General_100_CI_AS_SC_UTF8  NOT NULL,
  [on_delete_action] nvarchar(50) COLLATE Latin1_General_100_CI_AS_SC_UTF8 DEFAULT 'NO ACTION' NULL,
  [on_update_action] nvarchar(50) COLLATE Latin1_General_100_CI_AS_SC_UTF8 DEFAULT 'NO ACTION' NULL
)
GO

ALTER TABLE [dbo].[schema_foreign_keys] SET (LOCK_ESCALATION = TABLE)
GO

EXEC sp_addextendedproperty
'MS_Description', N'外鍵約束名稱（constraint name）',
'SCHEMA', N'dbo',
'TABLE', N'schema_foreign_keys',
'COLUMN', N'constraint_name'
GO

EXEC sp_addextendedproperty
'MS_Description', N'來源表格的 Schema 名稱',
'SCHEMA', N'dbo',
'TABLE', N'schema_foreign_keys',
'COLUMN', N'table_schema'
GO

EXEC sp_addextendedproperty
'MS_Description', N'來源表格的名稱',
'SCHEMA', N'dbo',
'TABLE', N'schema_foreign_keys',
'COLUMN', N'table_name'
GO

EXEC sp_addextendedproperty
'MS_Description', N'來源欄位名稱',
'SCHEMA', N'dbo',
'TABLE', N'schema_foreign_keys',
'COLUMN', N'column_name'
GO

EXEC sp_addextendedproperty
'MS_Description', N'被參照的表格的 Schema 名稱',
'SCHEMA', N'dbo',
'TABLE', N'schema_foreign_keys',
'COLUMN', N'referenced_schema'
GO

EXEC sp_addextendedproperty
'MS_Description', N'被參照的表格名稱',
'SCHEMA', N'dbo',
'TABLE', N'schema_foreign_keys',
'COLUMN', N'referenced_table'
GO

EXEC sp_addextendedproperty
'MS_Description', N'被參照的欄位名稱',
'SCHEMA', N'dbo',
'TABLE', N'schema_foreign_keys',
'COLUMN', N'referenced_column'
GO

EXEC sp_addextendedproperty
'MS_Description', N'刪除時的行為（如 NO ACTION）',
'SCHEMA', N'dbo',
'TABLE', N'schema_foreign_keys',
'COLUMN', N'on_delete_action'
GO

EXEC sp_addextendedproperty
'MS_Description', N'更新時的行為（如 NO ACTION）',
'SCHEMA', N'dbo',
'TABLE', N'schema_foreign_keys',
'COLUMN', N'on_update_action'
GO

EXEC sp_addextendedproperty
'MS_Description', N'記錄外鍵關聯（來源表 → 目標表）與行為條件',
'SCHEMA', N'dbo',
'TABLE', N'schema_foreign_keys'
GO


-- ----------------------------
-- Primary Key structure for table schema_foreign_keys
-- ----------------------------
ALTER TABLE [dbo].[schema_foreign_keys] ADD CONSTRAINT [PK__acc0_sch__543B5D879705F66D] PRIMARY KEY CLUSTERED ([constraint_name])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO

-- ==============================
-- Begin: meta_auto_sync.sql
-- ==============================
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

