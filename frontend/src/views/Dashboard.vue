<template>
  <div class="app-container">
    
    <!-- Row 1: 加权 CPK 控制区间分析 (全宽) -->
    <section class="section-row">
      <div id="tour-cpk-trend" class="card full-width">
        <div class="card-header">
          <div>
            <div class="card-title" style="display: inline-flex; align-items: center; gap: 10px; flex-wrap: wrap;">
              <span>{{ trendSelectedArticle ? trendSelectedArticle + ' · ' : '' }}整体指标预览</span>
              
              <!-- Tab 视图切换控件 (与 Main Hall 保持完全一致的看板风格) -->
              <el-radio-group
                v-model="trendViewMode"
                size="small"
                style="margin-left: 6px;"
                @change="handleTrendViewModeChange"
              >
                <el-radio-button id="tour-tab-cpk" value="cpk">CPK 波动</el-radio-button>
                <el-radio-button id="tour-tab-anomaly" value="anomaly">Yield 不良</el-radio-button>
              </el-radio-group>

              <el-tooltip
                placement="bottom-start"
                effect="light"
                popper-class="trend-help-popper"
                raw-content
              >
                <template #content>
                  <div v-if="trendViewMode === 'anomaly'" class="trend-help-content" style="max-width: 320px;">
                    <div class="trend-help-title">生产异常日趋势使用说明</div>
                    <div class="trend-help-section">
                      <div class="section-title">【这是做什么的】</div>
                      <div class="section-line">看全厂每天有多少轮胎不合格，以及到底是哪个工序出了问题。</div>
                      <div class="section-sub">• 顶部支持切换【三期 / 四期】车间分期；</div>
                      <div class="section-sub">• 支持切换【按日 / 按周】查看短期波动或长期走势。</div>
                    </div>
                    <div class="trend-help-section">
                      <div class="section-title">【计算公式】</div>
                      <div class="formula-box">总体异常率 = (当天不合格轮胎数 ÷ 当天检测总数) × 100%</div>
                      <div class="formula-box">比昨天涨跌 = (今天异常率 - 昨天异常率) ÷ 昨天异常率 × 100%</div>
                    </div>
                    <div class="trend-help-section">
                      <div class="section-title">【指标怎么看】</div>
                      <div class="section-line">• <strong>柱子总高度</strong>：代表当天不合格比例，越矮越好（0% 说明全部合格）；</div>
                      <div class="section-line">• <strong>柱子分段颜色</strong>：黄色为均匀性不良，蓝色为外观尺寸不良，橙色为动平衡不良，红色为多工序复合超标；</div>
                      <div class="section-line">• <strong>折线上升</strong>：说明今天异常率比昨天上涨了，质量在恶化。</div>
                    </div>
                    <div class="trend-help-section" style="margin-bottom: 0;">
                      <div class="section-title">【傻瓜操作】</div>
                      <div class="section-line">鼠标直接点击任意一天的柱子，下方表格和流向图会自动切换到那一天的详细数据，<strong>并且上方的异常指标会自动切换到当天异常最突出的指标</strong>。</div>
                    </div>
                  </div>

                  <div v-else-if="cpkIndicator === 'weight'" class="trend-help-content" style="max-width: 300px;">
                    <div class="trend-help-title">胎重偏差率分析说明</div>
                    <div class="trend-help-section">
                      <div class="section-title">【这是做什么的】</div>
                      <div class="section-line">检查做出来的轮胎是偏重还是偏轻。</div>
                    </div>
                    <div class="trend-help-section">
                      <div class="section-title">【计算公式】</div>
                      <div class="formula-box">胎重偏差率 = (称出实际重量 - 工艺标准重量) ÷ 工艺标准重量 × 100%</div>
                    </div>
                    <div class="trend-help-section" style="margin-bottom: 0;">
                      <div class="section-title">【指标怎么看】</div>
                      <div class="section-line">• <strong>0%</strong>：最完美，分毫不差；</div>
                      <div class="section-line">• <strong>正数（往上偏）</strong>：做重了，浪费胶料成本；</div>
                      <div class="section-line">• <strong>负数（往下偏）</strong>：做轻了，可能少胶欠压，质量不合格；</div>
                      <div class="section-line">• 超出 <strong>±0.8%</strong> 自动标红报警，说明用料偏差过大。</div>
                    </div>
                  </div>

                  <div v-else class="trend-help-content" style="max-width: 320px;">
                    <div class="trend-help-title">过程能力分析 (CPK) 说明</div>
                    <div class="trend-help-section">
                      <div class="section-title">【计算公式】</div>
                      <div class="formula-box">单个规格得分 (CPK) = (合格上限 - 实际平均值) ÷ (3 × 实际波动幅度)</div>
                      <div class="formula-box">全厂综合得分 = (各规格得分 × 它的产量) 汇总 ÷ 全厂总产量</div>
                    </div>
                    <div class="trend-help-section">
                      <div class="section-title">【分数代表什么（关键分界线）】</div>
                      <div class="section-line">• <strong>超过 1.33 分（绿色 / 优秀合格）</strong>：质量很稳定，基本不会出废品，放心生产；</div>
                      <div class="section-line">• <strong>1.00 ~ 1.33 分（黄色 / 预警危险）</strong>：质量开始抖动，随时可能超标，需要关注；</div>
                      <div class="section-line">• <strong>低于 1.00 分（红色 / 严重报警）</strong>：经常超标甚至批量报废，必须立即停机检查！</div>
                    </div>
                    <div class="trend-help-section" style="margin-bottom: 0;">
                      <div class="section-title">【傻瓜操作】</div>
                      <div class="section-line">点击折线上的红点，下方会出现当天拉低分数最低的前十个规格。</div>
                    </div>
                  </div>
                </template>
                <el-icon class="help-icon"><QuestionFilled /></el-icon>
              </el-tooltip>
              <div v-if="filterStore.dataUpdateTime" class="data-update-capsule">
                <span class="capsule-dot" />
                <span class="capsule-label">数据最近刷新时间:</span>
                <span class="capsule-val">{{ filterStore.dataUpdateTime }}</span>
              </div>

            </div>
            <div class="breadcrumb mt-4" v-if="trendSelectedArticle" style="display: flex; align-items: center; gap: 8px;">
              <el-button size="small" type="primary" plain :icon="RefreshLeft" @click="resetTrendArticle()">全部规格 (重置)</el-button>
              <span class="breadcrumb-sep">›</span>
              <span class="breadcrumb-current" style="font-weight: 600; color: #1e293b; font-family: 'JetBrains Mono', monospace; font-size: 13px;">{{ trendSelectedArticle }}</span>
            </div>
          </div>
          <div id="tour-cpk-controls" style="display: flex; align-items: center; gap: 16px;">
            <!-- 1. 最左侧下拉按钮：根据当前视图模式动态显示【报警模式 ▾】或【异常值剔除 ▾】 -->
            <!-- 1. 最左侧下拉按钮：根据当前视图模式动态显示【报警模式 ▾】或【异常值剔除 ▾】 -->
            <!-- Yield 不良视图下的报警模式下拉面板 (向下展开) -->
            <div v-if="trendViewMode !== 'cpk'" style="position: relative;">
              <el-button
                size="small"
                plain
                class="alarm-toggle-btn-capsule"
                :class="{ 'is-active': (anomalyAlarmModes && anomalyAlarmModes.length > 0) || alarmDropdownOpen }"
                @click.stop="alarmDropdownOpen = !alarmDropdownOpen; outlierDropdownOpen = false"
                title="点击展开报警模式筛选"
              >
                <span>报警模式</span>
                <span class="alarm-arrow">{{ alarmDropdownOpen ? '▴' : '▾' }}</span>
              </el-button>
              <transition name="dropdown-fade">
                <div v-show="alarmDropdownOpen" class="capsule-dropdown-menu" @click.stop>
                  <div class="dropdown-filter-title">报警模式筛选</div>
                  <el-checkbox-group v-model="anomalyAlarmModes" size="small" class="dropdown-checkbox-group">
                    <el-checkbox value="consecutive">
                      <span class="dropdown-item-label">连续两天上涨</span>
                    </el-checkbox>
                    <el-checkbox value="top5">
                      <span class="dropdown-item-label">极值点 Top 5</span>
                    </el-checkbox>
                  </el-checkbox-group>
                </div>
              </transition>
            </div>

            <!-- CPK 波动视图下的异常值剔除下拉面板 (向下展开) -->
            <div v-else style="position: relative;">
              <el-button
                size="small"
                plain
                class="alarm-toggle-btn-capsule"
                :class="{ 'is-active': (excludeTop10 || excludeOutliers) || outlierDropdownOpen }"
                @click.stop="outlierDropdownOpen = !outlierDropdownOpen; alarmDropdownOpen = false"
                title="点击展开异常值剔除选项"
              >
                <span>异常值剔除</span>
                <span class="alarm-arrow">{{ outlierDropdownOpen ? '▴' : '▾' }}</span>
              </el-button>
              <transition name="dropdown-fade">
                <div v-show="outlierDropdownOpen" class="capsule-dropdown-menu" @click.stop style="min-width: 215px;">
                  <div class="dropdown-filter-title">异常值剔除选项</div>
                  <div class="dropdown-checkbox-group">
                    <div v-if="!trendSelectedArticle" style="margin-bottom: 6px;">
                      <el-checkbox
                        v-model="excludeTop10"
                        size="small"
                        @change="handleExcludeTop10Change"
                      >
                        <span class="dropdown-item-label">剔除 Top 10 预警规格</span>
                      </el-checkbox>
                    </div>
                    <div>
                      <el-checkbox
                        v-model="excludeOutliers"
                        size="small"
                        @change="handleExcludeOutliersChange"
                      >
                        <span class="dropdown-item-label">剔除异常值 (Q3+1.5IQR)</span>
                      </el-checkbox>
                    </div>
                  </div>
                </div>
              </transition>
            </div>

            <!-- 2. 中间：维度筛选 (日 / 周) -->
            <div style="display: flex; align-items: center; gap: 6px;">
              <span style="font-size: 12px; color: var(--el-text-color-regular); font-weight: 600;">维度:</span>
              <el-radio-group
                v-model="filterStore.trendGranularity"
                size="small"
                @change="handleGranularityChange"
              >
                <el-radio-button value="daily">日</el-radio-button>
                <el-radio-button value="weekly">周</el-radio-button>
              </el-radio-group>
            </div>

            <!-- 3. 右侧：Main Hall (全部 / 三期 / 四期) -->
            <div style="display: flex; align-items: center; gap: 8px;">
              <span style="font-size: 12px; color: var(--el-text-color-regular); font-weight: 600;">Main Hall:</span>
              <el-radio-group
                v-model="filterStore.selectedPhase"
                size="small"
                @change="handlePhaseChange"
              >
                <el-radio-button value="all">全部</el-radio-button>
                <el-radio-button value="p3">三期</el-radio-button>
                <el-radio-button value="p4">四期</el-radio-button>
              </el-radio-group>
            </div>
          </div>
        </div>
        <div class="card-body" style="min-height:380px; height:380px;">
          <TrendChart
            v-if="trendViewMode === 'cpk'"
            :key="`cpk-${cpkIndicator}-${trendSelectedArticle || 'all'}-${filterStore.trendGranularity}-${trendChartKey}`"
            :cpk-data="cpkData"
            :indicator="cpkIndicator"
            :loading="cpkLoading"
            :error="cpkError"
            :x-key="filterStore.trendGranularity === 'daily' ? 'date' : 'week_start'"
            :selected-date="selectedTrendDate"
            @date-select="handleDateSelect"
          />
          <ProductionAnomalyTrendChart
            v-else
            :key="`anomaly-${trendSelectedArticle || 'all'}-${filterStore.selectedPhase}-${filterStore.trendGranularity}-${selectedWeekRange?.label || 'all'}-${trendChartKey}`"
            :data="displayedAnomalyData"
            :loading="anomalyLoading"
            :error="anomalyError"
            :selected-date="selectedTrendDate"
            :alarm-modes="anomalyAlarmModes"
            :phase="filterStore.selectedPhase"
            :grain="filterStore.trendGranularity"
            :zoom-range="selectedWeekRange"
            @date-select="handleDateSelect"
            @week-click="handleWeekClick"
          />
        </div>
      </div>
    </section>


    <!-- Row 3: 规格排行与机台排行并排 -->
    <section class="section-row two-col">
      <!-- 左侧: 核心规格行动表 (占 40%) -->
      <div id="tour-spec-action-table" class="card" style="min-width:0; flex: 4; display: flex; flex-direction: column; overflow: hidden; height: 650px;">
        <div v-if="!selectedTrendDate" class="empty-period-card" style="height: 100%; display: flex; align-items: center; justify-content: center;">
          <el-empty description="请点击上方 CPK 趋势图的任意数据点以载入该天的规格预警分析" :image-size="60" />
        </div>
        <template v-else>
          <div class="card-header" style="display: flex; justify-content: space-between; align-items: center; gap: 8px; border-bottom: 1px solid var(--el-border-color-lighter); padding-bottom: 8px; flex-shrink: 0; margin-bottom: 8px;">
            <div class="card-title" style="display: inline-flex; align-items: center; gap: 8px; flex-shrink: 0;">
              <span style="white-space: nowrap; font-weight: 600; font-size: 13px;">
                核心规格行动表
              </span>
              <!-- 日期标签 (极简纯文字，无图标) -->
              <el-tooltip v-if="selectedTrendDate" content="点击清除日期选择，返回全周期总览" placement="top">
                <span
                  class="filter-pill-tag pill-date"
                  @click="handleClearDate"
                >
                  <span>{{ selectedTrendDate }}</span>
                  <span class="pill-close">✕</span>
                </span>
              </el-tooltip>
              <!-- 规格标签 (极简纯文字，无图标) -->
              <el-tooltip v-if="tab1SelectedArticle" content="点击清除规格聚焦，展示当天全量预警规格" placement="top">
                <span
                  class="filter-pill-tag pill-spec"
                  @click="resetActionArticle"
                >
                  <span>{{ tab1SelectedArticle }}</span>
                  <span class="pill-close">✕</span>
                </span>
              </el-tooltip>
              <el-tooltip placement="top" effect="light" popper-class="help-tooltip-light" raw-content>
                <template #content>
                  <div class="trend-help-content" style="max-width: 300px;">
                    <div class="trend-help-title">核心规格行动表说明</div>
                    <div class="trend-help-section">
                      <div class="section-title">【这是做什么的】</div>
                      <div class="section-line">筛选出异常最严重的几个规格，按照从紧急到轻的程度进行排列。</div>
                    </div>
                    <div class="trend-help-section">
                      <div class="section-title">【拖累分怎么算】</div>
                      <template v-if="cpkIndicator === 'weight'">
                        <div class="formula-box">拖累分 = (单规格偏差率 - 全厂平均偏差率) × 产量占比</div>
                      </template>
                      <template v-else>
                        <div class="formula-box">拖累分 = (全厂平均水平 - 该规格得分) × 生产条数</div>
                      </template>
                      <div class="section-sub">(表现越差、生产条数越多，扣分越多，排在表格越靠前)</div>
                    </div>
                    <div class="trend-help-section">
                      <div class="section-title">【预警颜色级别】</div>
                      <div class="section-line">• 🔴 <strong>红色危险</strong>：经常超标或严重下滑，最紧急，必须优先处理；</div>
                      <div class="section-line">• 🟠 <strong>橙色警告</strong>：质量波动明显，需要工艺员调整；</div>
                      <div class="section-line">• 🟡 <strong>黄色注意</strong>：有轻微不稳定苗头。</div>
                    </div>
                    <div class="trend-help-section" style="margin-bottom: 0;">
                      <div class="section-title">【傻瓜操作】</div>
                      <div class="section-line">点击表格中任意一行规格，右侧流向图和下方物料图会立刻只聚焦该规格！</div>
                    </div>
                  </div>
                </template>
                <el-icon class="help-icon"><QuestionFilled /></el-icon>
              </el-tooltip>
            </div>
            <div style="display: flex; align-items: center; gap: 6px; flex-shrink: 0; white-space: nowrap;">
              <el-button
                v-if="tab1SelectedArticle"
                size="small"
                class="btn-warm-primary"
                :icon="TrendCharts"
                @click="handleOpenBarcodeMeasurements(tab1SelectedArticle)"
              >
                单规格折线图
              </el-button>
              <template v-if="!tab1SelectedArticle">
                <template v-if="cpkIndicator !== 'weight'">
                  <span style="font-size: 12px; color: var(--el-text-color-regular);">CPK:</span>
                  <el-input-number
                    v-model="warningMaxCpk"
                    :min="0.01"
                    :max="5.0"
                    :step="0.05"
                    :precision="2"
                    size="small"
                    style="width: 80px;"
                    @change="loadWarningArticles"
                  />
                </template>
                <span style="font-size: 12px; color: var(--el-text-color-regular); margin-left: 2px;">产量:</span>
                <el-input-number v-model="warningMinSamples" :min="1" :max="1000" size="small" style="width: 75px;" @change="loadWarningArticles" />
              </template>
            </div>
          </div>
          
          <div class="card-body" style="flex: 1; min-height: 0; padding: 0; display: flex; flex-direction: column; overflow: hidden;">
            <CoreSpecActionTable
              :data="articles"
              :loading="articleLoading"
              :error="articleError"
              :selected-article="tab1SelectedArticle"
              :indicator="cpkIndicator"
              :target-date="selectedTrendDate"
              :is-latest-date="isLatestDate"
              @drill-down="onTab1ArticleDrill"
              @open-recommend="handleOpenTableRecommend"
            />
          </div>
        </template>
      </div>


      <!-- 右侧: 机台 CPK (avg + 3σ) 数据表格 与 生产工序流转图 Tab 页面 (占 60%) -->
      <div id="tour-process-sankey" class="card" style="min-width:0; flex: 6; display: flex; flex-direction: column; overflow: hidden; height: 650px;">
        <div v-if="!selectedTrendDate" class="empty-period-card" style="height: 100%; display: flex; align-items: center; justify-content: center;">
          <el-empty description="请点击上方 CPK 趋势图的任意数据点以载入工序流转及路径分析" :image-size="60" />
        </div>
        <template v-else>
          <div class="card-header" style="display: flex; justify-content: space-between; align-items: flex-start; gap: 8px; border-bottom: 1px solid var(--el-border-color-lighter); padding-bottom: 8px; flex-shrink: 0;">
            <div style="display: flex; align-items: center; gap: 16px; flex-wrap: wrap;">
              <!-- 显示 Tab 切换与诊断 -->
              <el-radio-group v-model="machineTabActive" size="small">
                <el-radio-button value="sankey_flow">单日生产工序路径</el-radio-button>
                <el-radio-button value="best_sankey_flow">全量最佳生产路径</el-radio-button>
              </el-radio-group>

              <el-tooltip v-if="machineTabActive === 'sankey_flow'" placement="top" effect="light" popper-class="help-tooltip-light" raw-content>
                <template #content>
                  <div class="trend-help-content" style="max-width: 300px;">
                    <div class="trend-help-title">单日生产工序路径说明</div>
                    <div class="trend-help-section">
                      <div class="section-title">【这是做什么的】</div>
                      <div class="section-line">看选定规格从成型机（GT）做出来后流向哪台硫化机（CT），最后在哪台检测机（TU）检测，查出是哪台机台把轮胎做坏了。</div>
                    </div>
                    <div class="trend-help-section">
                      <div class="section-title">【图表怎么看】</div>
                      <div class="section-line">• <strong>连线粗细</strong>：线越粗，说明该路线上生产的轮胎数量越多；</div>
                      <div class="section-line">• <strong>发光机台圆圈</strong>：🔴 红色发光为问题最严重的机台；🟠 橙色/🟡 黄色为隐患机台；⚪ 灰色为正常机台。</div>
                    </div>
                    <div class="trend-help-section" style="margin-bottom: 0;">
                      <div class="section-title">【傻瓜操作】</div>
                      <div class="section-line">点击任意发光机台，可弹窗查看该机台近期是否改动过工艺参数（CGRS记录）。</div>
                    </div>
                  </div>
                </template>
                <el-icon class="help-icon" style="margin-left: 2px; cursor: pointer; color: var(--c-text-muted);"><QuestionFilled /></el-icon>
              </el-tooltip>

              <el-tooltip v-else-if="machineTabActive === 'best_sankey_flow'" placement="top" effect="light" popper-class="help-tooltip-light" raw-content>
                <template #content>
                  <div class="trend-help-content" style="max-width: 310px;">
                    <div class="trend-help-title">全量最佳生产路径说明</div>
                    <div class="trend-help-section">
                      <div class="section-title">【这是做什么的】</div>
                      <div class="section-line">系统根据过去 30 天历史数据，帮您算出合格率最高、质量最稳的一套“黄金搭配路线”，生产排产时跟着做准没错。</div>
                    </div>
                    <div class="trend-help-section">
                      <div class="section-title">【黄金路线怎么选出来的】</div>
                      <div class="section-line">1. <strong>挑最好质检机</strong>：挑出排产满200条以上且合格率最高的检测机台；</div>
                      <div class="section-line">2. <strong>逆向找源头</strong>：顺藤摸瓜找出这些优秀轮胎主要是由哪台硫化机和成型机生产的；</div>
                      <div class="section-line">3. <strong>绿色高亮链路</strong>：即为系统推荐的黄金工艺搭配路径。</div>
                    </div>
                  </div>
                </template>
                <el-icon class="help-icon" style="margin-left: 2px; cursor: pointer; color: var(--c-text-muted);"><QuestionFilled /></el-icon>
              </el-tooltip>

              <!-- 决策树分析入口按钮 -->
              <el-button type="primary" size="small" plain style="margin-left: 12px;" @click="combinationTreeDialogVisible = true">
                机台组合分析
              </el-button>


            </div>
            <div style="display: flex; align-items: center; gap: 12px; flex-wrap: wrap;">
              <div style="display: flex; align-items: center; gap: 6px;">
                <span style="font-size: 12px; color: var(--el-text-color-regular);">样本门槛:</span>
                <el-input-number v-model="machineMinSamples" :min="1" :max="1000" size="small" style="width: 90px;" @change="handleMachineMinSamplesChange" />
              </div>
              <el-button size="small" type="primary" plain :icon="ZoomIn" @click="handleOpenSankeyZoom">
                放大查看
              </el-button>
            </div>
          </div>

          <div class="card-body" style="flex: 1; min-height: 0; padding-top: 10px; display: flex; flex-direction: column; overflow: hidden;">
            <!-- 未选定规格提示 -->
            <div v-if="!tab1SelectedArticle" style="height: 100%; display: flex; flex-direction: column; align-items: center; justify-content: center;">
              <el-empty
                description="请在上方搜索栏或左侧预警列表中选定具体规格"
                :image-size="90"
              >
                <template #extra>
                  <div style="font-size: 12.5px; color: #64748b; line-height: 1.6; text-align: center; max-width: 480px; margin-top: 6px;">
                    💡 <strong>操作提示</strong>：单日工序流转与全量最佳路径针对具体规格进行分析。<br/>
                    请在左侧<strong>「恶化预警规格」</strong>中点击任意规格，或在顶部<strong>「规格」</strong>下拉栏中搜索选定。
                  </div>
                </template>
              </el-empty>
            </div>

            <!-- Tab 2: 单日生产工序流转桑基图 -->
            <MachineProcessSankeyChart
              v-else-if="machineTabActive === 'sankey_flow'"
              ref="sankeyChartRef"
              :sankey-data="sankeyData"
              :loading="sankeyLoading"
              :error="sankeyError"
              :indicator="cpkIndicator"
              :tolerance="filterStore.weightTolerance"
              :article="tab1SelectedArticle"
              :warning-machine-map="currentSpecWarningMachineMap"
              @open-cgrs="handleOpenCgrs"
            />
            <!-- Tab 3: 全量数据集最佳生产路径桑基图 -->
            <MachineBestProcessSankeyChart
              v-else-if="machineTabActive === 'best_sankey_flow'"
              ref="bestSankeyChartRef"
              :sankey-data="bestSankeyData"
              :loading="bestSankeyLoading"
              :error="bestSankeyError"
              :indicator="cpkIndicator"
              :tolerance="filterStore.weightTolerance"
              :article="tab1SelectedArticle"
              @open-cgrs="handleOpenCgrs"
            />

          </div>
        </template>
      </div>
    </section>

    <!-- Row 3.5: 横跨两列 (Full-Width 通栏): 物料批次分析卡片 -->
    <section class="section-row" v-if="selectedTrendDate">
      <div id="tour-lot-tracking" class="card full-width" style="width: 100%;">
        <template v-if="true">
          <div class="card-header" style="display: flex; justify-content: space-between; align-items: center;">
            <div style="display: flex; align-items: center; gap: 12px; flex-wrap: wrap;">
              <div class="card-title" style="display: inline-flex; align-items: center; gap: 6px;">
                <span>物料批次分析</span>
                <el-tooltip placement="top" effect="light" popper-class="help-tooltip-light" raw-content>
                  <template #content>
                    <div class="trend-help-content" style="max-width: 320px;">
                      <div class="trend-help-title">物料批次质量追溯说明</div>
                      <div class="trend-help-section">
                        <div class="section-title">【这是做什么的】</div>
                        <div class="section-line">当轮胎质量超标时，排查是否由于某一批胶料、帘布或带束层异常导致。</div>
                      </div>
                      <div class="trend-help-section">
                        <div class="section-title">【图表怎么看】</div>
                        <div class="section-line">• <strong>横轴</strong>：每个点代表一条轮胎，按生产时间先后排列；</div>
                        <div class="section-line">• <strong>红虚线</strong>：工艺要求的合格上限与下限；</div>
                        <div class="section-line">• 🔴 <strong>红色实心点</strong>：跳出虚线外的点，代表该轮胎实测超标不合格；</div>
                        <div class="section-line">• <strong>物料颜色相同</strong>：批号后五位相同的物料用同一种颜色（代表同一批胶料）。如果某一颜色段集中冒出大量红点，证明这批物料质量有问题！</div>
                      </div>
                      <div class="trend-help-section" style="margin-bottom: 0;">
                        <div class="section-title">【带束层组合模式特别说明】</div>
                        <div class="section-line">• 分析上、下带束层不同物料搭配时的合格情况；</div>
                        <div class="section-line">• 异常率最高的搭配会优先排在最前，一眼看清哪两种物料搭配最容易做废品。</div>
                      </div>
                    </div>
                  </template>
                  <el-icon class="help-icon" style="cursor: pointer; color: var(--c-text-muted);"><QuestionFilled /></el-icon>
                </el-tooltip>
              </div>

              <span style="font-size: 12px; color: var(--el-text-color-secondary);">
                | 日期: {{ selectedTrendDate }}
              </span>
            </div>
          </div>
          <div class="card-body" style="min-height: 380px; padding-top: 10px;">
            <div v-if="!tab1SelectedArticle" style="height: 340px; display: flex; align-items: center; justify-content: center;">
              <el-empty
                description="请先选定规格以查看物料批次质量追溯数据"
                :image-size="75"
              />
            </div>
            <ArticleLotCpkChart
              v-else
              :key="`lot-chart-${tab1SelectedArticle}-${selectedTrendDate}-${cpkIndicator}`"
              :lot-data="lotCpkData"
              :usl-value="lotUslValue"
              :lsl-value="lotLslValue"
              :loading="lotCpkLoading"
              :error="lotCpkError"
              :selected-article="tab1SelectedArticle"
              :target-date="selectedTrendDate"
              :indicator="cpkIndicator"
              @reload="handleLotChartReload"
            />
          </div>
        </template>
      </div>
    </section>



    <!-- 成型机台 CGRS 参数变更记录弹窗 -->
    <CgrsRecordDialog
      v-model:visible="cgrsDialogVisible"
      :machine="cgrsDialogMachine"
      :date="cgrsDialogDate"
      :article="cgrsDialogArticle"
      :indicator="cgrsDialogIndicator || cpkIndicator"
      :is-top-warning="cgrsIsTopWarning"
      :top-machines="cgrsTopMachines"
      @open-recommend-dialog="handleSwitchToRecommend"
    />

    <!-- 机台排列组合树分析弹窗 -->
    <el-dialog
      v-model="combinationTreeDialogVisible"
      title="机台组合分析"
      width="90%"
      top="4vh"
      destroy-on-close
      append-to-body
      @opened="handleCombinationTreeDialogOpened"
    >
      <div style="height: 600px; display: flex; flex-direction: column;">
        <MachineCombinationTree
          v-if="combinationTreeDialogRendered"
          :selected-article="tab1SelectedArticle || null"
          :start-date="machineCpkDateRange && machineCpkDateRange.length === 2 ? machineCpkDateRange[0] : null"
          :end-date="machineCpkDateRange && machineCpkDateRange.length === 2 ? machineCpkDateRange[1] : null"
          :target-date="selectedTrendDate"
          :indicator="cpkIndicator"
          :min-samples="machineMinSamples"
          :tolerance="filterStore.weightTolerance"
        />
      </div>
    </el-dialog>

    <!-- 单规格单胎实测值折线图弹窗 -->
    <BarcodeMeasurementsDialog
      v-model:visible="barcodeDialogVisible"
      :article10="barcodeDialogArticle || tab1SelectedArticle"
      :target-date="selectedTrendDate"
      :indicator="cpkIndicator"
      :time-col="filterStore.selectedTimeCol"
      :phase="filterStore.selectedPhase"
    />

    <!-- 专属轻量工艺参数推荐弹窗 (从核心规格行动表触发) -->
    <MachineRecommendParamDialog
      v-model:visible="recDialogVisible"
      :machine="recDialogMachine"
      :target-date="selectedTrendDate"
      :article="recDialogArticle"
      :workcenter-type="recDialogStage"
      :indicator="cpkIndicator"
      :reason="recDialogReason"
      :sankey-nodes="sankeyData?.nodes || []"
    />

  </div>
