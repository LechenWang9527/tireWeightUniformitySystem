<template>
  <div class="tire-weight-page">
    <!-- 纯净空白画布容器，预留后续胎重分析图表与模块接入 -->
    <div class="weight-canvas-container">
    </div>
  </div>
</template>

<script setup>
// 轮胎重量分析 (Tire Weight Analysis) 独立页面视图
</script>

<style scoped>
.tire-weight-page {
  width: 100%;
  min-height: calc(100vh - var(--header-h, 64px));
  background-color: var(--c-bg, #f8fafc);
  padding: 16px 20px;
  box-sizing: border-box;
}

.weight-canvas-container {
  width: 100%;
  min-height: calc(100vh - var(--header-h, 64px) - 32px);
  border-radius: var(--radius-md, 16px);
  box-sizing: border-box;
}
</style>
