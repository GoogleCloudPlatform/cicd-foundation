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

- [Preparation 1](01_workstation/): Create and Access your Cloud Workstation
- [Preparation 2](02_git-config/): Git Config
- [Preparation 3](03_gcloud/): Google Cloud CLI
- [Preparation 4](04_skaffold/): Set Default Container Repository

## Exercises 📝

- [Exercise 1](E1_git-clone/): Source Repositories
- [Exercise 2](E2_skaffold-dev/): Inner development loop
- [Exercise 3](E3_git-push/): Outer development loop

## Product Knowledge

- Knowledge 1: [Cloud Workstations](https://cloud.google.com/workstations/docs/overview)
  - [machine types](https://cloud.google.com/workstations/docs/available-machine-types)
  - [images](https://cloud.google.com/workstations/docs/preconfigured-base-images)
- Knowledge 2: [Skaffold](https://skaffold.dev/)
  - related tools for
    - build, e.g., [jib](https://skaffold.dev/docs/builders/builder-types/jib/) (Java) or [ko](https://ko.build/) (Go)
    - rendering of (hydration of image tags in) manifests
    - deployment, e.g., via [kustomize](https://kustomize.io/)
  - [profiles](https://skaffold.dev/docs/environment/profiles/)
- Knowledge 3: Kustomize
  - [namespaces](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/namespace/)
- Knowledge 4: [Cloud Build](https://cloud.google.com/build/docs/overview)
  - [triggers](https://cloud.google.com/build/docs/triggers)
  - [config file](https://cloud.google.com/build/docs/build-config-file-schema)
- Knowledge 5: [Cloud Deploy](https://cloud.google.com/deploy/docs/overview)
  - [pipelines and targets](https://cloud.google.com/deploy/docs/create-pipeline-targets)
  - [releases and rollouts](https://cloud.google.com/deploy/docs/view-release)
- Knowledge 6: [GKE Autopilot](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview)
  - [deployment](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-compute-classes)
  - [autoscaling](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview#scale_workloads)
  - [security](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-security)

## Further Reading

- [Skaffold Deep-Dive - Codelab](https://codelabs.developers.google.com/skaffold-deep-dive)
- [Rearchitecting to Cloud-Native - Article](https://cloud.google.com/resources/rearchitecting-to-cloud-native)
