---
---

# microk8s guide 
microk8s: The best Kubernetes experience for developers, DevOps, cloud and edge
```shell

sudo snap install microk8s --classic
microk8s status --wait-ready


microk8s enable dashboard
microk8s enable dns
microk8s enable registry
microk8s enable istio


# use 
microk8s kubectl get all --all-namespaces
alias mkctl="microk8s kubectl"

# dashboard
microk8s dashboard-proxy

# stop 
microk8s start and microk8s stop
```

# demo 
```shell
alias mkctl="microk8s kubectl"

mkctl expose deployment nginx --port 80 --target-port 80 --selector app=nginx --type ClusterIP --name nginx
watch microk8s kubectl get all

```

# kubernetes 
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202509021552570.png)
`Kubernetes 是一个用于运行应用程序和服务的平台。它通过自动执行任务、控制资源和抽象基础结构来管理基于容器的应用程序的整个生命周期。企业采用 Kubernetes 来降低运营成本、缩短上市时间并实现业务转型。开发人员喜欢基于容器的开发，因为它有助于将单体应用程序分解为更易于维护的微服务。Kubernetes 允许他们的工作从开发无缝转移到生产，并加快业务应用程序的上市时间。`

```
跨多个主机编排容器化应用程序
确保容器化应用在从测试到生产的所有环境中以相同的方式运行
```

# 参考
https://microk8s.io/docs
