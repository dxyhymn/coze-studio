# RocketMQ Kubernetes 部署配置

完整的 RocketMQ 集群 Kubernetes 部署方案，包含 NameServer、Broker 和管理控制台。

## 📁 文件说明

```
rocketmq-k8s/
├── namespace.yaml              # 命名空间配置
├── namesrv-deployment.yaml     # NameServer 部署配置
├── namesrv-service.yaml        # NameServer 服务配置
├── broker-configmap.yaml       # Broker 配置文件
├── broker-deployment.yaml      # Broker 部署配置
├── broker-service.yaml         # Broker 服务配置
├── console-deployment.yaml     # 管理控制台部署配置
├── console-service.yaml        # 管理控制台服务配置
├── deploy.sh                   # 一键部署脚本
└── README.md                   # 说明文档
```

## 🏗️ 架构说明

### 组件介绍

1. **NameServer**：服务注册中心，管理 Broker 的路由信息
2. **Broker**：消息存储和转发核心，处理消息的读写
3. **Console**：Web 管理界面，方便监控和管理 RocketMQ

### 网络架构

```
外部访问 → NodePort:30080 → Console → NameServer:9876 → Broker:10911
                              ↑
                          OpenCoze 连接
```

## 🚀 部署方法

### 方法1：在 Kuboard 界面部署

1. **创建命名空间**
   - 进入 Kuboard → 选择集群
   - "配置中心" → "命名空间" → 导入 `namespace.yaml`

2. **部署 NameServer**
   - "工作负载" → "无状态工作负载" → 导入 `namesrv-deployment.yaml`
   - "网络" → "服务" → 导入 `namesrv-service.yaml`

3. **部署 Broker**
   - "配置中心" → "字典" → 导入 `broker-configmap.yaml`
   - "工作负载" → "无状态工作负载" → 导入 `broker-deployment.yaml`
   - "网络" → "服务" → 导入 `broker-service.yaml`

4. **部署管理控制台**（可选）
   - "工作负载" → "无状态工作负载" → 导入 `console-deployment.yaml`
   - "网络" → "服务" → 导入 `console-service.yaml`

### 方法2：使用 kubectl 命令行

```bash
# 给脚本执行权限
chmod +x deploy.sh

# 一键部署
./deploy.sh
```

### 方法3：手动逐步部署

```bash
# 1. 创建命名空间
kubectl apply -f namespace.yaml

# 2. 部署 NameServer
kubectl apply -f namesrv-deployment.yaml
kubectl apply -f namesrv-service.yaml

# 3. 等待 NameServer 启动
kubectl wait --for=condition=available --timeout=300s deployment/rocketmq-namesrv -n rocketmq

# 4. 部署 Broker
kubectl apply -f broker-configmap.yaml
kubectl apply -f broker-deployment.yaml
kubectl apply -f broker-service.yaml

# 5. 部署管理控制台
kubectl apply -f console-deployment.yaml
kubectl apply -f console-service.yaml
```

## 📊 部署后检查

### 1. 检查 Pod 状态
```bash
kubectl get pods -n rocketmq
```

期望输出：
```
NAME                                READY   STATUS    RESTARTS   AGE
rocketmq-namesrv-xxxxxxxxx-xxxxx    1/1     Running   0          2m
rocketmq-broker-xxxxxxxxx-xxxxx     1/1     Running   0          1m
rocketmq-console-xxxxxxxxx-xxxxx    1/1     Running   0          1m
```

### 2. 检查服务状态
```bash
kubectl get svc -n rocketmq
```

期望输出：
```
NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)             AGE
rocketmq-namesrv   ClusterIP   10.96.xxx.xxx  <none>        9876/TCP            2m
rocketmq-broker    ClusterIP   10.96.xxx.xxx  <none>        10911/TCP,10912/TCP,10909/TCP   1m
rocketmq-console   NodePort    10.96.xxx.xxx  <none>        8080:30080/TCP      1m
```

### 3. 查看日志
```bash
# NameServer 日志
kubectl logs -n rocketmq -l component=namesrv -f

# Broker 日志
kubectl logs -n rocketmq -l component=broker -f

# Console 日志
kubectl logs -n rocketmq -l component=console -f
```

