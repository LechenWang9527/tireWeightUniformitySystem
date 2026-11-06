# 轮胎质量与均匀性分析及 Cpk 诊断系统

> Tire Weight & Uniformity Analysis & Cpk Diagnostics System

一套面向轮胎车间的**质量溯源决策系统**。它不只展示数据，而是每天输出一份排好序的「待修清单」：

> **先修 CU621 这台硫化机 —— 它 10 月 19 日那次调参改坏了，建议改回某参数，影响当日 27 胎。**

---

## 它解决什么

| 车间痛点 | 系统给出的答案 |
|---|---|
| 几十台机、几百个规格，先查哪台？ | 双重排序：拖累分（规格级）+ √产量平滑影响分（机台级） |
| 质量波动，是不是有人调参？ | 拉取 CGRS 调参日志做受控对比，给出 ΔCPK 证据 |
| 知道机器有问题，但改成什么？ | 三套推荐策略：成型按规格、硫化按机台、终检推荐标杆机台 |
| 老问题换个规格又出现 | 13 道工序全量血缘链 + 组合树，把经验固化成规则 |

**核心能力**：17 项检测指标（TU 均匀性 7 / TG 几何 7 / TB 动平衡 3）统一口径监控，四行漏斗按「宏观 → 规格 → 批次 → 单胎」逐层下钻。

---

## 技术栈

| 层 | 技术 |
|---|---|
| 前端 | Vue 3.5 + Vite + Element Plus + ECharts + Pinia |
| 后端 | FastAPI + Uvicorn（:8088）+ DuckDB（内存表）+ Pandas |
| 数据源 | Redshift（单胎检测）+ CGRS/SQL Server（调参日志）+ Recipes.csv（公差） |

---

## 快速开始

### 前置条件

- Windows，Python 3.10+，Node 20+
- 本项目已内置 `.venv/`（含全部依赖）与 `frontend/node_modules/`，**无需联网安装**

### 方式 A：开发模式（前端热更新，日常用这个）

双击 **`一键启动.bat`**，会打开两个窗口：

| 窗口 | 地址 |
|---|---|
| 后端 | http://127.0.0.1:8088/docs |
| 前端 | http://localhost:5173 ← **打开这个** |

### 方式 B：生产模式（单端口）

双击 **`构建并预览.bat`**，先构建再启动，浏览器访问 http://127.0.0.1:8088

### 手动启动

```powershell
# 终端 1：后端
.\.venv\Scripts\python.exe backend\run_server.py

# 终端 2：前端
cd frontend
npm run dev
```

### 验证是否跑起来

| 检查 | 地址 | 期望 |
|---|---|---|
| 接口文档 | http://127.0.0.1:8088/docs | FastAPI 文档页 |
| 数据加载 | http://127.0.0.1:8088/api/articles/all | 返回 `{"status":"success",...}` |
| 技术 Wiki | http://127.0.0.1:8088/wiki | 打开交接文档 |

> 首次打开后端约需 3~20 秒（要把 221MB parquet 载入 DuckDB 内存表）。

---

## 目录结构

```
TireWeight_Uniformity_System/
├── frontend/        Vue 源码（src）+ 依赖（node_modules）+ 构建产物（dist）
├── backend/
│   ├── core/        cpk.py（17 项指标字典）、db.py（DuckDB 自愈）、config.py（路径探测）
│   ├── services/    业务与 SQL：trend / article / machine / process_flow / cgrs
│   ├── routers/     20 个 HTTP 接口
│   ├── etl/         拉取 → 清洗 → 原子替换 → 调度
│   ├── data/        parquet（221MB）+ Recipes.csv + cgrs_data/
│   └── config/      db_config.json（加密凭据）、secret.key
├── docs/            Wiki、项目总结、三天框架、阅读路线
├── .venv/           Python 环境（已就绪）
├── 一键启动.bat / 构建并预览.bat
└── README.md        本文件
```

---

## 常用操作

| 想做什么 | 怎么做 |
|---|---|
| 改前端后看效果 | `npm run dev` 自动热更新；生产模式需 `npm run build` |
| 重新拉数清洗 | `.\.venv\Scripts\python.exe backend\etl\run_pipeline.py --full-fetch`（需连 Redshift） |
| 看系统怎么读 | 先读 `docs/项目总结.md`，再按 `docs/研究型阅读路线.md` 走 |
| 部署到服务器 | `deploy_to_server.py`（需生产共享盘 `\\YOUR-SERVER-IP`） |

---

## 配置说明（首次部署）

仓库里只带**模板**，真实凭据与数据不入库（见 `.gitignore`）：

| 模板 | 复制为 | 用途 | 缺失后果 |
|---|---|---|---|
| `backend/config/db_config.example.json` | `db_config.json` | Redshift 连接（ETL 用） | 看板正常，ETL 无法拉数 |
| `backend/config/ai_config.example.json` | `ai_config.json` | Wiki AI 助手 | 该功能不可用，其余正常 |
| `backend/config/etl_state.example.json` | `etl_state.json` | 增量水位线 | 首次运行自动生成 |

```powershell
cd backend\config
Copy-Item db_config.example.json db_config.json
Copy-Item ai_config.example.json ai_config.json
```

`db_config.json` 的 `password` 是**加密串**（XOR + Base64，密钥为 `backend/config/secret.key`）。
首次运行 `backend\etl\fetch_data.py` 会交互式引导生成，无需手写。

**数据文件同样不入库**：`backend/data/*.parquet`、`*.csv`、`cgrs_data/` 需自行放入——
清洗后 parquet、`Recipes.csv`（公差基准）、`cgrs_data/`（调参日志）。缺 `Recipes.csv` 会导致 CPK 全为空。

---

## 注意事项

- **当前数据截止 2026-10-22**：系统显示的是历史快照，演示前请先跑一次 ETL 更新
- **本机无外网**：`.venv` 与 `node_modules` 均为本地复制，换机器需重建环境
- **凭据勿外传**：`backend/config/db_config.json` 与 `secret.key` 含生产数据库账号
- **口径红线**：公差只认 `Recipes.csv`（没配就不算，绝不兜底）；生产日按 08:00 切分；不跨工段、不跨分期比较

---

## 更多文档

| 文件 | 内容 |
|---|---|
| `docs/项目总结.md` | 完整项目说明：数据流、算法、架构、技术债 |
| `docs/wiki/` | 原始技术 Wiki（01 架构 ~ 09 部署） |
| `docs/系统完整框架（三天摸清版）.md` | 一页纸总图 |
| `docs/研究型阅读路线.md` | 不懂代码怎么读这个项目 |
