#!/bin/bash

# RocketMQ Kubernetes 部署脚本

set -e

echo "🚀 开始部署 RocketMQ 到 Kubernetes..."

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

# 部署 NameServer
echo "🏗️  部署 NameServer..."
kubectl apply -f namesrv-deployment.yaml
kubectl apply -f namesrv-service.yaml

# 等待 NameServer 启动
echo "⏳ 等待 NameServer 启动..."
kubectl wait --for=condition=available --timeout=300s deployment/rocketmq-namesrv -n rocketmq

# 部署 Broker
echo "🏗️  部署 Broker..."
kubectl apply -f broker-configmap.yaml
kubectl apply -f broker-deployment.yaml
kubectl apply -f broker-service.yaml

# 等待 Broker 启动
echo "⏳ 等待 Broker 启动..."
kubectl wait --for=condition=available --timeout=300s deployment/rocketmq-broker -n rocketmq

# 部署 Console（可选）
echo "🏗️  部署管理控制台..."
kubectl apply -f console-deployment.yaml
kubectl apply -f console-service.yaml

echo "✅ RocketMQ 部署完成！"

# 检查部署状态
echo "📊 检查部署状态..."
kubectl get pods -n rocketmq
kubectl get svc -n rocketmq

echo ""
echo "🔍 查看 Pod 日志："
echo "  NameServer: kubectl logs -n rocketmq -l component=namesrv -f"
echo "  Broker:     kubectl logs -n rocketmq -l component=broker -f"
echo "  Console:    kubectl logs -n rocketmq -l component=console -f"
echo ""
echo "🌐 访问管理界面："
echo "  http://节点IP:30080"
echo ""
echo "📋 连接信息："
echo "  NameServer: rocketmq-namesrv.rocketmq.svc.cluster.local:9876"
echo "  Broker:     rocketmq-broker.rocketmq.svc.cluster.local:10911"
echo ""
echo "🗑️  删除部署："
echo "  kubectl delete namespace rocketmq"