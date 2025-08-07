# OpenCoze 简化 Kubernetes 部署

只包含两个核心文件的简化部署方案，适合快速部署和测试。

## 📁 文件说明

```
simple-k8s/
├── deployment.yaml    # 主应用部署配置（包含所有环境变量）
├── service.yaml       # 服务暴露配置（NodePort类型）
└── README.md          # 说明文档
```

## 🔧 部署前配置

### 必须修改的配置项

编辑 `deployment.yaml` 文件，在环境变量部分替换以下关键配置：

```yaml
# MySQL 配置
- name: MYSQL_HOST
  value: "your-mysql-host.company.com"     # 替换为实际 MySQL 地址
- name: MYSQL_USER
  value: "coze_user"                       # 替换为实际用户名
- name: MYSQL_PASSWORD
  value: "your_mysql_password"             # 替换为实际密码
- name: MYSQL_DSN
  value: "coze_user:your_mysql_password@tcp(your-mysql-host.company.com:3306)/opencoze?charset=utf8mb4&parseTime=True&loc=Local"

# Redis 配置
- name: REDIS_ADDR
  value: "your-redis-host.company.com:6379"  # 替换为实际 Redis 地址

# Elasticsearch 配置
- name: ES_ADDR
  value: "http://your-elasticsearch-host.company.com:9200"  # 替换为实际 ES 地址

# MinIO 配置
- name: MINIO_AK
  value: "your_minio_access_key"           # 替换为实际 Access Key
- name: MINIO_SK
  value: "your_minio_secret_key"           # 替换为实际 Secret Key
- name: MINIO_ENDPOINT
  value: "your-minio-host.company.com:9000"  # 替换为实际 MinIO 地址

# Milvus 配置
- name: MILVUS_ADDR
  value: "your-milvus-host.company.com:19530"  # 替换为实际 Milvus 地址

# RocketMQ 配置
- name: MQ_NAME_SERVER
  value: "http://your-rocketmq-host.company.com:9876"  # 替换为实际 RocketMQ 地址
```

### 必须配置的 API Key

**重要：** 由于使用 OpenAI 嵌入模型，必须配置 OpenAI API Key：

```yaml
# OpenAI 嵌入模型 API Key（必填）
- name: OPENAI_EMBEDDING_API_KEY
  value: "your_openai_api_key"        # 用于嵌入模型
```

### 聊天模型配置

**说明：** 聊天模型配置已经内置在服务中，服务启动时会自动加载 `conf/model` 目录下的配置文件。如果需要使用特定的模型，可以按照官方文档的方式在 Coze Studio 界面中配置模型服务。

### 可选配置项

如果需要使用火山引擎服务，配置以下 API Key：

```yaml
# 火山引擎 API Key（可选）
- name: VE_OCR_AK
  value: "your_ve_ocr_ak"            # OCR 服务
- name: VE_OCR_SK
  value: "your_ve_ocr_sk"
- name: VE_IMAGEX_AK
  value: "your_ve_imagex_ak"         # 图像服务
- name: VE_IMAGEX_SK
  value: "your_ve_imagex_sk"
```

## 🚀 部署方法

### 方法1：在 Kuboard 界面部署

1. 登录 Kuboard 管理界面
2. 选择目标集群和命名空间（默认使用 default）
3. 进入"工作负载" → "无状态工作负载" → 导入 `deployment.yaml`
4. 进入"网络" → "服务" → 导入 `service.yaml`

### 方法2：使用 kubectl 命令行

```bash
# 应用配置
kubectl apply -f simple-k8s/deployment.yaml
kubectl apply -f simple-k8s/service.yaml

# 检查部署状态
kubectl get pods -l app=opencoze
kubectl get svc opencoze-server
```

## 📊 部署后检查

### 1. 检查 Pod 状态
```bash
kubectl get pods -l app=opencoze
```

期望输出：
```
NAME                              READY   STATUS    RESTARTS   AGE
opencoze-server-xxxxxxxxx-xxxxx   1/1     Running   0          2m
```

### 2. 查看应用日志
```bash
kubectl logs -l app=opencoze -f
```

### 3. 检查服务状态
```bash
kubectl get svc opencoze-server
```

期望输出：
```
NAME              TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)                         AGE
opencoze-server   NodePort   10.96.xxx.xxx  <none>        8888:30888/TCP,8889:30889/TCP   2m
```

## 🌐 访问应用

由于使用了 NodePort 类型的 Service，您可以通过以下方式访问：

### 通过节点IP访问
```
http://<节点IP>:30888     # 主应用端口
http://<节点IP>:30889     # MinIO代理端口
```

### 通过端口转发访问（推荐测试时使用）
```bash
kubectl port-forward svc/opencoze-server 8888:8888
```

然后访问：`http://localhost:8888`

## 🔧 配置调优

### 资源配置

根据实际需求调整资源配置：

```yaml
resources:
  limits:
    cpu: 4000m      # 4核CPU限制
    memory: 8Gi     # 8GB内存限制
  requests:
    cpu: 2000m      # 2核CPU请求
    memory: 4Gi     # 4GB内存请求
```

### 副本数配置

如需高可用，可以增加副本数：

```yaml
spec:
  replicas: 3  # 增加到3个副本
```

### 健康检查配置

根据应用启动时间调整健康检查参数：

```yaml
livenessProbe:
  initialDelaySeconds: 60  # 启动后60秒开始检查
  periodSeconds: 30        # 每30秒检查一次

readinessProbe:
  initialDelaySeconds: 30  # 启动后30秒开始检查
  periodSeconds: 10        # 每10秒检查一次
```

## 🛠️ 故障排除

### 1. Pod 启动失败

```bash
# 查看 Pod 详细信息
kubectl describe pod -l app=opencoze

# 查看容器日志
kubectl logs -l app=opencoze
```

### 2. 连接中间件失败

检查配置项：
- 确认服务地址和端口正确
- 验证认证信息（用户名、密码、API Key）
- 确保网络连通性

### 3. 服务无法访问

```bash
# 检查 Service 配置
kubectl get svc opencoze-server -o yaml

# 检查端点
kubectl get endpoints opencoze-server
```

## 🔄 更新部署

```bash
# 修改配置后重新应用
kubectl apply -f simple-k8s/deployment.yaml

# 强制重启 Pod
kubectl rollout restart deployment/opencoze-server

# 查看更新状态
kubectl rollout status deployment/opencoze-server
```

## 🗑️ 删除部署

```bash
kubectl delete -f simple-k8s/service.yaml
kubectl delete -f simple-k8s/deployment.yaml
```

## ⚠️ 安全提醒

1. **敏感信息**：生产环境建议将密码等敏感信息放在 Kubernetes Secret 中
2. **网络安全**：NodePort 会在所有节点上开放端口，注意防火墙配置
3. **资源监控**：建议配置资源监控，防止资源耗尽

## 💡 优化建议

1. **使用 Secret**：将敏感配置移到 Secret 中
2. **配置 Ingress**：生产环境建议使用 Ingress 而不是 NodePort
3. **健康监控**：配置 Prometheus 监控应用健康状态
4. **日志收集**：配置日志收集系统收集应用日志