</template>

<script setup>
import { ref, watch, computed, onMounted, onUnmounted, nextTick } from 'vue'
import axios from 'axios'
import { ElMessage } from 'element-plus'
import { useFilterStore } from '../store/filter.js'
import { api } from '../api/index.js'
import TrendChart from '../components/charts/TrendChart.vue'
import ProductionAnomalyTrendChart from '../components/charts/ProductionAnomalyTrendChart.vue'
import CoreSpecActionTable from '../components/tables/CoreSpecActionTable.vue'
import MachineRecommendParamDialog from '../components/dialogs/MachineRecommendParamDialog.vue'
import CgrsRecordDialog from '../components/dialogs/CgrsRecordDialog.vue'
import MachineProcessSankeyChart from '../components/charts/MachineProcessSankeyChart.vue'
import MachineBestProcessSankeyChart from '../components/charts/MachineBestProcessSankeyChart.vue'
import MachineCombinationTree from '../components/charts/MachineCombinationTree.vue'
import ArticleLotCpkChart from '../components/charts/ArticleLotCpkChart.vue'
import BarcodeMeasurementsDialog from '../components/modals/BarcodeMeasurementsDialog.vue'

import { QuestionFilled, RefreshLeft, ZoomIn, TrendCharts, Select, BellFilled } from '@element-plus/icons-vue'
import { useDashboardTour } from '../composables/useDashboardTour.js'

