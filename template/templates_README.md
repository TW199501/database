
# 📦 SQL 模組腳本模板說明（SP + Job）

這個模板集合提供了一致且可複用的 SQL Server 腳本範本，涵蓋儲存程序（Stored Procedure）與排程任務（SQL Agent Job）兩種用途，支援模組化與參數化編寫，讓你在企業內部開發維運工作中快速落地部署。

---

## 🧩 1. `sp_template.sql` - 儲存程序公版模板

### 功能：
- 建立統一格式的 SP
- 支援 `TRY/CATCH` 錯誤處理與交易控制
- 適合封裝複雜邏輯或 CRUD 操作

### 修改方式：
只需要調整以下部分：
```sql
CREATE OR ALTER PROCEDURE [dbo].[sp_功能名稱_描述用途]
(
    @param1 NVARCHAR(100),  -- 📌 修改參數名稱
    @param2 INT = NULL      -- 📌 可選預設值
)
```
- 並撰寫你要執行的主要邏輯區塊於 `BEGIN TRY...END TRY` 區塊內。

---

## ⏰ 2. `job_template_v2.sql` - SQL Agent Job 建立模板（進階版）

### 功能：
- 自動建立一組 SQL Server Job
- 可自定義排程頻率、執行時間與內容
- 所有項目皆以 `DECLARE` 變數設為參數，可複製套用

### 修改方式：

只需編輯開頭區塊的參數，範例如下：

```sql
DECLARE @JobName         = N'job_sync_metadata_daily';
DECLARE @JobCommand      = N'EXEC sp_sync_metadata_all;';
DECLARE @FreqType        = 4;        -- 每日
DECLARE @ActiveStartTime = 80000;    -- 08:00:00
```

### 排程頻率對照表：

| `@FreqType` | 排程類型     |
|-------------|--------------|
| 1           | 一次性任務   |
| 4           | 每日         |
| 8           | 每週         |

| `@FreqInterval` | 用法說明       |
|------------------|----------------|
| `1`              | 每日一次       |
| `2~7`            | 每週的星期幾（1=日, 2=一, ..., 7=六） |

| `@ActiveStartTime` | 時間格式    |
|---------------------|-------------|
| `080000`            | 08:00:00 AM |
| `233000`            | 11:30:00 PM |

---

## 📂 建議放置結構

```bash
templates/
├── sp_template.sql
├── job_template_v2.sql
└── README.md
```

---

## ✍️ 建議用途
- 對內部系統維護或批次作業的標準化
- 建構資料倉儲、定時同步、Log 清理等工作
- 搭配 Git 版本控管，實現腳本自動化部署

