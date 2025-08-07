# 简化版 RocketMQ Kubernetes 部署

基于 OpenCoze 项目配置的简化版 RocketMQ 部署，只包含核心的 deployment 和 service 文件。

## 📁 文件说明

```
simple-rocketmq/
├── rocketmq-deployment.yaml    # RocketMQ 部署配置（包含 NameServer、Broker 和 ConfigMap）
├── rocketmq-service.yaml       # RocketMQ 服务配置
└── README.md                   # 说明文档
```

## 🏗️ 组件说明

### 包含的组件
- **NameServer**：服务注册中心（端口 9876）
- **Broker**：消息存储和转发（端口 10911、10912、10909）
- **ConfigMap**：Broker 配置文件

### 配置特点
- 使用项目推荐的 `apache/rocketmq:5.3.2` 镜像
- Broker 配置与项目 Helm Chart 一致
- 资源配置按项目标准设置
- 包含健康检查和初始化容器

## 🚀 部署方法

### 在 Kuboard 中部署

1. 登录 Kuboard 管理界面
2. 选择目标集群和命名空间（default）
3. 进入"工作负载" → "无状态工作负载" → 导入 `rocketmq-deployment.yaml`
4. 进入"网络" → "服务" → 导入 `rocketmq-service.yaml`

### 使用 kubectl 部署

```bash
# 部署 RocketMQ
kubectl apply -f simple-rocketmq/rocketmq-deployment.yaml
kubectl apply -f simple-rocketmq/rocketmq-service.yaml

# 检查部署状态
kubectl get pods -l app=rocketmq
kubectl get svc -l app=rocketmq
```

## 📊 部署后检查

### 1. 检查 Pod 状态
```bash
kubectl get pods -l app=rocketmq
```

期望输出：
```
NAME                                READY   STATUS    RESTARTS   AGE
rocketmq-namesrv-xxxxxxxxx-xxxxx    1/1     Running   0          2m
rocketmq-broker-xxxxxxxxx-xxxxx     1/1     Running   0          2m
```

### 2. 检查服务状态
```bash
kubectl get svc -l app=rocketmq
```

期望输出：
```
NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                         AGE
rocketmq-namesrv   ClusterIP   10.96.xxx.xxx  <none>        9876/TCP                        2m
rocketmq-broker    ClusterIP   10.96.xxx.xxx  <none>        10911/TCP,10912/TCP,10909/TCP  2m
```

### 3. 查看日志
```bash
# NameServer 日志
kubectl logs -l component=namesrv -f

# Broker 日志
kubectl logs -l component=broker -f
```

## 🔗 OpenCoze 连接配置

在 OpenCoze 的配置中使用以下连接地址：

```yaml
# 环境变量配置
MQ_NAME_SERVER: "http://rocketmq-namesrv:9876"

# 或者使用完整的服务地址
MQ_NAME_SERVER: "http://rocketmq-namesrv.default.svc.cluster.local:9876"
```

## 📋 Topics 自动创建

Broker 启动时会自动创建 OpenCoze 需要的所有 Topics 和 Consumer Groups：

### 自动创建的 Topics：
- `opencoze_knowledge` - 知识库相关消息
- `opencoze_search_app` - 应用搜索相关消息  
- `opencoze_search_resource` - 资源搜索相关消息
- `%RETRY%cg_knowledge` - 知识库重试消息
- `%RETRY%cg_search_app` - 应用搜索重试消息
- `%RETRY%cg_search_resource` - 资源搜索重试消息

### 自动创建的 Consumer Groups：
- `cg_knowledge` - 知识库消费者组
- `cg_search_app` - 应用搜索消费者组
- `cg_search_resource` - 资源搜索消费者组

### 验证 Topics 创建：
```bash
# 查看所有 Topics
kubectl exec -it deployment/rocketmq-broker -- sh -c "/home/rocketmq/rocketmq-5.3.2/bin/mqadmin topicList -n rocketmq-namesrv:9876"

# 查看消费者组
kubectl exec -it deployment/rocketmq-broker -- sh -c "/home/rocketmq/rocketmq-5.3.2/bin/mqadmin consumerProgress -n rocketmq-namesrv:9876"
```

## ⚙️ 资源配置

### 默认资源分配

**NameServer:**
- CPU: 请求 1核，限制 2核
- 内存: 请求 2GB，限制 4GB

**Broker:**
- CPU: 请求 2核，限制 4核
- 内存: 请求 4GB，限制 8GB

### 调整资源配置

根据实际需求可以修改 `rocketmq-deployment.yaml` 中的资源配置：

```yaml
resources:
  limits:
    cpu: 4000m      # 调整 CPU 限制
    memory: 8Gi     # 调整内存限制
  requests:
    cpu: 2000m      # 调整 CPU 请求
    memory: 4Gi     # 调整内存请求
```

## 🛠️ 故障排除

### 1. NameServer 启动失败
```bash
kubectl describe pod -l component=namesrv
kubectl logs -l component=namesrv
```

### 2. Broker 连接失败
```bash
kubectl describe pod -l component=broker
kubectl logs -l component=broker
```

常见问题：
- NameServer 未完全启动
- 网络连通性问题
- 资源不足

### 3. 验证连通性
```bash
# 测试 NameServer 连通性
kubectl exec -it deployment/rocketmq-broker -- nc -z rocketmq-namesrv 9876

# 查看集群状态
kubectl exec -it deployment/rocketmq-broker -- sh mqadmin clusterList -n rocketmq-namesrv:9876
```

## 🗑️ 删除部署

```bash
kubectl delete -f simple-rocketmq/rocketmq-service.yaml
kubectl delete -f simple-rocketmq/rocketmq-deployment.yaml
```

## 📝 注意事项

1. **数据持久化**：当前使用容器内存储，重启后数据会丢失
2. **生产环境**：建议配置持久化存储
3. **网络策略**：确保 Pod 间可以正常通信
4. **资源监控**：建议监控 CPU 和内存使用情况

## 💡 扩展建议

1. **持久化存储**：配置 PVC 实现数据持久化
2. **高可用**：增加 NameServer 和 Broker 副本数
3. **监控告警**：集成监控系统
4. **性能调优**：根据消息量调整 JVM 参数