# Exercise 2: Inner development loop 📝

👉 Open a Terminal (`Ctrl`+`Shift`+<code>`</code>) and change to the directory of the example application:

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

<details>
<summary>HTTP Request</summary>

👉 Open an additional Terminal (`Ctrl`+`Shift`+<code>`</code>) and execute:

```sh
curl http://127.0.0.1:8080/
```
Note that this is possible due to port-forwarding as defined in the `dev` profile of the `skaffold.yaml`.

In case you deployed an `HTTPRoute` for a `Gateway` you can lookup the IP-address with:
```sh
kubectl get gateway
```
and use it with the standard HTTP Port 80 (cf. `apps/hello-world/k8s/base/gateway.yaml`):
```sh
curl http://$GATEWAY_IP:80/
```
</details>

### Hot reloading

<details>
<summary>Customize the response</summary>

👉 Uncomment the last 3 lines in `/apps/hello-world/k8s/base/deployment.yaml`.

👉 Watch skaffold do the redeployment.

👉 Test/validate with `curl` as previously to see the effect of your changes.

You may want to customize the value of the `NAME` environment variable.

Also you can modify `/apps/hello-world/src/main.go`, e.g., by uppercassing "Hello".
</details>
