<template>
  <div ref="sankeyContainerRef" class="sankey-container" style="width: 100%; height: 100%; position: relative;">
    <div v-if="loading" class="sankey-loading" style="height: 100%; display: flex; align-items: center; justify-content: center;">
      <el-icon class="is-loading" size="24"><Loading /></el-icon>
      <span style="margin-left: 8px; font-size: 13px; color: #666;">正在生成全量最佳工序流转路径图...</span>
    </div>
    <div v-else-if="error" class="sankey-error" style="height: 100%; display: flex; align-items: center; justify-content: center; color: #ef4444; font-size: 13px;">
      <span>{{ error }}</span>
    </div>
    <div v-else-if="!sankeyData || !sankeyData.nodes || sankeyData.nodes.length === 0" class="sankey-empty" style="height: 100%; display: flex; align-items: center; justify-content: center; color: #8c959f; font-size: 13px;">
      <el-empty :description="sankeyEmptyDescription" :image-size="60" />
    </div>
    <template v-else>
      <div style="display: flex; flex-direction: column; height: 100%;">
        <div v-if="sankeyData.best_tu_machine" class="path-notice" style="flex-shrink: 0; margin-bottom: 8px; font-size: 12px; background: #ecfdf5; padding: 6px 12px; border-radius: 4px; border: 1px solid #a7f3d0; color: #047857; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px;">
          <div style="display: flex; align-items: center; gap: 6px; flex-wrap: wrap;">
            <span>基于过去30天数据计算出{{ bestTuCriterionText }} <strong>{{ sankeyData.best_tu_machine }}</strong></span>
            <el-tooltip placement="top" effect="light" popper-class="help-tooltip-light" raw-content>
              <template #content>
                <div class="trend-help-content" style="max-width: 320px;">
                  <div class="trend-help-title">全量最佳生产路径说明</div>
                  <div class="trend-help-section">
                    <div class="section-title">【这是做什么的】</div>
                    <div class="section-line">系统根据过去 30 天历史生产记录，帮您算出合格率最高、质量最稳的一套“黄金机台搭配路线”，生产排产时跟着它做准没错。</div>
                  </div>
                  <div class="trend-help-section">
                    <div class="section-title">【黄金路线怎么选出来的】</div>
                    <div class="section-line">1. <strong>挑最好质检机</strong>：挑出生产了 200 条以上且合格率最高的检测机台（排除做几条碰巧合格的小批量）；</div>
                    <div class="section-line">2. <strong>逆向找源头</strong>：顺藤摸瓜看这些优秀轮胎大部分是由哪台硫化机和成型机做出来的；</div>
                    <div class="section-line">3. <strong>整条绿色高亮路线</strong>：即为系统推荐的最优生产组合。</div>
                  </div>
                </div>
              </template>
              <el-icon style="cursor: pointer; color: #047857; font-size: 13px;"><QuestionFilled /></el-icon>
            </el-tooltip>
          </div>
          <span style="font-weight: 600; color: #059669;">绿色标注：全量最佳生产路径</span>
        </div>
        <v-chart
          :option="option"
          autoresize
          style="width: 100%; flex: 1; min-height: 0; cursor: pointer;"
          @click="onChartClick"
        />
      </div>
    </template>

    <!-- 放大全屏查看弹窗 -->
    <el-dialog
      v-model="dialogVisible"
      title="全量最佳生产工序路径桑基图 - 放大全屏分析"
      width="92%"
      top="4vh"
      destroy-on-close
      append-to-body
    >
      <div style="height: 650px; width: 100%;">
        <v-chart
          :option="zoomedOption"
          autoresize
          style="width: 100%; height: 100%; cursor: pointer;"
          @click="onChartClick"
        />
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import VChart from 'vue-echarts'
import { use } from 'echarts/core'
import { SankeyChart } from 'echarts/charts'
import { TooltipComponent } from 'echarts/components'
import { CanvasRenderer } from 'echarts/renderers'
import { Loading, ZoomIn, QuestionFilled } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'

use([SankeyChart, TooltipComponent, CanvasRenderer])

