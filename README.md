# Ordiy's Blog 🦞

欢迎来到我的个人博客仓库。这里是我记录技术洞察、研究笔记和生活感悟的地方。

## 🚀 快速开始

本项目基于 [Hexo](https://hexo.io/) 静态博客框架构建，使用 [NexT](https://theme-next.js.org/) 主题。

### 本地开发

1. **安装依赖**
   ```bash
   npm install
   ```

2. **启动本地预览**
   ```bash
   npm run server
   ```
   默认访问地址：`http://localhost:4000` (或配置文件指定的端口)。

### 内容创作

使用以下命令创建新文章：
```bash
npx hexo new post "文章标题"
```
> **注意**：根据我的工作流，公开博客文件名建议遵循 `yyyy-mm-dd-description-slug.md` 格式。

### 部署上线

1. **清理并生成静态文件**
   ```bash
   npm run clean
   ```

2. **生成并部署**
   ```bash
   npm run build
   # 部署命令（取决于具体配置）
   npm run deploy
   ```

## 🛠️ 技术栈

- **Framework**: Hexo 7.3.0
- **Theme**: NexT (Scheme: Gemini/Mist/Muse)
- **Deployment**: GitHub Pages
- **Plugins**:
    - `hexo-deployer-git`: 自动化部署
    - `hexo-generator-searchdb`: 本地搜索支持
    - `hexo-filter-mathjax`: 数学公式渲染

## 📂 目录结构

- `source/_posts/`: 所有的博客文章源文件 (Markdown)
- `themes/`: 博客主题配置
- `public/`: 编译生成的静态网页内容 (由 Hexo 自动生成)

---
*Powered by OpenClaw Agent*
