<template>
  <el-dialog
    v-model="dialogVisible"
    :width="dialogWidth"
    top="7vh"
    destroy-on-close
    append-to-body
    class="rec-param-dialog"
  >
    <!-- 自定义弹窗头部：机台名称 + 模式切换 + 推荐属性标签 -->
    <template #header>
      <div class="rec-dialog-header">
        <div class="header-left">
          <span class="dialog-title-text">{{ machine }} {{ activeViewMode === 'stage_compare' ? '同工段参数对比' : '机台参数推荐' }}</span>
          <el-tooltip placement="bottom-start" effect="light" popper-class="help-tooltip-light" raw-content>
            <template #content>
              <div class="trend-help-content" style="max-width: 320px;">
                <div class="trend-help-title">机台参数推荐与对比说明</div>
                <div class="trend-help-section">
                  <div class="section-title">【这是做什么的】</div>
                  <div class="section-line">当某台机台生产质量变差时，系统帮您找出最合理的工艺参数参考值，或对比当天各机台的参数差异。</div>
                </div>
                <div class="trend-help-section" style="margin-bottom: 0;">
                  <div class="section-title">【两大模式怎么用】</div>
                  <div class="section-line"><strong>1. 工艺参数推荐模式</strong>：</div>
                  <div class="section-sub">• 🟢 <strong>同机台推荐</strong>：调出本台机台过去做得最好那一天的工艺参数；</div>
                  <div class="section-sub">• 🟠 <strong>跨机台推荐</strong>：调出同车间生产同规格表现最优秀的另一台机台的参数；</div>
                  <div class="section-sub">• <strong>【展示修改前状态】按钮</strong>：一键对比“改动前”与“改动后”，一眼看清具体改了哪项参数导致质量波动。</div>
                  <div class="section-line" style="margin-top: 4px;"><strong>2. 当天机台参数对比模式</strong>：</div>
                  <div class="section-sub">• 把当天生产同规格的所有机台参数拉成一张横向对比表；</div>
                  <div class="section-sub">• 🟡 <strong>黄色高亮行</strong>：说明机台之间设的参数不一样（比如温度差了2度、压力不同等），有差异的地方往往就是导致异常的根因！</div>
                </div>
              </div>
            </template>
            <el-icon style="cursor: pointer; color: #64748b; font-size: 15px; margin-left: 4px; vertical-align: middle;"><QuestionFilled /></el-icon>
          </el-tooltip>
          <span v-if="targetPhaseTag" class="phase-tag">{{ targetPhaseTag }}</span>
          <template v-if="activeViewMode === 'recommend'">
            <span
              v-if="hasValidRecommendation"
              class="rec-header-badge"
              :class="isSameMachine ? 'badge-same' : 'badge-cross'"
            >
              {{ isSameMachine ? '🟢 同机台参数推荐' : `🟠 同分期跨机台推荐 (来源: ${recData.source_machine})` }}
            </span>
            <span v-else-if="recData && !hasValidRecommendation" class="rec-header-badge badge-neutral">
              ⚪ 未查询到有效参数
            </span>
          </template>
          <template v-else>
            <span class="rec-header-badge badge-same">
              {{ isCu ? '🔥 硫化工段参数对比' : '⚙️ 成型工段参数对比' }}
            </span>
          </template>
        </div>

        <!-- 顶端模式切换按钮 -->
        <div class="header-mode-switch">
          <el-radio-group v-model="activeViewMode" size="small" @change="onModeChange">
            <el-radio-button value="recommend">工艺参数推荐</el-radio-button>
            <el-radio-button value="stage_compare">当天机台参数对比</el-radio-button>
          </el-radio-group>
        </div>

        <!-- 控制区：推荐模式下展示修改前状态控制 -->
        <div v-if="activeViewMode === 'recommend' && hasValidRecommendation && hasStatusComparison" class="header-controls">
          <el-button
            size="small"
            :type="showPreState ? 'primary' : 'default'"
            :class="['btn-toggle-pre-state', { 'is-active': showPreState }]"
            @click="showPreState = !showPreState"
          >
            <el-icon style="margin-right: 4px;">
              <Hide v-if="showPreState" />
              <View v-else />
            </el-icon>
            {{ showPreState ? '只看结果' : '展示修改前状态' }}
          </el-button>
        </div>
      </div>
    </template>

    <!-- 模式 1: 工艺参数推荐 (原有四列推荐看板) -->
    <template v-if="activeViewMode === 'recommend'">
      <!-- 头部统一风格元信息标签栏 (精简为三个核心标签: 规格、当前日期、推荐参数日期) -->
    <div class="rec-meta-bar">
      <div class="meta-pill">
        <span class="meta-pill-label">规格</span>
        <span class="meta-pill-val font-mono">{{ article }}</span>
      </div>
      <!-- 当前日期 -->
      <div v-if="hasValidRecommendation" class="meta-pill meta-pill-highlight">
        <span class="meta-pill-label">当前日期</span>
        <span class="meta-pill-val font-mono">{{ recData.current_base_date || recData.baseline_status_date || targetDate }}</span>
      </div>
      <!-- 推荐参数日期 (点击可展开/收起生产表现对比) -->
      <div
        v-if="hasValidRecommendation && (recData.recommend_event_date || recData.best_event_time)"
        class="meta-pill meta-pill-rec-date is-clickable-pill"
        :class="{ 'is-active-pill': showCgrsPanel }"
        @click="onTopDatePillClick"
        :title="showCgrsPanel ? '点击收起生产表现与调参趋势对比' : '点击展开生产表现与调参趋势对比'"
      >
        <span class="meta-pill-label">推荐参数日期</span>
        <span class="meta-pill-val font-mono">{{ selectedEventTime || recData.recommend_event_date || recData.best_event_time }}</span>
        <el-icon class="pill-expand-icon" :class="{ 'is-rotated': showCgrsPanel }">
          <ArrowDown />
        </el-icon>
      </div>
    </div>

    <!-- 推荐调参对应的 CGRS 生产表现与趋势分析折叠面板 (点击顶端推荐调参选取日期展开) -->
    <el-collapse-transition @after-enter="handleCgrsTransitionDone">
      <div v-if="showCgrsPanel" class="cgrs-embedded-panel-card">
        <div class="embedded-panel-header">
          <div class="embedded-panel-title">
            <span class="pulse-indicator"></span>
            <span><strong>{{ isCu ? '硫化机' : '成型机' }} [{{ recData?.source_machine || recData?.recommend_machine || machine }}]</strong> CGRS 调参生产表现与全工序实测趋势</span>
            <span v-if="selectedEventTime || recData?.recommend_event_date" class="panel-event-tag">
              调参事件: {{ selectedEventTime || recData?.recommend_event_date || recData?.best_event_time }}
            </span>
          </div>
          <button type="button" class="embedded-close-btn" @click="showCgrsPanel = false">
            收起面板 ✕
          </button>
        </div>
        <div class="embedded-panel-body">
          <CgrsRecordPanel
            ref="embeddedCgrsPanelRef"
            :machine="recData?.source_machine || recData?.recommend_machine || machine"
            :date="formatShortDate(selectedEventTime || recData?.recommend_event_date || recData?.best_event_time)"
            :event-time="selectedEventTime || recData?.best_event_time || recData?.recommend_event_date"
            :article="article"
            :indicator="indicator"
            :recommend-reason="reason"
            :hide-recommend-btn="true"
          />
        </div>
      </div>
    </el-collapse-transition>

    <!-- Loading 状态 -->
    <div v-if="loading" class="rec-state-box">
      <el-icon class="is-loading" size="26" style="color: #f59e0b;"><Loading /></el-icon>
      <span style="margin-left: 10px; font-size: 13.5px; color: #64748b; font-weight: 500;">
        正在读取机台工艺参数底表并对齐历史优质调参推荐...
      </span>
    </div>

    <!-- 错误状态 -->
    <div v-else-if="error" class="rec-state-box state-empty">
      <el-icon size="26" style="color: #ef4444;"><CircleCloseFilled /></el-icon>
      <div class="empty-msg">
        <div class="msg-title">参数数据加载失败</div>
        <div class="msg-desc">{{ error }}</div>
      </div>
    </div>

    <!-- 无推荐调参记录状态 (明确提示未查询到修改记录，绝不强行展示表格) -->
    <div v-else-if="!recData || !hasValidRecommendation" class="rec-state-box state-empty">
      <el-icon size="28" style="color: #94a3b8;"><InfoFilled /></el-icon>
      <div class="empty-msg">
        <div class="msg-title">{{ recData?.recommend_title || '未查询到推荐参数' }}</div>
        <div class="msg-desc">{{ recData?.message || '该机台当前工艺参数已稳定在同分期最佳基准，或暂无同分期历史有效调参记录。' }}</div>
      </div>
    </div>

    <!-- 内容展示区 -->
    <div v-else class="rec-content-wrap">
      <!-- 模式 A: 成功匹配到工艺底表快照，四列状态全息对比表格 -->
      <el-table
        v-if="hasStatusComparison"
        :data="filteredStatusParams"
        class="rec-params-table status-comp-table"
        size="small"
        style="width: 100%"
        max-height="540"
        :row-class-name="tableRowClassName"
      >
        <!-- 1. 参数名称与工步 -->
        <el-table-column label="工序参数名称" min-width="220">
          <template #default="{ row }">
            <div class="param-name-cell">
              <div class="param-top-line">
                <span class="param-cn" :class="{ 'param-cn-highlight': row.is_changed }">{{ row.param_name }}</span>
                <span v-if="row.is_changed" class="changed-tag">★ 推荐调整</span>
              </div>
            </div>
          </template>
        </el-table-column>

        <!-- 2. 【第一列】当前参数状态 -->
        <el-table-column min-width="150" align="right">
          <template #header>
            <div class="col-header-wrap">
              <span class="col-header-strong">当前参数状态</span>
            </div>
          </template>
          <template #default="{ row }">
            <div class="val-cell-container">
              <div class="val-cell current-val-cell font-mono">
                <span class="val-num">{{ getRowVal(row, 'current') }}</span>
                <span v-if="row.unit && hasVal(getRowVal(row, 'current'))" class="unit-text">{{ row.unit }}</span>
              </div>
              <!-- 每一个参数具体的最后修改生效时间 -->
              <div v-if="row.current_offset_date" class="param-date-caption">
                <el-tooltip :content="`该参数最近一次现场调参时间: ${row.current_offset_date}`" placement="top">
                  <span class="date-chip font-mono">
                    {{ formatDisplayDate(row.current_offset_date) }}
                  </span>
                </el-tooltip>
              </div>
              <div v-else-if="getRowVal(row, 'current') === '-'" class="param-date-caption">
                <span class="text-muted-sub">未调过 (无记录)</span>
              </div>
            </div>
          </template>
        </el-table-column>

        <!-- 3. 【第二列】推荐修改前状态 (默认隐藏，点击按钮后展示) -->
        <el-table-column v-if="showPreState" min-width="150" align="right">
          <template #header>
            <div class="col-header-wrap">
              <span class="col-header-muted">推荐修改前状态</span>
            </div>
          </template>
          <template #default="{ row }">
            <div class="val-cell-container">
              <div class="val-cell pre-rec-val-cell font-mono">
                <span class="val-num">{{ getRowVal(row, 'pre') }}</span>
                <span v-if="row.unit && hasVal(getRowVal(row, 'pre'))" class="unit-text">{{ row.unit }}</span>
              </div>
              <div v-if="row.recommend_event_date && hasVal(getRowVal(row, 'pre'))" class="param-date-caption">
                <el-tooltip :content="`点击在上方查看该调参事件生产表现: ${row.recommend_event_date}`" placement="top">
                  <span
                    class="date-chip font-mono is-clickable-tag"
                    @click.stop="onDateChipClick(row.recommend_event_date)"
                  >
                    {{ formatDisplayDate(row.recommend_event_date) }}
                  </span>
                </el-tooltip>
              </div>
            </div>
          </template>
        </el-table-column>

        <!-- 4. 【第三列】推荐参数 -->
        <el-table-column min-width="160" align="right">
          <template #header>
            <div class="col-header-wrap">
              <span class="col-header-highlight">推荐参数</span>
            </div>
          </template>
          <template #default="{ row }">
            <div class="val-cell-container">
              <div class="val-cell rec-after-cell font-mono" :class="{ 'rec-val-changed': row.is_changed }">
                <span class="val-num">{{ getRowVal(row, 'post') }}</span>
                <span v-if="row.unit && hasVal(getRowVal(row, 'post'))" class="unit-text">{{ row.unit }}</span>
              </div>
              <!-- 推荐方案日期标记 (保持与当前参数状态时间标签完全相同的标准样式) -->
              <div v-if="row.recommend_event_date && hasVal(getRowVal(row, 'post'))" class="param-date-caption">
                <el-tooltip :content="`本次推荐参数源于调参事件: ${row.recommend_event_date}（点击在上方查看生产表现与全工序趋势）`" placement="top">
                  <span
                    class="date-chip font-mono is-clickable-tag"
                    @click.stop="onDateChipClick(row.recommend_event_date)"
                  >
                    {{ formatDisplayDate(row.recommend_event_date) }}
                  </span>
                </el-tooltip>
              </div>
            </div>
          </template>
        </el-table-column>

        <!-- 5. 【第四列】修改变化 -->
        <el-table-column label="修改变化" min-width="110" align="center">
          <template #default="{ row }">
            <template v-if="row.is_changed && getRowChange(row)">
              <span class="change-diff-pill font-mono" :class="getChangeBadgeClass(row.change_value ?? row.change_delta_value)">
                {{ getRowChange(row) }}
              </span>
            </template>
            <template v-else-if="!row.is_changed && getRowChange(row)">
              <el-tooltip content="当前参数与历史最优工况设定的标杆差异 (Gap)" placement="top">
                <span class="change-diff-pill font-mono badge-diff-gap">
                  {{ getRowChange(row) }}
                </span>
              </el-tooltip>
            </template>
            <span v-else class="val-empty-dash">-</span>
          </template>
        </el-table-column>
      </el-table>

      <!-- 模式 B: 硫化机或当期无原始底表快照时，仅展示真实调参记录明细 -->
      <el-table
        v-else
        :data="recData.params"
        size="small"
        style="width: 100%"
        max-height="540"
      >
        <!-- 1. 参数项信息 -->
        <el-table-column label="推荐调整工艺参数" min-width="220">
          <template #default="{ row }">
            <div class="param-name-cell">
              <span class="param-cn">{{ row.param_name }}</span>
            </div>
          </template>
        </el-table-column>

        <!-- 2. 工段类型 -->
        <el-table-column label="工序工段" width="110" align="center">
          <template #default="{ row }">
            <span class="stage-tag font-mono">{{ row.stage }}</span>
          </template>
        </el-table-column>

        <!-- 3. 参数变更轨迹 -->
        <el-table-column label="参数变更轨迹" min-width="200">
          <template #default="{ row }">
            <div class="trajectory-cell font-mono">
              <span class="from-num">{{ row.setting_from }}</span>
              <span class="arrow-symbol">➔</span>
              <span class="to-pill">{{ row.setting_to }}</span>
              <span v-if="row.unit" class="unit-text">{{ row.unit }}</span>
            </div>
          </template>
        </el-table-column>
      </el-table>
    </div>
    </template>

    <!-- 模式 2: 当天同工段机台状态参数对比 (纵向参数行，横向机台列，差异行醒目标记) -->
    <template v-else-if="activeViewMode === 'stage_compare'">
      <div class="comp-wrapper">
        <!-- 头部元信息栏 -->
        <div class="rec-meta-bar">
          <div class="meta-pill">
            <span class="meta-pill-label">规格</span>
            <span class="meta-pill-val font-mono">{{ article }}</span>
          </div>
          <div class="meta-pill meta-pill-highlight">
            <span class="meta-pill-label">选定日期</span>
            <span class="meta-pill-val font-mono">{{ targetDate }}</span>
          </div>
          <div class="meta-pill">
            <span class="meta-pill-label">选定机台</span>
            <span class="meta-pill-val font-mono" style="color: #dc2626; font-weight: 700;">{{ machine }}</span>
          </div>
          <div v-if="compData?.machines" class="meta-pill">
            <span class="meta-pill-label">当天分流机台</span>
            <span class="meta-pill-val font-mono">共 {{ compData.machines.length }} 台</span>
          </div>
        </div>

        <!-- 过滤与工序切换操作栏 -->
        <div class="comp-toolbar">
          <div class="comp-toolbar-left">
            <!-- 成型工段专属一段/二段切换 -->
            <div v-if="!isCu" class="comp-process-switcher">
              <el-radio-group v-model="compProcessType" size="small" @change="fetchStageMachinesComparison">
                <el-radio-button value="125">PU 成型二段 (30项)</el-radio-button>
                <el-radio-button value="119">KM 成型一段 (26项)</el-radio-button>
              </el-radio-group>
            </div>
            <span v-else class="comp-cu-badge font-mono">CU 硫化工序核心参数 (14项)</span>

            <!-- 说明提示文案：机台按 CPK 从高到低排列，黄色背景行为机台间存在差异的参数，红色背景列为选定机台 -->
            <div class="comp-tip-banner">
              <span class="tip-dot"></span>
              <span class="tip-text">机台按 CPK 从高到低排列，黄色背景行为机台间存在差异的参数，红色背景为选定机台</span>
            </div>
          </div>

          <div class="comp-toolbar-right">
            <!-- 搜索框 -->
            <el-input
              v-model="compSearchKeyword"
              placeholder="搜索参数名称..."
              size="small"
              clearable
              style="width: 170px;"
            />
          </div>
        </div>

        <!-- Loading 状态 -->
        <div v-if="compLoading" class="rec-state-box">
          <el-icon class="is-loading" size="26" style="color: #f59e0b;"><Loading /></el-icon>
          <span style="margin-left: 10px; font-size: 13.5px; color: #64748b; font-weight: 500;">
            正在读取选定当天同工段各机台工艺底表与生效偏置并进行比对...
          </span>
        </div>

        <!-- 错误状态 -->
        <div v-else-if="compError" class="rec-state-box state-empty">
          <el-icon size="26" style="color: #ef4444;"><CircleCloseFilled /></el-icon>
          <div class="empty-msg">
            <div class="msg-title">机台参数数据加载失败</div>
            <div class="msg-desc">{{ compError }}</div>
          </div>
        </div>

        <!-- 空数据提示 -->
        <div v-else-if="!compData || filteredCompParams.length === 0" class="rec-state-box state-empty">
          <el-icon size="28" style="color: #94a3b8;"><InfoFilled /></el-icon>
          <div class="empty-msg">
            <div class="msg-title">暂无匹配的机台参数数据</div>
            <div class="msg-desc">
              未检索到选定当天的机台参数记录。
            </div>
          </div>
        </div>

        <!-- 对比数据表格 (参数为行，机台为列，差异行标记高亮) -->
        <div v-else class="rec-content-wrap">
          <el-table
            :data="filteredCompParams"
            class="rec-params-table status-comp-table comp-table-view"
            size="small"
            style="width: 100%"
            max-height="540"
            :row-class-name="compTableRowClassName"
          >
            <!-- 1. 工序参数名称 -->
            <el-table-column label="工序参数名称" min-width="220" fixed="left">
              <template #default="{ row }">
                <div class="param-name-cell">
                  <div class="param-top-line">
                    <span class="param-cn" :class="{ 'param-cn-highlight': row.has_difference }">
                      {{ row.param_name }}
                    </span>
                    <span v-if="row.has_difference" class="diff-alert-badge">
                      ⚠️ 存在差异
                    </span>
                  </div>
                  <div class="param-sub-info">
                    <span v-if="row.process_step" class="param-step-tag">{{ row.process_step }}</span>
                    <span v-if="row.unit" class="param-unit-tag">[{{ row.unit }}]</span>
                  </div>
                </div>
              </template>
            </el-table-column>

            <!-- 2+. 当天同工段各机台动态列 (按桑基图 CPK 从高到低排列) -->
            <el-table-column
              v-for="mach in sortedMachines"
              :key="mach"
              :min-width="140"
              align="right"
              :class-name="mach === machine ? 'col-selected-mach' : ''"
              :label-class-name="mach === machine ? 'col-header-selected-mach' : ''"
            >
              <template #header>
                <div class="col-header-wrap" :class="{ 'is-primary-col': mach === machine }">
                  <div class="mach-name-line">
                    <span class="col-header-strong font-mono">{{ mach }}</span>
                    <span v-if="mach === machine" class="primary-mach-tag">选定</span>
                  </div>
                  <div v-if="sankeyMachineCpkMap[mach]" class="mach-cpk-sub font-mono">
                    CPK: {{ sankeyMachineCpkMap[mach].cpk_display }}
                  </div>
                </div>
              </template>
              <template #default="{ row }">
                <div class="val-cell-container" :class="{ 'is-primary-cell': mach === machine }">
                  <div class="val-cell current-val-cell font-mono">
                    <span class="val-num">{{ row.machine_values?.[mach]?.val_display || '-' }}</span>
                    <span v-if="row.unit && hasVal(row.machine_values?.[mach]?.val_display)" class="unit-text">{{ row.unit }}</span>
                  </div>
                  <!-- 偏置与最后修改时间标记 (灰色纯文本展示，不采用标签形式) -->
                  <div v-if="row.machine_values?.[mach]?.has_offset" class="param-date-caption">
                    <el-tooltip :content="`偏置: ${row.machine_values[mach]?.offset_display} (${row.machine_values[mach]?.offset_date || '现场设定'})`" placement="top">
                      <span class="comp-date-text font-mono">
                        {{ formatDisplayDate(row.machine_values[mach]?.offset_date) }}
                      </span>
                    </el-tooltip>
                  </div>
                  <div v-else-if="row.machine_values?.[mach]?.val_display && row.machine_values?.[mach]?.val_display !== '-'" class="param-date-caption">
                    <span class="comp-date-text">底表基准</span>
                  </div>
                </div>
              </template>
            </el-table-column>
          </el-table>
        </div>
      </div>
    </template>
  </el-dialog>