const filterStore = useFilterStore()
const {
  startTour,
  advanceTourIfActive,
  registerTourHandler,
  notifyTourDateSelected,
  notifyTourSpecSelected
} = useDashboardTour()

function handleTourInteraction(type) {
  if (type === 'start-tour') {
    trendViewMode.value = 'anomaly'
    if (!anomalyData.value || anomalyData.value.length === 0) {
      loadAnomalyTrend()
    }
  } else if (type === 'select-anomaly-date') {
    const list = anomalyData.value || []
    if (list.length > 0) {
      const target = list.find(d => d.date === '2026-08-25') ||
                     list.slice().sort((a, b) => (b.anomaly_growth_rate || 0) - (a.anomaly_growth_rate || 0))[0] ||
                     list[list.length - 1]
      if (target && target.date) {
        handleDateSelect(target.date)
      }
    }
  } else if (type === 'switch-to-cpk') {
    trendViewMode.value = 'cpk'
    loadCpkTrend()
  } else if (type === 'select-spec-row') {
    if (articles.value && articles.value.length > 0) {
      const firstSpec = articles.value[0].article10
      if (firstSpec) {
        onTab1ArticleDrill(firstSpec)
      }
    }
  } else if (type === 'open-recommend-dialog') {
    if (articles.value && articles.value.length > 0) {
      const firstRow = articles.value[0]
      handleOpenTableRecommend(firstRow)
    }
  }
}

