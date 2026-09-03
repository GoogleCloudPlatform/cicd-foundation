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
