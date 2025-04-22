---
layout: post
title: Servlet In Action 
date: 2019-01-01 00:00:02
indexing: true
tags:
  - java
  - servlet
categories:
  - tech
  - java
excerpt: 对于日新月异的Web技术来说，Servlet可以说是一个诞生历史非常悠久的技术了。2020-08-13 Java Servlet 从4.0.3之后正式更名为Jakarta Servlet（PS：Oracle拒绝出让Java商标给Eclipse基金会)，这里重新学习一下Servlet的知识。
---


# Instroduction 
在早期，Web服务器提供对用户请求无动于衷的静态内容。 Java servlet是服务器端程序（在Web服务器内运行），用于处理客户端的请求并返回每个请求的自定义或动态响应。 动态响应可以基于用户的输入（例如，搜索，在线购物，在线交易），其中数据库或其他应用程序或时间敏感数据（例如新闻和股票价格）。
Java Servlet通常在HTTP协议上运行。HTTP是一种不对称的请求 - 响应协议。 客户端向服务器发送请求消息，服务器返回如图所示的响应消息。
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20210712213022.png)

- Server-Side Technologies
有许多（竞争）服务器端技术可用：基于Java（Servlet，JSP，JSF，Struts，Spring，Hibernate），ASP，PHP，CGI脚本和许多其他技术。
Java Servlet是Java服务器端技术的基础，JSP（JavaServer Pages），JSF（JavaServer Faces），Struts，Spring，Hibernate、WebSocket，是Servlet技术的扩展。


# Abount Servlet 
Servlet 定义了一个服务器端API，用于处理HTTP请求和响应。（So Servlet也称为Servlet API)
Containers, 有时称为servlet引擎，是提供servlet功能的WebServer扩展。
Servlet通过Servlet Containers 实现的 Request/Response 范型与Web客户端交互.

- Servlet 的版本历史
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20210712212516.png)

- Servlet 过程
![image](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20210712205335.png)


- Servlet Containers Life Cycle
![image](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20210712205423.png)

- Servlet init/service/destroy 过程
![image](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20210712211431.png)

# Servlet 组件

## Session Tracking(session)
HTTP是一个无状态协议，换句话说，当前请求不知道在先前请求中已经完成了什么。这为运行多种请求的应用程序创造了问题，例如在线购物（或购物车）。 您需要维护所谓的会话以在多个请求之间传递数据。

维护session的几种机制：
- Cookie: cookie是存储在客户端计算机中的小文本文件，将在每个请求上发送到服务器。 您可以将您的会话数据放在cookie内。 使用cookie的最大问题是客户端可能会禁用cookie。
- URL重写：通过在每个URL的末尾附加短文本字符串来传递数据，例如，http：//host/path/file.html; jsessionid = 123456。 您需要重写所有URL（例如，“action”<form>的“action”属性以包含会话数据。
- 隐藏字段以HTML表单：通过使用隐藏的字段标记传递数据（<输入类型=“hidden”名称=“session”值=“....”/>）。 同样，您需要在所有页面中包含隐藏的字段。

Java Servlet API通过名为javax.servlet.http.httpsession的界面提供会话跟踪工具。 它允许servlet：
- 查看和操作关于会话的信息，例如会话标识符，创建时间和上次访问时间。
- 将对象绑定到会话，允许用户信息持续跨多个用户请求。

```java
HttpSession session = request.getSession(true);
```

- Session 过程：
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20210712213309.png)

## Spring Web MVC
Spring Web MVC 是Servlet API上构建的原始Web框架. 主要特性：DispatcherServlet、Filters、Annotated Controllers、Function Endpoints、Web Security、CORS

### ServletContext
ServletContext对象的创建是在服务器启动时完成的
ServletContext对象的销毁是在服务器关闭时完成的

- ServletContext 与Tomcat Servlet容器的初始化和Request/Response过程
![image](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20210712210858.png)




# 参考
- [Servlet Projects ](https://projects.eclipse.org/projects/ee4j.servlet)
- [Servlet API](https://github.com/eclipse-ee4j/servlet-api)
- [Servlet ](https://www3.ntu.edu.sg/home/ehchua/programming/java/JavaServlets.html)
- [Spring web MVC ](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html)
- [JavaServlet](https://www3.ntu.edu.sg/home/ehchua/programming/java/JavaServlets.html)
