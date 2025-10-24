---
title: "V2EX › API 2.0 Beta"
source: "https://www.v2ex.com/help/api"
author:
published:
created: 2025-10-23
description: "一系列正在持续更新中的新 V2EX API"
tags:
  - "clippings"
---
## API 2.0 Beta

API 2.0 Beta 是我们正在持续更新中的新接口，会提供一系列通过 [Personal Access Token](https://www.v2ex.com/help/personal-access-token) 访问 V2EX 功能的新方式。

如果你在使用过程中遇到任何疑问，欢迎来到 [V2EX API](https://www.v2ex.com/go/v2exapi) 节点讨论。

## Authentication / 认证方式

Personal Access Token 可以在 Authorization header 中使用，例子如下：

> `Authorization: Bearer bd1f2c67-cc7f-48e3-a48a-e5b88b427146`

## API 接口

所有 2.0 的 RESTful 的 API 接口都位于下面的这个前缀下：

> `https://www.v2ex.com/api/v2/`

| 接口 | HTTP 方法 | 结果 |
| --- | --- | --- |
| notifications | GET | [获取最新的提醒](https://www.v2ex.com/help/#latest-notifications) |
| notifications/:notification\_id | DELETE | [删除指定的提醒](https://www.v2ex.com/help/#delete-notification) |
| member | GET | [获取自己的 Profile](https://www.v2ex.com/help/#my-profile) |
| token | GET | [查看当前使用的令牌](https://www.v2ex.com/help/#current-token) |
| nodes/:node\_name | GET | [获取指定节点](https://www.v2ex.com/help/#get-node) |
| nodes/:node\_name/topics | GET | [获取指定节点下的主题](https://www.v2ex.com/help/#get-node-topics) |
| topics/:topic\_id | GET | [获取指定主题](https://www.v2ex.com/help/#get-topic) |
| topics/:topic\_id/replies | GET | [获取指定主题下的回复](https://www.v2ex.com/help/#get-topic-replies) |

推荐你可以在 VS Code 中安装和使用 [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) 来测试这些 API。

## API Rate Limit

默认情况下，每个 IP 每小时可以发起的 API 请求数被限制在 600 次。你可以在 API 返回结果的 HTTP 头部找到 Rate Limit 信息：

> X-Rate-Limit-Limit: 120 
> X-Rate-Limit-Reset: 1409479200 
> X-Rate-Limit-Remaining: 116

对于能够被 CDN 缓存的 API 请求，只有第一次请求时，才会消耗 Rate Limit 配额。

下面是具体的接口访问信息。

## 获取最新的提醒

> `GET notifications`

可选参数：

- `p` - 分页页码，默认为 1

完整例子：

> GET https://www.v2ex.com/api/v2/notifications?p=2 
> Authorization: Bearer bd1f2c67-cc7f-48e3-a48a-e5b88b427146

## 删除指定的提醒

> DELETE notifications/:notification_id

完整例子：

> DELETE https://www.v2ex.com/api/v2/notifications/123456 
> Authorization: Bearer bd1f2c67-cc7f-48e3-a48a-e5b88b427146

> GET member

完整例子：

> GET https://www.v2ex.com/api/v2/member 
> Authorization: Bearer bd1f2c67-cc7f-48e3-a48a-e5b88b427146

## 查看当前使用的令牌

> GET token

完整例子：

> GET https://www.v2ex.com/api/v2/token 
> Authorization: Bearer bd1f2c67-cc7f-48e3-a48a-e5b88b427146

## 创建新的令牌

> POST tokens

你可以在系统中最多创建 10 个 Personal Access Token。

输入参数：

- scope - 可选 everything 或者 regular，如果是 regular 类型的 Token 将不能用于进一步创建新的 token
- expiration - 可支持的值：2592000，5184000，7776000 或者 15552000，即 30 天，60 天，90 天或者 180 天的秒数

完整例子：

> POST https://www.v2ex.com/api/v2/tokens 
> Authorization: Bearer bd1f2c67-cc7f-48e3-a48a-e5b88b427146  
> {"scope": "everything", "expiration": 2592000} 

## 获取指定节点

> GET nodes/:node_name

完整例子：

> GET https://www.v2ex.com/api/v2/nodes/python 
> Authorization: Bearer bd1f2c67-cc7f-48e3-a48a-e5b88b427146

## 获取指定节点下的主题

> GET nodes/:node_name/topics

可选参数：

- `p` - 分页页码，默认为 1

完整例子：

> GET https://www.v2ex.com/api/v2/nodes/python/topics?p=2 
> Authorization: Bearer bd1f2c67-cc7f-48e3-a48a-e5b88b427146 

## 获取指定主题

> GET topics/:topic_id

完整例子：

> GET https://www.v2ex.com/api/v2/topics/1 
> Authorization: Bearer bd1f2c67-cc7f-48e3-a48a-e5b88b427146

## 获取指定主题下的回复

> GET topics/:topic_id/replies

可选参数：

- `p` - 分页页码，默认为 1

完整例子：

> GET https://www.v2ex.com/api/v2/topics/1/replies?p=2 
> Authorization: Bearer bd1f2c67-cc7f-48e3-a48a-e5b88b427146

---