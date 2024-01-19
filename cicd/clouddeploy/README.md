# Cloud Deploy

## Resources

The following Cloud Deploy resources are defined using Infra-as-Code (IaC):

### Targets

- runtime solution, e.g., GKE Cluster(s) in different environments such as DEV, TEST, PROD

cf. [`deploy.tf`](../../infra/reference/deploy.tf)

### Delivery Pipelines

- a CD pipeline is required per application
  - it defines stages (for DEV, TEST, PROD) by referencing the Targets

cf. [`apps.tf`](../../infra/reference/apps.tf)
