#!/bin/bash

# OpenCoze Kubernetes 部署脚本
# 使用前请先修改配置文件中的实际服务地址和认证信息

set -e

echo "🚀 开始部署 OpenCoze 到 Kubernetes..."

# 检查 kubectl 是否可用
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl 命令未找到，请先安装 kubectl"
    exit 1
fi

# 检查集群连接
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ 无法连接到 Kubernetes 集群，请检查配置"
    exit 1
fi

echo "✅ Kubernetes 集群连接正常"

# 创建命名空间
echo "📦 创建命名空间..."
kubectl apply -f namespace.yaml

# 等待命名空间创建完成
sleep 2

# 应用配置
echo "⚙️  应用配置文件..."
kubectl apply -f secret.yaml
kubectl apply -f configmap.yaml

# 部署应用
echo "🏗️  部署应用..."
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml

echo "✅ 部署完成！"

# 检查部署状态
echo "📊 检查部署状态..."
kubectl get pods -n opencoze -l app=opencoze
kubectl get svc -n opencoze
kubectl get ingress -n opencoze

echo ""
echo "🔍 查看 Pod 日志："
echo "kubectl logs -n opencoze -l app=opencoze -f"
echo ""
echo "🌐 如果配置了 Ingress，请访问："
echo "http://coze.your-company.com (请替换为实际域名)"
echo ""
echo "📋 其他有用命令："
echo "  查看所有资源: kubectl get all -n opencoze"
echo "  查看配置: kubectl get configmap,secret -n opencoze"
echo "  删除部署: kubectl delete namespace opencoze"