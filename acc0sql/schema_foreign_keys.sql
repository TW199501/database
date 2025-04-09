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