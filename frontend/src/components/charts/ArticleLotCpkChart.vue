<template>
  <div class="lot-chart-container" style="width: 100%; position: relative;">
    <!-- 顶部综合控制栏: 工段切换、分布模式、指标切换、时间维度排序、日期选择 -->
    <div class="lot-top-controls" style="margin-bottom: 12px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 10px;">
      <!-- 左侧: 视图分布模式 & 质量指标选择 -->
      <div style="display: flex; align-items: center; gap: 8px; flex-wrap: wrap;">
        <el-radio-group v-if="props.indicator !== 'weight'" v-model="displayMode" size="small" @change="handleDisplayModeChange">
          <el-radio-button value="cpk">CPK 分布</el-radio-button>
          <el-radio-button value="raw">实际值分布</el-radio-button>
          <el-radio-button value="combo">带束层组合分析</el-radio-button>
        </el-radio-group>
        <span v-else style="font-size: 13px; font-weight: bold; color: #475569; display: flex; align-items: center; gap: 4px;">
          胎重实际测量值分布 (单位: kg)
        </span>
        <el-tooltip placement="top" effect="light" popper-class="help-tooltip-light" raw-content>
          <template #content>
            <div class="trend-help-content" style="max-width: 320px;">
              <div class="trend-help-title">分布模式与带束层组合说明</div>
              <div class="trend-help-section">
                <div class="section-title">【三大视图模式】</div>
                <div class="section-sub">• <strong>CPK 分布</strong>：看不同物料批次下的质量稳定性打分；</div>
                <div class="section-sub">• <strong>实际值分布</strong>：看每一条轮胎的实际测量数值和跳出红虚线的超标红点；</div>
                <div class="section-sub">• <strong>带束层组合分析</strong>：分析上带束层和下带束层不同物料搭配时的合格情况，<strong>异常率最高的组合优先排在最前</strong>。</div>
              </div>
              <div class="trend-help-section">
                <div class="section-title">【物料图例同色规则】</div>
                <div class="section-line">后五位物料代码相同的使用同一种颜色（代表是同一批物料）；如果某个颜色段集中冒出多个红点，说明这批物料质量不稳定。</div>
              </div>
              <div class="trend-help-section" style="margin-bottom: 0;">
                <div class="section-title">【异常率计算公式】</div>
                <div class="formula-box">批次/组合异常率 = (超标轮胎条数 ÷ 该组合总条数) × 100%</div>
              </div>
            </div>
          </template>
          <el-icon style="cursor: pointer; color: #64748b; font-size: 14px;"><QuestionFilled /></el-icon>
        </el-tooltip>
      </div>

      <!-- 右侧: 时间维度选择器与日期范围选择器 -->
      <div style="display: flex; align-items: center; gap: 12px; flex-wrap: wrap;">
        <div class="nav-control-group stripe-pill">
          <div class="nav-label-badge">
            <el-icon class="nav-badge-icon"><Clock /></el-icon>
            <span class="nav-control-label">排序维度</span>
          </div>
          <el-select
            v-model="selectedTimeCol"
            size="small"
            class="header-nav-select time-sort-select"
            popper-class="header-select-popper"
            style="width: 165px;"
            @change="handleTimeColChange"
          >
            <el-option label="成型 GT 时间 (默认)" value="gt_loc_timestamp" />
            <el-option label="硫化 CT 时间" value="ct_loc_timestamp" />
            <el-option label="胎面时间" value="tread_loc_timestamp" />
            <el-option label="胎圈时间" value="bead_loc_timestamp" />
            <el-option label="内衬时间" value="inner_liner_loc_timestamp" />
            <el-option label="胎侧时间" value="sidewall_loc_timestamp" />
            <el-option label="带束层1时间" value="first_breaker_loc_timestamp" />
            <el-option label="带束层2时间" value="second_breaker_loc_timestamp" />
            <el-option label="帘布层1时间" value="first_ply_loc_timestamp" />
            <el-option label="帘布层2时间" value="second_ply_loc_timestamp" />
            <el-option label="冠带层1时间" value="wound_cap_ply1_loc_timestamp" />
            <el-option label="冠带层2时间" value="wound_cap_ply2_loc_timestamp" />
          </el-select>
        </div>

        <div class="nav-control-group stripe-pill">
          <div class="nav-label-badge">
            <el-icon class="nav-badge-icon"><Calendar /></el-icon>
            <span class="nav-control-label">生产日期</span>
          </div>
          <el-date-picker
            v-model="dateRange"
            type="daterange"
            range-separator="至"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
            size="small"
            format="YYYY-MM-DD"
            value-format="YYYY-MM-DD"
            class="header-nav-datepicker"
            style="width: 215px;"
            :clearable="false"
            @change="handleDateRangeChange"
          />
        </div>
      </div>
    </div>

    <!-- 工段快速定位导航按钮组 (在非组合分析模式下展示) -->
    <div v-if="!isComboMode" class="workcenter-nav-bar" style="margin-bottom: 10px; display: flex; align-items: center; gap: 8px; flex-wrap: wrap;">
      <span style="font-size: 12px; font-weight: 600; color: #475569; margin-right: 2px;">选择工段:</span>
      <button
        v-for="comp in allWorkcenters"
        :key="comp"
        class="wc-nav-btn"
        :class="{ active: activeComponent === comp }"
        @click="selectComponent(comp)"
      >
        {{ comp }}
      </button>
    </div>

    <!-- 图例与提示说明栏 (组合分析模式 vs 普通工段模式) -->
    <!-- 1. 组合分析模式图例说明栏 (左右两翼布局: 左侧操作统计，右侧独立图例区) -->
    <div v-if="isComboMode" class="lot-notice-bar combo-notice-bar" style="margin-bottom: 10px; font-size: 12px; background: #f8fafc; padding: 10px 16px; border-radius: 8px; border: 1px solid #e2e8f0; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 16px;">
      <!-- 左翼: 控制操作与统计走势说明 (文字统一中性深黑，不花哨) -->
      <div style="display: flex; gap: 16px; align-items: center; flex-wrap: wrap; color: #334155;">
        <!-- 成型机台单选下拉框 -->
        <div style="display: flex; align-items: center; gap: 6px;">
          <span style="font-weight: 600;">成型机台:</span>
          <el-select
            v-model="comboSelectedMachine"
            placeholder="请选择机台"
            size="small"
            style="width: 145px;"
            @change="handleComboMachineChange"
          >
            <el-option
              v-for="m in (comboData?.available_machines || [])"
              :key="m.machine"
              :label="`${m.machine} (${m.count}条)`"
              :value="m.machine"
            />
          </el-select>
        </div>

        <span>当日条码: <strong>{{ comboSummary.total_count }}</strong> 条</span>
        <span>超限预警: <strong>{{ comboSummary.out_of_spec_count }} 条 ({{ comboSummary.out_of_spec_rate }})</strong></span>
        <span><span style="color: #4f46e5; font-weight: bold;">──</span> 实际值走势</span>
        <span><span style="color: #ef4444; font-size: 13px;">●</span> 超限红点</span>
        <span v-if="comboSummary.usl !== null && comboSummary.usl !== undefined">
          <span style="color: #ef4444; font-weight: bold;">┄┄</span> 规格上限 (USL: {{ comboSummary.usl }})
        </span>
      </div>

      <!-- 右翼: 独立物料图例区 (最右侧，网格矩阵对齐，上下每一个物料号严格纵向对齐，按异常率从高到低优先排列) -->
      <div 
        class="combo-legend-grid-wrap" 
        style="flex-shrink: 0; display: grid; grid-template-columns: 130px repeat(4, 168px) auto; row-gap: 6px; column-gap: 8px; align-items: center; border-left: 1px solid #e2e8f0; padding-left: 14px; overflow-x: auto; max-width: 100%;"
      >
        <!-- 行1: 带束1 标题 (显示异常数量) -->
        <div style="grid-column: 1; font-size: 11px; color: #475569; font-weight: 600; white-space: nowrap;">
          ▲ 带束1 (异常 {{ comboSummary.b1_out_count || 0 }} 条):
        </div>
        <!-- 行1: 带束1 异常率最高优先物料徽章 (各占第 2, 3, 4, 5 列) -->
        <template v-for="(m, idx) in displayB1Materials" :key="'b1_' + m.material">
          <div
            class="combo-legend-badge"
            :class="{ active: hoveredMaterial === (m.mat_key || (m.material.length >= 5 ? m.material.slice(-5) : m.material)) }"
            :style="{ 
              gridColumn: idx + 2,
              backgroundColor: hoveredMaterial === (m.mat_key || (m.material.length >= 5 ? m.material.slice(-5) : m.material)) ? m.color.replace(/[\d.]+\)$/, '0.40)') : m.color,
              color: '#1e293b',
              boxShadow: hoveredMaterial === (m.mat_key || (m.material.length >= 5 ? m.material.slice(-5) : m.material)) ? '0 2px 6px rgba(0,0,0,0.18)' : 'none',
              transform: hoveredMaterial === (m.mat_key || (m.material.length >= 5 ? m.material.slice(-5) : m.material)) ? 'scale(1.02)' : 'none'
            }"
            :title="`物料号: ${m.material}\n异常数量: ${m.out_count || 0} 条\n总条码量: ${m.count} 条\n异常率: ${(m.out_rate || 0).toFixed(1)}%`"
            style="font-size: 11px; padding: 2.5px 6px; border-radius: 4px; font-weight: 600; cursor: pointer; transition: all 0.15s ease; border: 1px solid rgba(0,0,0,0.12); display: flex; align-items: center; justify-content: space-between; box-sizing: border-box; width: 100%; white-space: nowrap; user-select: none;"
            @mouseenter="hoveredMaterial = (m.mat_key || (m.material.length >= 5 ? m.material.slice(-5) : m.material))"
            @mouseleave="hoveredMaterial = null"
          >
            <span style="display: flex; align-items: center; gap: 4px; overflow: hidden; text-overflow: ellipsis;">
              <span style="font-size: 9px; line-height: 1;">■</span>
              <span style="font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; letter-spacing: -0.2px;">{{ m.material }}</span>
            </span>
            <span 
              style="font-size: 10px; margin-left: 4px; flex-shrink: 0;"
              :style="{ 
                color: (m.out_count || 0) > 0 ? '#dc2626' : '#64748b',
                fontWeight: (m.out_count || 0) > 0 ? '700' : 'normal'
              }"
            >
              <template v-if="(m.out_count || 0) > 0">
                ({{ m.out_count }}条, {{ (m.out_rate || 0).toFixed(1) }}%)
              </template>
              <template v-else>
                (0条异常)
              </template>
            </span>
          </div>
        </template>
        <!-- 行1: +N个 更多折叠物料浮窗 -->
        <div v-if="remainingB1Materials.length > 0" style="grid-column: 6; white-space: nowrap;">
          <el-popover placement="bottom-end" :width="290" trigger="hover">
            <template #reference>
              <span style="font-size: 11px; color: #2563eb; cursor: pointer; text-decoration: underline; font-weight: 600;">
                +{{ remainingB1Materials.length }}个
              </span>
            </template>
            <div style="font-size: 11px; max-height: 220px; overflow-y: auto; padding: 2px;">
              <div style="font-weight: 700; color: #334155; margin-bottom: 6px; padding-bottom: 4px; border-bottom: 1px solid #e2e8f0; display: flex; justify-content: space-between;">
                <span>带束1 其余物料 (共 {{ remainingB1Materials.length }} 个)</span>
                <span style="font-size: 10px; color: #94a3b8; font-weight: normal;">按异常率降序</span>
              </div>
              <div
                v-for="rm in remainingB1Materials"
                :key="rm.material"
                style="display: flex; justify-content: space-between; align-items: center; padding: 3px 6px; border-radius: 4px; cursor: pointer; margin-bottom: 3px;"
                :style="{ backgroundColor: hoveredMaterial === (rm.mat_key || (rm.material.length >= 5 ? rm.material.slice(-5) : rm.material)) ? 'rgba(37,99,235,0.12)' : '#f8fafc' }"
                @mouseenter="hoveredMaterial = (rm.mat_key || (rm.material.length >= 5 ? rm.material.slice(-5) : rm.material))"
                @mouseleave="hoveredMaterial = null"
              >
                <span style="display: flex; align-items: center; gap: 4px;">
                  <span style="font-size: 9px;">■</span>
                  <span style="font-family: monospace;">{{ rm.material }}</span>
                </span>
                <span :style="{ color: (rm.out_count || 0) > 0 ? '#dc2626' : '#64748b', fontWeight: (rm.out_count || 0) > 0 ? '700' : 'normal' }">
                  {{ rm.out_count || 0 }}条异常 ({{ (rm.out_rate || 0).toFixed(1) }}%)
                </span>
              </div>
            </div>
          </el-popover>
        </div>

        <!-- 行2: 带束2 标题 (显示异常数量) -->
        <div style="grid-column: 1; font-size: 11px; color: #475569; font-weight: 600; white-space: nowrap;">
          ▼ 带束2 (异常 {{ comboSummary.b2_out_count || 0 }} 条):
        </div>
        <!-- 行2: 带束2 异常率最高优先物料徽章 (各占第 2, 3, 4, 5 列) -->
        <template v-for="(m, idx) in displayB2Materials" :key="'b2_' + m.material">
          <div
            class="combo-legend-badge"
            :class="{ active: hoveredMaterial === (m.mat_key || (m.material.length >= 5 ? m.material.slice(-5) : m.material)) }"
            :style="{ 
              gridColumn: idx + 2,
              backgroundColor: hoveredMaterial === (m.mat_key || (m.material.length >= 5 ? m.material.slice(-5) : m.material)) ? m.color.replace(/[\d.]+\)$/, '0.40)') : m.color,
              color: '#1e293b',
              boxShadow: hoveredMaterial === (m.mat_key || (m.material.length >= 5 ? m.material.slice(-5) : m.material)) ? '0 2px 6px rgba(0,0,0,0.18)' : 'none',
              transform: hoveredMaterial === (m.mat_key || (m.material.length >= 5 ? m.material.slice(-5) : m.material)) ? 'scale(1.02)' : 'none'
            }"
            :title="`物料号: ${m.material}\n异常数量: ${m.out_count || 0} 条\n总条码量: ${m.count} 条\n异常率: ${(m.out_rate || 0).toFixed(1)}%`"
            style="font-size: 11px; padding: 2.5px 6px; border-radius: 4px; font-weight: 600; cursor: pointer; transition: all 0.15s ease; border: 1px solid rgba(0,0,0,0.12); display: flex; align-items: center; justify-content: space-between; box-sizing: border-box; width: 100%; white-space: nowrap; user-select: none;"
            @mouseenter="hoveredMaterial = (m.mat_key || (m.material.length >= 5 ? m.material.slice(-5) : m.material))"
            @mouseleave="hoveredMaterial = null"
          >
            <span style="display: flex; align-items: center; gap: 4px; overflow: hidden; text-overflow: ellipsis;">
              <span style="font-size: 9px; line-height: 1;">■</span>
              <span style="font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; letter-spacing: -0.2px;">{{ m.material }}</span>
            </span>
            <span 
              style="font-size: 10px; margin-left: 4px; flex-shrink: 0;"
              :style="{ 
                color: (m.out_count || 0) > 0 ? '#dc2626' : '#64748b',
                fontWeight: (m.out_count || 0) > 0 ? '700' : 'normal'
              }"
            >
              <template v-if="(m.out_count || 0) > 0">
                ({{ m.out_count }}条, {{ (m.out_rate || 0).toFixed(1) }}%)
              </template>
              <template v-else>
                (0条异常)
              </template>
            </span>
          </div>
        </template>
        <!-- 行2: +N个 更多折叠物料浮窗 -->
        <div v-if="remainingB2Materials.length > 0" style="grid-column: 6; white-space: nowrap;">
          <el-popover placement="bottom-end" :width="290" trigger="hover">
            <template #reference>
              <span style="font-size: 11px; color: #2563eb; cursor: pointer; text-decoration: underline; font-weight: 600;">
                +{{ remainingB2Materials.length }}个
              </span>
            </template>
            <div style="font-size: 11px; max-height: 220px; overflow-y: auto; padding: 2px;">
              <div style="font-weight: 700; color: #334155; margin-bottom: 6px; padding-bottom: 4px; border-bottom: 1px solid #e2e8f0; display: flex; justify-content: space-between;">
                <span>带束2 其余物料 (共 {{ remainingB2Materials.length }} 个)</span>
                <span style="font-size: 10px; color: #94a3b8; font-weight: normal;">按异常率降序</span>
              </div>
              <div
                v-for="rm in remainingB2Materials"
                :key="rm.material"
                style="display: flex; justify-content: space-between; align-items: center; padding: 3px 6px; border-radius: 4px; cursor: pointer; margin-bottom: 3px;"
                :style="{ backgroundColor: hoveredMaterial === (rm.mat_key || (rm.material.length >= 5 ? rm.material.slice(-5) : rm.material)) ? 'rgba(37,99,235,0.12)' : '#f8fafc' }"
                @mouseenter="hoveredMaterial = (rm.mat_key || (rm.material.length >= 5 ? rm.material.slice(-5) : rm.material))"
                @mouseleave="hoveredMaterial = null"
              >
                <span style="display: flex; align-items: center; gap: 4px;">
                  <span style="font-size: 9px;">■</span>
                  <span style="font-family: monospace;">{{ rm.material }}</span>
                </span>
                <span :style="{ color: (rm.out_count || 0) > 0 ? '#dc2626' : '#64748b', fontWeight: (rm.out_count || 0) > 0 ? '700' : 'normal' }">
                  {{ rm.out_count || 0 }}条异常 ({{ (rm.out_rate || 0).toFixed(1) }}%)
                </span>
              </div>
            </div>
          </el-popover>
        </div>
      </div>
    </div>

    <!-- 2. 普通单工段批次模式图例说明栏 -->
    <div v-else class="lot-notice-bar" style="margin-bottom: 10px; font-size: 12px; background: #f8fafc; padding: 8px 14px; border-radius: 6px; border: 1px solid #e2e8f0; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 10px;">
      <div style="display: flex; gap: 16px; align-items: center; flex-wrap: wrap;">
        <span>【{{ activeComponent || '工段' }}】有效批次: <strong>{{ currentCompLotCount }}</strong> 个</span>
        <template v-if="displayMode === 'cpk'">
          <span style="color: #334155; font-weight: 600;">● ── 单规格 CPK (点击数据点看 Barcode 明细)</span>
          <span style="color: #64748b; font-weight: 600;">◆ ┈┈ 其它规格加权 CPK (已排除当前单规格)</span>
        </template>
        <template v-else>
          <div v-if="props.indicator !== 'weight'" style="font-size: 11px; display: flex; align-items: center; gap: 8px;">
            <span style="color: #dc2626; font-weight: 600;">── 规格上限 (USL: {{ uslValue }})</span>
            <span v-if="props.lslValue !== null && props.lslValue !== undefined" style="color: #dc2626; font-weight: 600;">── 规格下限 (LSL: {{ props.lslValue }})</span>
            <span style="color: #ef4444; font-weight: 600;">── 基准线 (CPK Target: 1.33)</span>
          </div>
          <span v-else style="color: #475569; font-weight: 500;">按选定时间维度先后次序排列</span>
        </template>
      </div>
      
      <!-- 右侧图例组 -->
      <div style="display: flex; flex-direction: column; gap: 6px; align-items: flex-end;">
        <!-- 加工机台图例 -->
        <div style="display: flex; gap: 8px; align-items: center; flex-wrap: wrap;">
          <span style="color: #64748b; font-weight: 500;">加工机台:</span>
          <span
            v-for="m in uniqueMachines"
            :key="m.code"
            style="font-size: 11px; padding: 2px 6px; border-radius: 4px; background: #ffffff; border: 1px solid #cbd5e1; font-weight: bold;"
            :style="{ color: m.color }"
          >
            ● {{ m.code }}
          </span>
        </div>
        <!-- 成型机台比例背景色图例 -->
        <div v-if="uniqueBuildingMachines.length > 0" style="display: flex; gap: 8px; align-items: center; flex-wrap: wrap;">
          <span style="color: #64748b; font-weight: 500;">成型分流 (背景色):</span>
          <span
            v-for="m in uniqueBuildingMachines"
            :key="m.code"
            style="font-size: 11px; padding: 2px 6px; border-radius: 4px; border: 1px solid #cbd5e1; font-weight: bold; cursor: pointer; transition: all 0.2s;"
            :style="{ 
              borderColor: selectedBuildingMachine === m.code ? m.color : '#cbd5e1', 
              backgroundColor: selectedBuildingMachine === m.code ? m.color : m.bgColor, 
              color: selectedBuildingMachine === m.code ? '#ffffff' : '#334155',
              boxShadow: selectedBuildingMachine === m.code ? '0 1px 3px rgba(0,0,0,0.15)' : 'none'
            }"
            @click="toggleBuildingMachineFilter(m.code)"
          >
            ■ {{ m.code }}
          </span>
        </div>
      </div>
    </div>

    <!-- 加载状态 -->
    <div v-if="isComboMode ? comboLoading : loading" class="lot-loading" style="height: 350px; display: flex; align-items: center; justify-content: center;">
      <el-icon class="is-loading" size="24"><Loading /></el-icon>
      <span style="margin-left: 8px; font-size: 13px; color: #666;">
        {{ isComboMode ? '正在分析带束层物料组合与条码实测值走势...' : '正在加载物料批次追溯数据...' }}
      </span>
    </div>
    <!-- 错误状态 -->
    <div v-else-if="isComboMode ? comboError : error" class="lot-error" style="height: 350px; display: flex; align-items: center; justify-content: center; color: #ef4444; font-size: 13px;">
      <span>{{ isComboMode ? comboError : error }}</span>
    </div>
    <!-- 空数据状态 -->
    <div v-else-if="isComboMode ? (!comboData || !comboData.barcodes || comboData.barcodes.length === 0) : (!filteredLotData || filteredLotData.length === 0)" class="lot-empty" style="height: 350px; display: flex; align-items: center; justify-content: center; color: #8c959f; font-size: 13px;">
      <el-empty :description="isComboMode ? '当前规格与日期范围内暂无带束层物料生产数据' : `当前选中规格在 [${activeComponent}] 工段下暂无半成品物料批次记录`" :image-size="60" />
    </div>
    <!-- 图表展示 -->
    <template v-else>
      <v-chart
        ref="chartRef"
        :option="isComboMode ? comboOption : option"
        autoresize
        style="width: 100%; height: 350px; cursor: pointer;"
        @click="onChartClick"
        @datazoom="onDataZoom"
      />
    </template>

    <!-- 点击箱形图/数据点后的 Barcode 级测量实际值明细弹窗 -->
    <el-dialog
      v-model="barcodeDialogVisible"
      :title="`${localIndicator.toUpperCase()} 实际值 (按 barcode 和 ${dialogLotInfo?.component || activeComponent || ''}_lot)`"
      width="84%"
      top="4vh"
      destroy-on-close
      append-to-body
    >
      <!-- 弹窗顶栏控制与元数据说明 -->
      <div style="margin-bottom: 12px; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 10px; background: #f8fafc; padding: 10px 14px; border-radius: 6px; border: 1px solid #e2e8f0;">
        <div style="display: flex; gap: 16px; align-items: center; flex-wrap: wrap; font-size: 12px; color: #334155;">
          <span>规格: <strong>{{ selectedArticle || '未指定' }}</strong></span>
          <span>工段: <strong>{{ dialogLotInfo?.component || activeComponent }}</strong></span>
          <span>加工机台: <strong :style="{ color: getMachineColor(dialogLotInfo?.machine) }">● {{ dialogLotInfo?.machine }}</strong></span>
          <span>物料批次 Lot: <strong style="color: #2563eb;">{{ dialogLotInfo?.lot }}</strong></span>
          <span>下属 Barcode 样本量: <strong>{{ dialogBarcodeList.length }}</strong> 条</span>
        </div>

        <!-- 机台分组连线切换 Radio -->
        <div style="display: flex; align-items: center; gap: 8px;">
          <span style="font-size: 12px; font-weight: 600; color: #475569;">机台分组连线:</span>
          <el-radio-group v-model="barcodeGroupMode" size="small">
            <el-radio-button value="none">不分组 (全局顺序)</el-radio-button>
            <el-radio-button value="ct">按 CT 硫化机台分组</el-radio-button>
            <el-radio-button value="tu">按 TU 检测机台分组</el-radio-button>
          </el-radio-group>
        </div>
      </div>

      <div v-if="dialogLoading" style="height: 400px; display: flex; align-items: center; justify-content: center;">
        <el-icon class="is-loading" size="28"><Loading /></el-icon>
        <span style="margin-left: 10px; color: #64748b; font-size: 13px;">正在加载选中物料批次关联的 Barcode 级测量数据...</span>
      </div>
      <div v-else-if="dialogError" style="height: 400px; display: flex; align-items: center; justify-content: center; color: #ef4444; font-size: 13px;">
        {{ dialogError }}
      </div>
      <div v-else-if="!dialogBarcodeList || dialogBarcodeList.length === 0" style="height: 400px; display: flex; align-items: center; justify-content: center;">
        <el-empty description="该物料批次暂无关联的 Barcode 级实际测量记录" :image-size="60" />
      </div>
      <template v-else>
        <v-chart
          :option="barcodeChartOption"
          autoresize
          style="width: 100%; height: 420px;"
        />
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import VChart from 'vue-echarts'
import { use } from 'echarts/core'
import { LineChart, BoxplotChart, ScatterChart } from 'echarts/charts'
import { TooltipComponent, GridComponent, LegendComponent, MarkLineComponent, MarkAreaComponent, DataZoomComponent } from 'echarts/components'
import { CanvasRenderer } from 'echarts/renderers'
import { Loading, Clock, Calendar, QuestionFilled } from '@element-plus/icons-vue'
import { api } from '@/api'

