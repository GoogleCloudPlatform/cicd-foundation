# Exercise 2: Inner development loop 📝

👉 Open a Terminal (`Control`+`Shift`+<code>`</code>) and change to the directory of the example application:

```sh
cd apps/hello-world/
```
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

In case you deployed an `HTTPRoute` for an **external** `Gateway` (cf. [`gateway.yaml`](../../apps/hello-world/k8s/base/gateway.yaml)) you can lookup the IP-address with:
```sh
kubectl get gateway
```
and use it with the standard port (cf. [`gateway.yaml`](../../apps/hello-world/k8s/base/gateway.yaml)):
```sh
curl http://$GATEWAY_IP/
```

Note: By default an **internal** Application Load Balancer is used that can only be accessed within the VPC.
</details>

### Hot reloading

<details>
<summary>Customize the response</summary>

👉 Uncomment the last 3 lines in [`deployment.yaml`](../../apps/hello-world/k8s/base/deployment.yaml).

👉 Watch skaffold do the redeployment.

👉 Test/validate with `curl` as previously to see the effect of your changes.

You may want to customize the value of the `NAME` environment variable as defined in the [`deployment.yaml`](../../apps/hello-world/k8s/base/deployment.yaml).

Also you can modify [`main.go`](../../apps/hello-world/src/main.go), e.g., by uppercassing `Hello` or translating it to another language.
</details>
