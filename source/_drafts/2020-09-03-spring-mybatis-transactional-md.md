---
layout: post
title: Spring Transactional 
categories:
  - tech
tags:
  - blog
date: 2022-03-16 11:29:33
excerpt: Spring Transactional 
---

## Spring Transactional 

异常
```text
2022-03-16 11:26:06.200 INFO 31802 --- [-8080-exec-1156] o.a.c.c.C.[.[.[/].[dispatcherServlet]    : Servlet.service() for servlet [dispatcherServlet] in context with path [] threw exception [Request processing failed; nested exception is org.springframework.dao.CannotAcquireLockException:
### Error updating database.  Cause: com.mysql.cj.jdbc.exceptions.MySQLTransactionRollbackException: Lock wait timeout exceeded; try restarting transaction
### The error may involve cn.jiguang.dp.ods.offline.api.mapper.LoadJobMapper.setJobState-Inline
### The error occurred while setting parameters
### SQL: update load_jobs set state = ? where id = ?
### Cause: com.mysql.cj.jdbc.exceptions.MySQLTransactionRollbackException: Lock wait timeout exceeded; try restarting transaction
; Lock wait timeout exceeded; try restarting transaction; nested exception is com.mysql.cj.jdbc.exceptions.MySQLTransactionRollbackException: Lock wait timeout exceeded; try restarting transaction] with root cause

com.mysql.cj.jdbc.exceptions.MySQLTransactionRollbackException: Lock wait timeout exceeded; try restarting transaction
	at com.mysql.cj.jdbc.exceptions.SQLError.createSQLException(SQLError.java:123) ~[mysql-connector-java-8.0.15.jar!/:8.0.15]
	at com.mysql.cj.jdbc.exceptions.SQLError.createSQLException(SQLError.java:97) ~[mysql-connector-java-8.0.15.jar!/:8.0.15]
	at com.mysql.cj.jdbc.exceptions.SQLExceptionsMapping.translateException(SQLExceptionsMapping.java:122) ~[mysql-connector-java-8.0.15.jar!/:8.0.15]
	at com.mysql.cj.jdbc.ClientPreparedStatement.executeInternal(ClientPreparedStatement.java:970) ~[mysql-connector-java-8.0.15.jar!/:8.0.15]
	at com.mysql.cj.jdbc.ClientPreparedStatement.execute(ClientPreparedStatement.java:387) ~[mysql-connector-java-8.0.15.jar!/:8.0.15]
	at com.zaxxer.hikari.pool.ProxyPreparedStatement.execute(ProxyPreparedStatement.java:44) ~[HikariCP-3.4.5.jar!/:na]
	at com.zaxxer.hikari.pool.HikariProxyPreparedStatement.execute(HikariProxyPreparedStatement.java) ~[HikariCP-3.4.5.jar!/:na]
	at org.apache.ibatis.executor.statement.PreparedStatementHandler.update(PreparedStatementHandler.java:46) ~[mybatis-3.4.6.jar!/:3.4.6]
	at org.apache.ibatis.executor.statement.RoutingStatementHandler.update(RoutingStatementHandler.java:74) ~[mybatis-3.4.6.jar!/:3.4.6]
	at org.apache.ibatis.executor.SimpleExecutor.doUpdate(SimpleExecutor.java:50) ~[mybatis-3.4.6.jar!/:3.4.6]
	at org.apache.ibatis.executor.BaseExecutor.update(BaseExecutor.java:117) ~[mybatis-3.4.6.jar!/:3.4.6]
	at org.apache.ibatis.executor.CachingExecutor.update(CachingExecutor.java:76) ~[mybatis-3.4.6.jar!/:3.4.6]
	at sun.reflect.GeneratedMethodAccessor55.invoke(Unknown Source) ~[na:na]
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43) ~[na:1.8.0_181]
	at java.lang.reflect.Method.invoke(Method.java:498) ~[na:1.8.0_181]
	at org.apache.ibatis.plugin.Plugin.invoke(Plugin.java:63) ~[mybatis-3.4.6.jar!/:3.4.6]
	at com.sun.proxy.$Proxy124.update(Unknown Source) ~[na:na]
	at org.apache.ibatis.session.defaults.DefaultSqlSession.update(DefaultSqlSession.java:198) ~[mybatis-3.4.6.jar!/:3.4.6]
	at sun.reflect.GeneratedMethodAccessor108.invoke(Unknown Source) ~[na:na]
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43) ~[na:1.8.0_181]
	at java.lang.reflect.Method.invoke(Method.java:498) ~[na:1.8.0_181]
	at org.mybatis.spring.SqlSessionTemplate$SqlSessionInterceptor.invoke(SqlSessionTemplate.java:433) ~[mybatis-spring-1.3.2.jar!/:1.3.2]
	at com.sun.proxy.$Proxy68.update(Unknown Source) ~[na:na]
	at org.mybatis.spring.SqlSessionTemplate.update(SqlSessionTemplate.java:294) ~[mybatis-spring-1.3.2.jar!/:1.3.2]
	at org.apache.ibatis.binding.MapperMethod.execute(MapperMethod.java:63) ~[mybatis-3.4.6.jar!/:3.4.6]
	at org.apache.ibatis.binding.MapperProxy.invoke(MapperProxy.java:59) ~[mybatis-3.4.6.jar!/:3.4.6]
	at com.sun.proxy.$Proxy77.setJobState(Unknown Source) ~[na:na]
	at sun.reflect.GeneratedMethodAccessor299.invoke(Unknown Source) ~[na:na]
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43) ~[na:1.8.0_181]
	at java.lang.reflect.Method.invoke(Method.java:498) ~[na:1.8.0_181]
	at org.springframework.aop.support.AopUtils.invokeJoinpointUsingReflection(AopUtils.java:344) ~[spring-aop-5.2.7.RELEASE.jar!/:5.2.7.RELEASE]
	at org.springframework.aop.framework.ReflectiveMethodInvocation.invokeJoinpoint(ReflectiveMethodInvocation.java:198) ~[spring-aop-5.2.7.RELEASE.jar!/:5.2.7.RELEASE]
	at org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:163) ~[spring-aop-5.2.7.RELEASE.jar!/:5.2.7.RELEASE]
	at org.springframework.dao.support.PersistenceExceptionTranslationInterceptor.invoke(PersistenceExceptionTranslationInterceptor.java:139) ~[spring-tx-5.2.7.RELEASE.jar!/:5.2.7.RELEASE]
	at org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:186) ~[spring-aop-5.2.7.RELEASE.jar!/:5.2.7.RELEASE]
	at org.springframework.aop.framework.JdkDynamicAopProxy.invoke(JdkDynamicAopProxy.java:212) ~[spring-aop-5.2.7.RELEASE.jar!/:5.2.7.RELEASE]
	at com.sun.proxy.$Proxy78.setJobState(Unknown Source) ~[na:na]
	at cn.jiguang.dp.ods.offline.api.manager.impl.LoadJobManageImpl.approveJob(LoadJobManageImpl.java:167) ~[classes!/:1.0]
	at cn.jiguang.dp.ods.offline.api.manager.impl.LoadJobManageImpl$$FastClassBySpringCGLIB$$3b99abdc.invoke(<generated>) ~[classes!/:1.0]
	at org.springframework.cglib.proxy.MethodProxy.invoke(MethodProxy.java:218) ~[spring-core-5.2.7.RELEASE.jar!/:5.2.7.RELEASE]
	at org.springframework.aop.framework.CglibAopProxy$DynamicAdvisedInterceptor.intercept(CglibAopProxy.java:687) ~[spring-aop-5.2.7.RELEASE.jar!/:5.2.7.RELEASE]
	at cn.jiguang.dp.ods.offline.api.manager.impl.LoadJobManageImpl$$EnhancerBySpringCGLIB$$7f420099.approveJob(<generated>) ~[classes!/:1.0]
	at cn.jiguang.dp.ods.offline.api.service.impl.LoadJobServiceImpl.approveJob(LoadJobServiceImpl.java:47) ~[classes!/:1.0]
	at cn.jiguang.dp.ods.offline.api.client.LoadJobController.approveJob(LoadJobController.java:69) ~[classes!/:1.0]
	at sun.reflect.GeneratedMethodAccessor343.invoke(Unknown Source) ~[na:na]
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43) ~[na:1.8.0_181]
	at java.lang.reflect.Method.invoke(Method.java:498) ~[na:1.8.0_181]
	at org.springframework.web.method.support.InvocableHandlerMethod.doInvoke(InvocableHandlerMethod.java:190) ~[spring-web-5.2.7.RELEASE.jar!/:5.2.7.RELEASE]
	at org.springframework.web.method.support.InvocableHandlerMethod.invokeForRequest(InvocableHandlerMethod.java:138) ~[spring-web-5.2.7.RELEASE.jar!/:5.2.7.RELEASE]
	at org.springframework.web.servlet.mvc.method.annotation.ServletInvocableHandlerMethod.invokeAndHandle(ServletInvocableHandlerMethod.java:105) ~[spring-webmvc-5.2.7.RELEASE.jar!/:5.2.7.RELEASE]
	at org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.invokeHandlerMethod(RequestMappingHandlerAdapter.java:879) ~[spring-webmvc-5.2.7.RELEASE.jar!/:5.2.7.RELEASE]
	at org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.handleInternal(RequestMappingHandlerAdapter.java:793) ~[spring-webmvc-5.2.7.RELEASE.jar!/:5.2.7.RELEASE]
	at org.springframework.web.servlet.mvc.method.AbstractHandlerMethodAdapter.handle(AbstractHandlerMethodAdapter.java:87) ~[spring-webmvc-5.2.7.RELEASE.jar!/:5.2.7.RELEASE]
	at org.springframework.web.servlet.DispatcherServlet.doDispatch(DispatcherServlet.java:1040) ~[spring-webmvc-5.2.7.RELEASE.jar!/:5.2.7.RELEASE]
	at org.springframework.web.servlet.DispatcherServlet.doService(DispatcherServlet.java:943) ~[spring-webmvc-5.2.7.RELEASE.jar!/:5.2.7.RELEASE]
	at org.springframework.web.servlet.FrameworkServlet.processRequest(FrameworkServlet.java:1006) ~[spring-webmvc-5.2.7.RELEASE.jar!/:5.2.7.RELEASE]
	at org.springframework.web.servlet.FrameworkServlet.service(FrameworkServlet.java:880) ~[spring-webmvc-5.2.7.RELEASE.jar!/:5.2.7.RELEASE]
	at javax.servlet.http.HttpServlet.service(HttpServlet.java:741) ~[tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:231) ~[tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166) ~[tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at org.apache.tomcat.websocket.server.WsFilter.doFilter(WsFilter.java:53) ~[tomcat-embed-websocket-9.0.36.jar!/:9.0.36]
	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:193) ~[tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166) ~[tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at cn.jiguang.dp.ods.offline.api.interceptor.LoginFilter.doFilter(LoginFilter.java:64) ~[classes!/:1.0]
	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:193) ~[tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166) ~[tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at org.springframework.web.filter.RequestContextFilter.doFilterInternal(RequestContextFilter.java:100) ~[spring-web-5.2.7.RELEASE.jar!/:5.2.7.RELEASE]
	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:119) ~[spring-web-5.2.7.RELEASE.jar!/:5.2.7.RELEASE]
	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:193) ~[tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166) ~[tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at org.springframework.web.filter.FormContentFilter.doFilterInternal(FormContentFilter.java:93) ~[spring-web-5.2.7.RELEASE.jar!/:5.2.7.RELEASE]
	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:119) ~[spring-web-5.2.7.RELEASE.jar!/:5.2.7.RELEASE]
	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:193) ~[tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166) ~[tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at org.springframework.web.filter.CharacterEncodingFilter.doFilterInternal(CharacterEncodingFilter.java:201) ~[spring-web-5.2.7.RELEASE.jar!/:5.2.7.RELEASE]
	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:119) ~[spring-web-5.2.7.RELEASE.jar!/:5.2.7.RELEASE]
	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:193) ~[tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166) ~[tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at org.apache.catalina.core.StandardWrapperValve.invoke(StandardWrapperValve.java:202) ~[tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at org.apache.catalina.core.StandardContextValve.invoke(StandardContextValve.java:96) [tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at org.apache.catalina.authenticator.AuthenticatorBase.invoke(AuthenticatorBase.java:541) [tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at org.apache.catalina.core.StandardHostValve.invoke(StandardHostValve.java:139) [tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at org.apache.catalina.valves.ErrorReportValve.invoke(ErrorReportValve.java:92) [tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at org.apache.catalina.core.StandardEngineValve.invoke(StandardEngineValve.java:74) [tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at org.apache.catalina.connector.CoyoteAdapter.service(CoyoteAdapter.java:343) [tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at org.apache.coyote.http11.Http11Processor.service(Http11Processor.java:373) [tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at org.apache.coyote.AbstractProcessorLight.process(AbstractProcessorLight.java:65) [tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at org.apache.coyote.AbstractProtocol$ConnectionHandler.process(AbstractProtocol.java:868) [tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at org.apache.tomcat.util.net.NioEndpoint$SocketProcessor.doRun(NioEndpoint.java:1590) [tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at org.apache.tomcat.util.net.SocketProcessorBase.run(SocketProcessorBase.java:49) [tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149) [na:1.8.0_181]
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624) [na:1.8.0_181]
	at org.apache.tomcat.util.threads.TaskThread$WrappingRunnable.run(TaskThread.java:61) [tomcat-embed-core-9.0.36.jar!/:9.0.36]
	at java.lang.Thread.run(Thread.java:748) [na:1.8.0_181]
```