</template>

<script setup>
import { ref, computed, watch, nextTick } from 'vue'
import { Loading, InfoFilled, CircleCloseFilled, View, Hide, ArrowDown, ArrowUp, QuestionFilled } from '@element-plus/icons-vue'
import CgrsRecordPanel from './CgrsRecordPanel.vue'

const props = defineProps({
  visible:        { type: Boolean, default: false },
  machine:        { type: String, default: '' },
  article:        { type: String, default: '' },
  targetDate:     { type: String, default: '' },
  workcenterType: { type: String, default: 'gt' },
  indicator:      { type: String, default: 'rfpp' },
  reason:         { type: String, default: 'degradation' },
  sankeyNodes:    { type: Array, default: () => [] }
})

const emit = defineEmits(['update:visible'])

// 双向绑定弹窗显示状态，采用官方 computed get/set 消除 watch 滞后与状态竞争
const dialogVisible = computed({
  get: () => props.visible,
  set: (val) => emit('update:visible', val)
})

const loading = ref(false)
const error = ref(null)
const recData = ref(null)
const selectedEventTime = ref('') // 当前选中的具体调参事件时间戳
const showPreState = ref(false) // 默认只展示结果（不展示推荐修改前状态列）
const showCgrsPanel = ref(false)
const embeddedCgrsPanelRef = ref(null)

