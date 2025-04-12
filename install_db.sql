/*
==============================================
檔案名稱: install_db.sql
所屬模組: 生產
用途: 創建資料庫腳本
預存程序：無         
建立日期: 2025-04-09
建立者: 楊清雲（@eddie）
適用環境: 資料庫建立初始化腳本（參數化範本）
使用方式：透過變數取代下列 {{db_name}} 欄位
==============================================
*/

CREATE DATABASE [{{ db_name }}]
/*
ON PRIMARY (
    NAME = N'{{ db_name }}',
    FILENAME = N'{{ data_file_path }}\\{{ db_name }}.mdf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10MB
)
LOG ON (
    NAME = N'{{ db_name }}_log',
    FILENAME = N'{{ log_file_path }}\\{{ db_name }}_log.ldf',
    SIZE = 20MB,
    MAXSIZE = 2GB,
    FILEGROWTH = 10%
)
*/
COLLATE Latin1_General_100_CI_AS_SC_UTF8;
GO

-- 設定相容層級
ALTER DATABASE [{{ db_name }}] SET COMPATIBILITY_LEVEL = 140;
GO

-- 設定復原模式
ALTER DATABASE [{{ db_name }}] SET RECOVERY FULL;
GO

-- 建議參數設定
ALTER DATABASE [{{ db_name }}] SET AUTO_CLOSE OFF;
ALTER DATABASE [{{ db_name }}] SET AUTO_SHRINK OFF;
ALTER DATABASE [{{ db_name }}] SET AUTO_CREATE_STATISTICS ON;
ALTER DATABASE [{{ db_name }}] SET AUTO_UPDATE_STATISTICS ON;
ALTER DATABASE [{{ db_name }}] SET AUTO_UPDATE_STATISTICS_ASYNC OFF;
ALTER DATABASE [{{ db_name }}] SET PAGE_VERIFY CHECKSUM;
ALTER DATABASE [{{ db_name }}] SET ANSI_NULLS ON;
ALTER DATABASE [{{ db_name }}] SET QUOTED_IDENTIFIER ON;
ALTER DATABASE [{{ db_name }}] SET ALLOW_SNAPSHOT_ISOLATION ON;
ALTER DATABASE [{{ db_name }}] SET READ_COMMITTED_SNAPSHOT ON;
GO

PRINT '✅ {{ db_name }} 資料庫已成功建立';
