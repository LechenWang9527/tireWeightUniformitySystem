# backend/data （数据目录 · 骨架）

**这里不放真实数据。** 数据文件体积大、且属于公司业务资产，已随仓库排除（见根目录 `.gitignore`）。

首次部署时，把下面四样放回本目录：

| 文件 / 目录 | 是什么 | 缺失后果 |
|---|---|---|
| `yield_flat_table_joined_100_cleaned.parquet` | 清洗后的单胎检测大表（约 221 MB） | 看板全空，接口返回空数组 |
| `Recipes.csv` | 规格公差基准（USL/LSL） | **所有 CPK 为空**（系统不兜底） |
| `cgrs_data/*.parquet` | CGRS 调参日志（每日导出，约 31 个文件） | 推荐参数、调参回溯功能不可用 |
| `CGRS.csv` / `Status-CGRS.csv` | 调参记录与机台状态快照 | 相关面板不可用 |

## 从备份恢复

本项目的数据已移到仓库外：

```
D:\CT100765_Wang_Lechen\_data_outside_repo\backend\data\
```

恢复命令（PowerShell）：

```powershell
$src = 'D:\CT100765_Wang_Lechen\_data_outside_repo\backend\data'
$dst = 'D:\CT100765_Wang_Lechen\TireWeight_Uniformity_System\backend\data'
Copy-Item "$src\*" $dst -Recurse -Force
```

## 没有备份时怎么重新生成

```powershell
# 从 Redshift 重新拉数并清洗（需能连生产库）
.\.venv\Scripts\python.exe backend\etl\run_pipeline.py --full-fetch
```

`Recipes.csv` 与 `cgrs_data/` 无法自动生成，需要向工艺/IT 部门索取。

## 目录约定

- `cgrs_data/` —— 外部系统每日导出的 parquet，本项目只读
- `duckdb_tmp/` —— DuckDB 临时落盘目录，运行时自动创建
