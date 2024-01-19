# Configure your Default Container Repository

Get the URL of your container repository and export as `$SKAFFOLD_DEFAULT_REPO`.

<details>
<summary>Artifact Registry</summary>

💡 You can lookup existing artifact repositories with the following command:

```sh
gcloud artifacts repositories list
```

(👉) Create a container repository.

Just in case you would like to work with your own repository.
Otherwise, a central, shared container repository could be used by developers.
With Binary Authorization enabled at the runtime (e.g., GKE) it can be ensured that images have been built as part of the CI pipeline.
Thus, developers can be granted permissions to the repository.

```sh
gcloud artifacts repositories create $REPO_NAME --repository-format=docker --location=$REPO_REGION
```

#### References 🔗

- [Artifact Registry: Create Reposistory](https://cloud.google.com/artifact-registry/docs/repositories/create-repos)
- [Artifact Registry Locations](https://cloud.google.com/artifact-registry/docs/repositories/repo-locations)

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


With Skaffold, a default repository can be set per Kubernetes context (see below).

<details>
<summary>global default</summary>
👉 To set a global default repository execute the following command:

```sh
skaffold config set --global default-repo $SKAFFOLD_DEFAULT_REPO
```
and replace `$SKAFFOLD_DEFAULT_REPO` with the name of your container repository.
</details><br/>

If you would like to associate a Kubernetes context with a particular container repository (recommended) proceed with the following steps:

👉 Prior to setting the default repo, you need to set the Kubernetes context.

<details>
<summary>Kubernetes Context</summary>

👉 You need to fetch (at least once) the credentials for accessing the Kubernetes cluster.

<details>
<summary>gcloud</summary>

```sh
gcloud container clusters get-credentials $CLUSTER_NAME --region $CLUSTER_REGION
```

💡 You can lookup existing clusters with their name and region with the following command:
```sh
gcloud container clusters list
```

#### References 🔗

- [gcloud container clusters get-credentials](https://cloud.google.com/sdk/gcloud/reference/container/clusters/get-credentials)
</details><br/>

Alternatively to gcloud, you can directly use `kubectl` in case you already imported the credentials earlier:
<details>
<summary>kubectl</summary>

```sh
kubectl config get-contexts
```

#### References 🔗

- [kubectl config get-contexts](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-get-contexts-em-)

```sh
kubectl config use-context $CLUSTER_CONTEXT
```

#### References 🔗

- [kubectl config use-context](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-use-context-em-)
</details>
</details><br/>

👉 Finally set the default container repository.

<details>
<summary>Skaffold</summary>

The following command will associate the specified repository with the active Kubernetes context:

```sh
skaffold config set default-repo $SKAFFOLD_DEFAULT_REPO
```
Replace `$SKAFFOLD_DEFAULT_REPO` with the URL of the repository if necessary.
</details><br/>

(👉) Validate the config.

<details>
<summary>Skaffold</summary>

You can inspect the config file of skaffold. Notice the `kubeContexts` in addition to the `global` section.

```sh
cat ~/.skaffold/config
```
</details><br/>

#### References 🔗

- [Image Repository Handling](https://skaffold.dev/docs/environment/image-registries/)