use([LineChart, BoxplotChart, ScatterChart, TooltipComponent, GridComponent, LegendComponent, MarkLineComponent, MarkAreaComponent, DataZoomComponent, CanvasRenderer])

const props = defineProps({
  lotData:         { type: Array, default: () => [] },
  uslValue:        { type: Number, default: 100 },
  lslValue:        { type: Number, default: null },
  loading:         { type: Boolean, default: false },
  error:           { type: String, default: null },
  selectedArticle: { type: String, default: '' },
  targetDate:      { type: String, default: '' },
  indicator:       { type: String, default: 'rfpp' }
})

const emit = defineEmits(['reload'])

const chartRef = ref(null)
const displayMode = ref('cpk') // 'cpk' | 'raw'
const localIndicator = ref(props.indicator || 'rfpp')
function getNearThreeDaysRange(baseDateStr) {
  let endD = new Date()
  if (baseDateStr) {
    const p = new Date(baseDateStr)
    if (!isNaN(p.getTime())) {
      endD = p
    }
  }
  // 默认近三天: 往前推 2 天即为完整 3 天 (如 23, 24, 25)
  const startD = new Date(endD.getTime() - 2 * 24 * 60 * 60 * 1000)
  const fmt = (d) => {
    const y = d.getFullYear()
    const m = String(d.getMonth() + 1).padStart(2, '0')
    const day = String(d.getDate()).padStart(2, '0')
    return `${y}-${m}-${day}`
  }
  return [fmt(startD), fmt(endD)]
}

