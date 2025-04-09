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