# Coworking Space Analytics Service

## Getting Started

### Prerequisites
- AWS account with appropriate permissions
- AWS CLI configured with your credentials
- `eksctl`, `kubectl`, and `psql` installed locally
- Docker (for local development)

## Deployment Steps

### 1. Create an EKS Cluster
```bash
eksctl create cluster --name project3-cluster --region us-east-1 \
  --nodegroup-name project3-nodes --node-type t3.small \
  --nodes 1 --nodes-min 1 --nodes-max 2
```

### 2. Configure Kubernetes Access
```bash
aws eks --region us-east-1 update-kubeconfig --name project3-cluster
kubectl config current-context
``` 

### 3. Configure Environment and Secrets
```bash
kubectl apply -f deployment/configmap.yaml
kubectl apply -f deployment/secrets.yaml
```

### 4. Deploy PostgreSQL Database
#### 4.1 Deploy Database Infrastructure
```bash
kubectl apply -f deployment/pv.yaml
kubectl apply -f deployment/pvc.yaml
kubectl apply -f deployment/postgresql-deployment.yaml
kubectl apply -f deployment/postgresql-service.yaml
```
#### 4.2 Seed Data
```bash
kubectl port-forward --address 127.0.0.1 service/postgresql-service 5433:5432 # & didn't work so I opened a new terminal after running this command
export DB_PASSWORD=$(kubectl get secret project3-secrets -o jsonpath='{.data.password}' | base64 --decode)
export DB_USER=$(kubectl get configMap project3-config-map -o jsonpath='{.data.DB_USER}')
export DB_NAME=$(kubectl get configMap project3-config-map -o jsonpath='{.data.DB_NAME}')
PGPASSWORD="$DB_PASSWORD" psql --host 127.0.0.1 -U ${DB_USER} -d ${DB_NAME} -p 5433 < ./db/1_create_tables.sql
PGPASSWORD="$DB_PASSWORD" psql --host 127.0.0.1 -U ${DB_USER} -d ${DB_NAME} -p 5433 < ./db/2_seed_users.sql
PGPASSWORD="$DB_PASSWORD" psql --host 127.0.0.1 -U ${DB_USER} -d ${DB_NAME} -p 5433 < ./db/3_seed_tokens.sql
```

### 5. Deploy Application
```bash
kubectl apply -f deployment/coworking.yaml
```

### 6. Get Application URL
```bash
kubectl get service
```

### Access the application at app.py endpoints, e.g:
   http://<EXTERNAL-IP>:5153/health-check
   http://<EXTERNAL-IP>:5153/readiness_check

### Access to my application (not an extensive list):
   http://aa4e53a0cbeb24a2db7daee78b59d263-1902549326.us-east-1.elb.amazonaws.com:5153/health_check
   http://aa4e53a0cbeb24a2db7daee78b59d263-1902549326.us-east-1.elb.amazonaws.com:5153/readiness_check
   http://aa4e53a0cbeb24a2db7daee78b59d263-1902549326.us-east-1.elb.amazonaws.com:5153/api/reports/user_visits
   http://aa4e53a0cbeb24a2db7daee78b59d263-1902549326.us-east-1.elb.amazonaws.com:5153/api/reports/daily_usage

### 7. Configure Logging
```bash
aws iam attach-role-policy \
  --role-name eksctl-project3-cluster-nodegroup-project3-nodes-NodeInstanceRole-XXXXXXXXXX \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
aws eks create-addon --addon-name amazon-cloudwatch-observability --cluster-name project3-cluster
```

## Stand-Out Suggestions

### Resource Allocation Recommendations
For production deployments, add these resource limits to your Kubernetes deployment YAML:
```yaml
resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
  limits:
    cpu: "1"
    memory: "1Gi"
```

### Optimal AWS Instance Type
For production environments, we recommend:
   - Database: r5.large (balanced memory/CPU for PostgreSQL)
   - Application: t3.medium (burstable CPU for web service)
   - Nodes: m5.large (general purpose worker nodes)

### Cost Saving Strategies
- Cluster Autoscaler: Automatically scales node count based on demand.
- Spot Instances: Use for non-production environments (70-90% savings).
- Schedule Development: Shut down dev clusters nights/weekends using:
   ```bash
   eksctl scale nodegroup --cluster=project3-cluster --nodes=0 --name=project3-nodes
  ```

## Useful commands

### Accessing Application Logs
```bash 
kubectl logs -f deployment/coworking
```

### Scaling the Application
```bash
kubectl scale deployment coworking --replicas=3
```

### Tearing Down Resources
```bash
eksctl delete cluster --name project3-cluster --region us-east-1
```