const selectedTimeCol = ref('gt_loc_timestamp')
const dateRange = ref(getNearThreeDaysRange(props.targetDate || '2026-09-25'))
const activeComponent = ref('胎面')

// Barcode 明细弹窗管理与分组模式
const barcodeDialogVisible = ref(false)
const dialogLoading = ref(false)
const dialogError = ref(null)
const dialogLotInfo = ref(null)
const dialogBarcodeList = ref([])
const barcodeGroupMode = ref('none') // 'none' | 'ct' | 'tu'

// 固定的 9 大工段列表 (严格按生产顺序)
const allWorkcenters = [
  '胎面', '胎圈', '内衬', '胎侧', '帘布层1', '带束层1', '带束层2', '冠带层1', '冠带层2'
]

// 预定义机器调色板 (区分不同加工机台)
const machineColors = [
  '#2563eb', '#7c3aed', '#059669', '#d97706', '#db2777', 
  '#0284c7', '#9333ea', '#16a34a', '#ea580c', '#e11d48'
]

function hexToRgba(hex, alpha = 1.0) {
  if (!hex || typeof hex !== 'string' || !hex.startsWith('#')) return hex
  let c = hex.substring(1)
  if (c.length === 3) c = c.split('').map(x => x + x).join('')
  const num = parseInt(c, 16)
  return `rgba(${(num >> 16) & 255}, ${(num >> 8) & 255}, ${num & 255}, ${alpha})`
}

// 自动继承初始化日期与指标，并支持在规格/日期/指标变更时重置/同步追溯时间
watch(() => props.targetDate, (newVal) => {
  if (newVal) {
    dateRange.value = getNearThreeDaysRange(newVal)
  }
}, { immediate: true })

// ── 带束层物料组合分析状态与方法 ──────────────────────────
const isComboMode = ref(false)
const comboLoading = ref(false)
const comboError = ref(null)
const comboData = ref(null)
const comboSelectedMachine = ref('') // 当前选中的成型机台
const hoveredMaterial = ref(null) // 鼠标悬浮图例时高亮对应的物料号色块
const comboZoomState = ref({ start: 0, end: 100 }) // 保持全部展示，并记录用户当前缩放滑动位置

function onDataZoom(params) {
  if (isComboMode.value) {
    if (params.batch && params.batch[0]) {
      if (params.batch[0].start !== undefined) comboZoomState.value.start = params.batch[0].start
      if (params.batch[0].end !== undefined) comboZoomState.value.end = params.batch[0].end
    } else {
      if (params.start !== undefined) comboZoomState.value.start = params.start
      if (params.end !== undefined) comboZoomState.value.end = params.end
    }
  }
}

