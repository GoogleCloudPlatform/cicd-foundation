# Exercise 3: Outer development loop 📝

Now that we successfully ran and validated the application let's deploy it through secure CI / CD pipelines.

That is, for the outer development loop we are adopting GitOps.
This way we profit from full automation triggered by pushing to the repository.

## Push your changes

<details>
<summary>Git</summary>

Add your changes with
```sh
git add .
```

and commit these and push to the repository.
```sh
git commit -m "customized greeting"
git push
```
</details>

## Continuous Integration

This will trigger a CI pipeline with Cloud Build.

👉 Watch the build and push to Artifact Registry in Console.

## Continuous Deployment

As a last step of the CI pipeline, a new release will be created.
This in trun triggers the CD pipeline.

👉 Navigate to Cloud Deploy and watch the rollout(s) of the release (after rendering).

## Validate

👉 Finally validate deployment with `curl` (after establishing a port-forwarding if necessary).

<details>
<summary>curl</summary>

```sh
kubectl port-forward deployments/hello-world 9000:8080 &
curl http://127.0.0.1:9000
kill %1
```
</details>