const targetPhaseTag = computed(() => {
  const p = recData.value?.target_phase
  if (p === 'P4') return '四期'
  if (p === 'P3') return '三期'
  return ''
})

function handleCgrsTransitionDone() {
  if (embeddedCgrsPanelRef.value?.resizeChart) {
    embeddedCgrsPanelRef.value.resizeChart()
  }
}

watch(() => showCgrsPanel.value, (newVal) => {
  if (newVal) {
    nextTick(() => {
      setTimeout(() => embeddedCgrsPanelRef.value?.resizeChart?.(), 100)
      setTimeout(() => embeddedCgrsPanelRef.value?.resizeChart?.(), 350)
      setTimeout(() => embeddedCgrsPanelRef.value?.resizeChart?.(), 600)
    })
  }
})

const isCu = computed(() => {
  const m = String(props.machine || '').toUpperCase()
  return m.startsWith('CU') || m.startsWith('CT') || String(props.workcenterType).toLowerCase() in { ct: 1, cu: 1 }
})

const isSameMachine = computed(() => {
  if (!recData.value) return true
  return recData.value.recommend_category === 'same_machine' || recData.value.source_type === 'same_machine_best'
})

// 是否包含多工序工艺参数状态对比表 (只要包含 status_comparison 数据即渲染四列全息看板)
// 是否存在真正需要调整的有效推荐（排除“已到达最佳参数”/修改变化均为0的情况）
const hasValidRecommendation = computed(() => {
  if (!recData.value || !recData.value.has_recommendation) return false
  if (recData.value.is_optimal_no_diff) return false
  if (Array.isArray(recData.value.status_comparison)) {
    const changedRows = recData.value.status_comparison.filter(r => r && r.is_changed)
    if (changedRows.length > 0 && changedRows.every(r => r.change === '已到达最佳参数' || Math.abs(Number(r.change_value) || 0) < 0.0001)) {
      return false
    }
  }
  return true
})

