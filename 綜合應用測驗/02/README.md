# 綜合應用測驗 02

使用 Terraform 建立 AWS VPC 和 EKS Cluster，並於 EKS 上部署 WordPress 和 MySQL

## 技術考量

- EKS Worker Nodes 部署於 3 個 AZ 的 Private Subnet，以降低單一 Node 或 AZ 故障造成的影響
- WordPress 部署 3 個 replicas，並透過 `topologySpreadConstraints` 將 Pod 分散至不同 Availability Zone，以提高服務可用性
- WordPress 需要多個 Pod 共用 Persistent Storage，所以使用 Amazon EFS 與 EFS CSI Driver，PVC access mode 為 `ReadWriteMany`
- MySQL 使用 StatefulSet，並透過 EBS CSI Driver 為各 Pod 動態建立獨立的 EBS Volume。
- 目前同時啟用 EKS Private Endpoint 與 Public Endpoint，以方便部署及驗證，Public Endpoint 為作業驗證暫時允許 `0.0.0.0/0`；正式環境應限制固定來源 IP，或停用 Public Endpoint，改由 VPN、Direct Connect 或跳板機進行存取
- 目前 Application 固定維持 3 個 replicas，如果 workload 有動態流量的需求，可再導入 Metrics Server 和 HPA，並搭配 Karpenter
- MySQL 的機敏資料是使用 Kubernetes Secret，Production 環境可改用 AWS Secrets Manager
- 此作業為單一環境的小型範例，所以 Terraform 採較精簡的架構並使用 Local Backend
- AWS 操作使用本機 AWS CLI Profile `asiayo`

## 部署

### 建置 VPC 和 EKS

```sh
terraform -chdir=terraform init
terraform -chdir=terraform plan -out=tfplan
terraform -chdir=terraform apply tfplan
```

### 設定 kubeconfig

```sh
aws eks update-kubeconfig --region ap-east-2 --name asiayo --profile asiayo
```

### 建立 AWS Load Balancer Controller ServiceAccount

```sh
kubectl apply -f kubernetes/serviceaccount.yaml
```

### 安裝 AWS Load balancer controller

```sh
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set vpcId=<VPC ID> \
  --set clusterName=asiayo \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set ingressClassParams.spec.scheme=internet-facing \
  --set ingressClassParams.spec.targetType=ip \
  --version 1.14.0
```

### 修改 Kubernetes Manifest

- kubernetes/wordpress/storageclass.yaml
  - 將 `fileSystemId` 設為 Terraform 建立的 EFS File System ID
- kubernetes/mysql/secret.yaml
  - 設定測試使用的 MySQL 機敏資料

### 部署 Kubernetes 資源

```sh
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/mysql/secret.yaml
kubectl apply -f kubernetes/wordpress/
kubectl apply -f kubernetes/mysql/
```
