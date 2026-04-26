# ComplianceCheck GitOps with Fleet

This directory contains the Fleet configuration for continuous deployment of
ComplianceCheck to `cluster-dev` and `cluster-uat` from a single Git source of truth.

## Architecture

```
  Git repo (this repo)
       │
       │ polled every 60s
       ▼
  Rancher Fleet (in `local` mgmt cluster)
       │
       ├─► cluster-dev  (label env=dev)   — compliance.lab.local,      HPA off, PDB off
       └─► cluster-uat  (label env=uat)   — compliance-uat.lab.local,  HPA on,  PDB on
```

## One-time setup

### 1. Label the clusters in Rancher

```
Rancher UI → Cluster Management → cluster-dev → Edit → Labels:
  env = dev

Rancher UI → Cluster Management → cluster-uat → Edit → Labels:
  env = uat
```

### 2. Create the GitRepo in Rancher Continuous Delivery

```
Rancher UI → Continuous Delivery → Git Repos → Create
  Name:       compliance-app
  Repository: http://gitea.lab.local/admin/compliance-gitops.git
  Branch:     main
  Paths:      /
  Target:     All Clusters in the workspace (Fleet filters by label)
```

### 3. Wait

Within 60 seconds, Fleet clones the repo, finds `fleet.yaml`, and applies
the Helm chart to every matching cluster. Verify in the UI or CLI:

```
kubectl --context=cluster-dev -n compliance get all
kubectl --context=cluster-uat -n compliance get all
```

## Making changes

All changes go through Git. Never kubectl-apply directly to a Fleet-managed cluster.

**Scale the API:**
```
vi helm/compliance/values.yaml   # change replicaCount.api
git commit -am "Scale API"
git push
# Fleet deploys within 60 seconds
```

**Bump app version:**
```
vi helm/compliance/values.yaml   # change image.api.tag
git commit -am "Release v3"
git push
```

## Rollback

Fleet follows Git. To roll back: `git revert` and push.

```
git log --oneline
git revert <bad-commit-sha>
git push
```

## Troubleshooting

**GitRepo shows "Not Ready":**
- Check GitRepo detail page in Rancher UI → Events
- Typically: repo URL wrong, credentials missing, or branch doesn't exist

**Cluster shows "Not Ready" under Bundles:**
- Open the Bundle detail page in Rancher UI
- Check Target Clusters section → per-cluster status
- Usually a Helm rendering issue (check the stderr) or a missing dependency
  (e.g., Longhorn StorageClass not present on that cluster)

**Changes not propagating:**
- Default Fleet polling is 15 minutes. To speed up:
  - Add `pollingInterval: 60s` to fleet.yaml (already done in this repo)
  - Or trigger manually: `kubectl -n fleet-local patch gitrepo compliance-app --type=merge -p '{"spec":{"forceSyncGeneration": N}}'` where N increments each time