const hasStatusComparison = computed(() => {
  return Boolean(
    recData.value?.status_comparison &&
    Array.isArray(recData.value.status_comparison) &&
    recData.value.status_comparison.length > 0
  )
})

// 表格参数列表（直接输出状态对比全量数据）
const filteredStatusParams = computed(() => {
  if (!hasStatusComparison.value) return []
  return recData.value.status_comparison
})

function tableRowClassName({ row }) {
  if (row.is_changed) {
    return 'row-highlight-changed'
  }
  return ''
}

function getChangeBadgeClass(val) {
  if (val === null || val === undefined) return ''
  const num = Number(val)
  if (!isNaN(num) && Math.abs(num) < 0.0001) return 'badge-diff-zero'
  return num > 0 ? 'badge-diff-pos' : 'badge-diff-neg'
}

function getRowVal(row, type) {
  if (!row) return '-'
  if (type === 'current') {
    return row.current_value_formatted || row.current_status_display || (row.current_value !== null && row.current_value !== undefined ? String(row.current_value) : '-')
  }
  if (type === 'pre') {
    return row.pre_recommended_value_formatted || row.recommend_before_display || (row.pre_recommended_value !== null && row.pre_recommended_value !== undefined ? String(row.pre_recommended_value) : '-')
  }
  if (type === 'post') {
    return row.recommended_value_formatted || row.recommend_after_display || (row.recommended_value !== null && row.recommended_value !== undefined ? String(row.recommended_value) : '-')
  }
  return '-'
}

