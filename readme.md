## Kubernetes NodeJS app example

### Description
Uses Terraform to deploy a stack and install kubernetes, once up will build helloworld nodeJS app and launch under kubernetes with port 30000 exposed.

### Kubernetes Types
A great resource explaining the types in Kubernetes. People will normally use nginx or traefik ingress Controller with NodePort (exposed on host as an ephemeral range 30000-60000)
> http://alesnosek.com/blog/2017/02/14/accessing-kubernetes-pods-from-outside-of-the-cluster/

### AWS Application Load Balancer
Used with Kubernetes, each Target Group can point to an ephemeral port across multiple instances, a listener can route to multiple target groups.
> http://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html
