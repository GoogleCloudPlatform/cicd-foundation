# Exercise 4: Verifying the images

## Check what are the CVEs affecting your image

👉 Go to [Artifact Registry](https://console.cloud.google.com/artifacts), select the latest image, and select the Vulnerabilities tab.

## Check what is the current Binary Authorization and Kritis policies.

👉 Go to [Binary Authorization](https://console.cloud.google.com/security/binary-authorization/policy) in Console to vizualize the policy.  
👉 Go to your local [`tools/kritis`](../../tools/kritis/) folder to vizualize the [kritis policy](../../tools/kritis/vulnz-signing-policy.yaml).

## Introduce a vulnerability

👉 Inside your `main.go` file, import and use a library with a vulnerability. For example, uncomment the following:

```go
	"gopkg.in/yaml.v2"
```

```go
	// Sample call to an outdated library
	var a struct{}
	data := []byte("Foo: bar")
	err := yaml.Unmarshal(data, &a)
	_ = err
```

👉 In `go.mod` uncomment the outdated dependency:

```go
require gopkg.in/yaml.v2 v2.2.3
```

👉 Commit these and push to the repository.

```sh
git add .
git commit -m "introduced an old library with vulnerabilities"
git push private
```

👉 Check the results of [Cloud Build](https://console.cloud.google.com/cloud-build/builds) and [Cloud Deploy](https://console.cloud.google.com/deploy/delivery-pipelines).  
If you try to promote your release to `PROD`, it will fail.

👉 Go to [Artifact Registry](https://console.cloud.google.com/artifacts), to see the Vulnerabilities introduced. 
