<!--
Copyright 2026 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

# Preparation 5: Configure your default container repository for Skaffold

👉 Get the URL of your container repository and export as `$SKAFFOLD_DEFAULT_REPO`.

<details>
<summary>Artifact Registry</summary>

💡 You can lookup existing artifact repositories with the following command:

```sh
gcloud artifacts repositories list
```

A central, shared container repository could be used by developers.
With Binary Authorization enabled at the runtime (e.g., GKE) it can be ensured that images have been built as part of the CI pipeline.
Thus, developers can be granted permissions to the repository.

👉 Get the URL of the repository

```sh
gcloud artifacts repositories describe $REPO_NAME --location=$REPO_REGION
```

👉 export as `SKAFFOLD_DEFAULT_REPO`

```sh
export SKAFFOLD_DEFAULT_REPO=$(gcloud artifacts repositories describe $REPO_NAME --location=$REPO_REGION 2>&1 | grep "Registry URL" | sed -e 's/Registry URL:\ //')
```

#### References 🔗

- [Repository and image names](https://cloud.google.com/artifact-registry/docs/docker/names)

</details><br/>

With Skaffold, a default repository can be set (globally).
Such repository can also be set on a per Kubernetes context basis (see below).

<details>
<summary>Skaffold</summary>
👉 To set a global default repository execute the following command:

```sh
skaffold config set --global default-repo $SKAFFOLD_DEFAULT_REPO
```
and replace `$SKAFFOLD_DEFAULT_REPO` with the name of your container repository.
</details>

## Container repository per Kubernetes context

If you would like to associate a Kubernetes context with a particular container repository (recommended) proceed with the following steps:

⚠️ Prior to setting the default repo, you need to set the Kubernetes context, cf. [previous task](../04_kubectl/README.md).

👉 Finally set the default container repository.

<details>
<summary>Skaffold</summary>

The following command will associate the specified repository with the active Kubernetes context:

```sh
skaffold config set default-repo $SKAFFOLD_DEFAULT_REPO
```
Replace `$SKAFFOLD_DEFAULT_REPO` with the URL of the repository if necessary.
</details><br/>

#### References 🔗

- [Image Repository Handling](https://skaffold.dev/docs/environment/image-registries/)

##  Validate the config.

👉 Inspect your skaffold config file.

<details>
<summary>Skaffold config</summary>

Notice the `kubeContexts` in addition to the `global` section and look for `default-repo` entries.

```sh
cat ~/.skaffold/config
```
</details>
