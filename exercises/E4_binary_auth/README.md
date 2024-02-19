# Exercise 4: Verifying the images

## Check what are the CVEs affecting your image

👉 Go to Artifact Registry, select the latest image, and select the Vulnerabilities tab.   

## Check what is the current Binary Authorization and Kritis policies. 

👉 Go to Binary Authorization in Console to vizualize the policy.  
👉 Go to your local `cicd/kritis` folder to vizualize the kritis policy. 

## Introduce a vulnerability

👉 Inside your `main.go`` file, import and use a library with a vulnerability. For example, uncomment the following: 

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

👉 commit these and push to the repository.

```sh
git add .
git commit -m "introduced an old library with vulnerabilities"
git push google
```

👉 Check the results of Cloud Build and Cloud Deploy.  
If you try to promote your release to PROD, it will fail.

👉 Go to Artifact Registry, to see the Vulnerabilities introduced. 