async function fetchComboData(overrideMachine = null) {
  if (!props.selectedArticle) return
  comboLoading.value = true
  comboError.value = null
  try {
    const machineToQuery = overrideMachine !== null ? overrideMachine : comboSelectedMachine.value
    const sDate = dateRange.value?.[0]
    const eDate = dateRange.value?.[1]
    const res = await api.getBreakerCombination({
      article10: props.selectedArticle,
      start_date: sDate,
      end_date: eDate,
      target_date: sDate === eDate ? sDate : undefined,
      gt_workcenter: machineToQuery || undefined,
      indicator: localIndicator.value,
      time_col: selectedTimeCol.value,
      limit: 2500
    })
    const payload = res?.data || res
    if (payload && payload.status === 'success') {
      comboData.value = payload
      // 保持当前选中的机台与后端返回同步
      if (payload.summary?.selected_machine) {
        comboSelectedMachine.value = payload.summary.selected_machine
      }
      // 载入新数据时恢复默认 100% 全部展示
      comboZoomState.value = { start: 0, end: 100 }
    } else {
      comboError.value = payload?.message || '获取带束层组合分析数据失败'
    }
  } catch (err) {
    comboError.value = err.message || '网络请求异常'
  } finally {
    comboLoading.value = false
  }
}

function handleComboMachineChange(val) {
  comboSelectedMachine.value = val
  fetchComboData(val)
}

function handleDisplayModeChange(val) {
  if (val === 'combo') {
    isComboMode.value = true
    fetchComboData()
  } else {
    isComboMode.value = false
    emitReload()
  }
}


watch(() => props.selectedArticle, () => {
  if (isComboMode.value) {
    fetchComboData()
  }
})

watch(() => props.indicator, (newVal) => {
  if (newVal) {
    localIndicator.value = newVal
    if (newVal === 'weight') {
      displayMode.value = 'raw'
    }
    if (isComboMode.value) {
      fetchComboData()
    } else {
      emitReload()
    }
  }
}, { immediate: true })

// 当全局 lotData 加载更新时，校验当前选中的工段
watch(() => props.lotData, (newVal) => {
  if (newVal && newVal.length > 0) {
    const availableComps = allWorkcenters.filter(c => newVal.some(d => !d.is_break && d.component === c))
    if (availableComps.length > 0 && (!activeComponent.value || !availableComps.includes(activeComponent.value))) {
      activeComponent.value = availableComps[0]
    }
  }
}, { immediate: true })

function handleIndicatorChange() {
  if (isComboMode.value) {
    fetchComboData()
  } else {
    emitReload()
  }
}

function handleTimeColChange() {
  if (isComboMode.value) {
    fetchComboData()
  } else {
    emitReload()
  }
}

function handleDateRangeChange() {
  if (isComboMode.value) {
    fetchComboData()
  } else {
    emitReload()
  }
}

function emitReload() {
  emit('reload', {
    indicator: localIndicator.value,
    dateRange: dateRange.value || [],
    component: activeComponent.value,
    time_col: selectedTimeCol.value
  })
}

const selectedBuildingMachine = ref(null)

function toggleBuildingMachineFilter(code) {
  if (selectedBuildingMachine.value === code) {
    selectedBuildingMachine.value = null
  } else {
    selectedBuildingMachine.value = code
  }
}

function selectComponent(comp) {
  isComboMode.value = false
  if (displayMode.value === 'combo') {
    displayMode.value = 'cpk'
  }
  activeComponent.value = comp
  selectedBuildingMachine.value = null // 切换工段时重置选中机台过滤器
  emitReload()
}

// 过滤当前选中工段的数据
const filteredLotData = computed(() => {
  if (!props.lotData) return []
  return props.lotData.filter(d => d.component === activeComponent.value)
})

// 当前工段的有效物料批次数量 (排除切断点)
const currentCompLotCount = computed(() => {
  if (!filteredLotData.value) return 0
  return filteredLotData.value.filter(d => !d.is_break).length
})

// 提取当前过滤工段涉及的所有唯一机台及其专属颜色
const uniqueMachines = computed(() => {
  if (!filteredLotData.value) return []
  const map = {}
  const result = []
  filteredLotData.value.forEach(d => {
    if (d.is_break) return
    const code = (d.machine || 'N/A').trim()
    if (code && !(code in map)) {
      const idx = Object.keys(map).length % machineColors.length
      const color = machineColors[idx]
      map[code] = color
      result.push({ code, color })
    }
  })
  return result
})

// 成型机台柔和配色板 (用于比例分段背景色)
const buildingMachineColors = [
  'rgba(59, 130, 246, 0.10)',   // Soft blue
  'rgba(16, 185, 129, 0.10)',   // Soft green
  'rgba(245, 158, 11, 0.10)',   // Soft orange
  'rgba(139, 92, 246, 0.10)',   // Soft purple
  'rgba(236, 72, 153, 0.10)',   // Soft pink
  'rgba(20, 184, 166, 0.10)',   // Soft teal
  'rgba(244, 63, 94, 0.10)',    // Soft rose
  'rgba(101, 163, 13, 0.10)'    // Soft lime
]

// 提取当前工段涉及的所有唯一成型机台及其专属柔和背景色
const uniqueBuildingMachines = computed(() => {
  if (!filteredLotData.value) return []
  const map = {}
  const result = []
  filteredLotData.value.forEach(d => {
    if (d.is_break || !d.building_machine || d.building_machine === 'N/A') return
    const code = d.building_machine.trim()
    if (code && !(code in map)) {
      const idx = Object.keys(map).length % buildingMachineColors.length
      const color = buildingMachineColors[idx]
      map[code] = color
      result.push({
        code,
        color: color.replace('0.10', '0.8'), // Border/legend color
        bgColor: color // BG color
      })
    }
  })
  return result
})

function getBuildingMachineColor(code) {
  const match = uniqueBuildingMachines.value.find(m => m.code === (code || '').trim())
  return match ? match.bgColor : 'transparent'
}

function getMachineColor(machineCode) {
  const match = uniqueMachines.value.find(m => m.code === (machineCode || '').trim())
  return match ? match.color : '#64748b'
}

// 点击箱形图/折线图节点时弹出 Barcode 弹窗
async function openBarcodeDialog(lotInfo) {
  if (!lotInfo || !lotInfo.lot) return
  dialogLotInfo.value = lotInfo
  barcodeDialogVisible.value = true
  dialogLoading.value = true
  dialogError.value = null
  dialogBarcodeList.value = []

  try {
    const res = await api.getLotBarcodeDetail({
      article10: props.selectedArticle || '',
      lot: lotInfo.lot,
      component: activeComponent.value || lotInfo.component || '',
      indicator: localIndicator.value
    })

    if (res.data && res.data.status === 'success') {
      const list = res.data.data || []
      // 默认按 Barcode 从小到大升序排列
      list.sort((a, b) => (a.barcode || '').localeCompare(b.barcode || '', undefined, { numeric: true }))
      dialogBarcodeList.value = list
    } else {
      dialogError.value = res.data?.message || '获取 Barcode 明细失败'
    }
  } catch (e) {
    dialogError.value = '加载 Barcode 测量数据异常'
  } finally {
    dialogLoading.value = false
  }
}

function onChartClick(params) {
  if (!params || !params.data) return
  const lotInfo = params.data.lotInfo
  if (lotInfo && !lotInfo.is_break && lotInfo.lot) {
    openBarcodeDialog(lotInfo)
  }
}

