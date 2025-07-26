# Workshop 2 - Hands On

## Objectives 🎯

The objectives of this workshop are twofold:

1. getting **hands-on** experience in your **real-life environment** with:
  - setting up, configuring, and customizing
    - a Cloud Workstation
    - developer tools
  - retrieving and working with code
    - using source code repositories
  - mastering the inner-development loop
    - application deployment
    - validation / testing
  - triggering the outer-development loop
    - pushing a change
    - observing the continuous integration pipeline execution
      - build of a container image
      - push to a container repository
      - signing of the image for binary authorization
    - observing the continuous deployment pipeline execution
      - release creation
      - rollout to a target after rendering of manifest
2. establishing an understanding and acquiring product knowledge (see below)

## Preparations 📝

- [Preparation 1](E0_preparations/01_workstation): Create and access your Cloud Workstation
- [Preparation 2](E0_preparations/02_git-config/): Configure your Version Control System (VCS) client
- [Preparation 3](E0_preparations/03_gcloud/): Setup Google Cloud CLI
- [Preparation 4](E0_preparations/04_kubectl/): Kubernetes cluster credentials and setup
- [Preparation 5](E0_preparations/05_skaffold/): Set Default Container Repository for Skaffold

## Exercises 📝

- [Exercise 1](E1_git-clone/): Source Repositories
- [Exercise 2](E2_skaffold-dev/): Inner development loop
- [Exercise 3](E3_git-push/): Outer development loop
- [Exercise 4](E4_binary_auth/): Verifying the images

## Product Knowledge

- Knowledge 1: [Cloud Workstations](https://cloud.google.com/workstations/docs/overview)
  - [architecture](https://cloud.google.com/workstations/docs/architecture)
  - [machine types](https://cloud.google.com/workstations/docs/available-machine-types)
  - [images](https://cloud.google.com/workstations/docs/preconfigured-base-images)
    - [customize container images](https://cloud.google.com/workstations/docs/customize-container-images)
  - [VPC Service Controls and private clusters](https://cloud.google.com/workstations/docs/configure-vpc-service-controls-private-clusters)
  - [local JetBrains IDEs](https://cloud.google.com/workstations/docs/develop-code-using-local-jetbrains-ides)
  - [Duet AI](https://cloud.google.com/workstations/docs/write-code-duet-ai)
- Knowledge 2: [Skaffold](https://skaffold.dev/)
  - [skaffold.yaml Reference](https://skaffold.dev/docs/references/yaml/)
  - related tools for
    - build, e.g., [jib](https://skaffold.dev/docs/builders/builder-types/jib/) (Java) or [ko](https://ko.build/) (Go)
    - rendering of (hydration of image tags in) manifests
    - deployment, e.g., via [kustomize](https://kustomize.io/)
  - [profiles](https://skaffold.dev/docs/environment/profiles/)
- Knowledge 3: [Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)
  - [kustomization](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/)
    - [namespaces](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/namespace/)
- Knowledge 4: [Cloud Build](https://cloud.google.com/build/docs/overview)
  - [triggers](https://cloud.google.com/build/docs/triggers)
  - [private pools](https://cloud.google.com/build/docs/private-pools/private-pools-overview)
  - [config file](https://cloud.google.com/build/docs/build-config-file-schema)
- Knowledge 5: [Cloud Deploy](https://cloud.google.com/deploy/docs/overview)
  - [pipelines and targets](https://cloud.google.com/deploy/docs/create-pipeline-targets)
  - [releases and rollouts](https://cloud.google.com/deploy/docs/view-release)
  - [deployment strategies](https://cloud.google.com/deploy/docs/deployment-strategies)
  - [promotion and approvals](https://cloud.google.com/deploy/docs/promote-release)
  - [release automation](https://cloud.google.com/deploy/docs/automation)
  - [Skaffold and Cloud Deploy](https://cloud.google.com/deploy/docs/using-skaffold)
- Knowledge 6: [GKE Autopilot](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview)
  - [deployment: compute classes](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-compute-classes)
  - [autoscaling](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview#scale_workloads)
  - [security](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-security)
  - [placement](https://cloud.google.com/kubernetes-engine/docs/how-to/gke-zonal-topology)
  - [binary authorization](https://cloud.google.com/architecture/binary-auth-with-cloud-build-and-gke)

## Further Reading

- [Skaffold Deep-Dive - Codelab](https://codelabs.developers.google.com/skaffold-deep-dive)
- [Rearchitecting to Cloud-Native - Article](https://cloud.google.com/resources/rearchitecting-to-cloud-native)