// 注册交互处理器给全局引导管理
if (typeof registerTourHandler === 'function') {
  registerTourHandler(handleTourInteraction)
}

// ── 核心规格行动表参数推荐弹窗控制 ──
const recDialogVisible = ref(false)
const recDialogMachine = ref('')
const recDialogArticle = ref('')
const recDialogStage = ref('gt')
const recDialogReason = ref('degradation')

// 监听推荐参数弹窗关闭：关闭后自动推进新手引导进入第 4 步 (工序流转图)
watch(() => recDialogVisible.value, (newVal, oldVal) => {
  if (oldVal === true && newVal === false) {
    advanceTourIfActive(2)
  }
})

function handleOpenTableRecommend(row) {
  console.log('[Dashboard] handleOpenTableRecommend called with:', row)
  const mach = row?.warning_machine || row?.machine || row?.workcenter
  if (!mach) {
    console.warn('[Dashboard] no warning_machine found in row:', row)
    return
  }
  recDialogMachine.value = mach
  recDialogArticle.value = row.article10 || tab1SelectedArticle.value || ''
  const mUpper = String(mach).toUpperCase()
  const isCuring = mUpper.startsWith('CU') || mUpper.startsWith('CT')
  recDialogStage.value = row.recommend_stage || (isCuring ? 'ct' : 'gt')
  recDialogReason.value = 'degradation'
  recDialogVisible.value = true
}

function handleSwitchToRecommend(payload) {
  console.log('[Dashboard] Switching from CGRS dialog to Recommend dialog:', payload)
  cgrsDialogVisible.value = false
  recDialogMachine.value = payload.machine
  recDialogArticle.value = payload.article || tab1SelectedArticle.value || ''
  const mUpper = String(payload.machine || '').toUpperCase()
  const isCuring = mUpper.startsWith('CU') || mUpper.startsWith('CT')
  recDialogStage.value = payload.stage || (isCuring ? 'ct' : 'gt')
  recDialogReason.value = 'degradation'
  recDialogVisible.value = true
}

// ── 单胎实际测量值折线图 (Barcode Run Chart) 弹窗 ──
const barcodeDialogVisible = ref(false)
const barcodeDialogArticle = ref(null)

function handleOpenBarcodeMeasurements(article = null) {
  const target = article || tab1SelectedArticle.value
  if (!target) {
    ElMessage.warning('请先选定要查看单胎实测值的规格')
    return
  }
  barcodeDialogArticle.value = target
  barcodeDialogVisible.value = true
}

// 排序控制 (固定使用异常贡献率与提升度)


// 下方行动表与工序下钻选中的规格状态
const tab1SelectedArticle = ref(null)
// 上方【整体指标预览】图表独立选中的规格状态
const trendSelectedArticle = ref(null)

// 同步选中规格至全局 Store，以便导航栏同步展示
watch(() => filterStore.selectedArticle, (newVal) => {
  if (tab1SelectedArticle.value !== newVal) {
    if (newVal) {
      trendViewMode.value = 'cpk'
    }
    tab1SelectedArticle.value = newVal
    trendSelectedArticle.value = newVal
    if (trendViewMode.value === 'cpk') {
      loadCpkTrend()
    } else {
      loadAnomalyTrend()
    }
    if (selectedTrendDate.value) {
      if (!articles.value || articles.value.length === 0) {
        loadWarningArticles()
      }
      loadLotCpkTrend()
    }
    if (machineTabActive.value === 'sankey_flow') {
      loadMachineProcessSankey()
    } else if (machineTabActive.value === 'best_sankey_flow') {
      loadMachineBestProcessSankey()
    }
  }
}, { immediate: true })

watch(() => tab1SelectedArticle.value, (newVal) => {
  if (filterStore.selectedArticle !== newVal) {
    filterStore.selectedArticle = newVal
  }
})


// 趋势图视图模式: 'cpk' (CPK 波动图) | 'anomaly' (Yield 不良监控)
const trendViewMode = ref('cpk')

// CPK 趋势与指标状态
const cpkIndicator = computed(() => filterStore.cpkIndicator)
const selectedTrendDate = ref(null) // 点击选中日期
const cpkData = ref({})
const cpkLoading = ref(false)
const cpkError = ref(null)
const excludeTop10 = ref(false)
const excludeOutliers = ref(false)

// 顶部控制栏胶囊下拉面板展开/折叠状态
const outlierDropdownOpen = ref(false)
const alarmDropdownOpen = ref(false)

// 全量生产异常趋势状态与日增长报警模式
const anomalyData = ref([])
const allAnomalyDailyData = ref([])
const selectedWeekRange = ref(null)
const anomalyLoading = ref(false)
const anomalyError = ref(null)
const anomalyAlarmModes = ref(['consecutive', 'top5'])
const alarmModesExpanded = ref(false)
const lastLoadedCpkIndicator = ref(null)

// 计算当前实际呈现给图表的数据 (保持全量日/周数据，周下钻通过 zoomRange 精确聚焦视口并完好保留滑动条供左右滑动查看)
const displayedAnomalyData = computed(() => {
  if (filterStore.trendGranularity === 'daily') {
    return (allAnomalyDailyData.value && allAnomalyDailyData.value.length > 0)
      ? allAnomalyDailyData.value
      : (anomalyData.value || [])
  }
  return anomalyData.value || []
})

