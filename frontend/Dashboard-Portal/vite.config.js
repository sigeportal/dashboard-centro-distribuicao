import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'
import { VitePWA } from 'vite-plugin-pwa'

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');

  return {
    plugins: [
      react(),
      VitePWA({
        registerType: 'autoUpdate',
        includeAssets: [
          'favicon.ico',
          'apple-touch-icon.png',
          'portal_gerencial_icon.svg',
          'portal_gerencial_logo.svg',
          'user-avatar.png',
          'screenshot-desktop.png',
          'screenshot-mobile.png'
        ],
        manifest: {
          name: 'Portal Gerencial',
          short_name: 'Portal Gerencial',
          description: 'Dashboard analítico do Portal Gerencial',
          theme_color: '#f97316',
          background_color: '#f8f9ff',
          display: 'standalone',
          start_url: '/',
          icons: [
            {
              src: 'pwa-192x192.png',
              sizes: '192x192',
              type: 'image/png',
              purpose: 'any'
            },
            {
              src: 'pwa-512x512.png',
              sizes: '512x512',
              type: 'image/png',
              purpose: 'any'
            },
            {
              src: 'pwa-512x512.png',
              sizes: '512x512',
              type: 'image/png',
              purpose: 'maskable'
            }
          ],
          screenshots: [
            {
              src: 'screenshot-desktop.png',
              sizes: '1920x1080',
              type: 'image/png',
              form_factor: 'wide',
              label: 'Portal Gerencial no Desktop'
            },
            {
              src: 'screenshot-mobile.png',
              sizes: '1080x1920',
              type: 'image/png',
              form_factor: 'narrow',
              label: 'Portal Gerencial no Celular'
            }
          ]
        }
      })
    ],
    server: {
      allowedHosts: env.VITE_ALLOWED_HOST
        ? [env.VITE_ALLOWED_HOST]
        : []
    }
  }
})

