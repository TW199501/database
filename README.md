

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