async function loadCpkTrend() {
  const targetIndicator = cpkIndicator.value
  cpkLoading.value = true
  cpkError.value = null
  try {
    const params = {}
    params.indicator = cpkIndicator.value
    params.grain = filterStore.trendGranularity
    params.time_col = filterStore.selectedTimeCol
    params.phase = filterStore.selectedPhase
    params.shift = filterStore.selectedShift
    if (excludeOutliers.value) {
      params.exclude_outliers = true
    }
    if (trendSelectedArticle.value) {
      params.article10 = trendSelectedArticle.value
    } else if (excludeTop10.value) {
      let topArticlesList = articles.value
      if (!topArticlesList || topArticlesList.length === 0) {
        try {
          const warnRes = await api.getWarningArticles({
            indicator: cpkIndicator.value,
            min_samples: warningMinSamples.value,
            time_col: filterStore.selectedTimeCol,
            phase: filterStore.selectedPhase,
            max_cpk: warningMaxCpk.value
          })
          if (warnRes.data && warnRes.data.status === 'success') {
            topArticlesList = warnRes.data.data || []
          }
        } catch (err) {
          console.warn('Failed to pre-fetch warning articles for top 10 exclusion', err)
        }
      }
      if (topArticlesList && topArticlesList.length > 0) {
        const top10Articles = topArticlesList.slice(0, 10).map(a => a.article10).filter(Boolean)
        if (top10Articles.length > 0) {
          params.exclude_articles = top10Articles.join(',')
        }
      }
    }
    const res = await api.getCpkTrend(params)
    if (res.data.status === 'success') {
      cpkData.value = res.data.data || {}
      lastLoadedCpkIndicator.value = targetIndicator
    } else {
      cpkData.value = {}
      cpkError.value = res.data.message
    }
  } catch (e) {
    cpkError.value = 'CPK 趋势数据加载异常'
  } finally {
    cpkLoading.value = false
  }
}

async function loadAnomalyTrend() {
  anomalyLoading.value = true
  anomalyError.value = null
  try {
    const params = {
      grain: filterStore.trendGranularity || 'daily',
      time_col: filterStore.selectedTimeCol,
      phase: filterStore.selectedPhase,
      shift: filterStore.selectedShift
    }
    if (trendSelectedArticle.value) {
      params.article10 = trendSelectedArticle.value
    }
    const res = await api.getTrendProductionAnomaly(params)
    if (res.data && res.data.status === 'success') {
      const list = res.data.data || []
      anomalyData.value = list
      if ((filterStore.trendGranularity || 'daily') === 'daily') {
        allAnomalyDailyData.value = list
      }
      if (selectedTrendDate.value) {
        applyTopProcessAndIndicatorLinkage(selectedTrendDate.value)
      }
    } else {
      anomalyError.value = res.data?.message || '加载生产异常数据失败'
    }
  } catch (err) {
    anomalyError.value = '生产异常数据请求异常'
  } finally {
    anomalyLoading.value = false
  }
}

// 页面初次载入时静默预加载生产异常数据，确保点击日期能即时联动定位
loadAnomalyTrend()

function handleTrendViewModeChange(mode) {
  trendViewMode.value = mode
  if (mode === 'anomaly') {
    loadAnomalyTrend()
  } else if (mode === 'cpk') {
    loadCpkTrend()
  }
}

function handleExcludeTop10Change() {
  loadCpkTrend()
}

function handleExcludeOutliersChange() {
  loadCpkTrend()
  // 勾选/取消剔除异常值后，对整个核心规格行动表进行重新选用
  tab1SelectedArticle.value = null
  filterStore.selectedArticle = null
  if (selectedTrendDate.value) {
    loadWarningArticles()
  }
}

function handleToggleExcludeOutliers() {
  excludeOutliers.value = !excludeOutliers.value
  handleExcludeOutliersChange()
}

function handlePhaseChange(val) {
  if (val && filterStore.selectedPhase !== val) {
    filterStore.setSelectedPhase(val)
  }
  if (trendViewMode.value === 'cpk') {
    loadCpkTrend()
  } else {
    loadAnomalyTrend()
  }
  if (selectedTrendDate.value) {
    loadWarningArticles()
  }
}

// 在周模式下点击某一周，自动下钻展示该周的日数据
async function handleWeekClick(weekItem) {
  if (!weekItem) return
  const weekStart = weekItem.week_start || weekItem.date
  const weekEnd = weekItem.week_end || weekItem.date
  selectedWeekRange.value = {
    start: weekStart,
    end: weekEnd,
    label: weekItem.date_range || `${weekStart} ~ ${weekEnd}`
  }

  // 若尚未预载全量日数据，预先请求
  if (!allAnomalyDailyData.value || allAnomalyDailyData.value.length === 0) {
    try {
      const res = await api.getTrendProductionAnomaly({
        grain: 'daily',
        time_col: filterStore.selectedTimeCol,
        phase: filterStore.selectedPhase,
        shift: filterStore.selectedShift,
        ...(trendSelectedArticle.value ? { article10: trendSelectedArticle.value } : {})
      })
      if (res.data && res.data.status === 'success') {
        allAnomalyDailyData.value = res.data.data || []
        anomalyData.value = res.data.data || []
      }
    } catch (e) {
      console.warn('Failed to fetch daily anomaly data on week click', e)
    }
  } else {
    anomalyData.value = allAnomalyDailyData.value
  }

  // 自动切换为日模式
  filterStore.setGranularity('daily')

  // 联动定位到该周第一天
  if (weekStart) {
    selectedTrendDate.value = weekStart
    loadWarningArticles()
  }
}

function handleGranularityChange(val) {
  // 用户直接切换周或日时，重置单周锁定范围，恢复全景查看
  selectedWeekRange.value = null
  if (val && filterStore.trendGranularity !== val) {
    filterStore.setGranularity(val)
  }
  selectedTrendDate.value = null
  if (trendViewMode.value === 'cpk') {
    loadCpkTrend()
  } else {
    loadAnomalyTrend()
  }
}

watch(
  [
    () => filterStore.selectedPhase,
    () => filterStore.selectedShift,
    () => filterStore.selectedTimeCol,
    () => filterStore.cpkIndicator,
    () => filterStore.trendGranularity
  ],
  ([newPhase, newShift, newTimeCol, newInd, newGrain], [oldPhase, oldShift, oldTimeCol, oldInd, oldGrain] = []) => {
    if (newPhase !== oldPhase || newShift !== oldShift || newTimeCol !== oldTimeCol || newGrain !== oldGrain) {
      if (trendViewMode.value === 'cpk') {
        loadCpkTrend()
      } else {
        loadAnomalyTrend()
      }
    } else if (newInd !== oldInd) {
      // 只要指标发生切换（无论是手动选择还是由 Yield 点击联动触发），立即拉取该指标的 CPK 趋势
      loadCpkTrend()
    }
    if (selectedTrendDate.value) {
      loadWarningArticles()
      loadMachineProcessSankey()
      loadLotCpkTrend()
    }
  }
)

// 防抖重型接口请求，防止拖动日期快速更新导致高并发拥堵
let debounceTimer = null
function debounceLoad(fn, delay = 300) {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(fn, delay)
}

function onTab1ArticleDrill(article) {
  if (tab1SelectedArticle.value === article) {
    resetActionArticle()
  } else {
    // 选中核心规格时，上方整体指标自动切换到 CPK 波动这一页
    trendViewMode.value = 'cpk'
    tab1SelectedArticle.value = article
    trendSelectedArticle.value = article
    filterStore.selectedArticle = article

    // 刷新单规格 CPK 波动数据
    loadCpkTrend()

    // 下方工序流转与物料批次追溯同步刷新
    loadMachineProcessSankey()
    loadLotCpkTrend()
    if (machineTabActive.value === 'best_sankey_flow') {
      loadMachineBestProcessSankey()
    }
    if (typeof notifyTourSpecSelected === 'function') {
      notifyTourSpecSelected()
    }
  }
}

// 顶部全部规格重置：仅重置上方整体指标预览图表，完全不影响下方行动表及图表状态
function resetTrendArticle() {
  trendSelectedArticle.value = null
  if (trendViewMode.value === 'cpk') {
    loadCpkTrend()
  } else {
    loadAnomalyTrend()
  }
}

// 下方行动表标签清除：仅重置下方行动表和工序/批次图表，完全不影响上方图表状态
function resetActionArticle() {
  tab1SelectedArticle.value = null
  filterStore.selectedArticle = null
  if (selectedTrendDate.value) {
    loadWarningArticles()
    loadMachineProcessSankey()
    loadLotCpkTrend()
  }
}

function handleClearDate() {
  selectedTrendDate.value = null
  tab1SelectedArticle.value = null
  trendSelectedArticle.value = null
  filterStore.selectedArticle = null
  articles.value = []
  sankeyData.value = { nodes: [], links: [] }
  lotCpkData.value = []
  if (trendViewMode.value === 'cpk') {
    loadCpkTrend()
  } else {
    loadAnomalyTrend()
  }
}

const trendChartKey = ref(0)

function resetOverallTrend() {
  selectedTrendDate.value = null
  tab1SelectedArticle.value = null
  filterStore.selectedPhase = 'all'
  trendChartKey.value++

  if (trendViewMode.value === 'cpk') {
    excludeTop10.value = false
    excludeOutliers.value = false
    loadCpkTrend()
  } else {
    loadAnomalyTrend()
  }
  loadLotCpkTrend()
  ElMessage.success('已恢复总体趋势图')
}


