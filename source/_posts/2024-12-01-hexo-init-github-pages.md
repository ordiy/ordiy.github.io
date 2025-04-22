---
title: Hexo blog site start and deploy github pages 
excerpt: 配置Hexo blog , 并deploy github pages 
layout: post
date: 2024-01-01 00:00:00
tags:
 - hexo
categories:
 - blog
---

# config and init 
node js install and config hexo. 
```shell

 curl -fsSL https://deb.nodesource.com/setup_22.x -o nodesource_setup.sh
 sudo -E bash nodesource_setup.sh
 node -version

 sudo npm install -g hexo-cli
 npm version 

# logs ====
added 53 packages in 10s
14 packages are looking for funding
  run `npm fund` for details
npm notice
npm notice New major version of npm available! 10.9.2 - 11.3.0
npm notice Changelog: https://github.com/npm/cli/releases/tag/v11.3.0
npm notice To update run: npm install -g npm@11.3.0
npm notice


## -- npm update 
 npm install -g npm@11.3.0

 npm install -g hexo-cli
 npm install hexo

hexo init test-hexo-page-v1
cd test-hexo-page-v1

npm install && npm fund

# 配置theme-next 
#参考
#https://github.com/next-theme/hexo-theme-next
npm install hexo-theme-next --save


```

# test start 
```shell 
 hexo server 
```

# git 
```shell 
- 修改 _config.yml , 配置 git repository
- 配置 theme , cp ./themes/next/_config.next.yml ./

#配置 gitignore 
cat  >> .gitignore << 'EOF

public/
public
themes/
node_modules/

node_modules/
public/
.deploy_git/
themes/next/

EOF'

```

# 配置github pages action 

利用 github actions 将项目 deploy github page .

```shell

 mkdir .github/workflow
 vim .github/workflow/hexo-pages.yml
```
hexo-pages.yml

```yml

name: Hexo Pages CI

on:
  push:
    branches:
      - main # default branch

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          # If your repository depends on submodule, please see: https://github.com/actions/checkout
          submodules: recursive
      - name: Use Node.js 22
        uses: actions/setup-node@v4
        with:
          # Examples: 20, 18.19, =16.20.2, lts/Iron, lts/Hydrogen, *, latest, current, node
          # Ref: https://github.com/actions/setup-node#supported-version-syntax
          node-version: "22"
      - name: Cache NPM dependencies
        uses: actions/cache@v4
        with:
          path: node_modules
          key: ${{ runner.OS }}-npm-cache
          restore-keys: |
            ${{ runner.OS }}-npm-cache
      - name: Install Dependencies
        run: npm install
      - name: Build
        run: npm run build
      - name: Upload Pages artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./public
  deploy:
    needs: build
    permissions:
      pages: write
      id-token: write
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```


#  参考
https://hexo.io/zh-cn/docs/index.html
