---
templating: mustache
---

# Go Service Runbook

## Read the pods and the logs

```bash
kubectl -n {{params.namespace}} get pods -l app.kubernetes.io/name={{params.md_metadata.name_prefix}}
kubectl -n {{params.namespace}} logs deploy/{{params.md_metadata.name_prefix}} --tail=100
```

## The pod is in `ImagePullBackOff`

The cluster cannot read the image `{{params.image}}`. Make the image public, or
give the cluster access to the registry. Then deploy again.

## The pod is in `CrashLoopBackOff`

Read the logs of the last failed container.

```bash
kubectl -n {{params.namespace}} logs deploy/{{params.md_metadata.name_prefix}} --previous
```

A Go service that does not listen on the `PORT` variable fails the health check.

## Call the service from inside the cluster

```bash
kubectl -n {{params.namespace}} run curl --rm -it --restart=Never --image=curlimages/curl -- \
  curl -s http://{{params.md_metadata.name_prefix}}.{{params.namespace}}.svc.cluster.local/
```
