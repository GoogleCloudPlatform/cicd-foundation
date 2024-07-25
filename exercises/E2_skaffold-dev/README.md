# Exercise 2: Inner development loop 📝

👉 Open a Terminal (`Control`+`Shift`+<code>`</code>) and change to the directory of the example application:

```sh
cd apps/go-hello-world/
```

<details>
<summary>Authenticate</summary>

```sh
gcloud auth login
gcloud auth configure-docker $REGION-docker.pkg.dev
```

#### References 🔗

- [gcloud credential helper](https://cloud.google.com/artifact-registry/docs/docker/authentication#gcloud-helper)
</details><br/>

<details>
<summary>Skaffold</summary>

⚠️ Did you [set the default container repository for Skaffold](../04_skaffold/)?

```sh
skaffold dev
```
</details>

### Validating the deployment

⚠️ In case you are using [Remote-SSH](../01_workstation/README.md#remote-ssh) a `Preview Link` is provided that you can open.

<details>
<summary>HTTP Request</summary>

👉 Open an additional Terminal (`Control`+`Shift`+<code>`</code>) and execute:

```sh
curl http://127.0.0.1:8080/
```
Note that this is possible due to port-forwarding as defined in the `dev` profile of the `skaffold.yaml`.

In case you deployed an `HTTPRoute` for an **external** `Gateway` (cf. [`gateway.yaml`](../../apps/go-hello-world/envs/base/gateway.yaml#L29)) you can lookup the IP-address with:
```sh
kubectl get gateway
```
and use it with a standard port (cf. [`gateway.yaml`](../../apps/go-hello-world/envs/base/gateway.yaml#L38)):
```sh
curl http://$GATEWAY_IP/
```

Note: By default an **internal** Application Load Balancer is used that can only be accessed within the VPC network.
</details>

### Hot reloading

<details>
<summary>Customize the response</summary>

👉 Uncomment the last 3 lines in [`deployment.yaml`](../../apps/go-hello-world/envs/base/deployment.yaml#L45).

👉 Watch `skaffold dev` do the redeployment.

👉 Test/validate with `curl` as previously to see the effect of your changes.

You may want to customize the value of the `NAME` environment variable as defined in the [`deployment.yaml`](../../apps/go-hello-world/envs/base/deployment.yaml#L46).

Also you can modify [`main.go`](../../apps/go-hello-world/src/main.go#L55), e.g., by uppercassing `Hello` or translating it to another language.
</details>