function hasVal(v) {
  return Boolean(v && v !== '-' && v !== '')
}

function getRowChange(row) {
  if (!row) return ''
  return row.change || row.change_delta_display || ''
}

function formatShortDate(d) {
  if (!d) return ''
  const str = String(d).trim()
  return str.slice(0, 10)
}

function formatDisplayDate(d) {
  if (!d) return ''
  const str = String(d).trim()
  // 去除 4 位年份前缀，呈现更紧凑美观的 MM-DD HH:mm 或 MM-DD
  return str.replace(/^\d{4}-/, '')
}

function formatInheritedTag(d) {
  if (!d) return ''
  const str = String(d).trim().slice(0, 10)
  return str.replace(/^\d{4}-/, '')
}

function onTopDatePillClick() {
  showCgrsPanel.value = !showCgrsPanel.value
  if (showCgrsPanel.value && !selectedEventTime.value) {
    selectedEventTime.value = recData.value?.best_event_time || recData.value?.recommend_event_date || ''
  }
  if (showCgrsPanel.value) {
    nextTick(() => {
      setTimeout(() => embeddedCgrsPanelRef.value?.resizeChart?.(), 100)
      setTimeout(() => embeddedCgrsPanelRef.value?.resizeChart?.(), 300)
      setTimeout(() => embeddedCgrsPanelRef.value?.resizeChart?.(), 600)
    })
  }
}

function onDateChipClick(dtStr) {
  if (!dtStr) return
  selectedEventTime.value = String(dtStr).trim()
  showCgrsPanel.value = true
}

// ── 模式切换与对比状态管理 ──────────────────────────────────────────
const activeViewMode = ref('recommend') // 'recommend' | 'stage_compare'
const compProcessType = ref('125') // '125' (PU二段30项) | '119' (KM一段26项)
const compData = ref(null)
const compLoading = ref(false)
const compError = ref(null)
const compSearchKeyword = ref('')

// 提取右侧桑基图中各机台已计算好的实测 CPK
const sankeyMachineCpkMap = computed(() => {
  const map = {}
  if (!Array.isArray(props.sankeyNodes)) return map
  props.sankeyNodes.forEach(node => {
    if (!node) return
    const rawName = node.machine_code || (node.name ? node.name.split('_').slice(1).join('_') : '') || node.name || ''
    const code = String(rawName).trim().toUpperCase()
    if (code && node.spec_cpk !== undefined && node.spec_cpk !== null) {
      map[code] = {
        cpk: Number(node.spec_cpk),
        cpk_display: Number(node.spec_cpk).toFixed(2)
      }
    }
  })
  return map
})

// 机台列按桑基图的 CPK 从高到低（从优到劣由左至右）横向排序
const sortedMachines = computed(() => {
  if (!compData.value || !Array.isArray(compData.value.machines)) return []
  const list = [...compData.value.machines]
  const cpkMap = sankeyMachineCpkMap.value

  list.sort((a, b) => {
    const aCode = String(a).trim().toUpperCase()
    const bCode = String(b).trim().toUpperCase()
    const aCpk = cpkMap[aCode]?.cpk ?? -9999
    const bCpk = cpkMap[bCode]?.cpk ?? -9999
    if (bCpk !== aCpk) {
      return bCpk - aCpk // 降序：高 CPK 在左，低 CPK 在右
    }
    if (aCode === String(props.machine).toUpperCase()) return -1
    if (bCode === String(props.machine).toUpperCase()) return 1
    return aCode.localeCompare(bCode)
  })

  return list
})

const dialogWidth = computed(() => {
  if (activeViewMode.value === 'stage_compare') {
    const machCount = sortedMachines.value.length || compData.value?.machines?.length || 2
    const calcW = Math.max(980, Math.min(1360, 320 + machCount * 145))
    return `${calcW}px`
  }
  return hasStatusComparison.value ? '1040px' : '760px'
})

function onModeChange(newMode) {
  if (newMode === 'stage_compare') {
    if (!compData.value || compData.value.article10 !== props.article || compData.value.target_date !== props.targetDate) {
      fetchStageMachinesComparison()
    }
  }
}

