import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'https://localhost:7155', // your .NET Core API
        changeOrigin: true,
        secure: false, // allow self-signed dev certificates
      },
    },
  },
})
