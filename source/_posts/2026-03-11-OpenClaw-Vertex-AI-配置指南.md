---
layout: post
title: OpenClaw + Google Vertex AI 配置与排查指南
date: 2026-03-11 11:42:00 +08:00
categories: 
 - tech
 - ai
tags: 
 - openclaw
 - google-vertex
 - gemini
 - hexo-publish
---

# OpenClaw + Google Vertex AI 配置与排查指南

> **适用版本**：OpenClaw 2026.3.2+  
> **日期**：2026-03-11  
> **作者**：根据实际排查过程整理

---

## 背景

本文记录了为 OpenClaw 启用 Google Vertex AI 的完整配置过程，以及排查过程中遇到的若干坑点，包括：

- 如何用**服务账号（Service Account）**做认证（无需安装 gcloud CLI）
- `us-central1` 区域支持哪些模型
- **Gemini 3 系列模型**为何必须使用 `global` 端点
- 旧 plugin 配置报警的清理方式

---

## 一、前提条件

### 1.1 Google Cloud 准备

1. 创建（或已有）一个 GCP 项目，开启 **Vertex AI API**
2. 创建一个服务账号，授予 `Vertex AI User` 角色
3. 下载服务账号 JSON 密钥文件，存放至安全路径，例如：
   ```
   /home/openclaw/myproject-xxxxxx.json
   ```

### 1.2 认证方式说明

OpenClaw 的 `google-vertex` provider 使用 **gcloud ADC（Application Default Credentials）**认证。

ADC 的读取优先级：
1. 环境变量 `GOOGLE_APPLICATION_CREDENTIALS` 指向的服务账号 JSON ← **本文采用此方式**
2. gcloud CLI 登录后的用户凭证（需要安装 gcloud）
3. GCE/Cloud Run 等托管环境的元数据服务

> ✅ 无需安装 gcloud CLI，直接用服务账号 JSON 即可。

---

## 二、最小配置（快速上手）

编辑 `~/.openclaw/openclaw.json`，在顶层加入 `env` 块：

```json
{
  "env": {
    "GOOGLE_APPLICATION_CREDENTIALS": "/path/to/your-service-account.json",
    "GOOGLE_CLOUD_PROJECT": "your-gcp-project-id",
    "GOOGLE_CLOUD_LOCATION": "global"
  },
  "agents": {
    "defaults": {
      "model": "google-vertex/gemini-3-flash-preview"
    }
  }
}
```

验证配置有效：
```bash
openclaw config validate
# 期望输出：Config valid: ~/.openclaw/openclaw.json

openclaw models list
# 期望输出：google-vertex/gemini-3-flash-preview  ...  Auth: yes
```

---

## 三、坑点详解

### 坑 1：`GOOGLE_CLOUD_LOCATION=us-central1` 对 Gemini 3 系列无效

#### 现象

将 `GOOGLE_CLOUD_LOCATION` 设置为 `us-central1`，调用 `gemini-3-flash-preview` 时返回 HTTP 404：

```
Publisher Model `.../locations/us-central1/.../gemini-3-flash-preview` was not found
```

但 `openclaw models list --all` 中明明列出了这个模型。

#### 原因

Google 官方文档明确说明：

> *"The Gemini 3.1 Pro Preview model `gemini-3.1-pro-preview` and Gemini 3 Flash Preview model `gemini-3-flash-preview` are **only available on global endpoints**."*  
> — [Get started with Gemini 3 | Vertex AI Docs](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/start/get-started-with-gemini-3)

Gemini 3 系列是 Preview 阶段，尚未在具体区域（如 `us-central1`）部署，只能通过 `global` 路由访问。

#### 解决方案

```json
"GOOGLE_CLOUD_LOCATION": "global"
```

#### 额外发现：两种端点的区别

| 端点格式 | Gemini 3 Flash | Gemini 2.5 |
|---------|---------------|------------|
| `https://us-central1-aiplatform.googleapis.com/v1/...` | ❌ 404 | ✅ 正常 |
| `https://aiplatform.googleapis.com/v1/.../locations/us-central1/...` | ✅ 正常 | ✅ 正常 |
| `https://aiplatform.googleapis.com/v1/.../locations/global/...` | ✅ 正常 | ✅ 正常 |

**结论**：使用 `global` 端点可以同时兼容所有模型，是最通用的选择。

---

### 坑 2：旧 plugin 配置导致启动警告

#### 现象

每次运行 openclaw 命令都出现：

```
Config warnings: plugins.entries.google-antigravity-auth: plugin removed:
google-antigravity-auth (stale config entry ignored; remove it from plugins config)
```

#### 原因

`google-antigravity-auth` 插件已从 OpenClaw 移除，但配置文件中仍有残留条目。

#### 解决方案

从 `~/.openclaw/openclaw.json` 的 `plugins.entries` 中删除该条目：

```json
// 删除前
"plugins": {
  "entries": {
    "google-antigravity-auth": { "enabled": true },  // ← 删除这一项
    "google-gemini-cli-auth":  { "enabled": true }
  }
}

// 删除后
"plugins": {
  "entries": {
    "google-gemini-cli-auth": { "enabled": true }
  }
}
```

---

### 坑 3：模型 ID 的 preview 版本号

#### 现象

尝试带日期后缀的模型 ID 全部返回 404：

```
gemini-2.5-pro-preview-03-25   → 404
gemini-2.5-flash-preview-04-17 → 404
gemini-3-flash-preview-0514    → 404
```

#### 原因

