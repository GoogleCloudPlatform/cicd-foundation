# Exercise 1: Source Repositories 📝

Having opened your Cloud Workstation, let's deploy an Hello World application to GKE Autopilot!

First, let's fork or clone the following Git repository:

```
https://github.com/googlecloudplatform/cicd-jumpstart
```

If you fork the repository in GitHub skip the next section.

## Get the code

You can skip this part in case you forked the repository.

<details>
<summary>VSCode</summary>

- press `Control`+`Shift`+`P`
- type `git.clone` and press Enter
- select a folder and/or press Enter
- `Open` the cloned repository
</details><br/>

<details>
<summary>Terminal</summary>

👉 press `Control`+`Shift`+<code>`</code>

```sh
git clone https://github.com/googlecloudplatform/cicd-jumpstart
```

#### References 🔗

- [git-clone](https://git-scm.com/docs/git-clone)

👉 press `Control`+`K` + `Control`+`O`, select the new folder and press Enter
</details>

## Working with your repository

Eventually, you need to work with your own source repository when you want to push changes that shall be applied in your real-life environment.

### GitHub

👉 If you have forked the code in GitHub clone the code after authentication.

<details>
<summary>GitHub</summary>

- press `Control`+`Shift`+`P`
- type `git.clone` and press Enter
- select `Clone from GitHub`
- enter the name of the repo
- authenticate @ GitHub
</details>

### Cloud Source Repository

👉 Create a Cloud Source Repository

<details>
<summary>gcloud</summary>

```sh
gcloud source repos create $CSR_REPO_NAME
```

- Use `$CSR_REPO_NAME` for the name of the repository.
- Specify the `--project` option to explicitly select a GCP project which may not be the active one.
</details><br/>

👉 Add the repository as a remote repository

<details>
<summary>gcloud</summary>

```sh
export CSR_REPO_URL=$(gcloud source repos describe $CSR_REPO_NAME | grep "url:" | sed -e 's/url: //')
git remote add google $CSR_REPO_URL
```
</details><br/>

👉 Push to the remote repository

<details>
<summary>git</summary>

```sh
git push --all google
```
</details>


## Open Folder

👉 Press `Ctrl`+`K` + `Ctrl`+`O`
and select the new directory

## References 🔗

- [Version control with Cloud Workstations](https://cloud.google.com/workstations/docs/version-control#clone_a_repository)
- [Cloud Source Repositories](https://cloud.google.com/source-repositories)
- [Clone using the gcloud CLI](https://cloud.google.com/source-repositories/docs/cloning-repositories#clone-using-the-cloud-sdk)
- [`gcloud source repos`](https://cloud.google.com/sdk/gcloud/reference/source/repos)