async function fetchStageMachinesComparison() {
  if (!props.machine || !props.article) return
  compLoading.value = true
  compError.value = null
  try {
    const params = new URLSearchParams({
      machine: props.machine,
      article10: props.article,
      target_date: props.targetDate || '',
      workcenter_type: isCu.value ? 'ct' : 'gt',
      process_type_id: isCu.value ? '123' : compProcessType.value
    })
    const res = await fetch(`/api/cgrs/stage-machines-status-comparison?${params.toString()}`)
    const json = await res.json()
    if (json.status === 'success') {
      compData.value = json
    } else {
      compError.value = json.message || '获取同工段机台对比数据失败'
    }
  } catch (e) {
    console.error('fetchStageMachinesComparison error:', e)
    compError.value = '网络请求异常，无法加载机台对比参数'
  } finally {
    compLoading.value = false
  }
}

const filteredCompParams = computed(() => {
  if (!compData.value || !Array.isArray(compData.value.parameters)) return []
  let list = compData.value.parameters
  if (compSearchKeyword.value.trim()) {
    const kw = compSearchKeyword.value.trim().toLowerCase()
    list = list.filter(p =>
      (p.param_name && p.param_name.toLowerCase().includes(kw)) ||
      (p.sys_name && p.sys_name.toLowerCase().includes(kw)) ||
      (p.process_step && p.process_step.toLowerCase().includes(kw)) ||
      (p.category && p.category.toLowerCase().includes(kw))
    )
  }
  return list
})

function compTableRowClassName({ row }) {
  if (row.has_difference) {
    return 'row-has-difference'
  }
  return ''
}

watch(() => props.visible, (v) => {
  if (v && props.machine) {
    activeViewMode.value = 'recommend'
    compData.value = null
    compSearchKeyword.value = ''
    showPreState.value = false // 每次打开弹窗默认只展示结果
    showCgrsPanel.value = false // 每次打开弹窗默认收起面板
    selectedEventTime.value = ''
    fetchRecommendedParams()
  }
})

async function fetchRecommendedParams() {
  loading.value = true
  error.value = null
  recData.value = null
  selectedEventTime.value = ''

  try {
    const params = new URLSearchParams({
      machine: props.machine,
      article10: props.article,
      workcenter_type: isCu.value ? 'ct' : 'gt',
      indicator: props.indicator || 'rfpp',
      target_date: props.targetDate || '',
      reason: props.reason || 'degradation'
    })
    const res = await fetch(`/api/cgrs/recommended-params?${params.toString()}`)
    const json = await res.json()
    if (json.status === 'success') {
      recData.value = json
      selectedEventTime.value = json.best_event_time || json.recommend_event_date || ''
    } else {
      error.value = json.message || '获取推荐数据失败'
    }
  } catch (e) {
    console.error('fetchRecommendedParams error:', e)
    error.value = '网络请求异常，无法加载推荐参数'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.rec-param-dialog :deep(.el-dialog__body) {
  padding: 14px 20px 18px;
  background: #ffffff;
}

/* 弹窗头部：标题 + 胶囊徽标 + 筛选控制区 */
.rec-dialog-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding-right: 20px;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.header-controls {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-toggle-pre-state {
  font-weight: 500;
  border-radius: 6px;
  font-size: 12.5px;
  padding: 6px 12px;
  border-color: #cbd5e1;
  color: #334155;
  transition: all 0.2s ease;
}

.btn-toggle-pre-state:hover {
  border-color: #3b82f6;
  color: #2563eb;
  background-color: #eff6ff;
}

.btn-toggle-pre-state.is-active {
  background-color: #2563eb !important;
  border-color: #2563eb !important;
  color: #ffffff !important;
  box-shadow: 0 1px 3px rgba(37, 99, 235, 0.25);
}

.dialog-title-text {
  font-size: 16px;
  font-weight: 700;
  color: #0f172a;
  letter-spacing: -0.01em;
}

.phase-tag {
  display: inline-flex;
  align-items: center;
  padding: 2px 10px;
  font-size: 11.5px;
  font-weight: 600;
  border-radius: 12px;
  background: #f1f5f9;
  color: #475569;
  border: 1px solid #cbd5e1;
}

.rec-header-badge {
  font-size: 12px;
  font-weight: 600;
  padding: 2px 12px;
  border-radius: 20px;
  display: inline-flex;
  align-items: center;
  line-height: 1.5;
}

.badge-same {
  background: #ecfdf5;
  color: #047857;
  border: 1px solid #a7f3d0;
}

.badge-cross {
  background: #fff7ed;
  color: #c2410c;
  border: 1px solid #fed7aa;
}

.badge-neutral {
  background: #f1f5f9;
  color: #475569;
  border: 1px solid #e2e8f0;
}

/* 头部元信息栏 */
.rec-meta-bar {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 12px;
}

.meta-pill {
  display: inline-flex;
  align-items: center;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 20px;
  padding: 4px 13px;
  font-size: 12px;
  line-height: 1.4;
  gap: 6px;
}

.meta-pill-label {
  color: #64748b;
  font-weight: 500;
}

.meta-pill-val {
  color: #0f172a;
  font-weight: 600;
}

.meta-pill-highlight {
  background: #eff6ff;
  border-color: #bfdbfe;
}
.meta-pill-highlight .meta-pill-label {
  color: #1d4ed8;
}
.meta-pill-highlight .meta-pill-val {
  color: #1e40af;
}

.meta-pill-changed {
  background: #fef3c7;
  border-color: #fde68a;
}

.meta-pill-rec-date {
  background: #fffbeb;
  border-color: #fde68a;
}

.meta-pill-rec-date .meta-pill-label {
  color: #b45309;
}

.meta-pill-rec-date .meta-pill-val {
  color: #92400e;
}

.is-clickable-pill {
  cursor: pointer;
  user-select: none;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}

.is-clickable-pill:hover {
  background: #fef3c7;
  border-color: #f59e0b;
  box-shadow: 0 2px 6px rgba(245, 158, 11, 0.15);
  transform: translateY(-1px);
}

.is-clickable-pill.is-active-pill {
  background: #fef3c7;
  border-color: #d97706;
  box-shadow: 0 0 0 2px rgba(217, 119, 6, 0.2);
}

.pill-expand-icon {
  font-size: 12px;
  color: #d97706;
  margin-left: 2px;
  transition: transform 0.25s ease;
}

.pill-expand-icon.is-rotated {
  transform: rotate(180deg);
}

/* 嵌入式 CGRS 生产表现与趋势折叠面板 */
.cgrs-embedded-panel-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  margin-bottom: 16px;
  box-shadow: 0 4px 16px rgba(15, 23, 42, 0.06);
  overflow: hidden;
}

.embedded-panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 14px;
  background: #f1f5f9;
  border-bottom: 1px solid #e2e8f0;
}

.embedded-panel-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #334155;
}

