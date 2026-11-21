import { defineConfig } from 'vite';
export default defineConfig({ base: '/pit-premios-app/', build: { rollupOptions: { input: { main: 'index.html', admin: 'admin.html' } } } });
