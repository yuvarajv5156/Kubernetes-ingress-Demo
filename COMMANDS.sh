# HiQode — Ingress & Ingress Controller Demo
# ============================================
# 3 Apps: Login / Order / Payment → AWS ALB Ingress
#
#  FOLDER STRUCTURE
# ─────────────────────────────────────────────
# hiqode-ingress-demo/
# ├── login-app/
# │   ├── Dockerfile
# │   └── index.html
# ├── order-app/
# │   ├── Dockerfile
# │   └── index.html
# ├── payment-app/
# │   ├── Dockerfile
# │   └── index.html
# └── k8s/
#     ├── 00-namespace.yaml
#     ├── 01-login.yaml
#     ├── 02-order.yaml
#     ├── 03-payment.yaml
#     └── 04-ingress.yaml


# ─────────────────────────────────────────────
#  STEP 1 — Authenticate Docker to ECR
# ─────────────────────────────────────────────

aws ecr get-login-password --region <REGION> | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 965278178995.dkr.ecr.us-east-1.amazonaws.com


# ─────────────────────────────────────────────
#  STEP 2 — Create ECR Repositories
# ─────────────────────────────────────────────

aws ecr create-repository --repository-name login-app   --region <REGION>
aws ecr create-repository --repository-name order-app   --region <REGION>
aws ecr create-repository --repository-name payment-app --region <REGION>

aws ecr create-repository --repository-name login-app   --region us-east-1
aws ecr create-repository --repository-name order-app   --region us-east-1
aws ecr create-repository --repository-name payment-app --region us-east-1


# ─────────────────────────────────────────────
#  STEP 3 — Build, Tag & Push Docker Images
# ─────────────────────────────────────────────

# LOGIN APP
cd login-app
docker build -t login-app .
# docker tag login-app:latest <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/login-app:v1
docker tag login-app:latest 965278178995.dkr.ecr.us-east-1.amazonaws.com/login-app:v1 
# docker push <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/login-app:v1
docker push 965278178995.dkr.ecr.us-east-1.amazonaws.com/login-app:v1
cd ..

965278178995.dkr.ecr.us-east-1.amazonaws.com

# ORDER APP
cd order-app
docker build -t order-app .
docker tag order-app:latest 965278178995.dkr.ecr.us-east-1.amazonaws.com/order-app:v1
docker push 965278178995.dkr.ecr.us-east-1.amazonaws.com/order-app:v1
cd ..

# PAYMENT APP
cd payment-app
docker build -t payment-app .
docker tag payment-app:latest 965278178995.dkr.ecr.us-east-1.amazonaws.com/payment-app:v1
docker push 965278178995.dkr.ecr.us-east-1.amazonaws.com/payment-app:v1
cd ..


# ─────────────────────────────────────────────
#  STEP 4 — Update image URLs in Manifest files
# ─────────────────────────────────────────────
# Open k8s/01-login.yaml, 02-order.yaml, 03-payment.yaml
# Replace <AWS_ACCOUNT_ID> and <REGION> with real values


# ─────────────────────────────────────────────
#  STEP 5 — Apply All Manifests
# ─────────────────────────────────────────────

kubectl apply -f k8s/00-namespace.yaml
kubectl apply -f k8s/01-login.yaml
kubectl apply -f k8s/02-order.yaml
kubectl apply -f k8s/03-payment.yaml
kubectl apply -f k8s/04-ingress.yaml


# ─────────────────────────────────────────────
#  STEP 6 — Verify Everything is Running
# ─────────────────────────────────────────────

# Check pods
kubectl get pods -n hiqode

# Check services
kubectl get svc -n hiqode

# Check ingress (wait 2-3 mins for ALB to provision)
kubectl get ingress -n hiqode

# Get ALB URL
kubectl get ingress hiqode-ingress -n hiqode -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'


# ─────────────────────────────────────────────
#  STEP 7 — Test in Browser
# ─────────────────────────────────────────────
#
#  http://<ALB-URL>/           → Login Page   🔐
#  http://<ALB-URL>/order      → Order Page   📦
#  http://<ALB-URL>/payment    → Payment Page 💳


# ─────────────────────────────────────────────
#  QUICK LOCAL TEST (before pushing to ECR)
# ─────────────────────────────────────────────

docker run -d -p 8081:80 login-app    # → http://localhost:8081
docker run -d -p 8082:80 order-app    # → http://localhost:8082
docker run -d -p 8083:80 payment-app  # → http://localhost:8083


# ─────────────────────────────────────────────
#  CLEANUP
# ─────────────────────────────────────────────

kubectl delete namespace hiqode
