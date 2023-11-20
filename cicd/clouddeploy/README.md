# Cloud Deploy

## Resources

The following Cloud Deploy resources are defined using Infra-as-Code (IaC):

### Targets

- runtime solution, e.g., GKE Cluster(s) in different environments such as DEV, TEST, PROD

cf. `/infra/reference/deploy.tf`

### Delivery Pipelines

- each application requires a delivery pipeline
- defines stages by referencing the Targets

cf. `/infra/reference/apps.tf`
