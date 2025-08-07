# OpenCoze Kubernetes 部署配置

这是 OpenCoze 的原生 Kubernetes 部署配置，无需 Helm，可直接在 Kuboard 或通过 kubectl 部署。

## 📁 文件说明

```
k8s-deployment/
├── namespace.yaml      # 命名空间配置
├── secret.yaml        # 敏感信息配置（密码、API Key等）
├── configmap.yaml     # 非敏感配置信息
├── deployment.yaml    # 主应用部署配置
├── service.yaml       # 服务暴露配置
├── ingress.yaml       # 外部访问入口配置
├── deploy.sh          # 一键部署脚本
└── README.md          # 说明文档
```

## 🔧 部署前配置

### 1. 修改 Secret 配置（重要！）

编辑 `secret.yaml` 文件，替换以下敏感信息：

```yaml
stringData:
  mysql-password: "your_mysql_password"           # MySQL 密码
  minio-access-key: "your_minio_access_key"      # MinIO 访问密钥
  minio-secret-key: "your_minio_secret_key"      # MinIO 秘密密钥
  # ... 其他 API Key
```

### 2. 修改 ConfigMap 配置

编辑 `configmap.yaml` 文件，替换以下服务地址：

```yaml
data:
  MYSQL_HOST: "your-mysql-host.company.com"           # MySQL 地址
  REDIS_ADDR: "your-redis-host.company.com:6379"     # Redis 地址
  ES_ADDR: "http://your-elasticsearch-host:9200"     # Elasticsearch 地址
  MINIO_ENDPOINT: "your-minio-host.company.com:9000" # MinIO 地址
  MILVUS_ADDR: "your-milvus-host.company.com:19530"  # Milvus 地址
  # ... 其他服务地址
```

### 3. 修改 Ingress 配置（可选）

编辑 `ingress.yaml` 文件，配置您的域名：

```yaml
rules:
  - host: coze.your-company.com  # 替换为实际域名
```

## 🚀 部署方法

### 方法1：使用 Kuboard 界面部署

1. 在 Kuboard 中选择目标集群
2. 进入"配置中心" → "导入"
3. 逐个导入以下文件：
   - namespace.yaml
   - secret.yaml
   - configmap.yaml
   - deployment.yaml
   - service.yaml
   - ingress.yaml

### 方法2：使用 kubectl 命令行部署

```bash
# 给部署脚本执行权限
chmod +x deploy.sh

# 一键部署
./deploy.sh
```

### 方法3：手动逐步部署

```bash
# 1. 创建命名空间
kubectl apply -f namespace.yaml

# 2. 创建配置
kubectl apply -f secret.yaml
kubectl apply -f configmap.yaml

# 3. 部署应用
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
```

## 📊 部署后检查

### 1. 检查 Pod 状态
```bash
kubectl get pods -n opencoze
```

### 2. 查看应用日志
```bash
kubectl logs -n opencoze -l app=opencoze -f
```

### 3. 检查服务状态
```bash
kubectl get svc,ingress -n opencoze
```

### 4. 测试服务连通性
```bash
# 端口转发测试
kubectl port-forward -n opencoze svc/opencoze-server 8888:8888

# 然后访问 http://localhost:8888
```

## 🔧 配置说明

### 环境变量配置

应用支持以下主要环境变量：

| 变量名 | 说明 | 示例值 |
|--------|------|--------|
| MYSQL_HOST | MySQL 主机地址 | mysql.company.com |
| REDIS_ADDR | Redis 地址 | redis.company.com:6379 |
| ES_ADDR | Elasticsearch 地址 | http://es.company.com:9200 |
| MINIO_ENDPOINT | MinIO 地址 | minio.company.com:9000 |
| MILVUS_ADDR | Milvus 地址 | milvus.company.com:19530 |

### 资源配置

默认资源配置：
- CPU: 请求 2 核，限制 4 核
- 内存: 请求 4GB，限制 8GB
- 副本数: 1 个

根据实际负载调整 `deployment.yaml` 中的资源配置。

## 🛠️ 故障排除

### 1. Pod 无法启动

```bash
# 查看 Pod 详细信息
kubectl describe pod -n opencoze -l app=opencoze

# 查看事件
kubectl get events -n opencoze --sort-by=.metadata.creationTimestamp
```

### 2. 连接外部服务失败

- 检查网络连通性
- 验证服务地址和端口
- 确认认证信息正确

### 3. 健康检查失败

- 检查应用启动时间是否过长
- 调整 `initialDelaySeconds` 参数
- 查看应用日志确认 `/health` 端点可用

## 🔄 更新部署

```bash
# 更新配置
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml

# 重启 Pod 使配置生效
kubectl rollout restart deployment/opencoze-server -n opencoze

# 查看更新状态
kubectl rollout status deployment/opencoze-server -n opencoze
```

## 🗑️ 卸载

```bash
# 删除整个命名空间（包含所有资源）
kubectl delete namespace opencoze

# 或者逐个删除资源
kubectl delete -f .
```

## 📝 注意事项

1. **安全性**：确保所有敏感信息都存储在 Secret 中，不要将密码写在 ConfigMap 里
2. **网络**：确保 Kubernetes 集群可以访问公司的中间件服务
3. **监控**：建议配置监控和告警，及时发现问题
4. **备份**：重要数据请定期备份
5. **更新**：定期更新镜像版本，保持系统安全性

## 💡 优化建议

1. **使用 HPA**：配置水平 Pod 自动伸缩
2. **资源监控**：使用 Prometheus + Grafana 监控资源使用情况
3. **日志收集**：配置 ELK 或 Loki 收集应用日志
4. **健康检查**：完善 liveness 和 readiness 探针
5. **安全策略**：配置 Pod Security Policy 或 Pod Security Standards