## 🌐 访问和使用

### 1. 管理控制台访问
```
http://节点IP:30080
```

通过管理界面可以：
- 查看集群状态
- 监控消息生产和消费
- 管理 Topic 和消费者组
- 查看消息详情

### 2. 应用连接配置

在 OpenCoze 或其他应用中配置 RocketMQ 连接：

```yaml
# NameServer 地址
MQ_NAME_SERVER: "http://rocketmq-namesrv.rocketmq.svc.cluster.local:9876"

# 如果在不同命名空间，使用完整的服务地址
# 格式：服务名.命名空间.svc.cluster.local:端口
```

### 3. 创建 Topic

通过管理界面或命令行创建 OpenCoze 需要的 Topic：

```bash
# 进入 Broker Pod
kubectl exec -it -n rocketmq deployment/rocketmq-broker -- /bin/bash

# 创建 Topic
sh mqadmin updateTopic -n rocketmq-namesrv:9876 -t opencoze_knowledge -c DefaultCluster
sh mqadmin updateTopic -n rocketmq-namesrv -t opencoze_search_app -c DefaultCluster
sh mqadmin updateTopic -n rocketmq-namesrv:9876 -t opencoze_search_resource -c DefaultCluster
```

## ⚙️ 配置调优

### 1. 资源配置

根据实际负载调整资源配置：

```yaml
# NameServer 资源配置
resources:
  limits:
    cpu: 1000m      # 1核CPU
    memory: 2Gi     # 2GB内存
  requests:
    cpu: 500m       # 0.5核CPU
    memory: 1Gi     # 1GB内存

# Broker 资源配置（建议更高配置）
resources:
  limits:
    cpu: 2000m      # 2核CPU
    memory: 4Gi     # 4GB内存
  requests:
    cpu: 1000m      # 1核CPU
    memory: 2Gi     # 2GB内存
```

### 2. 存储配置

生产环境建议使用持久化存储：

```yaml
# 替换 emptyDir 为 PersistentVolumeClaim
volumes:
  - name: broker-store
    persistentVolumeClaim:
      claimName: rocketmq-broker-pvc
```

### 3. 高可用配置

生产环境建议：
- NameServer 部署多个副本（奇数个）
- Broker 配置主从模式
- 使用 StatefulSet 而不是 Deployment

## 🛠️ 故障排除

### 1. Pod 启动失败

```bash
# 查看 Pod 详细信息
kubectl describe pod -n rocketmq -l app=rocketmq

# 查看事件
kubectl get events -n rocketmq --sort-by=.metadata.creationTimestamp
```

### 2. Broker 连接 NameServer 失败

检查：
- NameServer 是否正常运行
- 网络连通性
- 配置文件中的 NameServer 地址

### 3. 消息发送失败

检查：
- Broker 状态是否正常
- Topic 是否已创建
- 网络连接是否正常

## 🔧 运维命令

### 查看集群状态
```bash
kubectl exec -it -n rocketmq deployment/rocketmq-broker -- sh mqadmin clusterList -n rocketmq-namesrv:9876
```

### 查看 Topic 列表
```bash
kubectl exec -it -n rocketmq deployment/rocketmq-broker -- sh mqadmin topicList -n rocketmq-namesrv:9876
```

### 查看消费者组
```bash
kubectl exec -it -n rocketmq deployment/rocketmq-broker -- sh mqadmin consumerProgress -n rocketmq-namesrv:9876
```

## 🗑️ 卸载

```bash
# 删除整个命名空间（包含所有资源）
kubectl delete namespace rocketmq

# 或者逐个删除资源
kubectl delete -f .
```

## 📝 注意事项

1. **资源要求**：确保集群有足够的 CPU 和内存资源
2. **网络策略**：确保 Pod 之间可以正常通信
3. **存储**：生产环境建议使用持久化存储
4. **监控**：建议配置监控告警
5. **备份**：定期备份重要的消息数据

## 💡 优化建议

1. **性能调优**：根据消息量调整 JVM 参数
2. **存储优化**：使用高性能存储（如 SSD）
3. **网络优化**：使用高带宽网络
4. **监控告警**：集成 Prometheus + Grafana
5. **自动扩缩容**：配置 HPA 实现自动扩缩容