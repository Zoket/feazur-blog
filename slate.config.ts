/*
 * @file Theme configuration
 */
import { defineConfig } from './src/helpers/config-helper';

export default defineConfig({
  lang: 'zh-CN',
  site: 'https://blog.feazur.com',
  avatar: '/avatar.min.svg',
  title: 'Welcome to Feazur.com',
  description: 'Simple share, simple thought.',
  lastModified: false,
  readTime: true,
  footer: {
    copyright: '© 2025 Zoket Power by Slate blog',
  },
  socialLinks: [
    {
      icon: 'github',
      link: 'https://github.com/Zoket'
    },
]
});