# Changelog

## 0.1.0

- Add the first version of the runtime.
- Deploy a Go service with a Deployment, a ClusterIP Service, and a Secret.
- Install the chart with one OpenTofu step and the Helm provider. The step outputs the name, the namespace, and the URL of the service.
- Map app envs, app secrets, and the connection strings of the dependencies to the container.