const machineCpkDateRange = ref([])

// 联动逻辑：悬浮卡片排行第一的工序及其增幅最大详细指标置顶与自动切换 (仅在 Yield 不良模式下生效)
function applyTopProcessAndIndicatorLinkage(date) {
  // CPK 波动视图下固定用户选中的指标，绝对不自动切换指标，只切换日期
  if (trendViewMode.value === 'cpk') {
    return
  }

  if (!date || !anomalyData.value || anomalyData.value.length === 0) {
    filterStore.updateIndicatorPriority(null, null, null)
    return
  }

  const item = anomalyData.value.find(d => d.date === date)
  if (!item) return

  // 1. 获取该天日环比增幅排行第一的工序 (与悬浮卡片 100% 一致)
  let topProcess = item.top_process
  if (!topProcess) {
    const processItems = [
      { name: 'TB', growth: item.tb_growth_rate, rate: item.tb_anomaly_rate },
      { name: 'TU', growth: item.tu_growth_rate, rate: item.tu_anomaly_rate },
      { name: 'TG', growth: item.tg_growth_rate, rate: item.tg_anomaly_rate }
    ]
    processItems.sort((a, b) => {
      const gA = (a.growth !== null && a.growth !== undefined) ? a.growth : -99999
      const gB = (b.growth !== null && b.growth !== undefined) ? b.growth : -99999
      if (gA !== gB) return gB - gA
      return (b.rate || 0) - (a.rate || 0)
    })
    topProcess = processItems[0]?.name
  }

  // 2. 统计该工序下日异常增幅最大的详细指标 (规则：当日异常数少于 50 的指标忽略，自动顺延寻找首个 count >= 50 的指标)
  let topIndicator = item.top_indicator
  if (!topIndicator) {
    const procInds = item.detail_indicators?.[topProcess] || []
    const validCands = procInds.filter(it => (it.count || 0) >= 50)
    if (validCands.length > 0) {
      topIndicator = validCands[0].key
    } else if (procInds.length > 0) {
      const sortedByCount = [...procInds].sort((a, b) => (b.count || 0) - (a.count || 0))
      topIndicator = sortedByCount[0]?.key
    }
  }

  // 3. 更新 filterStore 中的指标分组置顶，并将推荐高亮 isMax 精准赋予顺延选中的 topIndicator
  filterStore.updateIndicatorPriority(topProcess, item.detail_indicators, date, topIndicator)

  // 4. 自动优先选中该指标 (仅在 Yield 不良模式下)
  if (topIndicator && filterStore.cpkIndicator !== topIndicator) {
    filterStore.setCpkIndicator(topIndicator)
  }
}

function handleDateSelect(date) {
  selectedTrendDate.value = date
  if (typeof notifyTourDateSelected === 'function') {
    notifyTourDateSelected()
  }
  
  if (date) {
    const dObj = new Date(date)
    const dStart = new Date(dObj.getTime() - 7 * 24 * 60 * 60 * 1000)
    const fmt = (d) => d.toISOString().split('T')[0]
    machineCpkDateRange.value = [fmt(dStart), date]
  }

  // 仅在 Yield 不良视图且未锁定单规格时才执行工序与最大增幅详细指标联动自动切换；
  // 当在 CPK 这一页选择日期、或已锁定单规格跨日期分析时，固定当前指标，绝不自动切换指标
  if (trendViewMode.value !== 'cpk' && !tab1SelectedArticle.value) {
    const hasPrevNext = anomalyData.value?.[0]?.detail_indicators && 
      Object.values(anomalyData.value[0].detail_indicators)?.[0]?.[0]?.prev_date !== undefined

    if (anomalyData.value && anomalyData.value.length > 0 && hasPrevNext) {
      applyTopProcessAndIndicatorLinkage(date)
    } else {
      loadAnomalyTrend().then(() => {
        applyTopProcessAndIndicatorLinkage(date)
      })
    }
  }

  loadWarningArticles().then(() => {
    loadMachineProcessSankey()
    loadLotCpkTrend()
  })
}

// ── 预警规格列表 (CPK稳定值) ──────────────────────────────────────────────────
const articles      = ref([])
const isLatestDate  = ref(false)
const articleLoading= ref(false) // 默认不处于 loading 状态，直到用户点击加载
const articleError  = ref(null)
const onlyDeclining = ref(true)
const warningMinSamples = ref(30)
const warningMaxCpk     = ref(0.9)

// 当前选定规格的最严重第 1 台预警机台映射（仅保留最严重的问题机台报警：红报红，橙报橙，黄报黄）
const currentSpecWarningMachineMap = computed(() => {
  if (!tab1SelectedArticle.value || !articles.value || articles.value.length === 0) {
    return {}
  }
  const specItems = articles.value.filter(
    item => item.article10 === tab1SelectedArticle.value && item.warning_machine && item.warning_machine !== '-'
  )
  if (specItems.length === 0) return {}

  // 严格按严重度排序（红色 3 > 橙色 2 > 黄色 1），同等级按由重到轻原顺序
  const severityOrder = { red: 3, orange: 2, yellow: 1 }
  const sorted = [...specItems].sort((a, b) => {
    const sA = severityOrder[a.warning_level] || 1
    const sB = severityOrder[b.warning_level] || 1
    return sB - sA
  })

  // 只保留最严重的第一台机台
  const top1 = sorted[0]
  const mach = String(top1.warning_machine).trim().toUpperCase()
  const lvl = top1.warning_level || 'yellow'
  return { [mach]: lvl }
})

async function loadWarningArticles() {
  if (!selectedTrendDate.value) {
    articles.value = []
    isLatestDate.value = false
    return
  }
  articleLoading.value = true
  articleError.value   = null
  try {
    const params = {
      indicator: cpkIndicator.value,
      only_declining: onlyDeclining.value,
      study_from: selectedTrendDate.value,
      study_to: selectedTrendDate.value,
      min_samples: warningMinSamples.value,
      time_col: filterStore.selectedTimeCol,
      phase: filterStore.selectedPhase,
      max_cpk: warningMaxCpk.value,
      exclude_outliers: excludeOutliers.value
    }
    // 当处于单规格锁定跨日期追踪模式时，带上 article10 查看该规格在当前日期下的情况
    if (tab1SelectedArticle.value) {
      params.article10 = tab1SelectedArticle.value
    }
    const res = await api.getWarningArticles(params)
    if (res.data && res.data.status === 'success') {
      articles.value = res.data.data || []
      isLatestDate.value = !!res.data.is_latest_date
    } else {
      articles.value = []
      isLatestDate.value = false
    }
    if (excludeTop10.value && !tab1SelectedArticle.value) {
      loadCpkTrend()
    }
  } catch (e) {
    articleError.value = '预警规格列表加载异常'
    isLatestDate.value = false
  } finally {
    articleLoading.value = false
  }
}


// ── 机台 CPK / 桑基图 Tab 页签控制 ──────────────────────────────
const machineTabActive = ref('sankey_flow')
const machineMinSamples = ref(50)

const sankeyData = ref({ nodes: [], links: [] })
const sankeyLoading = ref(false)
const sankeyError = ref(null)

const bestSankeyData = ref({ nodes: [], links: [] })
const bestSankeyLoading = ref(false)
const bestSankeyError = ref(null)
const bestPathArticle = ref(null)
const sankeyChartRef = ref(null)
const bestSankeyChartRef = ref(null)

function handleOpenSankeyZoom() {
  if (machineTabActive.value === 'sankey_flow' && sankeyChartRef.value) {
    sankeyChartRef.value.openZoomDialog()
  } else if (machineTabActive.value === 'best_sankey_flow' && bestSankeyChartRef.value) {
    bestSankeyChartRef.value.openZoomDialog()
  }
}

async function loadMachineProcessSankey() {
  if (!selectedTrendDate.value || !tab1SelectedArticle.value) {
    sankeyData.value = { nodes: [], links: [] }
    return
  }
  const articleParam = tab1SelectedArticle.value
  sankeyLoading.value = true
  sankeyError.value = null
  try {
    const effectiveMinSamples = tab1SelectedArticle.value ? 1 : machineMinSamples.value
    const params = {
      article10: articleParam,
      indicator: cpkIndicator.value,
      target_date: selectedTrendDate.value,
      min_samples: effectiveMinSamples
    }
    const res = await api.getMachineProcessSankey(params)
    sankeyData.value = res.data.status === 'success' ? res.data.data : { nodes: [], links: [] }
  } catch (e) {
    sankeyError.value = '单日工序流转桑基图加载异常'
  } finally {
    sankeyLoading.value = false
  }
}

async function loadMachineBestProcessSankey() {
  const articleParam = tab1SelectedArticle.value || bestPathArticle.value
  if (!articleParam) {
    bestSankeyData.value = { nodes: [], links: [] }
    return
  }
  bestSankeyLoading.value = true
  bestSankeyError.value = null
  try {
    const effectiveMinSamples = (tab1SelectedArticle.value || bestPathArticle.value) ? 1 : machineMinSamples.value
    const params = {
      article10: articleParam,
      indicator: cpkIndicator.value,
      min_samples: effectiveMinSamples
    }
    const res = await api.getMachineBestProcessSankey(params)
    bestSankeyData.value = res.data.status === 'success' ? res.data.data : { nodes: [], links: [] }
  } catch (e) {
    bestSankeyError.value = '全量最佳工序流转路径加载异常'
  } finally {
    bestSankeyLoading.value = false
  }
}