// 构建弹窗内的 Barcode 级折线图 Option (支持按 CT / TU 机台分组同机台同色隔断连线)
const barcodeChartOption = computed(() => {
  if (!dialogBarcodeList.value || dialogBarcodeList.value.length === 0) return {}

  const groupMode = barcodeGroupMode.value
  const targetUSL = props.uslValue || 100

  if (groupMode === 'none') {
    // ── 不分组连线 ─────────────────────────────────────────
    const list = [...dialogBarcodeList.value]
    list.sort((a, b) => (a.barcode || '').localeCompare(b.barcode || '', undefined, { numeric: true }))

    const mColor = getMachineColor(dialogLotInfo.value?.machine)
    const xCategories = list.map(b => b.barcode)
    const yValues = list.map(b => b.val)

    let yMin, yMax
    if (localIndicator.value === 'weight') {
      const nonZeroVals = yValues.filter(v => v > 1.0)
      const realMin = nonZeroVals.length > 0 ? Math.min(...nonZeroVals) : 10.0
      const realMax = nonZeroVals.length > 0 ? Math.max(...nonZeroVals) : 16.0
      const targetUSLVal = targetUSL && targetUSL > 1.0 ? targetUSL : realMax
      
      const minV = Math.min(realMin, targetUSLVal)
      const maxV = Math.max(realMax, targetUSLVal)
      yMin = Math.max(0.0, Math.floor((minV - 0.25) * 10) / 10)
      yMax = Math.ceil((maxV + 0.25) * 10) / 10
    } else {
      const minV = Math.min(...yValues)
      const maxV = Math.max(...yValues, targetUSL)
      yMin = Math.floor((minV - 2.0) / 5) * 5
      yMax = Math.ceil((maxV + 5.0) / 5) * 5
    }
    const zoomEnd = Math.min(100, Math.max(20, Math.round((28 / Math.max(1, yValues.length)) * 100)))

    return {
      backgroundColor: 'transparent',
      grid: { left: 55, right: 35, top: 45, bottom: 90 },
      tooltip: {
        trigger: 'axis',
        backgroundColor: '#ffffff',
        borderColor: '#cbd5e1',
        borderWidth: 1,
        padding: [8, 12],
        textStyle: { color: '#0f172a', fontSize: 12 },
        formatter(params) {
          if (!params || params.length === 0) return ''
          const p = params[0]
          return `
            <div style="font-weight:bold; font-size:12px; margin-bottom:4px; color:#0f172a;">
              Barcode: ${p.name}
            </div>
            <div style="display:flex; justify-content:space-between; gap:12px;">
              <span style="color:#64748b;">${localIndicator.value.toUpperCase()} 实际值:</span>
              <strong style="color:${mColor}">${p.value}</strong>
            </div>
          `
        }
      },
      dataZoom: [
        { type: 'slider', show: true, orient: 'horizontal', start: 0, end: zoomEnd, height: 20, bottom: 8, borderColor: '#cbd5e1', fillerColor: 'rgba(51, 65, 85, 0.15)', handleStyle: { color: '#334155' } },
        { type: 'inside', orient: 'horizontal' },
        { type: 'slider', show: true, orient: 'vertical', right: 10, borderColor: '#cbd5e1', fillerColor: 'rgba(51, 65, 85, 0.15)', handleStyle: { color: '#334155' } },
        { type: 'inside', orient: 'vertical' }
      ],
      xAxis: {
        type: 'category',
        name: 'barcode',
        nameLocation: 'middle',
        nameGap: 65,
        nameTextStyle: { color: '#475569', fontSize: 12, fontWeight: 'bold' },
        data: xCategories,
        axisLine: { lineStyle: { color: '#cbd5e1' } },
        axisTick: { alignWithLabel: true },
        axisLabel: { fontSize: 10, color: '#334155', interval: 0, rotate: 90 }
      },
      yAxis: {
        type: 'value',
        name: `${localIndicator.value.toUpperCase()} 实际测量值`,
        nameTextStyle: { color: '#64748b', fontSize: 11 },
        min: yMin,
        max: yMax,
        splitLine: { lineStyle: { color: '#f1f5f9', type: 'dashed' } },
        axisLabel: { color: '#64748b', fontSize: 11 }
      },
      series: [
        {
          name: `${dialogLotInfo.value?.lot} 实际测量值`,
          type: 'line',
          smooth: 0.2,
          symbol: 'circle',
          symbolSize: 7,
          lineStyle: { color: mColor, width: 2.2 },
          itemStyle: { color: mColor, borderColor: '#ffffff', borderWidth: 1 },
          label: { show: true, position: 'top', fontSize: 10, color: '#334155', formatter: '{c}' },
          markLine: {
            symbol: 'none',
            data: [
              {
                yAxis: targetUSL,
                name: '规格上限 USL',
                lineStyle: { color: '#ef4444', type: 'dashed', width: 1.5 },
                label: { formatter: `USL 上限 (${targetUSL})`, position: 'end', color: '#ef4444', fontSize: 10 }
              }
            ]
          },
          data: yValues
        }
      ]
    }
  } else {
    // ── 按 CT 硫化或 TU 检测机台分组连线 (同机台同色，异机台隔断) ──────────
    const keyField = groupMode === 'ct' ? 'ct_workcenter' : 'tu_workcenter'
    const groupName = groupMode === 'ct' ? 'CT 硫化机台' : 'TU 检测机台'

    // 按 机台, Barcode 二重排序
    const list = [...dialogBarcodeList.value]
    list.sort((a, b) => {
      const mA = a[keyField] || 'N/A'
      const mB = b[keyField] || 'N/A'
      if (mA !== mB) return mA.localeCompare(mB)
      return (a.barcode || '').localeCompare(b.barcode || '', undefined, { numeric: true })
    })

    // 插入隔断点并映射数据
    const processedList = []
    list.forEach((item, idx) => {
      if (idx > 0 && item[keyField] !== list[idx - 1][keyField]) {
        processedList.push({
          barcode: '',
          val: null,
          is_break: true,
          [keyField]: list[idx - 1][keyField]
        })
      }
      processedList.push({ ...item, is_break: false })
    })

    const xCategories = processedList.map(b => (b.is_break ? '' : b.barcode))
    const validVals = processedList.filter(b => !b.is_break && b.val !== null).map(b => b.val)

    const minV = validVals.length > 0 ? Math.min(...validVals) : 0
    const maxV = validVals.length > 0 ? Math.max(...validVals, targetUSL) : targetUSL
    let yMin, yMax
    if (localIndicator.value === 'weight') {
      yMin = Math.max(0.0, Math.floor((minV - 0.2) * 10) / 10)
      yMax = Math.ceil((maxV + 0.2) * 10) / 10
    } else {
      yMin = Math.max(0, Math.floor((minV - 2.0) / 5) * 5)
      yMax = Math.ceil((maxV + 5.0) / 5) * 5
    }
    const zoomEnd = Math.min(100, Math.max(20, Math.round((28 / Math.max(1, processedList.length)) * 100)))

    // 提取唯一机台并关联专属颜色
    const subUniqueMachines = []
    const subMap = {}
    processedList.forEach(b => {
      if (b.is_break) return
      const code = (b[keyField] || 'N/A').trim()
      if (code && !(code in subMap)) {
        const idx = Object.keys(subMap).length % machineColors.length
        const color = machineColors[idx]
        subMap[code] = color
        subUniqueMachines.push({ code, color })
      }
    })

    function getSubColor(code) {
      const match = subUniqueMachines.find(m => m.code === (code || '').trim())
      return match ? match.color : '#64748b'
    }

    const seriesList = []
    seriesList.push({
      name: '规格上限 USL',
      type: 'line',
      data: [],
      markLine: {
        symbol: 'none',
        data: [
          {
            yAxis: targetUSL,
            name: '规格上限 USL',
            lineStyle: { color: '#ef4444', type: 'dashed', width: 1.5 },
            label: { formatter: `USL 上限 (${targetUSL})`, position: 'end', color: '#ef4444', fontSize: 10 }
          }
        ]
      }
    })

    subUniqueMachines.forEach(mInfo => {
      const mCode = mInfo.code
      const mColor = mInfo.color

      const mData = processedList.map(b => {
        if (!b.is_break && (b[keyField] || '').trim() === mCode) {
          return {
            value: b.val,
            barcodeInfo: b
          }
        }
        return null
      })

      seriesList.push({
        name: `${mCode}`,
        type: 'line',
        smooth: 0.2,
        connectNulls: false,
        symbol: 'circle',
        symbolSize: 7,
        lineStyle: { color: mColor, width: 2.2 },
        itemStyle: { color: mColor, borderColor: '#ffffff', borderWidth: 1 },
        label: { show: true, position: 'top', fontSize: 10, color: '#334155', formatter: '{c}' },
        data: mData
      })
    })

    return {
      backgroundColor: 'transparent',
      grid: { left: 55, right: 35, top: 45, bottom: 95 },
      legend: {
        show: true,
        top: 5,
        right: 20,
        textStyle: { color: '#475569', fontSize: 11 }
      },
      tooltip: {
        trigger: 'axis',
        backgroundColor: '#ffffff',
        borderColor: '#cbd5e1',
        borderWidth: 1,
        padding: [8, 12],
        textStyle: { color: '#0f172a', fontSize: 12 },
        formatter(params) {
          if (!params || params.length === 0) return ''
          const validP = params.find(p => p.data && p.data.barcodeInfo)
          if (!validP) return ''
          const bInfo = validP.data.barcodeInfo
          const mColor = getSubColor(bInfo[keyField])
          return `
            <div style="font-weight:bold; font-size:12px; margin-bottom:4px; color:#0f172a;">
              Barcode: ${bInfo.barcode}
            </div>
            <div style="display:flex; justify-content:space-between; gap:12px; margin-bottom:2px;">
              <span style="color:#64748b;">${groupName}:</span>
              <strong style="color:${mColor}">● ${bInfo[keyField]}</strong>
            </div>
            <div style="display:flex; justify-content:space-between; gap:12px;">
              <span style="color:#64748b;">${localIndicator.value.toUpperCase()} 实际值:</span>
              <strong style="color:${mColor}">${bInfo.val}</strong>
            </div>
          `
        }
      },
      dataZoom: [
        { type: 'slider', show: true, orient: 'horizontal', start: 0, end: zoomEnd, height: 20, bottom: 8, borderColor: '#cbd5e1', fillerColor: 'rgba(51, 65, 85, 0.15)', handleStyle: { color: '#334155' } },
        { type: 'inside', orient: 'horizontal' },
        { type: 'slider', show: true, orient: 'vertical', right: 10, borderColor: '#cbd5e1', fillerColor: 'rgba(51, 65, 85, 0.15)', handleStyle: { color: '#334155' } },
        { type: 'inside', orient: 'vertical' }
      ],
      xAxis: {
        type: 'category',
        name: 'barcode',
        nameLocation: 'middle',
        nameGap: 65,
        nameTextStyle: { color: '#475569', fontSize: 12, fontWeight: 'bold' },
        data: xCategories,
        axisLine: { lineStyle: { color: '#cbd5e1' } },
        axisTick: { alignWithLabel: true },
        axisLabel: { fontSize: 10, color: '#334155', interval: 0, rotate: 90 }
      },
      yAxis: {
        type: 'value',
        name: `${localIndicator.value.toUpperCase()} 实际测量值`,
        nameTextStyle: { color: '#64748b', fontSize: 11 },
        min: yMin,
        max: yMax,
        splitLine: { lineStyle: { color: '#f1f5f9', type: 'dashed' } },
        axisLabel: { color: '#64748b', fontSize: 11 }
      },
      series: seriesList
    }
  }
})

