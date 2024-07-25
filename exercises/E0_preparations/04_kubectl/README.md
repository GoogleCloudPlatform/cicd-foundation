# Preparation 4: Kubernetes cluster credentials and setup

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

## Set the preferred namespace

👉 Configure the context to use your preferred namespace.

For the hands-on workshop use the localpart of your Google Identity without any non-latin characters for the namespace.

<details>
<summary>kubectl</summary>

```sh
export GOOGLE_IDENTITY="alex@example.com"

export TEAM=$(echo "${GOOGLE_IDENTITY%%@*}" | tr -dc '[:alnum:]')
kubectl config set-context --current --namespace=$TEAM
```
</details>

#### References 🔗

- [Setting the namespace preferences](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/#setting-the-namespace-preference)
