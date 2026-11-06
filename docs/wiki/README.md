# 轮胎质量与均匀性分析及 Cpk 诊断系统 · 技术交接与系统维护 Wiki

本目录为独立成册的项目技术交接与系统维护 Wiki，与项目工程代码（`untitled1`、`untitled1_v2`）位于同级目录。

---

## 1. 快速启动与访问

1. **直接双击浏览**：
   - 双击本目录下的 `一键打开Wiki.bat`，即可在浏览器中直接打开交互式 Wiki 界面。
2. **通过后端服务访问**（推荐，支持实时保存与 AI 对话）：
   - 当 `untitled1_v2` 后端服务运行时，在浏览器打开：`http://localhost:8088/wiki`。

---

## 2. 目录文件结构

| 文件名 | 说明 |
| :--- | :--- |
| `wiki.html` | 交互式 Wiki 前端页面（包含网状知识图谱、章节精读、在线编辑器、高亮划词及 AI 对话助手） |
| `catalog.json` | 7 大核心交接模块结构与网状拓扑图节点元数据 |
| `01_system_architecture.md` | 01. 系统全景架构与工程规范（六层分层拓扑、服务解耦与依赖隔离） |
| `02_data_sources_and_er.md` | 02. 全流程数据源与实体关系拓扑（Redshift宽表、MES CGRS库、13道工序条码流转） |
| `03_etl_pipeline_and_engine.md` | 03. ETL 流式清洗管线与 DuckDB 内存引擎（安全水位线、DuckDB 4GB 内存保护） |
| `04_metrics_and_standard_cpk.md` | 04. 17项质检指标统一定义与标准 CPK 引擎（量纲字典、单双侧 CPK 纯函数公式） |
| `05_core_algorithms_deepdive.md` | 05. 核心归因算法与 CGRS 控制变量模型（产量平方根平滑、三级预警瀑布流、路径拆分） |
| `06_frontend_dashboard_views.md` | 06. 前端看板交互与组件状态流转（四行大屏流向、Pinia状态树、ECharts内存防护） |
| `07_devops_and_troubleshooting.md` | 07. 系统运维部署、排错手册与红线守则（局域网部署、排错SOP、四大防劣铁律） |
| `一键打开Wiki.bat` | Windows 本地快捷启动脚本 |