const option = computed(() => {
  if (!filteredLotData.value || filteredLotData.value.length === 0) return {}

  const currentData = filteredLotData.value
  const isBoxplotMode = displayMode.value === 'raw'

  // 1. 过滤出真正的有效物料数据
  const validLots = currentData.filter(d => !d.is_break && d.boxplot)
  
  // 2. X 轴标签 - 只保留物料批次 (Lot)，不用显示规格/机台信息
  const xCategories = isBoxplotMode
    ? validLots.map(d => d.lot)
    : currentData.map(d => (d.is_break ? '' : d.lot))

  // 3. 构建比例背景渐变色块 (markAreaData)
  const markAreaData = []
  const dataListForMarkArea = isBoxplotMode ? validLots : currentData

  for (let i = 0; i < dataListForMarkArea.length; i++) {
    const d = dataListForMarkArea[i]
    if (d.is_break || !d.gt_distribution || Object.keys(d.gt_distribution).length === 0) {
      continue
    }

    const dist = d.gt_distribution
    const sortedEntries = Object.entries(dist).sort((a, b) => b[1] - a[1]) // 按比例从大到小排序

    const stops = []
    let accum = 0
    sortedEntries.forEach(([machine, pct]) => {
      const color = getBuildingMachineColor(machine)
      stops.push({ offset: accum, color: color })
      accum += pct
      const clampedAccum = Math.min(1.0, accum)
      stops.push({ offset: clampedAccum, color: color })
    })

    // 如果选中了某成型机台，对于不含该机台分流的批次进行背景置灰弱化
    let finalItemStyle = {
      color: {
        type: 'linear',
        x: 0,
        y: 1,  // 从下往上渲染
        x2: 0,
        y2: 0,
        colorStops: stops
      }
    }

    if (selectedBuildingMachine.value) {
      const hasSelected = dist[selectedBuildingMachine.value] !== undefined && dist[selectedBuildingMachine.value] > 0
      if (!hasSelected) {
        const dimmedStops = stops.map(s => ({
          offset: s.offset,
          color: 'rgba(241, 245, 249, 0.01)' // 极淡底色
        }))
        finalItemStyle = {
          color: {
            type: 'linear',
            x: 0,
            y: 1,
            x2: 0,
            y2: 0,
            colorStops: dimmedStops
          }
        }
      }
    }

    markAreaData.push([
      {
        xAxis: i - 0.5,
        itemStyle: finalItemStyle
      },
      {
        xAxis: i + 0.5
      }
    ])
  }

  // 4. 动态自适应计算 Y 轴刻度范围
  let yMin = 0
  let yMax = 3.0

  if (isBoxplotMode) {
    const validRawVals = validLots
      .flatMap(d => d.boxplot)
      .filter(v => v !== null && v !== undefined && !isNaN(v))

    if (validRawVals.length > 0) {
      if (localIndicator.value === 'weight') {
        const nonZeroVals = validRawVals.filter(v => v > 1.0)
        const realMin = nonZeroVals.length > 0 ? Math.min(...nonZeroVals) : 10.0
        const realMax = nonZeroVals.length > 0 ? Math.max(...nonZeroVals) : 16.0
        const targetUSL = props.uslValue && props.uslValue > 1.0 ? props.uslValue : realMax
        
        const minVal = Math.min(realMin, targetUSL)
        const maxVal = Math.max(realMax, targetUSL)
        yMin = Math.max(0.0, Math.floor((minVal - 0.25) * 10) / 10)
        yMax = Math.ceil((maxVal + 0.25) * 10) / 10
      } else {
        const targetUSL = props.uslValue || 100
        const minVal = Math.min(...validRawVals)
        const maxVal = Math.max(...validRawVals, targetUSL)
        yMin = Math.floor((minVal - 2.0) / 5) * 5
        yMax = Math.ceil((maxVal + 5.0) / 5) * 5
      }
    } else {
      yMin = 0
      yMax = 120
    }
  } else {
    const validCpkValues = currentData
      .filter(d => !d.is_break)
      .flatMap(d => [d.spec_cpk, d.multi_cpk])
      .filter(v => v !== null && v !== undefined && !isNaN(v))

    if (validCpkValues.length > 0) {
      const minVal = Math.min(...validCpkValues, 1.33)
      const maxVal = Math.max(...validCpkValues, 1.33)
      yMin = Math.max(0, Math.floor((minVal - 0.1) * 10) / 10)
      yMax = Math.min(5.0, Math.ceil((maxVal + 0.15) * 10) / 10)
    }
  }

  // 5. 构建 Series List
  const seriesList = []

  if (isBoxplotMode) {
    // ── 箱线图实际值模式 ──────────────────────────────────────────
    const mlEntries = [
      {
        yAxis: props.uslValue || 100,
        name: '规格上限 USL',
        lineStyle: { color: '#ef4444', type: 'dashed', width: 1.5 },
        label: { formatter: `USL 上限 (${props.uslValue || 100})`, position: 'end', color: '#ef4444', fontSize: 10 }
      }
    ]
    if (props.lslValue !== null && props.lslValue !== undefined) {
      mlEntries.push({
        yAxis: props.lslValue,
        name: '规格下限 LSL',
        lineStyle: { color: '#ef4444', type: 'dashed', width: 1.5 },
        label: { formatter: `LSL 下限 (${props.lslValue})`, position: 'end', color: '#ef4444', fontSize: 10 }
      })
    }

    seriesList.push({
      name: '规格上限 USL',
      type: 'line',
      data: [],
      markLine: {
        symbol: 'none',
        data: mlEntries
      }
    })

    // 1. 单条 Boxplot Series 填充所有有效物料 (保留矩形箱体，中间中线为均值 Mean)
    const boxData = validLots.map(d => {
      const mColor = getMachineColor(d.machine)
      
      let isDimmed = false
      if (selectedBuildingMachine.value) {
        const dist = d.gt_distribution || {}
        const hasSelected = dist[selectedBuildingMachine.value] !== undefined && dist[selectedBuildingMachine.value] > 0
        if (!hasSelected) {
          isDimmed = true
        }
      }

      return {
        value: d.boxplot, // [min_v, q1_v, mean_v, q3_v, max_v]
        lotInfo: d,
        itemStyle: {
          color: isDimmed ? 'rgba(241, 245, 249, 0.03)' : hexToRgba(mColor, 0.45),
          borderColor: isDimmed ? 'rgba(203, 213, 225, 0.2)' : mColor,
          borderWidth: isDimmed ? 0.5 : 2.0
        }
      }
    })

    seriesList.push({
      name: '实际测量值箱线图',
      type: 'boxplot',
      boxWidth: [8, 30],
      z: 3,
      data: boxData,
      markArea: {
        silent: true,
        data: markAreaData
      }
    })

    // 2. 增加按机台分组的【均值连接折线】(Mean Line)
    uniqueMachines.value.forEach(mInfo => {
      const mCode = mInfo.code
      const mColor = mInfo.color

      const meanData = validLots.map(d => {
        if (d.machine === mCode) {
          const val = d.mean_v !== undefined && d.mean_v !== null ? d.mean_v : (d.boxplot ? d.boxplot[2] : null)
          return {
            value: val,
            lotInfo: d
          }
        }
          return null
      })

      seriesList.push({
        name: `${mCode} 均值连线`,
        type: 'line',
        smooth: 0.2,
        connectNulls: false,
        symbol: 'circle',
        symbolSize: 5,
        z: 4,
        lineStyle: { color: mColor, width: 1.8 },
        itemStyle: { color: mColor, borderColor: '#ffffff', borderWidth: 1 },
        data: meanData
      })
    })

  } else {
    // ── CPK 模式 (按机台生成专属折线) ──────────────────────────────
    seriesList.push({
      name: 'CPK 预警线',
      type: 'line',
      data: [],
      markLine: {
        symbol: 'none',
        data: [
          {
            yAxis: 1.33,
            name: 'CPK 预警线',
            lineStyle: { color: '#ef4444', type: 'dashed', width: 1.5 },
            label: { formatter: 'CPK 预警线 (1.33)', position: 'end', color: '#ef4444', fontSize: 10 }
          }
        ]
      }
    })

    uniqueMachines.value.forEach((mInfo, idx) => {
      const mCode = mInfo.code
      const mColor = mInfo.color

      const specData = []
      const multiData = []

      currentData.forEach(d => {
        let isDimmed = false
        if (selectedBuildingMachine.value && !d.is_break) {
          const dist = d.gt_distribution || {}
          const hasSelected = dist[selectedBuildingMachine.value] !== undefined && dist[selectedBuildingMachine.value] > 0
          if (!hasSelected) {
            isDimmed = true
          }
        }

        if (!d.is_break && d.machine === mCode) {
          specData.push({
            value: d.spec_cpk,
            lotInfo: d,
            symbolSize: isDimmed ? 3 : 9,
            itemStyle: {
              opacity: isDimmed ? 0.15 : 1.0
            }
          })
          multiData.push({
            value: d.multi_cpk,
            lotInfo: d,
            symbolSize: isDimmed ? 3 : 9,
            itemStyle: {
              opacity: isDimmed ? 0.15 : 1.0
            }
          })
        } else {
          specData.push(null)
          multiData.push(null)
        }
      })

      const specSeries = {
        name: `${mCode} 单规格`,
        type: 'line',
        smooth: 0.25,
        connectNulls: false,
        symbol: 'circle',
        symbolSize: 9,
        lineStyle: { color: mColor, width: 2.5 },
        itemStyle: { color: mColor, borderColor: mColor },
        data: specData
      }

      if (idx === 0) {
        specSeries.markArea = {
          silent: true,
          data: markAreaData
        }
      }

      seriesList.push(specSeries)

      seriesList.push({
        name: `${mCode} 其它规格加权`,
        type: 'line',
        smooth: 0.25,
        connectNulls: false,
        symbol: 'diamond',
        symbolSize: 9,
        lineStyle: { color: mColor, width: 2.0, type: 'dashed', opacity: 0.65 },
        itemStyle: { color: hexToRgba(mColor, 0.65), borderColor: mColor },
        data: multiData
      })
    })
  }

  const totalCount = isBoxplotMode ? validLots.length : currentData.length
  const zoomEnd = Math.min(100, Math.max(25, Math.round((22 / Math.max(1, totalCount)) * 100)))

  return {
    backgroundColor: 'transparent',
    grid: {
      left: 50,
      right: 30,
      top: 35,
      bottom: 95
    },
    tooltip: {
      trigger: 'axis',
      backgroundColor: '#ffffff',
      borderColor: '#e2e8f0',
      borderWidth: 1,
      padding: [10, 14],
      textStyle: { color: '#1e293b', fontSize: 12 },
      formatter(params) {
        if (!params || params.length === 0) return ''
        const validParam = params.find(p => p.data && p.data.lotInfo)
        if (!validParam) return ''

        const lotInfo = validParam.data.lotInfo
        if (!lotInfo || lotInfo.is_break) return ''

        const mColor = getMachineColor(lotInfo.machine)

        let gtDistStr = 'N/A'
        if (lotInfo.gt_distribution && Object.keys(lotInfo.gt_distribution).length > 0) {
          gtDistStr = Object.entries(lotInfo.gt_distribution)
            .sort((a, b) => b[1] - a[1])
            .map(([mac, pct]) => `${mac} (${Math.round(pct * 100)}%)`)
            .join(' | ')
        }

        if (isBoxplotMode) {
          const bp = lotInfo.boxplot || [0, 0, 0, 0, 0]
          const meanV = lotInfo.mean_v !== undefined && lotInfo.mean_v !== null ? lotInfo.mean_v : bp[2]
          return `
            <div style="font-weight:bold; font-size:13px; margin-bottom:6px; color:#0f172a; border-bottom:1px solid #f1f5f9; padding-bottom:4px;">
              【${lotInfo.component}】批次: ${lotInfo.lot}
            </div>
            <div style="display:flex; justify-content:space-between; gap:16px; margin-bottom:3px;">
              <span style="color:#64748b;">加工机台:</span>
              <strong style="color:${mColor}">● ${lotInfo.machine}</strong>
            </div>
            <div style="display:flex; justify-content:space-between; gap:16px; margin-bottom:3px;">
              <span style="color:#64748b;">成型机台:</span>
              <strong>${gtDistStr}</strong>
            </div>
            <div style="display:flex; justify-content:space-between; gap:16px; margin-bottom:2px;">
              <span style="color:#64748b;">样本条数:</span>
              <strong>N = ${lotInfo.spec_n}</strong>
            </div>
            <div style="display:flex; justify-content:space-between; gap:16px; margin-bottom:2px;">
              <span style="color:#64748b;">最大值 (Max):</span>
              <strong style="color:#dc2626">${bp[4]}</strong>
            </div>
            <div style="display:flex; justify-content:space-between; gap:16px; margin-bottom:2px;">
              <span style="color:#64748b;">均值 (Mean):</span>
              <strong style="color:#2563eb">${meanV}</strong>
            </div>
            <div style="display:flex; justify-content:space-between; gap:16px;">
              <span style="color:#64748b;">最小值 (Min):</span>
              <strong style="color:#059669">${bp[0]}</strong>
            </div>
            <div style="margin-top:6px; font-size:10px; color:#94a3b8; text-align:right; border-top:1px dashed #e2e8f0; padding-top:4px;">
              点击图形查看 Barcode 级明细
            </div>
          `
        } else {
          return `
            <div style="font-weight:bold; font-size:13px; margin-bottom:6px; color:#0f172a; border-bottom:1px solid #f1f5f9; padding-bottom:4px;">
              【${lotInfo.component}】批次: ${lotInfo.lot}
            </div>
            <div style="display:flex; justify-content:space-between; gap:16px; margin-bottom:3px;">
              <span style="color:#64748b;">加工机台:</span>
              <strong style="color:${mColor}">● ${lotInfo.machine}</strong>
            </div>
            <div style="display:flex; justify-content:space-between; gap:16px; margin-bottom:3px;">
              <span style="color:#64748b;">成型机台:</span>
              <strong>${gtDistStr}</strong>
            </div>
            <div style="display:flex; justify-content:space-between; gap:16px; margin-bottom:3px;">
              <span style="color:#64748b;">单规格 CPK (${props.selectedArticle || '当前'}):</span>
              <strong style="color:${lotInfo.spec_cpk < 1.33 ? '#dc2626' : '#16a34a'}">${lotInfo.spec_cpk} (N=${lotInfo.spec_n})</strong>
            </div>
            <div style="display:flex; justify-content:space-between; gap:16px;">
              <span style="color:#64748b;">其它规格加权 CPK (已排除单规格):</span>
              <strong style="color:${lotInfo.multi_cpk < 1.33 ? '#dc2626' : '#d97706'}">${lotInfo.multi_cpk} (N=${lotInfo.multi_n})</strong>
            </div>
            <div style="margin-top:6px; font-size:10px; color:#94a3b8; text-align:right; border-top:1px dashed #e2e8f0; padding-top:4px;">
              点击图形查看 Barcode 级明细
            </div>
          `
        }
      }
    },
    dataZoom: [
      {
        // 隐藏底部横向滑块：百余个批次全展开时滑块只会挤压绘图区，缩放改由滚轮/拖拽触发
        type: 'slider',
        show: false,
        orient: 'horizontal',
        start: 0,
        end: zoomEnd
      },
      { type: 'inside', orient: 'horizontal' },
      {
        type: 'slider',
        show: true,
        orient: 'vertical',
        right: 40,
        borderColor: '#cbd5e1',
        fillerColor: 'rgba(51, 65, 85, 0.15)',
        handleStyle: { color: '#334155' }
      },
      { type: 'inside', orient: 'vertical' }
    ],
    xAxis: {
      type: 'category',
      data: xCategories,
      axisLine: { lineStyle: { color: '#cbd5e1' } },
      axisTick: { alignWithLabel: true },
      axisLabel: {
        fontSize: 10,
        color: '#334155',
        interval: 'auto',
        hideOverlap: true,
        rotate: 45,
        lineHeight: 13
      }
    },
    yAxis: {
      type: 'value',
      name: isBoxplotMode ? (localIndicator.value === 'weight' ? '实测胎重 (kg)' : `测量实际值 (${(localIndicator.value || 'rfpp').toUpperCase()})`) : 'CPK 指数',
      nameTextStyle: { color: '#64748b', fontSize: 11 },
      min: yMin,
      max: yMax,
      splitLine: { lineStyle: { color: '#f1f5f9', type: 'dashed' } },
      axisLabel: { color: '#64748b', fontSize: 11 }
    },
    series: seriesList
  }
})