const props = defineProps({
  sankeyData: { type: Object, default: () => ({ nodes: [], links: [] }) },
  loading:    { type: Boolean, default: false },
  error:      { type: String, default: null },
  indicator:  { type: String, default: 'rfpp' },
  tolerance:  { type: Number, default: 0.8 },
  article:    { type: String, default: '' }
})

const emit = defineEmits(['open-cgrs'])

const sankeyContainerRef = ref(null)
const dialogVisible = ref(false)

const sankeyEmptyDescription = computed(() => {
  if (props.sankeyData && props.sankeyData.empty_message) {
    return props.sankeyData.empty_message
  }
  return '该规格暂无全量最佳工序流转数据'
})

const bestTuCriterionText = computed(() => {
  if (props.indicator === 'cony') {
    return '最佳标准差终检机台'
  } else if (props.indicator === 'weight') {
    return '最佳胎重偏差终检机台'
  } else {
    return '最佳 CPK 终检机台'
  }
})

const sankeyPrefixToCol = {
  "胎面": "tread_workcenter",
  "胎圈": "bead_workcenter",
  "内衬": "inner_liner_workcenter",
  "胎侧": "sidewall_workcenter",
  "带束层1": "first_breaker_workcenter",
  "带束层2": "second_breaker_workcenter",
  "帘布层1": "first_ply_workcenter",
  "帘布层2": "second_ply_workcenter",
  "冠带层1": "wound_cap_ply1_workcenter",
  "冠带层2": "wound_cap_ply2_workcenter",
  "生胎成型GT": "gt_workcenter",
  "硫化CT": "ct_workcenter",
  "终检TU": "tu_first_workcenter",
  "动平衡TB": "tb_first_workcenter"
}

function onChartClick(params) {
  if (params && params.dataType === 'node') {
    const parts = params.name.split('_')
    const prefix = parts[0]
    const machine = parts.length > 1 ? parts.slice(1).join('_') : parts[0]
    const workcenterCol = sankeyPrefixToCol[prefix]
    
    // 成型工段 (生胎成型GT) 或 硫化工段 (硫化CT) 触发 CGRS 弹窗
    if (
      prefix.includes('成型') || prefix.includes('GT') || prefix.includes('硫化') || prefix.includes('CT') || prefix.includes('CU') ||
      (workcenterCol && (workcenterCol.includes('gt_workcenter') || workcenterCol.includes('ct_workcenter')))
    ) {
      emit('open-cgrs', {
        machine,
        stage: prefix,
        article: props.article,
        indicator: props.indicator,
        topWarningMachines: props.sankeyData?.top_warning_machines || []
      })
      dialogVisible.value = false
    } else {
      ElMessage.info(`CGRS 参数修改记录仅支持成型与硫化工段设备 (当前点击: ${prefix} - ${machine})`)
    }
  }
}

