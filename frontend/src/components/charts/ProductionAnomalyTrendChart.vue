<template>
  <div class="production-anomaly-chart-wrap">
    <div v-if="loading" class="chart-loading-state">
      <el-skeleton :rows="5" animated />
    </div>
    <div v-else-if="error" class="chart-error-state">
      <el-icon size="28" color="#ef4444"><WarningFilled /></el-icon>
      <span>{{ error }}</span>
    </div>
    <div v-else-if="!data || data.length === 0" class="chart-empty-state">
      <el-empty description="当前筛选条件下暂无生产异常记录" :image-size="70" />
    </div>
    <div v-else class="chart-body-container">
      <v-chart 
        ref="chartRef" 
        :option="chartOption" 
        :not-merge="true"
        autoresize 
        style="width: 100%; height: 100%;" 
        @click="handleChartClick" 
      />
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import VChart from 'vue-echarts'
import { use } from 'echarts/core'
import { BarChart, LineChart } from 'echarts/charts'
import {
  GridComponent,
  TooltipComponent,
  LegendComponent,
  DataZoomComponent,
  MarkLineComponent
} from 'echarts/components'
import { CanvasRenderer } from 'echarts/renderers'
import { WarningFilled } from '@element-plus/icons-vue'

use([
  BarChart,
  LineChart,
  GridComponent,
  TooltipComponent,
  LegendComponent,
  DataZoomComponent,
  MarkLineComponent,
  CanvasRenderer
])