// ── 带束层组合分析 Option 构建 (时序 Barcode、实测值折线、超限预警红点、上下分层物料色块) ──
const comboSummary = computed(() => {
  return comboData.value?.summary || {
    total_count: 0,
    out_of_spec_count: 0,
    out_of_spec_rate: '0.00%',
    b1_out_count: 0,
    b2_out_count: 0,
    b1_lot_count: 0,
    b2_lot_count: 0,
    mean_val: 0,
    usl: props.uslValue,
    lsl: props.lslValue
  }
})

// ── 异常率最高优先排序的带束层物料列表 (异常率最高 -> 异常数最多 -> 产量最大) ──
const sortedB1Materials = computed(() => {
  const list = [...(comboData.value?.b1_materials || [])]
  return list.sort((a, b) => {
    const rateA = a.out_rate ?? (a.count > 0 ? ((a.out_count || 0) / a.count) * 100 : 0)
    const rateB = b.out_rate ?? (b.count > 0 ? ((b.out_count || 0) / b.count) * 100 : 0)
    if (Math.abs(rateB - rateA) > 0.001) return rateB - rateA
    if ((b.out_count || 0) !== (a.out_count || 0)) return (b.out_count || 0) - (a.out_count || 0)
    return (b.count || 0) - (a.count || 0)
  })
})

const sortedB2Materials = computed(() => {
  const list = [...(comboData.value?.b2_materials || [])]
  return list.sort((a, b) => {
    const rateA = a.out_rate ?? (a.count > 0 ? ((a.out_count || 0) / a.count) * 100 : 0)
    const rateB = b.out_rate ?? (b.count > 0 ? ((b.out_count || 0) / b.count) * 100 : 0)
    if (Math.abs(rateB - rateA) > 0.001) return rateB - rateA
    if ((b.out_count || 0) !== (a.out_count || 0)) return (b.out_count || 0) - (a.out_count || 0)
    return (b.count || 0) - (a.count || 0)
  })
})

const displayB1Materials = computed(() => sortedB1Materials.value.slice(0, 4))
const remainingB1Materials = computed(() => sortedB1Materials.value.slice(4))

const displayB2Materials = computed(() => sortedB2Materials.value.slice(0, 4))
const remainingB2Materials = computed(() => sortedB2Materials.value.slice(4))

