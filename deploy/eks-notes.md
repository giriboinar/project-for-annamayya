# Deploy to Amazon EKS — steps only, nothing here creates anything

> ⚠️ **Cost warning.** A real EKS cluster costs about **$70+ per month
> for the control plane alone**, plus EC2 worker-node charges, and it is
> **not AWS Free Tier eligible**. Check current pricing before you run
> any of this. For a free demo, use `kind` locally instead (see README).

## Prerequisites

- `aws` CLI configured with your own credentials (never commit them).
- `eksctl` and `kubectl` installed.
- A Docker image pushed to a registry you control (ECR or Docker Hub),
  because a cluster cannot pull an image that only exists on your laptop.

## Steps

```bash
# 1. Push the image (example uses ECR; replace <account> and <region>)
aws ecr create-repository --repository-name project-for-annamayya --region <region>
docker tag project-for-annamayya:latest <account>.dkr.ecr.<region>.amazonaws.com/project-for-annamayya:latest
docker push <account>.dkr.ecr.<region>.amazonaws.com/project-for-annamayya:latest

# 2. Create the cluster (PAID — this is the step that starts billing)
eksctl create cluster --name annamayya --region <region> --node-type t3.small --nodes 2

# 3. Point the Deployment at your pushed image
# Edit k8s/deployment.yaml: set image to your ECR URI.

# 4. Deploy
kubectl apply -f k8s/
kubectl get pods,svc -l app=project-for-annamayya

# 5. Expose it (creates a paid load balancer — optional)
kubectl expose deployment project-for-annamayya --type=LoadBalancer --port=80
```

## Tear down (stops billing)

```bash
eksctl delete cluster --name annamayya --region <region>
```

Verify in the AWS console that the cluster, node groups, and load
balancer are all gone — a leftover load balancer keeps billing.
