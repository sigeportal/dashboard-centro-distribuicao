import sharp from 'sharp';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const svgPath = path.resolve(__dirname, '../public/portal_gerencial_icon.svg');

const targets = [
  { name: 'pwa-192x192.png', size: 192 },
  { name: 'pwa-512x512.png', size: 512 },
  { name: 'apple-touch-icon.png', size: 180 }
];

import fs from 'fs/promises';

async function resizeScreenshots() {
  const desktopPath = path.resolve(__dirname, '../public/screenshot-desktop.png');
  const mobilePath = path.resolve(__dirname, '../public/screenshot-mobile.png');

  try {
    // Redimensiona o screenshot desktop para 1920x1080 (cover) com segurança de leitura/escrita
    const desktopData = await fs.readFile(desktopPath);
    const desktopBuffer = await sharp(desktopData)
      .resize(1920, 1080, { fit: 'cover' })
      .png()
      .toBuffer();
    await fs.writeFile(desktopPath, desktopBuffer);
    console.log('Resized: screenshot-desktop.png to 1920x1080');

    // Redimensiona o screenshot mobile para 1080x1920 (cover) com segurança de leitura/escrita
    const mobileData = await fs.readFile(mobilePath);
    const mobileBuffer = await sharp(mobileData)
      .resize(1080, 1920, { fit: 'cover' })
      .png()
      .toBuffer();
    await fs.writeFile(mobilePath, mobileBuffer);
    console.log('Resized: screenshot-mobile.png to 1080x1920');
  } catch (err) {
    console.error('Error resizing screenshots:', err);
  }
}

async function generate() {
  try {
    for (const target of targets) {
      const outputPath = path.resolve(__dirname, '../public', target.name);
      await sharp(svgPath)
        .resize(target.size, target.size)
        .png()
        .toFile(outputPath);
      console.log(`Generated: ${target.name} (${target.size}x${target.size})`);
    }
    console.log('All PWA icons generated successfully!');
    
    // Redimensiona as capturas de tela após gerar os ícones
    await resizeScreenshots();
  } catch (err) {
    console.error('Error generating icons:', err);
    process.exit(1);
  }
}

generate();
