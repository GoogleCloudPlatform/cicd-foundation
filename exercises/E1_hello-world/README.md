# Exercise 1: Deploying a Hello World Application 📝

Having opened your Cloud Workstation, let's now deploy an Hello World application to GKE Autopilot!

## Getting the Code

👉 clone the repository from (select from below):

<details>
<summary>Cloud Source Repository</summary>

```sh
gcloud source repos clone $CSR_REPO --project=$GOOGLE_CLOUD_PROJECT
```

#### References 🔗

- [Cloud Source Repositories](https://cloud.google.com/source-repositories)
- [Clone using the gcloud CLI](https://cloud.google.com/source-repositories/docs/cloning-repositories#clone-using-the-cloud-sdk)
- [`gcloud source repos`](https://cloud.google.com/sdk/gcloud/reference/source/repos)
</details><br/>

<details>
<summary>GitHub</summary>

- press `Control`+`Shift`+`P`
- type `Git: Clone` and press enter
- select `Clone from GitHub`
- enter the name of the repo
- authenticate @ GitHub

#### References 🔗

- [Cloud Workstations](https://cloud.google.com/workstations/docs/version-control#clone_a_repository)
</details><br/>

## Inner development loop

⚠️ Did you [set the default container repository for Skaffold](../03_skaffold/) for your kubernetes context?

<details>
<summary>Skaffold</summary>

```sh
cd apps/hello-world/
skaffold dev
```
</details><br/>

## Outer development loop

GitOps style: Automated through CI / CD pipelines - triggered by commiting to the repository

<details>
<summary>Git</summary>

```sh
git commit -m "Hello-World application"
git push
```
</details><br/>
