
---

### metadata元數據核心功能：
#### 實現資料庫建表修改欄位結構同步
#### 實現資料庫欄位中文說明同步
#### 實現資料庫資料表關聯同步
#### 實現資料庫資料表建立記錄同步
#### 實現資料庫資料表修改記錄同步
#### 實現資料庫資料表刪除記錄同步

### metadata元數據模組：
| 模組 | 功能 |
|------|------|
| `schema_tables` | 表格建立追蹤與描述管理 |
| `schema_columns` | 欄位結構 + 中文說明 |
| `schema_foreign_keys` | 關聯資料表追蹤 |
| `sp_sync_*` 系列 | 可手動或自動同步所有資料 |
| `trg_AuditTableCreation` | 實時建表記錄 |
| `sp_sync_metadata_all` | 一鍵同步總控 |
| `reset_schemafull.` | 一鍵恢復初始狀態 |

---