const comboOption = computed(() => {
  if (!comboData.value || !comboData.value.barcodes || comboData.value.barcodes.length === 0) {
    return {}
  }
  const data = comboData.value
  const barcodes = data.barcodes
  const values = data.values
  const details = data.details || []
  const usl = data.summary?.usl ?? props.uslValue
  const lsl = data.summary?.lsl ?? props.lslValue

  // 计算 Y 轴范围自适应与上下分层中分线
  let minVal = Math.min(...values)
  let maxVal = Math.max(...values)
  if (usl !== null && usl !== undefined) {
    maxVal = Math.max(maxVal, usl)
  }
  if (lsl !== null && lsl !== undefined) {
    minVal = Math.min(minVal, lsl)
  }

  const rangeSpan = maxVal - minVal || 1.0
  const padding = rangeSpan * 0.18
  const yMin = Math.floor((minVal - padding) * 10) / 10
  const yMax = Math.ceil((maxVal + padding) * 10) / 10
  const yMid = Math.round(((yMin + yMax) / 2) * 100) / 100

  // 1. 构建 MarkArea 背景双层色块 (上半区: 带束1，下半区: 带束2)
  const markAreaData = []
  const hovered = hoveredMaterial.value

  const checkIsTarget = (seg) => {
    if (!hovered) return false
    const h = String(hovered).trim()
    const segKey = seg.mat_key || (seg.lot && seg.lot.length >= 5 ? seg.lot.slice(-5) : seg.lot)
    return segKey === h || (seg.lot && seg.lot.endsWith(h)) || seg.lot === h
  }

  // 带束1 色块 (上半区: yMid ~ yMax，采用 2px 纯白物理间隔与纯灰无底色物料号文字)
  ;(data.b1_segments || []).forEach(seg => {
    const isTarget = checkIsTarget(seg)
    let segColor = seg.color || 'rgba(37, 99, 235, 0.14)'
    let borderColor = '#ffffff'
    let borderWidth = 2
    let textColor = '#64748b'
    let textFontWeight = 600

    if (hovered) {
      if (isTarget) {
        segColor = segColor.replace(/[\d.]+\)$/, '0.38)') // 悬浮物料号全区高亮 (后五位相同则上下同时高亮)
        borderColor = '#2563eb'
        borderWidth = 2.5
        textColor = '#0f172a'
        textFontWeight = 700
      } else {
        segColor = segColor.replace(/[\d.]+\)$/, '0.03)') // 其余物料淡化
        textColor = 'rgba(100, 116, 139, 0.30)'
      }
    }

    markAreaData.push([
      {
        name: seg.material,
        xAxis: seg.start_idx - 0.46,
        yAxis: yMid,
        itemStyle: {
          color: segColor,
          borderColor: borderColor,
          borderWidth: borderWidth
        },
        label: {
          show: seg.count >= 6 || isTarget,
          position: 'insideTop',
          offset: [0, 8],
          formatter: seg.lot, // 纯物料号
          fontSize: 10,
          fontWeight: textFontWeight,
          color: textColor, // 纯灰色文字，无背景框
          backgroundColor: 'transparent',
          borderWidth: 0,
          padding: 0
        }
      },
      {
        xAxis: seg.end_idx + 0.46,
        yAxis: yMax
      }
    ])
  })

  // 带束2 色块 (下半区: yMin ~ yMid，采用 2px 纯白物理间隔与纯灰无底色物料号文字)
  ;(data.b2_segments || []).forEach(seg => {
    const isTarget = checkIsTarget(seg)
    let segColor = seg.color || 'rgba(37, 99, 235, 0.14)'
    let borderColor = '#ffffff'
    let borderWidth = 2
    let textColor = '#64748b'
    let textFontWeight = 600

    if (hovered) {
      if (isTarget) {
        segColor = segColor.replace(/[\d.]+\)$/, '0.38)') // 悬浮物料号全区高亮 (后五位相同则上下同时高亮)
        borderColor = '#2563eb'
        borderWidth = 2.5
        textColor = '#0f172a'
        textFontWeight = 700
      } else {
        segColor = segColor.replace(/[\d.]+\)$/, '0.03)') // 其余物料淡化
        textColor = 'rgba(100, 116, 139, 0.30)'
      }
    }

    markAreaData.push([
      {
        name: seg.material,
        xAxis: seg.start_idx - 0.46,
        yAxis: yMin,
        itemStyle: {
          color: segColor,
          borderColor: borderColor,
          borderWidth: borderWidth
        },
        label: {
          show: seg.count >= 6 || isTarget,
          position: 'insideBottom',
          offset: [0, -8],
          formatter: seg.lot, // 纯物料号，不带带束1/2前缀
          fontSize: 10,
          fontWeight: textFontWeight,
          color: textColor, // 纯灰色文字，无背景框
          backgroundColor: 'transparent',
          borderWidth: 0,
          padding: 0
        }
      },
      {
        xAxis: seg.end_idx + 0.46,
        yAxis: yMid
      }
    ])
  })

  // 标线: USL / LSL 与上下区分割线 (弱化分割线避免抢折线焦点)
  const markLineData = [
    {
      yAxis: yMid,
      lineStyle: { color: '#cbd5e1', type: 'dashed', width: 1.2 },
      label: {
        show: true,
        position: 'start',
        formatter: '▲ 带束层1 (上半区)  |  ▼ 带束层2 (下半区)',
        color: '#64748b',
        fontSize: 10,
        backgroundColor: 'rgba(248, 250, 252, 0.95)',
        borderColor: '#e2e8f0',
        borderWidth: 1,
        padding: [2, 6],
        borderRadius: 3
      }
    }
  ]
  if (usl !== null && usl !== undefined) {
    markLineData.push({
      yAxis: usl,
      lineStyle: { color: '#ef4444', type: 'dashed', width: 2 },
      label: {
        show: true,
        position: 'end',
        formatter: `USL: ${usl}`,
        color: '#ef4444',
        fontWeight: 'bold',
        fontSize: 11
      }
    })
  }
  if (lsl !== null && lsl !== undefined) {
    markLineData.push({
      yAxis: lsl,
      lineStyle: { color: '#ef4444', type: 'dashed', width: 2 },
      label: {
        show: true,
        position: 'end',
        formatter: `LSL: ${lsl}`,
        color: '#ef4444',
        fontWeight: 'bold',
        fontSize: 11
      }
    })
  }

  // 2. 超限红点散点系列数据
  const outOfSpecPoints = []
  details.forEach((d, i) => {
    if (d.is_out_of_spec) {
      outOfSpecPoints.push([d.barcode, d.value])
    }
  })

  return {
    backgroundColor: 'transparent',
    grid: { left: 55, right: 35, top: 40, bottom: 85 },
    tooltip: {
      trigger: 'axis',
      backgroundColor: 'rgba(255, 255, 255, 0.98)',
      borderColor: '#e2e8f0',
      borderWidth: 1,
      padding: [10, 14],
      textStyle: { color: '#0f172a', fontSize: 12 },
      formatter(params) {
        if (!params || params.length === 0) return ''
        const idx = params[0].dataIndex
        const detail = details[idx]
        if (!detail) return ''

        const isOut = detail.is_out_of_spec
        const outBadge = isOut 
          ? `<span style="background:#fee2e2; color:#ef4444; border:1px solid #fca5a5; font-size:11px; padding:1px 6px; border-radius:4px; font-weight:bold; margin-left:8px;">⚠️ 超出上限预警</span>`
          : `<span style="background:#dcfce7; color:#15803d; border:1px solid #86efac; font-size:11px; padding:1px 6px; border-radius:4px; font-weight:bold; margin-left:8px;">合格</span>`

        return `
          <div style="font-weight:bold; font-size:13px; margin-bottom:6px; color:#0f172a; display:flex; align-items:center;">
            <span>条码: ${detail.barcode}</span>
            ${outBadge}
          </div>
          <div style="font-size:11px; color:#64748b; margin-bottom:8px;">
            成型时间: ${detail.gt_time} (成型机台: <strong>${detail.gt_machine}</strong>)
          </div>
          <div style="background:#f8fafc; padding:6px 10px; border-radius:4px; border:1px solid #f1f5f9; margin-bottom:8px; display:flex; justify-content:space-between; align-items:center;">
            <span style="color:#475569;">${data.summary?.indicator_label || '指标'} 实测值:</span>
            <strong style="color:${isOut ? '#ef4444' : '#2563eb'}; font-size:14px;">${detail.value} ${data.summary?.unit || ''}</strong>
          </div>
          <div style="font-size:11px; border-top:1px dashed #e2e8f0; padding-top:6px; display:flex; flex-direction:column; gap:4px;">
            <div style="display:flex; justify-content:space-between; gap: 8px;">
              <span style="color:#1d4ed8; font-weight:600;">【带束层 1 物料号】:</span>
              <span><strong>${detail.b1_lot}</strong> (工段机台: ${detail.b1_machine})</span>
            </div>
            <div style="display:flex; justify-content:space-between; gap: 8px;">
              <span style="color:#7e22ce; font-weight:600;">【带束层 2 物料号】:</span>
              <span><strong>${detail.b2_lot}</strong> (工段机台: ${detail.b2_machine})</span>
            </div>
          </div>
        `
      }
    },
    dataZoom: [
      {
        // 同上：隐藏横向滑块，保留内部缩放能力
        type: 'slider',
        show: false,
        orient: 'horizontal',
        start: comboZoomState.value.start ?? 0,
        end: comboZoomState.value.end ?? 100
      },
      {
        type: 'inside',
        orient: 'horizontal',
        start: comboZoomState.value.start ?? 0,
        end: comboZoomState.value.end ?? 100
      }
    ],
    xAxis: {
      type: 'category',
      data: barcodes,
      axisLine: { lineStyle: { color: '#cbd5e1' } },
      axisTick: { alignWithLabel: true },
      axisLabel: {
        fontSize: 10,
        color: '#334155',
        interval: 'auto',
        hideOverlap: true,
        rotate: 45
      }
    },
    yAxis: {
      type: 'value',
      name: `${data.summary?.indicator_label || '实际值'} (${data.summary?.unit || ''})`,
      nameTextStyle: { color: '#64748b', fontSize: 11 },
      min: yMin,
      max: yMax,
      splitLine: { lineStyle: { color: '#f1f5f9', type: 'dashed' } },
      axisLabel: { color: '#64748b', fontSize: 11 }
    },
    series: [
      // 1. 实际测量值折线
      {
        name: '测量实际值',
        type: 'line',
        smooth: false,
        showSymbol: true,
        symbol: 'circle',
        symbolSize: 4,
        lineStyle: { color: '#4f46e5', width: 1.8 },
        itemStyle: { color: '#4f46e5' },
        data: values,
        markArea: {
          silent: false,
          data: markAreaData
        },
        markLine: {
          silent: true,
          symbol: ['none', 'none'],
          data: markLineData
        }
      },
      // 2. 超限红点高亮预警散点
      {
        name: '超限预警',
        type: 'scatter',
        symbol: 'circle',
        symbolSize: 9,
        itemStyle: {
          color: '#ef4444',
          borderColor: '#ffffff',
          borderWidth: 2,
          shadowColor: 'rgba(239, 68, 68, 0.6)',
          shadowBlur: 8
        },
        data: outOfSpecPoints,
        z: 10
      }
    ]
  }
})
</script>

<style scoped>
.lot-chart-container {
  overflow: hidden;
}

.wc-nav-btn {
  background: var(--c-surface-2);
  border: none;
  color: var(--c-text-secondary);
  font-size: 11px;
  font-weight: 500;
  padding: 5px 12px;
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: all var(--dur-normal) var(--ease);
}

.wc-nav-btn:hover {
  background: var(--c-accent-light);
  color: var(--c-accent);
  transform: translateY(-1px);
}

.wc-nav-btn.active {
  background: var(--c-accent);
  color: #ffffff;
  font-weight: 600;
}

/* 🧬 带束层组合分析专属高亮按钮 */
.combo-nav-btn {
  background: linear-gradient(135deg, rgba(99, 102, 241, 0.12), rgba(168, 85, 247, 0.14));
  color: #4f46e5;
  border: 1px solid rgba(99, 102, 241, 0.35);
  font-weight: 600;
}

.combo-nav-btn:hover {
  background: linear-gradient(135deg, rgba(99, 102, 241, 0.22), rgba(168, 85, 247, 0.24));
  color: #3730a3;
  transform: translateY(-1px);
}

.combo-nav-btn.active {
  background: linear-gradient(135deg, #4f46e5, #7c3aed);
  color: #ffffff;
  border-color: #4f46e5;
  box-shadow: 0 2px 6px rgba(79, 70, 229, 0.35);
}
</style>
