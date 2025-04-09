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