const props = defineProps({
  data: {
    type: Array,
    default: () => []
  },
  loading: {
    type: Boolean,
    default: false
  },
  error: {
    type: String,
    default: null
  },
  selectedDate: {
    type: String,
    default: null
  },
  alarmModes: {
    type: Array,
    default: () => ['consecutive', 'top5']
  },
  phase: {
    type: String,
    default: 'all'
  },
  grain: {
    type: String,
    default: 'daily'
  },
  zoomRange: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['date-select', 'week-click'])
const chartRef = ref(null)

// 采用用户指定优雅四色配色方案 B (三期与四期柱均采用统一标准四色，全厂单折线)
const COLOR_TU = '#FBB07A'     // 高明度透亮暖橙 (TU 均匀性异常)
const COLOR_TG = '#FFF0AB'     // 浅黄奶油色 (TG 几何尺寸异常)
const COLOR_TB = '#D0F2CF'     // 薄荷淡浅绿 (TB 动平衡异常)
const COLOR_MULTI = '#EEA5AC'  // 优雅浅玫瑰粉 (多工段复合异常)
const COLOR_LINE = '#0ea5e9'   // 清爽浅天蓝 (全厂相较昨日/上周增长比例折线)

const COLOR_P3_THEME = '#0284c7' // 三期主题蓝 (用于卡片与标识)
const COLOR_P4_THEME = '#ea580c' // 四期主题橙 (用于卡片与标识)

const isAllPhase = computed(() => !props.phase || props.phase === 'all')
const isWeekly = computed(() => props.grain === 'weekly')
const lineName = computed(() => isWeekly.value ? '相较上周增长比例 (%)' : '相较昨日增长比例 (%)')
const growthPeriodLabel = computed(() => isWeekly.value ? '相较上周增长' : '相较昨日增长')
const growthShortLabel = computed(() => isWeekly.value ? '周环比' : '日环比')
const dataCategoryName = computed(() => isWeekly.value ? '周汇总数据' : '生产数据')

// 格式化环比增长文本及颜色辅助函数
function formatGrowth(growth) {
  if (growth === null || growth === undefined || isNaN(growth)) {
    return { text: '-', color: '#94a3b8' }
  }
  if (growth > 0) return { text: `+${growth}%`, color: '#dc2626' }
  if (growth < 0) return { text: `${growth}%`, color: '#16a34a' }
  return { text: '0.00%', color: '#64748b' }
}

// 构建折线点及预警高亮
function buildLinePointsData(rawList, rateField, defaultLineColor, enableTop5, enableConsecutive) {
  const top5Map = new Map()
  if (enableTop5) {
    const validRatePoints = rawList
      .map((item, idx) => ({ idx, date: item.date, rate: item[rateField] }))
      .filter(p => typeof p.rate === 'number' && !isNaN(p.rate))
    validRatePoints.sort((a, b) => b.rate - a.rate)
    validRatePoints.slice(0, 5).forEach((p, rank) => {
      top5Map.set(p.idx, rank + 1)
    })
  }

  const consecutiveSet = new Set()
  if (enableConsecutive) {
    for (let i = 1; i < rawList.length; i++) {
      const curr = rawList[i][rateField]
      const prev = rawList[i - 1][rateField]
      if (typeof curr === 'number' && curr > 0 && typeof prev === 'number' && prev > 0) {
        consecutiveSet.add(i)
      }
    }
  }

  return rawList.map((item, idx) => {
    const val = item[rateField]
    if (val === null || val === undefined || isNaN(val)) {
      return null
    }

    const isTop5 = enableTop5 && top5Map.has(idx)
    const isConsecutive = enableConsecutive && consecutiveSet.has(idx)

    if (isTop5 && isConsecutive) {
      const rank = top5Map.get(idx)
      return {
        value: val,
        symbol: 'circle',
        symbolSize: 11,
        itemStyle: {
          color: '#dc2626',
          borderColor: '#ffffff',
          borderWidth: 2.5,
          shadowBlur: 10,
          shadowColor: 'rgba(220, 38, 38, 0.65)'
        },
        alarmType: 'both',
        alarmRank: rank
      }
    } else if (isTop5) {
      const rank = top5Map.get(idx)
      return {
        value: val,
        symbol: 'circle',
        symbolSize: 10,
        itemStyle: {
          color: '#ef4444',
          borderColor: '#ffffff',
          borderWidth: 2,
          shadowBlur: 8,
          shadowColor: 'rgba(239, 68, 68, 0.55)'
        },
        alarmType: 'top5',
        alarmRank: rank
      }
    } else if (isConsecutive) {
      return {
        value: val,
        symbol: 'circle',
        symbolSize: 9,
        itemStyle: {
          color: '#f97316',
          borderColor: '#ffffff',
          borderWidth: 2,
          shadowBlur: 8,
          shadowColor: 'rgba(249, 115, 22, 0.55)'
        },
        alarmType: 'consecutive'
      }
    }

    return {
      value: val,
      symbol: 'circle',
      symbolSize: 4.5,
      itemStyle: {
        color: defaultLineColor,
        borderColor: '#ffffff',
        borderWidth: 1.5
      }
    }
  })
}

const chartOption = computed(() => {
  const rawList = props.data || []
  if (rawList.length === 0) return {}

  const dates = rawList.map(item => (isWeekly.value && item.date_range ? item.date_range : item.date))

  // 1. 报警模式开启判定与算法计算
  const activeAlarmModes = props.alarmModes || []
  const enableConsecutive = activeAlarmModes.includes('consecutive')
  const enableTop5 = activeAlarmModes.includes('top5')

  // 选中日期的标线高亮 (支持在周模式下高亮选中的周)
  const markLineData = []
  let selectedAxisVal = props.selectedDate
  if (isWeekly.value && props.selectedDate) {
    const found = rawList.find(i => i.date === props.selectedDate || i.week_start === props.selectedDate || i.date_range === props.selectedDate)
    if (found && found.date_range) {
      selectedAxisVal = found.date_range
    }
  }

  if (selectedAxisVal && dates.includes(selectedAxisVal)) {
    markLineData.push({
      xAxis: selectedAxisVal,
      lineStyle: {
        color: '#2563eb',
        width: 2,
        type: 'dashed'
      },
      label: {
        show: true,
        position: 'end',
        formatter: (isWeekly.value ? '已选周: ' : '当前选定: ') + selectedAxisVal,
        fontSize: 11,
        color: '#2563eb',
        fontWeight: 'bold',
        backgroundColor: 'rgba(239, 246, 255, 0.95)',
        borderColor: '#93c5fd',
        borderWidth: 1,
        borderRadius: 4,
        padding: [3, 6]
      }
    })
  }

  const series = []
  let legendSelected = {}

  if (isAllPhase.value) {
    // -------------------------------------------------------------------------
    // 【方案 B 全部模式】：三四期双堆叠柱 (同一套四色: stack p3 与 stack p4) + 全厂单折线
    // -------------------------------------------------------------------------
    const p3TuRateList = rawList.map(item => {
      const tot = item.p3_total_tires || 1
      const count = item.p3_tu_only_anomalies !== undefined ? item.p3_tu_only_anomalies : (item.p3_tu_anomalies || 0)
      return Number(((count / tot) * 100).toFixed(2))
    })
    const p3TgRateList = rawList.map(item => {
      const tot = item.p3_total_tires || 1
      const count = item.p3_tg_only_anomalies !== undefined ? item.p3_tg_only_anomalies : (item.p3_tg_anomalies || 0)
      return Number(((count / tot) * 100).toFixed(2))
    })
    const p3TbRateList = rawList.map(item => {
      const tot = item.p3_total_tires || 1
      const count = item.p3_tb_only_anomalies !== undefined ? item.p3_tb_only_anomalies : (item.p3_tb_anomalies || 0)
      return Number(((count / tot) * 100).toFixed(2))
    })
    const hasP3Multi = rawList.some(item => (item.p3_multi_anomalies || 0) > 0)
    const p3MultiRateList = rawList.map(item => {
      const tot = item.p3_total_tires || 1
      return Number((((item.p3_multi_anomalies || 0) / tot) * 100).toFixed(2))
    })

    const p4TuRateList = rawList.map(item => {
      const tot = item.p4_total_tires || 1
      const count = item.p4_tu_only_anomalies !== undefined ? item.p4_tu_only_anomalies : (item.p4_tu_anomalies || 0)
      return Number(((count / tot) * 100).toFixed(2))
    })
    const p4TgRateList = rawList.map(item => {
      const tot = item.p4_total_tires || 1
      const count = item.p4_tg_only_anomalies !== undefined ? item.p4_tg_only_anomalies : (item.p4_tg_anomalies || 0)
      return Number(((count / tot) * 100).toFixed(2))
    })
    const p4TbRateList = rawList.map(item => {
      const tot = item.p4_total_tires || 1
      const count = item.p4_tb_only_anomalies !== undefined ? item.p4_tb_only_anomalies : (item.p4_tb_anomalies || 0)
      return Number(((count / tot) * 100).toFixed(2))
    })
    const hasP4Multi = rawList.some(item => (item.p4_multi_anomalies || 0) > 0)
    const p4MultiRateList = rawList.map(item => {
      const tot = item.p4_total_tires || 1
      return Number((((item.p4_multi_anomalies || 0) / tot) * 100).toFixed(2))
    })

    const hasAnyMulti = hasP3Multi || hasP4Multi

    // 三期堆叠柱 (stack: 'p3', 左柱)
    series.push({
      name: 'TU',
      type: 'bar',
      stack: 'p3',
      barMaxWidth: 32,
      barGap: '12%',
      barCategoryGap: '45%',
      itemStyle: { color: COLOR_TU },
      data: p3TuRateList,
      markLine: markLineData.length > 0 ? { silent: true, symbol: ['none', 'none'], data: markLineData } : undefined
    })
    series.push({
      name: 'TG',
      type: 'bar',
      stack: 'p3',
      barMaxWidth: 32,
      itemStyle: { color: COLOR_TG, borderColor: '#fef08a', borderWidth: 0.5 },
      data: p3TgRateList
    })
    series.push({
      name: 'TB',
      type: 'bar',
      stack: 'p3',
      barMaxWidth: 32,
      itemStyle: { color: COLOR_TB, borderColor: '#bbf7d0', borderWidth: 0.5, borderRadius: hasP3Multi ? [0, 0, 0, 0] : [2, 2, 0, 0] },
      data: p3TbRateList
    })
    if (hasAnyMulti) {
      series.push({
        name: '多工段复合',
        type: 'bar',
        stack: 'p3',
        barMaxWidth: 32,
        itemStyle: { color: COLOR_MULTI, borderRadius: [2, 2, 0, 0] },
        data: p3MultiRateList
      })
    }

    // 四期堆叠柱 (stack: 'p4', 右柱，采用相同四色)
    series.push({
      name: 'TU',
      type: 'bar',
      stack: 'p4',
      barMaxWidth: 32,
      itemStyle: { color: COLOR_TU },
      data: p4TuRateList
    })
    series.push({
      name: 'TG',
      type: 'bar',
      stack: 'p4',
      barMaxWidth: 32,
      itemStyle: { color: COLOR_TG, borderColor: '#fef08a', borderWidth: 0.5 },
      data: p4TgRateList
    })
    series.push({
      name: 'TB',
      type: 'bar',
      stack: 'p4',
      barMaxWidth: 32,
      itemStyle: { color: COLOR_TB, borderColor: '#bbf7d0', borderWidth: 0.5, borderRadius: hasP4Multi ? [0, 0, 0, 0] : [2, 2, 0, 0] },
      data: p4TbRateList
    })
    if (hasAnyMulti) {
      series.push({
        name: '多工段复合',
        type: 'bar',
        stack: 'p4',
        barMaxWidth: 32,
        itemStyle: { color: COLOR_MULTI, borderRadius: [2, 2, 0, 0] },
        data: p4MultiRateList
      })
    }

    // 全厂单折线 (相较昨日/上周增长比例)
    const linePointsData = buildLinePointsData(rawList, 'anomaly_growth_rate', COLOR_LINE, enableTop5, enableConsecutive)
    series.push({
      name: lineName.value,
      type: 'line',
      yAxisIndex: 1,
      data: linePointsData,
      showSymbol: true,
      connectNulls: true,
      smooth: 0.2,
      lineStyle: { color: COLOR_LINE, width: 2 },
      itemStyle: { color: COLOR_LINE },
      emphasis: {
        scale: 1.4,
        itemStyle: { borderColor: COLOR_LINE, borderWidth: 2.5, shadowBlur: 8, shadowColor: 'rgba(14, 165, 233, 0.45)' }
      },
      markLine: {
        silent: true,
        symbol: ['none', 'none'],
        data: [
          {
            yAxis: 0,
            lineStyle: { color: '#475569', type: 'dashed', width: 1.8 },
            label: { show: true, position: 'end', formatter: '0%', fontSize: 10, fontWeight: 'bold', color: '#475569', distance: 4 }
          }
        ]
      }
    })

    legendSelected = {
      'TU': true,
      'TG': true,
      'TB': true,
      [lineName.value]: true
    }
    if (hasAnyMulti) legendSelected['多工段复合'] = true

  } else {
    // -------------------------------------------------------------------------
    // 【单期模式】：原有单柱堆叠模式 (stack: 'production')
    // -------------------------------------------------------------------------
    const tuRateList = rawList.map(item => {
      const total = item.total_tires || 1
      const count = item.tu_only_anomalies !== undefined ? item.tu_only_anomalies : (item.tu_anomalies || 0)
      return Number(((count / total) * 100).toFixed(2))
    })
    const tgRateList = rawList.map(item => {
      const total = item.total_tires || 1
      const count = item.tg_only_anomalies !== undefined ? item.tg_only_anomalies : (item.tg_anomalies || 0)
      return Number(((count / total) * 100).toFixed(2))
    })
    const tbRateList = rawList.map(item => {
      const total = item.total_tires || 1
      const count = item.tb_only_anomalies !== undefined ? item.tb_only_anomalies : (item.tb_anomalies || 0)
      return Number(((count / total) * 100).toFixed(2))
    })
    const multiList = rawList.map(item => item.multi_anomalies || 0)
    const multiRateList = rawList.map(item => {
      const total = item.total_tires || 1
      const count = item.multi_anomalies || 0
      return Number(((count / total) * 100).toFixed(2))
    })
    const hasMulti = multiList.some(v => v > 0)

    const linePointsData = buildLinePointsData(rawList, 'anomaly_growth_rate', COLOR_LINE, enableTop5, enableConsecutive)

    series.push({
      name: 'TU',
      type: 'bar',
      stack: 'production',
      barMaxWidth: 64,
      barCategoryGap: '45%',
      itemStyle: { color: COLOR_TU },
      data: tuRateList,
      markLine: markLineData.length > 0 ? { silent: true, symbol: ['none', 'none'], data: markLineData } : undefined
    })
    series.push({
      name: 'TG',
      type: 'bar',
      stack: 'production',
      barMaxWidth: 64,
      itemStyle: { color: COLOR_TG, borderColor: '#fef08a', borderWidth: 0.5 },
      data: tgRateList
    })
    series.push({
      name: 'TB',
      type: 'bar',
      stack: 'production',
      barMaxWidth: 64,
      itemStyle: { color: COLOR_TB, borderColor: '#bbf7d0', borderWidth: 0.5, borderRadius: hasMulti ? [0, 0, 0, 0] : [2, 2, 0, 0] },
      data: tbRateList
    })
    if (hasMulti) {
      series.push({
        name: '多工段复合',
        type: 'bar',
        stack: 'production',
        barMaxWidth: 64,
        itemStyle: { color: COLOR_MULTI, borderRadius: [2, 2, 0, 0] },
        data: multiRateList
      })
    }
    series.push({
      name: lineName.value,
      type: 'line',
      yAxisIndex: 1,
      data: linePointsData,
      showSymbol: true,
      connectNulls: true,
      smooth: 0.2,
      lineStyle: { color: COLOR_LINE, width: 2 },
      itemStyle: { color: COLOR_LINE },
      emphasis: {
        scale: 1.4,
        itemStyle: { borderColor: COLOR_LINE, borderWidth: 2.5, shadowBlur: 8, shadowColor: 'rgba(14, 165, 233, 0.45)' }
      },
      markLine: {
        silent: true,
        symbol: ['none', 'none'],
        data: [
          {
            yAxis: 0,
            lineStyle: { color: '#475569', type: 'dashed', width: 1.8 },
            label: { show: true, position: 'end', formatter: '0%', fontSize: 10, fontWeight: 'bold', color: '#475569', distance: 4 }
          }
        ]
      }
    })

    legendSelected = {
      'TU': true,
      'TG': true,
      'TB': true,
      [lineName.value]: true
    }
    if (hasMulti) legendSelected['多工段复合'] = true
  }

  // 次 Y 轴范围自适应与 0 轴对称微调 (单折线：基于全厂 anomaly_growth_rate)
  const validGrowth = rawList.map(i => i.anomaly_growth_rate).filter(v => typeof v === 'number' && !isNaN(v))

  let y2Min = -20
  let y2Max = 20
  if (validGrowth.length > 0) {
    const minG = Math.min(...validGrowth)
    const maxG = Math.max(...validGrowth)
    const maxAbs = Math.max(Math.abs(minG), Math.abs(maxG), 10)
    const bound = Math.ceil((maxAbs * 1.25) / 5) * 5
    y2Min = -bound
    y2Max = bound
  }

  // 数据滑块与缩放控制 (支持周下钻通过 zoomRange 精确聚焦选中的这几天，并完好保留滑动条供左右滑动查看)
  let hasZoom = false
  let zoomStartPercent = 0
  let zoomEndPercent = 100
  let zoomStartValue = undefined
  let zoomEndValue = undefined

  if (!isWeekly.value) {
    if (props.zoomRange && props.zoomRange.start && props.zoomRange.end) {
      hasZoom = true
      const startIdx = dates.findIndex(d => d >= props.zoomRange.start)
      let endIdx = -1
      for (let i = dates.length - 1; i >= 0; i--) {
        if (dates[i] <= props.zoomRange.end) {
          endIdx = i
          break
        }
      }
      if (startIdx >= 0 && endIdx >= startIdx) {
        zoomStartValue = dates[startIdx]
        zoomEndValue = dates[endIdx]
        zoomStartPercent = Math.max(0, Math.floor((startIdx / dates.length) * 100))
        zoomEndPercent = Math.min(100, Math.ceil(((endIdx + 1) / dates.length) * 100))
      }
    } else if (isAllPhase.value) {
      const displayDays = 15
      hasZoom = dates.length > displayDays
      zoomStartPercent = hasZoom ? Math.max(0, Math.round(((dates.length - displayDays) / dates.length) * 100)) : 0
      zoomEndPercent = 100
    } else {
      hasZoom = dates.length > 25
      zoomStartPercent = 0
      zoomEndPercent = 100
    }
  } else {
    // 周维度：默认全景展示全部周期，仅在超多数据 (>25项) 时提供全景滑块
    hasZoom = dates.length > 25
    zoomStartPercent = 0
    zoomEndPercent = 100
  }

  return {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'axis',
      axisPointer: {
        type: 'shadow',
        shadowStyle: {
          color: 'rgba(59, 130, 246, 0.05)'
        }
      },
      padding: [10, 14],
      backgroundColor: 'rgba(255, 255, 255, 0.98)',
      borderColor: '#e2e8f0',
      borderWidth: 1,
      textStyle: {
        color: '#1e293b',
        fontSize: 12
      },
      extraCssText: 'box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1); border-radius: 8px;',
      formatter: (params) => {
        if (!params || params.length === 0) return ''
        const dateStr = params[0].axisValue
        const itemIdx = rawList.findIndex(d => (d.date_range === dateStr || d.date === dateStr))
        const item = rawList[itemIdx]
        if (!item) return ''

        if (isAllPhase.value) {
          const totalG = formatGrowth(item.anomaly_growth_rate)
          const p3G = formatGrowth(item.p3_growth_rate)
          const p4G = formatGrowth(item.p4_growth_rate)

          // 辅助生成单期工序行 (方案B：统一标准四色)
          const renderPhaseRows = (tuCnt, tgCnt, tbCnt, multiCnt, totTires, tuColor, tgColor, tbColor, multiColor) => {
            const tot = totTires || 1
            const items = [
              { name: 'TU', count: tuCnt, color: tuColor, rate: Number(((tuCnt / tot) * 100).toFixed(2)) },
              { name: 'TG', count: tgCnt, color: tgColor, rate: Number(((tgCnt / tot) * 100).toFixed(2)) },
              { name: 'TB', count: tbCnt, color: tbColor, rate: Number(((tbCnt / tot) * 100).toFixed(2)) },
            ]
            if (multiCnt && multiCnt > 0) {
              items.push({ name: '复合', count: multiCnt, color: multiColor, rate: Number(((multiCnt / tot) * 100).toFixed(2)) })
            }
            items.sort((a, b) => b.rate - a.rate)

            return items.map(p => `
              <div style="display: flex; justify-content: space-between; align-items: center; font-size: 11.5px; margin-bottom: 3px;">
                <div style="display: flex; align-items: center; gap: 5px;">
                  <span style="display: inline-block; width: 7px; height: 7px; border-radius: 50%; background: ${p.color};"></span>
                  <span style="color: #0f172a; font-weight: 600; font-family: 'JetBrains Mono', monospace;">${p.name}</span>
                </div>
                <span style="font-family: 'JetBrains Mono', monospace; font-weight: 600; color: #334155;">${p.count.toLocaleString()} 胎 (${p.rate}%)</span>
              </div>
            `).join('')
          }

          const p3Rows = renderPhaseRows(item.p3_tu_only_anomalies || item.p3_tu_anomalies || 0, item.p3_tg_only_anomalies || item.p3_tg_anomalies || 0, item.p3_tb_only_anomalies || item.p3_tb_anomalies || 0, item.p3_multi_anomalies || 0, item.p3_total_tires, COLOR_TU, COLOR_TG, COLOR_TB, COLOR_MULTI)
          const p4Rows = renderPhaseRows(item.p4_tu_only_anomalies || item.p4_tu_anomalies || 0, item.p4_tg_only_anomalies || item.p4_tg_anomalies || 0, item.p4_tb_only_anomalies || item.p4_tb_anomalies || 0, item.p4_multi_anomalies || 0, item.p4_total_tires, COLOR_TU, COLOR_TG, COLOR_TB, COLOR_MULTI)

          return `
            <div style="padding: 4px 6px; min-width: 460px;">
              <div style="font-size: 13px; font-weight: 700; color: #0f172a; margin-bottom: 8px; padding-bottom: 6px; border-bottom: 1px solid #f1f5f9; display: flex; justify-content: space-between; align-items: center;">
                <span>${item.date} ${dataCategoryName.value}</span>
                <span style="font-size: 11px; font-weight: 500; color: #64748b; background: #f8fafc; padding: 2px 6px; border-radius: 4px; border: 1px solid #e2e8f0;">三四期双堆叠对比</span>
              </div>

              <div style="display: flex; justify-content: space-between; align-items: center; font-size: 12px; margin-bottom: 4px;">
                <span style="color: #64748b;">全厂总产 / 异常</span>
                <span style="font-family: 'JetBrains Mono', monospace; font-weight: 600; color: #0f172a;">
                  ${item.total_tires.toLocaleString()} 胎 / <span style="color: #e11d48; font-weight: 700;">${item.anomaly_rate}%</span> (${item.anomaly_tires.toLocaleString()} 胎)
                </span>
              </div>

              <div style="display: flex; justify-content: space-between; align-items: center; font-size: 12px; margin-bottom: 8px;">
                <span style="color: #64748b;">全厂${growthPeriodLabel.value}</span>
                <span style="font-family: 'JetBrains Mono', monospace; font-weight: 700; color: ${totalG.color};">
                  ${totalG.text}
                </span>
              </div>

              <!-- 三期与四期卡片横向排布 -->
              <div style="display: flex; gap: 10px; margin-top: 6px;">
                <!-- 三期卡片 -->
                <div style="flex: 1; min-width: 220px; background: #f0f9ff; border-radius: 6px; padding: 6px 8px; border-left: 3.5px solid ${COLOR_P3_THEME};">
                  <div style="display: flex; justify-content: space-between; align-items: center; font-size: 12px; font-weight: 700; color: #0369a1; margin-bottom: 3px;">
                    <span>三期生产 (${item.p3_total_tires.toLocaleString()} 胎)</span>
                    <span style="font-family: 'JetBrains Mono', monospace; color: ${p3G.color}; font-size: 11px;">${growthShortLabel.value}: ${p3G.text}</span>
                  </div>
                  <div style="font-size: 11px; color: #475569; margin-bottom: 5px;">
                    不良率: <b style="color: #0369a1; font-family: 'JetBrains Mono', monospace;">${item.p3_anomaly_rate}%</b> (${item.p3_anomaly_tires.toLocaleString()} 胎)
                  </div>
                  <div style="border-top: 1px dashed #bae6fd; padding-top: 4px;">
                    ${p3Rows}
                  </div>
                </div>

                <!-- 四期卡片 -->
                <div style="flex: 1; min-width: 220px; background: #fff7ed; border-radius: 6px; padding: 6px 8px; border-left: 3.5px solid ${COLOR_P4_THEME};">
                  <div style="display: flex; justify-content: space-between; align-items: center; font-size: 12px; font-weight: 700; color: #c2410c; margin-bottom: 3px;">
                    <span>四期生产 (${item.p4_total_tires.toLocaleString()} 胎)</span>
                    <span style="font-family: 'JetBrains Mono', monospace; color: ${p4G.color}; font-size: 11px;">${growthShortLabel.value}: ${p4G.text}</span>
                  </div>
                  <div style="font-size: 11px; color: #475569; margin-bottom: 5px;">
                    不良率: <b style="color: #c2410c; font-family: 'JetBrains Mono', monospace;">${item.p4_anomaly_rate}%</b> (${item.p4_anomaly_tires.toLocaleString()} 胎)
                  </div>
                  <div style="border-top: 1px dashed #fed7aa; padding-top: 4px;">
                    ${p4Rows}
                  </div>
                </div>
              </div>
            </div>`
        }

        // 仅保留 TB, TU, TG，去掉中文解释
        const processItems = [
          {
            name: 'TB',
            color: COLOR_TB,
            borderColor: '#86efac',
            count: item.tb_anomalies,
            rate: item.tb_anomaly_rate,
            growth: item.tb_growth_rate
          },
          {
            name: 'TU',
            color: COLOR_TU,
            borderColor: 'transparent',
            count: item.tu_anomalies,
            rate: item.tu_anomaly_rate,
            growth: item.tu_growth_rate
          },
          {
            name: 'TG',
            color: COLOR_TG,
            borderColor: '#fde047',
            count: item.tg_anomalies,
            rate: item.tg_anomaly_rate,
            growth: item.tg_growth_rate
          }
        ]

        if (item.multi_anomalies && item.multi_anomalies > 0) {
          const multiRate = Number(((item.multi_anomalies / (item.total_tires || 1)) * 100).toFixed(2))
          processItems.push({
            name: '复合异常',
            color: COLOR_MULTI,
            borderColor: '#f472b6',
            count: item.multi_anomalies,
            rate: multiRate,
            growth: null
          })
        }

        // 按日环比增长比例由高到低 (降序) 排序
        processItems.sort((a, b) => {
          const gA = (a.growth !== null && a.growth !== undefined) ? a.growth : -99999
          const gB = (b.growth !== null && b.growth !== undefined) ? b.growth : -99999
          if (gA !== gB) return gB - gA
          return (b.rate || 0) - (a.rate || 0)
        })

        const processRows = processItems.map(p => {
          let pGrowthText = '-'
          let pGrowthColor = '#94a3b8'
          if (p.growth !== null && p.growth !== undefined) {
            if (p.growth > 0) {
              pGrowthText = `+${p.growth}%`
              pGrowthColor = '#dc2626'
            } else if (p.growth < 0) {
              pGrowthText = `${p.growth}%`
              pGrowthColor = '#16a34a'
            } else {
              pGrowthText = '0.00%'
              pGrowthColor = '#64748b'
            }
          }

          return `
            <div style="display: flex; justify-content: space-between; align-items: center; font-size: 12px; margin-bottom: 5px;">
              <div style="display: flex; align-items: center; min-width: 45px;">
                <span style="display: inline-block; width: 8px; height: 8px; border-radius: 50%; background: ${p.color}; ${p.borderColor ? `border: 1px solid ${p.borderColor};` : ''} margin-right: 7px;"></span>
                <span style="color: #0f172a; font-weight: 700; font-family: 'JetBrains Mono', monospace;">${p.name}</span>
              </div>
              <div style="display: flex; align-items: center; gap: 10px;">
                <span style="font-family: 'JetBrains Mono', monospace; font-weight: 600; color: #0f172a;">${p.count.toLocaleString()} 胎 (${p.rate}%)</span>
                <span style="font-family: 'JetBrains Mono', monospace; font-weight: 600; min-width: 52px; text-align: right; color: ${pGrowthColor};">${pGrowthText}</span>
              </div>
            </div>`
        }).join('')

        return `
          <div style="padding: 4px 6px; min-width: 245px;">
            <div style="font-size: 13px; font-weight: 700; color: #0f172a; margin-bottom: 8px; padding-bottom: 6px; border-bottom: 1px solid #f1f5f9;">
              ${item.date} ${dataCategoryName.value}
            </div>

            <div style="display: flex; justify-content: space-between; align-items: center; font-size: 12px; margin-bottom: 5px;">
              <span style="color: #64748b;">总生产条数</span>
              <span style="font-family: 'JetBrains Mono', monospace; font-weight: 600; color: #0f172a;">${item.total_tires.toLocaleString()} 胎</span>
            </div>

            <div style="display: flex; justify-content: space-between; align-items: center; font-size: 12px; margin-bottom: 8px;">
              <span style="color: #64748b;">异常比例</span>
              <span style="font-family: 'JetBrains Mono', monospace; font-weight: 700; color: #e11d48;">${item.anomaly_rate}% (${item.anomaly_tires.toLocaleString()} 胎)</span>
            </div>

            <div style="border-top: 1px solid #f1f5f9; padding-top: 7px; margin-top: 4px;">
              <div style="display: flex; justify-content: space-between; align-items: center; font-size: 11px; font-weight: 600; color: #94a3b8; margin-bottom: 6px;">
                <span>工序分布</span>
                <span>${growthShortLabel.value}</span>
              </div>
              ${processRows}
            </div>
          </div>
        `
      }
    },
    legend: {
      top: 0,
      left: 'center',
      itemWidth: 12,
      itemHeight: 10,
      itemGap: 14,
      textStyle: {
        fontSize: 11,
        color: '#64748b'
      },
      selected: legendSelected
    },
    grid: {
      top: 36,
      left: 16,
      right: 28,
      bottom: hasZoom ? 42 : 16,
      containLabel: true
    },

    xAxis: {
      type: 'category',
      data: dates,
      axisLine: { lineStyle: { color: '#e2e8f0' } },
      axisTick: { alignWithLabel: true, lineStyle: { color: '#cbd5e1' } },
      axisLabel: {
        fontSize: 11,
        color: '#64748b',
        interval: 0,
        formatter: (val) => {
          if (!val) return ''
          if (isWeekly.value) return val
          const parts = val.split('-')
          return parts.length >= 3 ? `${parts[1]}-${parts[2]}` : val
        }
      }
    },
    yAxis: [
      {
        type: 'value',
        name: '不良率 (%)',
        min: 0,
        nameTextStyle: {
          fontSize: 11,
          color: '#64748b',
          padding: [0, 0, 0, -10]
        },
        axisLabel: {
          fontSize: 11,
          color: '#64748b',
          formatter: (val) => `${val}%`
        },
        splitLine: {
          lineStyle: {
            color: '#f1f5f9',
            type: 'dashed'
          }
        }
      },
      {
        type: 'value',
        name: isWeekly.value ? '周环比增幅' : '日环比增幅',
        min: y2Min,
        max: y2Max,
        nameTextStyle: {
          fontSize: 11,
          color: '#0ea5e9',
          fontWeight: 600,
          padding: [0, -10, 0, 0]
        },
        axisLabel: {
          fontSize: 11,
          color: '#0ea5e9',
          formatter: (val) => (val > 0 ? `+${val}` : val) + '%'
        },
        splitLine: {
          show: false
        }
      }
    ],
    dataZoom: hasZoom ? [
      {
        type: 'inside',
        start: zoomStartPercent,
        end: zoomEndPercent,
        startValue: zoomStartValue,
        endValue: zoomEndValue,
        zoomOnMouseWheel: 'ctrl',
        moveOnMouseMove: true,
        moveOnMouseWheel: true
      },
      {
        type: 'slider',
        height: 18,
        bottom: 2,
        left: 24,
        right: 36,
        start: zoomStartPercent,
        end: zoomEndPercent,
        startValue: zoomStartValue,
        endValue: zoomEndValue,
        borderColor: '#e2e8f0',
        backgroundColor: '#f8fafc',
        fillerColor: 'rgba(59, 130, 246, 0.12)',
        handleSize: '110%',
        handleStyle: {
          color: '#3b82f6',
          borderColor: '#ffffff',
          borderWidth: 1.5,
          shadowBlur: 4,
          shadowColor: 'rgba(59, 130, 246, 0.25)'
        },
        dataBackground: {
          lineStyle: { color: '#cbd5e1', width: 1 },
          areaStyle: { color: 'rgba(241, 245, 249, 0.6)' }
        },
        selectedDataBackground: {
          lineStyle: { color: '#3b82f6', width: 1.5 },
          areaStyle: { color: 'rgba(191, 219, 254, 0.5)' }
        },
        textStyle: {
          color: '#64748b',
          fontSize: 10,
          fontFamily: 'JetBrains Mono, monospace'
        }
      }
    ] : [],
    series: series
  }
})

function handleChartClick(params) {
  const dataList = props.data || []
  let targetItem = null
  if (params.dataIndex !== undefined && params.dataIndex >= 0 && params.dataIndex < dataList.length) {
    targetItem = dataList[params.dataIndex]
  } else if (params.name) {
    targetItem = dataList.find(d => (d.date_range === params.name || d.date === params.name))
  } else if (params.value) {
    targetItem = dataList.find(d => (d.date_range === params.value || d.date === params.value))
  }

  if (isWeekly.value && targetItem) {
    emit('week-click', targetItem)
  } else if (targetItem) {
    emit('date-select', targetItem.date)
  } else if (params.name) {
    emit('date-select', params.name)
  } else if (params.value) {
    emit('date-select', params.value)
  }
}
</script>

<style scoped>
.production-anomaly-chart-wrap {
  width: 100%;
  height: 100%;
  position: relative;
  display: flex;
  flex-direction: column;
}

.chart-body-container {
  flex: 1;
  width: 100%;
  min-height: 0;
  position: relative;
}

.chart-loading-state,
.chart-error-state,
.chart-empty-state {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 10px;
}

.chart-error-state {
  color: #ef4444;
  font-size: 13px;
  font-weight: 500;
}
</style>