.pulse-indicator {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #f59e0b;
  box-shadow: 0 0 0 2px rgba(245, 158, 11, 0.25);
}

.embedded-close-btn {
  background: transparent;
  border: none;
  font-size: 12px;
  color: #64748b;
  cursor: pointer;
  padding: 2px 6px;
  border-radius: 4px;
  transition: all 0.15s ease;
}

.embedded-close-btn:hover {
  background: #e2e8f0;
  color: #0f172a;
}

.embedded-panel-body {
  padding: 12px 14px;
  max-height: 580px;
  overflow-y: auto;
}

/* 说明条 */
.table-sub-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 6px 12px;
  background: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
  font-size: 11.5px;
  color: #64748b;
}

.sub-header-tip {
  display: flex;
  align-items: center;
  gap: 6px;
}

.tip-icon {
  font-size: 13px;
}

.sub-header-counts {
  font-weight: 600;
  color: #475569;
}

/* 状态框 */
.rec-state-box {
  height: 200px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f8fafc;
  border-radius: 8px;
  border: 1px dashed #cbd5e1;
}

.state-empty {
  flex-direction: column;
  gap: 8px;
}

.empty-msg {
  text-align: center;
}

.msg-title {
  font-size: 14px;
  font-weight: 700;
  color: #334155;
  margin-bottom: 4px;
}

.msg-desc {
  font-size: 12px;
  color: #64748b;
}

/* 表格主体 */
.rec-content-wrap {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
}

.rec-params-table {
  width: 100%;
}

.rec-params-table :deep(th.el-table__cell) {
  background: #f8fafc;
  color: #475569;
  font-weight: 600;
  font-size: 12.5px;
  padding: 9px 0;
  border-bottom: 1px solid #e2e8f0;
}

.rec-params-table :deep(td.el-table__cell) {
  padding: 8px 12px;
  border-bottom: 1px solid #f1f5f9;
}

/* 修改项整行高亮 */
.status-comp-table :deep(.row-highlight-changed) {
  background-color: #fffbeb !important;
}

.status-comp-table :deep(.row-highlight-changed:hover > td.el-table__cell) {
  background-color: #fef3c7 !important;
}

