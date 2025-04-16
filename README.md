
### 資料庫規範

#### 資料庫建立規範

##### 一、資料庫命名規則
- 命名風格：全部小駝峰或首字大寫
- 對應用途：
- 資料庫名：

| 資料庫名     | 對應用途                       |
|----------    |--------               |
| `ShareDB`    | 專為共用結構設計，所有模組（會計、報關、帳號等）共享 |
| `AccDB`      | 會計總帳模組、、 |
| `INVDB`      | 電子發票模組、、 |

##### 二、定序（Collation）選擇：`Latin1_General_100_CI_AS_SC_UTF8`

| 屬性     | 說明 |
|----------|------|
| `100`    | 支援 Unicode 排序規則（比 90 更現代） |
| `CI`     | Case Insensitive（大小寫不敏感） |
| `AS`     | Accent Sensitive（區分音調） |
| `SC`     | Supplementary Character（支援 Unicode 補充字元，如 emoji） |
| `UTF8`   | UTF-8 編碼，減少空間、提高跨平台與語言支援能力 |

- 多語系介面
- API 串接（不會出現 mojibake 亂碼）
- 資料導入 CSV / JSON 等通用格式更簡潔

##### 三、🎛️ 相容層級：`140`（對應 SQL Server 2017）

| 層級 | 適用版本 | 支援功能 |
|------|-----------|-----------|
| 140  | SQL 2017  | 支援 `STRING_AGG()`、`TRIM()`、`TRANSLATE()` 等現代 T-SQL |
| 150+ | SQL 2019+ | 支援更高效能功能（如批次模式 ON ROWSTORE）但可能不穩定 |
  

##### 四、復原模式：`FULL`

- **完整事務日誌記錄**
- **時間點還原（Point-In-Time Recovery）**
- **AlwaysOn、Log Shipping、Backup Chain）**


### 五、檔案配置

| 檔案類型 | 建議磁碟/儲存位置 | 理由 |
|----------|--------------------|------|
| 資料檔（.mdf） | 快速儲存裝置（如 SSD） | 提升查詢效能 |
| 日誌檔（.ldf） | 獨立磁碟（與資料檔分開） | 避免 IO 競爭，確保日誌寫入穩定性 |
| TempDB     | 單獨磁碟，多檔案配置    | 減少鎖與爭用，特別對多核心 HA 系統效能提升顯著 |

---

### 六、建立語法範本（帶參數說明）

```sql
CREATE DATABASE {DB名稱}
ON PRIMARY (
    NAME = N'{資料庫名稱}',
    FILENAME = N'{資料檔完整路徑}',  -- 例：C:\MSSQL\Data\ShareDB_data.mdf
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10MB
)
LOG ON (
    NAME = N'ShareDB_log',
    FILENAME = N'{日誌檔完整路徑}',  -- 例：C:\MSSQL\Log\ShareDB_log.ldf
    SIZE = 20MB,
    MAXSIZE = 2GB,
    FILEGROWTH = 10%
)
COLLATE Latin1_General_100_CI_AS_SC_UTF8; -- 語系設定
GO

ALTER DATABASE {DB名稱} SET COMPATIBILITY_LEVEL = 140; -- SQL 2017
ALTER DATABASE {DB名稱} SET RECOVERY FULL;  -- 完整事務日誌記錄
ALTER DATABASE {DB名稱} SET AUTO_CLOSE OFF; -- 開啟資料庫自動關閉
ALTER DATABASE {DB名稱} SET PAGE_VERIFY CHECKSUM; -- 檢查頁面完整性
ALTER DATABASE {DB名稱} SET AUTO_SHRINK OFF; -- 禁用自動縮小
ALTER DATABASE {DB名稱} SET ANSI_NULLS ON; -- 設定 ANSI NULL 規則
ALTER DATABASE {DB名稱} SET QUOTED_IDENTIFIER ON;   -- 設定 ANSI 引號規則
ALTER DATABASE {DB名稱} SET ALLOW_SNAPSHOT_ISOLATION ON;    -- 設定快照隔離
ALTER DATABASE {DB名稱} SET READ_COMMITTED_SNAPSHOT ON; -- 設定讀取提交快照
ALTER DATABASE {DB名稱} SET AUTO_CREATE_STATISTICS ON; -- 設定自動建立統計資訊
ALTER DATABASE {DB名稱} SET AUTO_UPDATE_STATISTICS ON;      -- 設定自動更新統計資訊
ALTER DATABASE {DB名稱} SET AUTO_UPDATE_STATISTICS_ASYNC OFF;       -- 設定是否同步更新統計資訊
GO
```


### 結構說明
```
📁 database/
├── 📁 metadata/
│   ├── schema_meta_auto_sync_v6.sql
│   ├── reset_schema_metadata_full.sql
│   ├── sp_sync_table_columns_safe.sql
│   ├── sp_sync_metadata_all.sql
│   ├── extended_properties/
│   │   ├── schema_tables_description.sql
│   │   ├── schema_columns_description.sql
│   └── docs/
│       ├── metadata_guidelines.md
│       ├── naming_conventions.md
├── 📁 ddl/
│   ├── tables/
│   ├── views/
│   ├── triggers/
│   └── functions/
├── 📁 seeds/
│   └── initial_metadata_data.sql
├── 📁 tests/
│   └── check_metadata_consistency.sql
├── 📁 consolidation/            
│   ├── 📁 customer/
│   │   └── 📁 ddl/
│   │       ├── 01_create_customer.sql
│   │       ├── 02_create_customer_profile.sql
│   │       └── 03_create_customer_login_log.sql
│   │   └── 📁 模組/
│   │       ├── sp_delete_customer.sql
│   │       ├── sp_insert_customer.sql
│   │       ├── sp_update_customer.sql
│   │       └── sp_login_full_process.sql
│   │
│   ├── 📁 package/
│   │   └── 📁 ddl/
│   │       ├── 01_create_package.sql
│   │       └── 02_create_package_entry.sql
├── 📁 template/
│   ├── job_template_v2.sql
│   └── sp_template.sql

```

---

## 命名與分類原則

| 目的 | 建議做法 |
|------|----------|
| 🔧 自動同步工具 | 放在 `metadata/` 下，如 `schema_meta_auto_sync_v6.sql` |
| 📄 中文說明設定（MS_Description） | 放在 `metadata/extended_properties/` 下分類 |
| 📁 資料表 DDL | 獨立放在 `ddl/tables/`，不要混到 meta 裡 |
| 📂 說明文件 | 放在 `metadata/docs/`（可加 git README、設計文件） |
| ✅ CI/CD 部署用腳本 | 命名 `*_deploy.sql`, `*_init.sql`, `*_reset.sql` |

---

## 統一命名建議（檔名風格）

| 類型 | 建議命名規則 | 範例 |
|------|----------------|------|
| 自動同步主程式 | `schema_meta_auto_sync_vN.sql` | `schema_meta_auto_sync_v6.sql` |
| 初始化腳本 | `reset_schema_metadata_full.sql` | ✅ |
| 補欄位說明 | `schema_columns_description.sql` | ✅ |
| 說明文件 | `metadata_guidelines.md` | ✅ |

---