const option = computed(() => {
  if (!props.sankeyData || !props.sankeyData.nodes) return {}

  const nodes = props.sankeyData.nodes.map(n => {
    const prefix = n.name.split("_")[0]
    const adjustedDepth = (prefix === '动平衡TB') ? n.depth + 1 : n.depth
    let nodeColor = '#64748b' // 普通节点：蓝灰
    
    // 全量最佳路径上的节点使用翡翠绿标记
    if (n.is_best_path) {
      nodeColor = '#10b981'
    }

    return {
      name: n.name,
      depth: adjustedDepth,
      is_best_path: n.is_best_path,
      is_best_tu: n.is_best_tu,
      avg_val: n.avg_val,
      std_val: n.std_val,
      cpk_val: n.cpk_val,
      ratio_val: n.ratio_val,
      itemStyle: {
        color: nodeColor,
        borderColor: nodeColor,
        borderWidth: 0
      }
    }
  })

  const links = props.sankeyData.links.map(l => {
    return {
      source: l.source,
      target: l.target,
      value: l.value,
      avg_3sigma: l.avg_3sigma,
      lineStyle: l.is_best_path ? {
        color: 'rgba(16, 185, 129, 0.75)',
        curveness: 0.5,
        width: 3
      } : {
        color: 'rgba(148, 163, 184, 0.35)',
        curveness: 0.5,
        width: 1.5
      }
    }
  })

  return {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'item',
      triggerOn: 'mousemove',
      backgroundColor: '#fff',
      borderColor: '#e2e8f0',
      borderWidth: 1,
      padding: [8, 12],
      extraCssText: 'box-shadow: 0 4px 12px rgba(0,0,0,0.08); border-radius: 6px;',
      formatter(params) {
        if (params.dataType === 'node') {
          const isBest = params.data.is_best_path
          const isBestTu = params.data.is_best_tu
          const avgVal = params.data.avg_val
          const stdVal = params.data.std_val
          const cpkVal = params.data.cpk_val

          let badge = ''
          if (isBestTu) {
            badge = `<div style="color:#059669;font-weight:600;font-size:11px;margin-top:6px;padding-top:4px;border-top:1px dashed #e2e8f0;">[最佳 TU 终检机台] 全量波动最小 / 能力最高</div>`
          } else if (isBest) {
            badge = `<div style="color:#059669;font-weight:600;font-size:11px;margin-top:6px;padding-top:4px;border-top:1px dashed #e2e8f0;">[最佳推荐节点] 全量最佳生产路径推荐</div>`
          }

          if (props.indicator === 'weight') {
            const ratioVal = params.data.ratio_val ?? cpkVal
            const ratioStr = ratioVal !== undefined && ratioVal !== null ? (ratioVal > 0 ? '+' : '') + ratioVal.toFixed(2) + '%' : '暂无数据'
            const stdStr = stdVal !== undefined && stdVal !== null ? stdVal.toFixed(2) + '%' : '暂无数据'
            const meanStr = avgVal !== undefined && avgVal !== null ? (avgVal > 0 ? '+' : '') + avgVal.toFixed(3) + ' kg' : '暂无数据'
            return `
              <div style="font-weight:bold;font-size:13px;margin-bottom:6px;color:#1e293b;border-bottom:1px solid #f1f5f9;padding-bottom:4px;">${params.name}</div>
              <div style="display:flex;flex-direction:column;gap:3px;font-size:12px;color:#475569;">
                <div>偏差率: <strong style="color:#2563eb;">${ratioStr}</strong></div>
                <div>标准差 (σ): <strong style="color:#10b981;">${stdStr}</strong></div>
                <div>物理均值差: <strong style="color:#0f172a;">${meanStr}</strong></div>
              </div>
              ${badge}
            `
          }

          const cpkStr = (cpkVal !== undefined && cpkVal !== null) ? cpkVal.toFixed(2) : '暂无数据'
          const stdStr = (stdVal !== undefined && stdVal !== null) ? stdVal.toFixed(2) : '暂无数据'
          const avgStr = (avgVal !== undefined && avgVal !== null) ? avgVal.toFixed(2) : '暂无数据'

          return `
            <div style="font-weight:bold;font-size:13px;margin-bottom:6px;color:#1e293b;border-bottom:1px solid #f1f5f9;padding-bottom:4px;">${params.name}</div>
            <div style="display:flex;flex-direction:column;gap:3px;font-size:12px;color:#475569;">
              <div>全量 CPK: <strong style="color:#2563eb;">${cpkStr}</strong></div>
              <div>标准差 (σ): <strong style="color:#10b981;">${stdStr}</strong></div>
              <div>均值 (μ): <strong style="color:#0f172a;">${avgStr}</strong></div>
            </div>
            ${badge}
          `
        } else if (params.dataType === 'edge') {
          const l = params.data
          const bestTag = l.is_best_path ? `<div style="color:#059669;font-weight:600;font-size:11px;margin-top:4px;">[最佳生产流转链路]</div>` : ''
          return `
            <div style="font-weight:bold;font-size:13px;margin-bottom:6px;color:#1e293b;border-bottom:1px solid #f1f5f9;padding-bottom:4px;">${l.source} ➔ ${l.target}</div>
            <div style="font-size:12px;color:#475569;">全量历史轮胎数 (N): <strong style="color:#2563eb;">${l.value}</strong></div>
            ${bestTag}
          `
        }
      }
    },
    series: [
      {
        type: 'sankey',
        left: 10,
        top: 10,
        right: 180,
        bottom: 10,
        nodeWidth: 16,
        nodeGap: 24,
        nodeAlign: 'justify',
        layoutIterations: 64,
        orient: 'horizontal',
        draggable: true,
        data: nodes,
        links: links,
        label: {
          position: 'right',
          fontSize: 10,
          color: '#334155',
          formatter: (params) => {
            const parts = params.name.split('_')
            const displayName = (parts.length > 1 ? parts[1] : params.name).toUpperCase()
            const avgVal = params.data?.avg_val
            const stdVal = params.data?.std_val
            const cpkVal = params.data?.cpk_val
            let suffix = ''
            if (props.indicator === 'weight') {
              const ratioVal = params.data?.ratio_val ?? cpkVal
              if (ratioVal !== undefined && ratioVal !== null) {
                const sign = ratioVal > 0 ? '+' : ''
                const avgText = (avgVal !== undefined && avgVal !== null) ? ` μ: ${(avgVal > 0 ? '+' : '')}${avgVal.toFixed(2)}` : ''
                const stdText = (stdVal !== undefined && stdVal !== null) ? ` σ: ${stdVal.toFixed(2)}` : ''
                suffix = `  {info|[ 偏离: ${sign}${ratioVal.toFixed(2)}%${avgText}${stdText} ]}`
              }
            } else {
              if (cpkVal !== undefined && cpkVal !== null) {
                const avgText = (avgVal !== undefined && avgVal !== null) ? ` μ: ${avgVal.toFixed(2)}` : ''
                const stdText = (stdVal !== undefined && stdVal !== null) ? ` σ: ${stdVal.toFixed(2)}` : ''
                suffix = `  {info|[ CPK: ${cpkVal.toFixed(2)}${avgText}${stdText} ]}`
              } else if (avgVal !== undefined && avgVal !== null) {
                const stdText = (stdVal !== undefined && stdVal !== null) ? ` σ: ${stdVal.toFixed(2)}` : ''
                suffix = `  {info|[ μ: ${avgVal.toFixed(2)}${stdText} ]}`
              }
            }
            return `{mach|${displayName}}${suffix}`
          },
          rich: {
            mach: {
              fontWeight: '900',
              fontSize: 11,
              color: '#0f172a'
            },
            info: {
              fontWeight: '400',
              fontSize: 9,
              color: '#64748b'
            }
          }
        },
        lineStyle: {
          color: 'gradient',
          curveness: 0.5
        }
      }
    ]
  }
})

