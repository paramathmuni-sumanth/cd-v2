# ai-qic and ai-qic-sync Image Tag Sync

Both **ai-qic** and **ai-qic-sync** must deploy the same ECR image tag. They use the same image (`341118756977.dkr.ecr.ap-south-1.amazonaws.com/ai-qic`) with different entrypoints.

## Pipeline Integration

When deploying a new ai-qic image, run the unified deploy script (updates all three files):

```bash
./scripts/deploy-ai-qic-image.sh ml-1.0.0.49.0
```

Then commit and push:

```bash
git add internal/ai-qic/microservice.yaml internal/ai-qic/image-tag.yaml internal/ai-qic-sync/deployment.yaml
git commit -m "chore(ai-qic): deploy image ml-1.0.0.49.0"
git push
```

**Alternative:** If the pipeline already updates `microservice.yaml`, run the sync script to update only ai-qic-sync:

```bash
./scripts/sync-ai-qic-image-tag.sh          # extracts tag from microservice.yaml
./scripts/sync-ai-qic-image-tag.sh ml-1.0.0.49.0   # or pass tag explicitly
```

## Verification

After deployment, both pods should use the same image:

```bash
kubectl get pods -n internal -l app=ai-qic -o jsonpath='{.items[0].status.containerStatuses[0].imageID}'
kubectl get pods -n internal -l app=ai-qic-sync -o jsonpath='{.items[0].status.containerStatuses[0].imageID}'
```
