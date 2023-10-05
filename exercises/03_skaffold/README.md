# Configure your Default Container Repository

With Skaffold, a default repository can be set per Kubernetes context.

👉 Thus, prior to setting the default repo, set the Kubernetes context.

<details>
<summary>Kubernetes Context</summary>

<details>
<summary>gcloud</summary>

```sh
gcloud container clusters get-credentials $CLUSTER_NAME --region $CLUSTER_REGION
```

#### References 🔗

- [gcloud container clusters get-credentials](https://cloud.google.com/sdk/gcloud/reference/container/clusters/get-credentials)
</details><br/>

Alternatively to gcloud, you could directly use `kubectl` in case you already had imported the config earlier:
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

(👉) Create a container repository.

<details>
<summary>Artifact Registry</summary>

```sh
gcloud artifacts repositories create $REPO_NAME --repository-format=docker --location=$REPO_REGION
```

#### References 🔗

- [Artifact Registry: Create Reposistory](https://cloud.google.com/artifact-registry/docs/repositories/create-repos)
- [Artifact Registry Locations](https://cloud.google.com/artifact-registry/docs/repositories/repo-locations)
</details><br/>

👉 Set the default container repository.

<details>
<summary>Skaffold</summary>

```sh
skaffold config set default-repo $SKAFFOLD_DEFAULT_REPO
```
</details><br/>

(👉) Validate the config.

<details>
<summary>Skaffold</summary>

```sh
cat ~/.skaffold/config
```

#### References 🔗

- [Image Repository Handling](https://skaffold.dev/docs/environment/image-registries/)
</details><br/>