// 放大全屏模式配置（增强字号与节点间距）
const zoomedOption = computed(() => {
  const baseOpt = option.value
  if (!baseOpt || !baseOpt.series) return {}

  const deep = JSON.parse(JSON.stringify(baseOpt))
  const s = deep.series[0]
  s.left = 50
  s.right = 200
  s.top = 25
  s.bottom = 25
  s.nodeGap = 18
  s.nodeWidth = 22
  s.label.fontSize = 11
  s.label.color = '#1e293b'
  s.label.formatter = baseOpt.series[0].label.formatter
  s.label.rich = baseOpt.series[0].label.rich
  if (deep.tooltip) {
    deep.tooltip.formatter = baseOpt.tooltip.formatter
  }

  return deep
})

function openZoomDialog() {
  dialogVisible.value = true
}

defineExpose({
  openZoomDialog
})
</script>

<style scoped>
.path-notice {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
}
.zoom-btn {
  background-color: #fff !important;
  border-color: #a7f3d0 !important;
  color: #047857 !important;
  transition: all 0.2s ease-in-out !important;
  font-weight: 600 !important;
}
.zoom-btn:hover {
  background-color: #a7f3d0 !important;
  border-color: #86efac !important;
  color: #065f46 !important;
  transform: translateY(-1px);
  box-shadow: 0 2px 4px rgba(4, 120, 87, 0.08);
}
.zoom-btn:active {
  transform: translateY(0);
}

</style>
