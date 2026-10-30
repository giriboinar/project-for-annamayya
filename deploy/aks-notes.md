# Deploy to Azure AKS — steps only, nothing here creates anything

> ⚠️ **Cost warning.** AKS does not charge for the control plane, but
> its **worker nodes are paid** (VM charges apply for as long as they
> run). Check current pricing before you run any of this. For a free
> demo, use `kind` locally instead (see README).

## Prerequisites

- `az` CLI logged in with your own account (never commit credentials).
- `kubectl` installed.
- A Docker image pushed to a registry you control (ACR or Docker Hub).

## Steps

```bash
# 1. Push the image (example uses ACR)
az acr create --resource-group <rg> --name <acr-name> --sku Basic
az acr login --name <acr-name>
docker tag project-for-annamayya:latest <acr-name>.azurecr.io/project-for-annamayya:latest
docker push <acr-name>.azurecr.io/project-for-annamayya:latest

# 2. Create the cluster (PAID nodes — this is the step that starts billing)
az aks create --resource-group <rg> --name annamayya --node-count 2 --node-vm-size Standard_B2s --attach-acr <acr-name>

# 3. Connect kubectl
az aks get-credentials --resource-group <rg> --name annamayya

# 4. Point the Deployment at your pushed image
# Edit k8s/deployment.yaml: set image to your ACR URI.

# 5. Deploy
kubectl apply -f k8s/
kubectl get pods,svc -l app=project-for-annamayya
```

## Tear down (stops billing)

```bash
az aks delete --resource-group <rg> --name annamayya --yes
```

Verify in the Azure portal that the cluster and its node resource group
are deleted — leftover disks/IPs can keep billing.