Vertex AI 使用**不带日期后缀的稳定别名**，Google 会在后端自动指向最新 preview 版本。不同于直接调用 Gemini API（`generativelanguage.googleapis.com`）可以指定具体版本号，Vertex AI 端点只接受官方文档中列出的短 ID。

#### 解决方案

始终使用文档中的标准 Model ID，不要加日期后缀：

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| `gemini-3-flash-preview` | `gemini-3-flash-preview-0514` |
| `gemini-2.5-pro` | `gemini-2.5-pro-preview-03-25` |
| `gemini-2.5-flash` | `gemini-2.5-flash-preview-04-17` |

---

## 四、此项目实测可用模型（us-central1 / global）

测试时间：2026-03-11，项目：`mydevproject20260304`

| 模型 ID | us-central1 | global | 备注 |
|--------|-------------|--------|------|
| `gemini-3-flash-preview` | ✅ | ✅ | Gemini 3，推荐用 global |
| `gemini-3.1-pro-preview` | ✅ | ✅ | Gemini 3.1，推荐用 global |
| `gemini-2.5-pro` | ✅ | ✅ | 最强推理，较慢 |
| `gemini-2.5-flash` | ✅ | ✅ | 速度与能力均衡 |
| `gemini-2.5-flash-lite` | ✅ | ✅ | 最快最省费 |
| `gemini-2.0-flash` | ✅ | ✅ | 上一代 Flash |

> **注意**：模型可用性取决于项目配额和区域部署进度，不同项目可能存在差异。

---

## 五、完整参考配置

以下为生产可用的完整 `~/.openclaw/openclaw.json` env 相关部分：

```json
{
  "env": {
    "GOOGLE_APPLICATION_CREDENTIALS": "/home/YOUR_USER/your-project-key.json",
    "GOOGLE_CLOUD_PROJECT": "your-gcp-project-id",
    "GOOGLE_CLOUD_LOCATION": "global"
  },
  "agents": {
    "defaults": {
      "model": "google-vertex/gemini-3-flash-preview",
      "compaction": {
        "mode": "safeguard"
      }
    }
  }
}
```

### 验证脚本（无需安装 google-auth SDK）

以下脚本使用 openssl 直接签名 JWT，验证服务账号是否可以正常访问 Vertex AI：

```python
#!/usr/bin/env python3
"""
验证 Google Vertex AI 服务账号连通性
依赖：openssl（系统自带）
"""
import json, base64, time, urllib.request, urllib.error, urllib.parse, subprocess, tempfile, os

KEY_PATH = "/path/to/your-service-account.json"
PROJECT_ID = "your-gcp-project-id"
LOCATION = "global"
MODEL_ID = "gemini-3-flash-preview"

with open(KEY_PATH) as f:
    key_data = json.load(f)

# 构造 JWT 并获取 Access Token
private_key = key_data['private_key']
client_email = key_data['client_email']
token_uri = key_data.get('token_uri', 'https://oauth2.googleapis.com/token')

header = base64.urlsafe_b64encode(json.dumps({"alg": "RS256", "typ": "JWT"}).encode()).decode().rstrip("=")
now = int(time.time())
payload = base64.urlsafe_b64encode(json.dumps({
    "iss": client_email,
    "scope": "https://www.googleapis.com/auth/cloud-platform",
    "aud": token_uri,
    "exp": now + 3600,
    "iat": now
}).encode()).decode().rstrip("=")

unsigned_jwt = f"{header}.{payload}"
with tempfile.NamedTemporaryFile(mode='w', suffix='.pem', delete=False) as f:
    f.write(private_key)
    key_file = f.name

sig = subprocess.run(
    ['openssl', 'dgst', '-sha256', '-sign', key_file, '-'],
    input=unsigned_jwt.encode(), capture_output=True
)
os.unlink(key_file)

jwt = f"{unsigned_jwt}.{base64.urlsafe_b64encode(sig.stdout).decode().rstrip('=')}"
post_data = urllib.parse.urlencode({
    "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
    "assertion": jwt
}).encode()

with urllib.request.urlopen(
    urllib.request.Request(token_uri, data=post_data,
    headers={"Content-Type": "application/x-www-form-urlencoded"})
) as r:
    access_token = json.loads(r.read())['access_token']
    print("✅ 服务账号认证成功")

# 调用 Vertex AI
url = f"https://aiplatform.googleapis.com/v1/projects/{PROJECT_ID}/locations/{LOCATION}/publishers/google/models/{MODEL_ID}:generateContent"
data = {"contents": [{"role": "user", "parts": [{"text": "Say: Vertex AI is working"}]}]}
req = urllib.request.Request(url, data=json.dumps(data).encode(),
    headers={"Authorization": f"Bearer {access_token}", "Content-Type": "application/json"})

try:
    with urllib.request.urlopen(req) as resp:
        text = json.loads(resp.read())['candidates'][0]['content']['parts'][0]['text'].strip()
        print(f"✅ 模型响应：{text}")
except urllib.error.HTTPError as e:
    print(f"❌ HTTP {e.code}: {e.read().decode()[:300]}")
```

---

## 六、参考文档

- [OpenClaw 模型提供商文档](https://docs.openclaw.ai/concepts/model-providers#google-vertex-antigravity-and-gemini-cli)
- [Gemini 3 Flash 模型说明](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/3-flash)
- [Gemini 3 快速入门（Vertex AI）](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/start/get-started-with-gemini-3)
- [Vertex AI 支持的区域与端点](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/locations)
