# Codespaces Setup

Short setup notes for starting ABOX in GitHub Codespaces.

## 1. Docker storage

The Codespace root disk can fill up while pulling images. Run the setup script before `make run`:

```bash
chmod +x scripts/codespaces-move-docker-to-tmp.sh
./scripts/codespaces-move-docker-to-tmp.sh
```

It preserves the current Codespaces `dockerd` arguments, changes Docker's data root to `/tmp/docker`, and restarts Docker.

Expected: `Docker Root Dir: /tmp/docker`

> `/tmp` is ephemeral, so it may be needed to repeat this after a Codespace rebuild.

## 2. Other notes 

### ngrok

ngrok credentials are required by the ngrok operator. If ngrok fails, services that depend on its tunnels/endpoints may not start or become available.

Set the ngrok credentials:

```bash
export NGROK_AUTHTOKEN='sometoken'
export NGROK_API_KEY='sometoken'

kubectl -n ngrok-operator create secret generic ngrok-operator-credentials \
  --from-literal=API_KEY="$NGROK_API_KEY" \
  --from-literal=AUTHTOKEN="$NGROK_AUTHTOKEN"
```

Check ngrok:

```bash
kubectl get pods -n ngrok-operator
kubectl get secrets -n ngrok-operator
```
Clear the credentials from the shell:
```bash
unset NGROK_AUTHTOKEN NGROK_API_KEY
```


### Astronomy Shop:

to accesss UI:

```bash
kubectl port-forward -n otel-demo svc/frontend-proxy 8080:8080
```

Chatbot: `/chatbot/`

### MLflow:

```bash
kubectl port-forward -n mlflow svc/mlflow-mlflow 5000:5000
```

### Phoenix:

```bash
kubectl port-forward -n phoenix svc/phoenix-svc 6006:6006
```

Open the forwarded ports from the Codespaces **Ports** tab.

[Arize Phoenix default user credentials here](https://arize.com/docs/phoenix/self-hosting/features/authentication)