.param-name-cell {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.param-title-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.local-name {
  font-size: 13.5px;
  font-weight: 600;
  color: #0f172a;
}

.text-bold-changed {
  color: #92400e;
  font-weight: 700;
}

.changed-tag {
  font-size: 10.5px;
  font-weight: 700;
  color: #b45309;
  background: #fef3c7;
  border: 1px solid #fde68a;
  border-radius: 4px;
  padding: 1px 6px;
  line-height: 1.4;
}

.param-name-cell {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.param-top-line {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 6px;
}

.param-cn {
  font-size: 13.5px;
  font-weight: 600;
  color: #0f172a;
}

.param-cn-highlight {
  font-weight: 700;
  color: #92400e;
}

.param-en {
  font-size: 11px;
  color: #64748b;
  line-height: 1.2;
}

.step-pill {
  font-size: 11px;
  font-weight: 600;
  padding: 1px 7px;
  border-radius: 4px;
  background: #f1f5f9;
  color: #475569;
  border: 1px solid #e2e8f0;
  line-height: 1.4;
  white-space: nowrap;
}

.step-cu {
  background: #eff6ff;
  color: #2563eb;
  border-color: #bfdbfe;
}

.step-gt {
  background: #f0fdf4;
  color: #15803d;
  border-color: #bbf7d0;
}

.changed-tag {
  font-size: 11px;
  font-weight: 700;
  color: #b45309;
  background: #fef3c7;
  border: 1px solid #fde68a;
  border-radius: 4px;
  padding: 1px 7px;
  line-height: 1.4;
  white-space: nowrap;
}

/* 单元格数值与表头 */
.col-header-wrap {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 2px;
}

.col-header-strong {
  font-weight: 700;
  color: #0f172a;
}

.col-header-muted {
  font-weight: 600;
  color: #64748b;
}

.col-header-highlight {
  font-weight: 700;
  color: #b45309;
}

.col-header-date-badge {
  font-size: 10px;
  font-weight: 600;
  color: #2563eb;
  background: #eff6ff;
  border: 1px solid #bfdbfe;
  border-radius: 3px;
  padding: 0 4px;
  line-height: 1.4;
  letter-spacing: -0.2px;
}

.badge-rec-date {
  color: #b45309;
  background: #fffbeb;
  border-color: #fde68a;
}

.meta-pill-rec-date {
  background: #fffbeb;
  border-color: #fde68a;
}
.meta-pill-rec-date .meta-pill-label {
  color: #b45309;
}
.meta-pill-rec-date .meta-pill-val {
  color: #92400e;
}

.val-cell-container {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 2px;
}

.val-cell {
  display: inline-flex;
  align-items: baseline;
  justify-content: flex-end;
  gap: 4px;
}

.val-num {
  font-size: 13.5px;
  font-weight: 700;
  color: #1e293b;
}

.unit-text {
  font-size: 11px;
  color: #64748b;
  font-weight: 500;
}

.param-date-caption {
  font-size: 10px;
  line-height: 1.3;
}

.date-chip {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  font-size: 10px;
  color: #475569;
  background: #f1f5f9;
  border: 1px solid #e2e8f0;
  border-radius: 3px;
  padding: 0 4px;
  cursor: help;
  transition: all 0.15s ease;
}

.date-chip:hover {
  background: #e2e8f0;
  color: #0f172a;
}

.date-chip-rec {
  color: #b45309;
  background: #fffbeb;
  border-color: #fde68a;
}

.date-chip-rec:hover {
  background: #fef3c7;
  color: #78350f;
}

.is-clickable-tag {
  cursor: pointer !important;
  user-select: none;
}

.is-clickable-tag:hover {
  background-color: #e2e8f0;
  color: #0f172a;
}

.panel-event-tag {
  display: inline-flex;
  align-items: center;
  background: #eff6ff;
  color: #2563eb;
  border: 1px solid #bfdbfe;
  padding: 1px 8px;
  border-radius: 4px;
  font-size: 11.5px;
  font-weight: 600;
  margin-left: 8px;
}

.date-chip-inherited {
  color: #0369a1;
  background: #f0f9ff;
  border-color: #bae6fd;
}

.date-chip-inherited:hover {
  background: #e0f2fe;
}

.inherited-tag {
  color: #0284c7;
  font-weight: 600;
  margin-left: 2px;
}

.text-muted-sub {
  color: #94a3b8;
  font-size: 10px;
}

.val-empty-dash {
  color: #94a3b8;
  font-size: 13px;
}

.rec-val-changed {
  background: transparent;
  padding: 0;
  border: none;
}

.rec-val-changed .val-num {
  color: #b45309;
  font-weight: 700;
}

.change-diff-pill {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 52px;
  height: 22px;
  padding: 0 8px;
  border-radius: 11px;
  font-size: 12px;
  font-weight: 700;
}

.badge-diff-pos {
  background: #ecfdf5;
  color: #047857;
  border: 1px solid #a7f3d0;
}

.badge-diff-neg {
  background: #fff7ed;
  color: #c2410c;
  border: 1px solid #fed7aa;
}

.badge-diff-zero {
  background: #f8fafc;
  color: #475569;
  border: 1px solid #cbd5e1;
}

.badge-diff-gap {
  background: #f8fafc;
  color: #334155;
  border: 1px dashed #94a3b8;
  cursor: help;
}

.date-chip-empty {
  color: #94a3b8;
  background: #f8fafc;
  border-color: #e2e8f0;
  font-style: italic;
}

.date-chip-bench {
  color: #0369a1;
  background: #f0f9ff;
  border-color: #bae6fd;
}

.empty-placeholder {
  display: inline-block;
  width: 20px;
}

/* 硫化机旧视图轨迹 */
.trajectory-cell {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
}

.from-num {
  color: #64748b;
  font-weight: 500;
}

.arrow-symbol {
  color: #94a3b8;
  font-size: 12px;
}

.to-pill {
  background: #e0f2fe;
  color: #0369a1;
  font-weight: 700;
  padding: 2px 9px;
  border-radius: 4px;
  border: 1px solid #bae6fd;
  font-size: 13.5px;
}

.priority-tag {
  height: 18px;
  line-height: 16px;
  padding: 0 5px;
  font-size: 10.5px;
  font-weight: 700;
  border-radius: 4px;
  background: #fef2f2;
  color: #dc2626;
  border: 1px solid #fecaca;
  display: inline-flex;
  align-items: center;
}

.time-val {
  font-size: 12px;
  color: #334155;
}

.font-mono {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  font-variant-numeric: tabular-nums;
  font-feature-settings: "tnum";
}

/* ── 当天同工段机台对比视图样式 ── */
.header-mode-switch {
  display: flex;
  align-items: center;
}

.header-mode-switch :deep(.el-radio-button__inner) {
  font-weight: 600;
  font-size: 12.5px;
  padding: 6px 14px;
}

.comp-wrapper {
  display: flex;
  flex-direction: column;
}

.comp-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 12px;
  padding: 8px 12px;
  background: #f8fafc;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.comp-toolbar-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.comp-toolbar-right {
  display: flex;
  align-items: center;
  gap: 10px;
}

.comp-cu-badge {
  font-size: 12px;
  font-weight: 600;
  color: #c2410c;
  background: #fff7ed;
  padding: 3px 10px;
  border-radius: 6px;
  border: 1px solid #ffedd5;
}

.comp-stage-badge {
  font-size: 12px;
  font-weight: 700;
  color: #1e293b;
  padding: 2px 8px;
  border-radius: 4px;
  background: #e2e8f0;
}

.comp-date-tip {
  font-size: 12px;
  color: #64748b;
}

/* 差异行标记与高亮 */
.comp-table-view :deep(.el-table__row.row-has-difference) {
  background-color: #fefce8 !important;
}

.comp-table-view :deep(.el-table__row.row-has-difference:hover > td) {
  background-color: #fef9c3 !important;
}

.diff-alert-badge {
  display: inline-flex;
  align-items: center;
  font-size: 11px;
  font-weight: 700;
  color: #b45309;
  background: #fef3c7;
  border: 1px solid #fde68a;
  border-radius: 4px;
  padding: 1px 6px;
  margin-left: 8px;
  line-height: 1.3;
}

.param-sub-info {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 2px;
}

.param-step-tag {
  font-size: 11px;
  color: #64748b;
}

.param-unit-tag {
  font-size: 11px;
  color: #94a3b8;
  font-family: monospace;
}

.is-primary-col .col-header-strong {
  color: #dc2626 !important;
}

.primary-mach-tag {
  display: inline-block;
  margin-left: 4px;
  font-size: 10px;
  font-weight: 700;
  color: #dc2626;
  background: #fee2e2;
  border: 1px solid #fca5a5;
  border-radius: 3px;
  padding: 0 4px;
  line-height: 14px;
}

/* 选定机台列与参数单元格红色背景标记 */
.comp-table-view :deep(td.col-selected-mach) {
  background-color: #fee2e2 !important;
}

.comp-table-view :deep(.el-table__row:hover td.col-selected-mach),
.comp-table-view :deep(.el-table__row.row-has-difference:hover td.col-selected-mach) {
  background-color: #fecaca !important;
}

.comp-table-view :deep(th.col-header-selected-mach) {
  background-color: #fff1f2 !important;
}

.is-primary-cell .val-num {
  color: #991b1b;
  font-weight: 700;
}

.comp-date-text {
  font-size: 11px;
  color: #94a3b8;
  line-height: 1.2;
  display: inline-block;
}

.col-selected-mach .comp-date-text {
  color: #8c7171;
}

.comp-tip-banner {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  background: #fefce8;
  border: 1px solid #fef08a;
  border-radius: 4px;
  padding: 4px 10px;
  font-size: 12px;
  color: #854d0e;
  font-weight: 500;
  margin-left: 12px;
}

.comp-tip-banner .tip-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: #eab308;
  display: inline-block;
  flex-shrink: 0;
}

.mach-name-line {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 4px;
}

.mach-cpk-sub {
  font-size: 11px;
  font-weight: 700;
  color: #059669;
  background: #ecfdf5;
  border: 1px solid #a7f3d0;
  border-radius: 3px;
  padding: 0 5px;
  margin-top: 3px;
  display: inline-block;
  line-height: 16px;
  letter-spacing: 0.2px;
}
</style>