// ── 选中规格关联物料批次 (Lot) 质量追溯 ─────────────────────────
const lotCpkData = ref([])
const lotUslValue = ref(100)
const lotLslValue = ref(null)
const lotCpkLoading = ref(false)
const lotCpkError = ref(null)
async function loadLotCpkTrend(customParams = {}) {
  const articleParam = tab1SelectedArticle.value
  if (!articleParam || !selectedTrendDate.value) {
    lotCpkData.value = []
    return
  }
  lotCpkLoading.value = true
  lotCpkError.value = null
  try {
    const params = {
      article10: articleParam,
      indicator: customParams.indicator || cpkIndicator.value,
      target_date: selectedTrendDate.value,
      min_samples: 1
    }
    if (customParams.component && customParams.component !== '全部工段') {
      params.component = customParams.component
    }
    if (customParams.time_col) {
      params.time_col = customParams.time_col
    }
    if (customParams.dateRange && customParams.dateRange.length === 2) {
      params.start_date = customParams.dateRange[0]
      params.end_date = customParams.dateRange[1]
    } else if (machineCpkDateRange.value && machineCpkDateRange.value.length === 2) {
      params.start_date = machineCpkDateRange.value[0]
      params.end_date = machineCpkDateRange.value[1]
    }
    const res = await api.getLotCpkTrend(params)
    if (res.data.status === 'success') {
      lotCpkData.value = res.data.data
      if (res.data.usl !== undefined) lotUslValue.value = res.data.usl
      lotLslValue.value = res.data.lsl !== undefined ? res.data.lsl : null
    } else {
      lotCpkData.value = []
    }
  } catch (e) {
    lotCpkError.value = '选中规格物料批次追溯数据加载异常'
  } finally {
    lotCpkLoading.value = false
  }
}

function handleLotChartReload(payload) {
  loadLotCpkTrend(payload)
}

function handleMachineMinSamplesChange() {
  if (machineTabActive.value === 'sankey_flow') {
    loadMachineProcessSankey()
  } else if (machineTabActive.value === 'best_sankey_flow') {
    loadMachineBestProcessSankey()
  }
}

watch(
  tab1SelectedArticle,
  (newVal) => {
    if (newVal) {
      bestPathArticle.value = newVal
    }
  }
)

watch(
  [machineTabActive, tab1SelectedArticle, selectedTrendDate, cpkIndicator],
  ([tabVal]) => {
    if (tabVal === 'sankey_flow') {
      loadMachineProcessSankey()
    } else if (tabVal === 'best_sankey_flow') {
      loadMachineBestProcessSankey()
    }
  }
)

// ── 成型机台 CGRS 参数变更记录弹窗状态 ──────────────────────────
const WORKCENTER_COL_LABEL_MAP = {
  gt_workcenter: '生胎成型GT',
  ct_workcenter: '硫化CT',
  tu_first_workcenter: '终检TU',
  tread_workcenter: '胎面',
  bead_workcenter: '胎圈',
  inner_liner_workcenter: '内衬',
  sidewall_workcenter: '胎侧',
  first_breaker_workcenter: '带束层1',
  second_breaker_workcenter: '带束层2',
  first_ply_workcenter: '帘布层1',
  second_ply_workcenter: '帘布层2',
  wound_cap_ply1_workcenter: '冠带层1',
  wound_cap_ply2_workcenter: '冠带层2',
  tb_first_workcenter: '动平衡TB'
}

const cgrsDialogVisible = ref(false)
const cgrsDialogMachine = ref('')
const cgrsDialogDate = ref('')
const cgrsDialogArticle = ref('')
const cgrsDialogIndicator = ref('rfpp')
const cgrsIsTopWarning = ref(false)
const cgrsTopMachines = ref([])

function handleOpenCgrs(payload) {
  cgrsDialogMachine.value = payload.machine || ''
  cgrsDialogDate.value = selectedTrendDate.value || payload.date || ''
  cgrsDialogArticle.value = payload.article || tab1SelectedArticle.value || ''
  cgrsDialogIndicator.value = payload.indicator || cpkIndicator.value || 'rfpp'
  
  const topList = payload.topWarningMachines || []
  // 提取影响度为负的 Top 3 全局预警机台
  const negMachines = topList
    .map(m => (typeof m === 'string' ? m : (m.machine || '')).toUpperCase())
    .filter(Boolean)
  cgrsTopMachines.value = Array.from(new Set(negMachines)).slice(0, 3)
  
  const rank1 = topList[0]
  const curMach = (payload.machine || '').toUpperCase()
  const rank1Name = typeof rank1 === 'string' ? rank1.toUpperCase() : (rank1?.machine || '').toUpperCase()
  const isRank1 = rank1Name && (rank1Name === curMach || curMach.includes(rank1Name) || rank1Name.includes(curMach))
  cgrsIsTopWarning.value = !!isRank1
  
  cgrsDialogVisible.value = true
}

const combinationTreeDialogVisible = ref(false)
const combinationTreeDialogRendered = ref(false)

watch(combinationTreeDialogVisible, (val) => {
  if (!val) {
    combinationTreeDialogRendered.value = false
  }
})

function handleCombinationTreeDialogOpened() {
  combinationTreeDialogRendered.value = true
}


// ── 监听状态变动刷新数据 ──────────────────────────────────────

watch(
  () => filterStore.minYieldThreshold,
  () => {
    selectedTrendDate.value = null
    articles.value = []
    onlyBelowMean.value = false
  }
)

watch(
  [() => filterStore.baselineRange, () => filterStore.studyRange],
  () => {
    selectedTrendDate.value = null
    articles.value = []
    onlyBelowMean.value = false
    loadCpkTrend()
  }
)

watch(cpkIndicator, () => {
  if (selectedTrendDate.value) {
    loadWarningArticles()
    loadLotCpkTrend()
  }
})

watch(() => filterStore.selectedTimeCol, () => {
  loadCpkTrend()
  if (selectedTrendDate.value) {
    loadWarningArticles()
    loadLotCpkTrend()
  }
  if (machineTabActive.value === 'sankey_flow') {
    loadMachineProcessSankey()
  } else if (machineTabActive.value === 'best_sankey_flow') {
    loadMachineBestProcessSankey()
  }
})

watch(() => tab1SelectedArticle.value, (newVal) => {
  if (cpkIndicator.value === 'cony') {
    if (bestPathArticle.value !== newVal) {
      bestPathArticle.value = newVal
      loadMachineBestProcessSankey()
    }
  }
})

watch(() => bestPathArticle.value, (newVal) => {
  if (cpkIndicator.value === 'cony') {
    if (tab1SelectedArticle.value !== newVal) {
      tab1SelectedArticle.value = newVal
      loadCpkTrend()
    }
  }
})

watch(machineTabActive, (newTab) => {
  if (newTab === 'sankey_flow') {
    loadMachineProcessSankey()
  } else if (newTab === 'best_sankey_flow') {
    loadMachineBestProcessSankey()
  }
})

// 全量规格列表
const allArticles = ref([])

async function loadAllArticles() {
  try {
    const res = await api.getAllArticles()
    if (res.data.status === 'success') {
      allArticles.value = res.data.data
    }
  } catch (e) {
    console.error('全量规格加载失败', e)
  }
}

// ── 初始挂载 ──────────────────────────────────────────────────
onMounted(async () => {
  const handleWindowClick = (e) => {
    if (!e.target.closest('#tour-cpk-controls')) {
      outlierDropdownOpen.value = false
      alarmDropdownOpen.value = false
    }
  }
  window.addEventListener('click', handleWindowClick)
  onUnmounted(() => {
    window.removeEventListener('click', handleWindowClick)
  })

  await Promise.all([
    loadCpkTrend(),
    loadAllArticles()
  ])
})

</script>

<style scoped>
.app-container {
  max-width: min(1600px, 98vw);
  margin: 0 auto;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.section-row {
  width: 100%;
  display: flex;
  gap: 20px;
}
.section-row.two-col {
  align-items: stretch;
}

.card {
  background-color: #fff;
  border: 1px solid #e5e8ef;
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-sm);
  display: flex;
  flex-direction: column;
}
.full-width {
  width: 100%;
}

.card-header {
  padding: 16px 20px;
  border-bottom: 1px solid #f0f2f5;
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
}

.card-header-tabs {
  border-bottom: 1px solid #f0f2f5;
}

.card-title {
  font-size: 14px;
  font-weight: 700;
  color: var(--c-text-primary);
}

.card-body {
  padding: 20px;
  flex: 1;
}

.tab-pane-content {
  padding: 16px 20px 20px 20px;
}

.filter-row-sub {
  margin-bottom: 12px;
}

.text-muted {
  font-size: 12px;
  color: var(--c-text-secondary);
}

.mt-4 { margin-top: 4px; }
.mt-8 { margin-top: 8px; }
.mt-16 { margin-top: 16px; }
.text-bold { font-weight: 600; }
.font-mono { font-family: 'JetBrains Mono', monospace; }
.text-danger { color: var(--c-danger); }

/* 面板空提示 */
.empty-period-card {
  padding: 60px 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  text-align: center;
  background-color: #fff;
  border: 1px solid #e5e8ef;
  border-radius: var(--radius-md);
}

/* 导航面包屑 */
.breadcrumb {
  font-size: 11px;
}
.breadcrumb-link {
  color: var(--c-accent);
  cursor: pointer;
  font-weight: 500;
}
.breadcrumb-link:hover {
  text-decoration: underline;
}
.breadcrumb-sep {
  margin: 0 4px;
  color: var(--c-text-muted);
}
.breadcrumb-current {
  color: var(--c-text-secondary);
}

