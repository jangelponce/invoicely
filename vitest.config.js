import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./app/javascript/test/setup.ts'],
  },
  resolve: {
    alias: {
      '@': './app/javascript',
    },
  },
})
