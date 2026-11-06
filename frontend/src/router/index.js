import { createRouter, createWebHistory } from 'vue-router'
import Dashboard from '@/views/Dashboard.vue'

const routes = [
  {
    path: '/',
    name: 'UniformityAnalysis',
    component: Dashboard,
    meta: { title: '均匀性分析' }
  },
  {
    path: '/tire-weight',
    name: 'TireWeightAnalysis',
    component: () => import('@/views/TireWeightAnalysis.vue'),
    meta: { title: '轮胎重量分析' }
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/'
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