.help-icon {
  font-size: 14px;
  color: var(--c-text-muted);
  cursor: pointer;
  transition: color var(--dur-fast) var(--ease);
}
.help-icon:hover {
  color: var(--c-accent);
}

.jump-link {
  padding: 0;
  height: auto;
  font-size: 13px;
}
.jump-link:hover {
  text-decoration: underline;
}



/* ── 数据时间胶囊徽章样式 (类似服务状态胶囊) ── */
.data-update-capsule {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  padding: 3px 12px;
  border-radius: 20px;
  box-shadow: 0 1px 2px 0 rgba(15, 23, 42, 0.04);
  margin-left: 8px;
  vertical-align: middle;
}

.capsule-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: #10b981;
  box-shadow: 0 0 0 2px rgba(16, 185, 129, 0.2);
  animation: pulse-dot 2s ease-in-out infinite;
}

@keyframes pulse-dot {
  0%, 100% { opacity: 1; transform: scale(1); }
  50%       { opacity: 0.4; transform: scale(0.9); }
}

.capsule-label {
  font-size: 12px;
  font-weight: 500;
  color: #64748b;
}

.capsule-val {
  font-size: 12px;
  font-weight: 600;
  font-family: 'JetBrains Mono', monospace;
  color: #1e293b;
}

/* ── 剔除异常值按钮高亮样式 (与 Main Hall 选中橙色/黄色主题保持一致) ── */
.exclude-outliers-btn {
  margin-left: 10px;
  font-weight: 500 !important;
  border-radius: 20px !important;
  height: 28px !important;
  line-height: 28px !important;
  padding: 0 14px !important;
  font-size: 12px !important;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1) !important;
  background: #f8fafc !important;
  border: 1px solid #e2e8f0 !important;
  color: #475569 !important;
}

.exclude-outliers-btn:hover {
  background-color: #fffbeb !important;
  border-color: #fde68a !important;
  color: #b45309 !important;
}

.exclude-outliers-btn.is-active {
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%) !important;
  border-color: #d97706 !important;
  color: #ffffff !important;
  box-shadow: 0 2px 8px rgba(245, 158, 11, 0.3) !important;
  font-weight: 700 !important;
}

.exclude-outliers-btn.is-active:hover {
  background: linear-gradient(135deg, #d97706 0%, #b45309 100%) !important;
  box-shadow: 0 3px 10px rgba(245, 158, 11, 0.4) !important;
}

/* ── 核心规格行动表黄色风格统一控件 ── */
.spec-focus-badge {
  display: inline-flex;
  align-items: center;
  height: 22px;
  line-height: 20px;
  padding: 0 9px;
  border-radius: 11px;
  background-color: #fffbeb;
  border: 1px solid #fde68a;
  color: #b45309;
  font-weight: 700;
  font-size: 11.5px;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  box-shadow: 0 1px 2px rgba(245, 158, 11, 0.08);
}

.btn-warm-outline {
  background: #ffffff !important;
  border: 1px solid #fde68a !important;
  color: #92400e !important;
  font-weight: 600 !important;
  border-radius: 14px !important;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1) !important;
}

.btn-warm-outline:hover {
  background: #fffbeb !important;
  border-color: #f59e0b !important;
  color: #78350f !important;
  box-shadow: 0 2px 6px rgba(245, 158, 11, 0.15) !important;
  transform: translateY(-1px);
}

/* ── 核心规格行动表顶部极简纯文字状态胶囊标签 ── */
.filter-pill-tag {
  display: inline-flex;
  align-items: center;
  height: 24px;
  line-height: 22px;
  padding: 0 9px;
  border-radius: 12px;
  font-size: 12px;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  font-weight: 600;
  cursor: pointer;
  user-select: none;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  gap: 4px;
}

.pill-date {
  background: #f1f5f9;
  border: 1px solid #cbd5e1;
  color: #334155;
}

.pill-date:hover {
  background: #e2e8f0;
  border-color: #94a3b8;
  color: #0f172a;
}

.pill-spec {
  background: #fffbeb;
  border: 1px solid #fde68a;
  color: #92400e;
  box-shadow: 0 1px 2px rgba(245, 158, 11, 0.08);
}

.pill-spec:hover {
  background: #fef3c7;
  border-color: #f59e0b;
  color: #78350f;
  box-shadow: 0 2px 5px rgba(245, 158, 11, 0.18);
}

.pill-close {
  font-size: 11px;
  font-weight: 700;
  line-height: 1;
  opacity: 0.6;
  transition: opacity 0.15s ease, color 0.15s ease;
  margin-left: 2px;
}

.filter-pill-tag:hover .pill-close {
  opacity: 1;
  color: #dc2626;
}

.btn-warm-primary {
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%) !important;
  border: 1px solid #d97706 !important;
  color: #ffffff !important;
  font-weight: 700 !important;
  border-radius: 14px !important;
  box-shadow: 0 2px 6px rgba(245, 158, 11, 0.25) !important;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1) !important;
}

.btn-warm-primary:hover {
  background: linear-gradient(135deg, #fbbf24 0%, #d97706 100%) !important;
  box-shadow: 0 4px 12px rgba(245, 158, 11, 0.35) !important;
  transform: translateY(-1px);
}

/* ── 报警模式胶囊按钮展开折叠 (与重置按钮保持完全一致规格) ── */
.alarm-toggle-btn-capsule {
  font-family: 'JetBrains Mono', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "PingFang SC", "Microsoft YaHei", sans-serif !important;
  font-weight: 700 !important;
  color: #d97706 !important;
  border-color: #fde68a !important;
  background: #ffffff !important;
  padding: 0 10px !important;
  height: 24px !important;
  font-size: 12px !important;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1) !important;
}

.alarm-toggle-btn-capsule:hover {
  color: #b45309 !important;
  border-color: #f59e0b !important;
  background: #fffdf5 !important;
}

.alarm-toggle-btn-capsule.is-active {
  color: #92400e !important;
  border-color: #f59e0b !important;
  background: #fffbeb !important;
  box-shadow: 0 1px 3px rgba(245, 158, 11, 0.15) !important;
}

.alarm-arrow {
  margin-left: 4px;
  font-size: 11px;
  font-weight: 800;
  color: #f59e0b;
  transition: color 0.15s ease;
}

.alarm-toggle-btn-capsule:hover .alarm-arrow {
  color: #d97706;
}

/* ── 顶部控制栏下拉面板 (报警模式 / 异常值剔除) ── */
.dropdown-filter-panel {
  padding: 4px 6px;
}

.dropdown-filter-title {
  font-size: 11px;
  font-weight: 700;
  color: #64748b;
  margin-bottom: 8px;
  padding-bottom: 4px;
  border-bottom: 1px solid #f1f5f9;
  letter-spacing: 0.5px;
}

.dropdown-checkbox-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.dropdown-item-label {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  font-size: 12px;
  color: #1e293b;
  font-weight: 500;
  user-select: none;
}

.dot-indicator {
  display: inline-block;
  width: 7px;
  height: 7px;
  border-radius: 50%;
  box-shadow: 0 0 0 2px rgba(255, 255, 255, 0.9), 0 1px 2px rgba(0, 0, 0, 0.15);
}

.capsule-dropdown-menu {
  position: absolute;
  top: calc(100% + 6px);
  left: 0;
  min-width: 195px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 8px 10px;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.12), 0 8px 10px -6px rgba(0, 0, 0, 0.06);
  z-index: 1000;
  white-space: nowrap;
}

/* ── 下拉菜单内 Element Plus 复选框主题色深度定制 (剔除默认蓝色，融入暖金主题) ── */
.capsule-dropdown-menu :deep(.el-checkbox) {
  height: 30px !important;
  margin-right: 0 !important;
  display: flex !important;
  align-items: center !important;
  padding: 0 8px !important;
  border-radius: 6px !important;
  transition: all 0.15s ease !important;
  width: 100% !important;
}

.capsule-dropdown-menu :deep(.el-checkbox:hover) {
  background-color: #fffbeb !important;
}

.capsule-dropdown-menu :deep(.el-checkbox__inner) {
  border-color: #cbd5e1 !important;
  border-radius: 4px !important;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1) !important;
}

.capsule-dropdown-menu :deep(.el-checkbox:hover .el-checkbox__inner) {
  border-color: #f59e0b !important;
}

.capsule-dropdown-menu :deep(.el-checkbox__input.is-checked .el-checkbox__inner) {
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%) !important;
  border-color: #d97706 !important;
  box-shadow: 0 1px 3px rgba(217, 119, 6, 0.3) !important;
}

.capsule-dropdown-menu :deep(.el-checkbox__inner::after) {
  border-color: #ffffff !important;
}

.capsule-dropdown-menu :deep(.el-checkbox__input.is-focus .el-checkbox__inner) {
  border-color: #f59e0b !important;
}

.capsule-dropdown-menu :deep(.el-checkbox__label) {
  padding-left: 8px !important;
  color: #334155 !important;
  font-size: 12px !important;
  font-weight: 500 !important;
}

.capsule-dropdown-menu :deep(.el-checkbox__input.is-checked + .el-checkbox__label) {
  color: #0f172a !important;
  font-weight: 600 !important;
}

.dropdown-fade-enter-active,
.dropdown-fade-leave-active {
  transition: opacity 0.15s cubic-bezier(0.4, 0, 0.2, 1), transform 0.15s cubic-bezier(0.4, 0, 0.2, 1);
}
.dropdown-fade-enter-from,
.dropdown-fade-leave-to {
  opacity: 0;
  transform: translateY(-4px) scale(0.98);
}
</style>

