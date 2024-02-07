# Exercise 1: Source Repositories 📝

Having opened your Cloud Workstation, let's deploy an Hello World application to GKE Autopilot!

First, let's fork or clone the following Git repository:

```
https://github.com/googlecloudplatform/cicd-jumpstart
```

## Get the code

### GitHub

👉 Using your GitHub account, **fork** the repository in GitHub.  
👉 Clone the forked repository after authentication from your Cloud Workstation.

<details>
<summary>VSCode</summary>

- press `Control`+`Shift`+`P`
- type `git.clone` and press `Enter`
- select `Clone from GitHub`
- enter the name of the forked repository
- authenticate @ GitHub
</details>

## References 🔗

- [GitHub: Fork a repository](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo)

### Fallback Options

You can skip this part in case you forked the repository in GitHub.

<details>
<summary>VSCode</summary>

- press `Control`+`Shift`+`P`
- type `git.clone` and press `Enter`
- select a folder and/or press `Enter`
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
</details>

### Open Folder

👉 press `Control`+`K` + `Control`+`O`, select the new folder and press `Enter`

## Working with a private repository

Eventually, you may want work with your own, private source repository when you want to push changes that shall be applied in your real-life environment.

### Cloud Source Repository

Your (private) Cloud Source Repository has been provisioned, e.g., by a central-IT team.

<details>
<summary>Create a Cloud Source Repository</summary>

#### gcloud

```sh
gcloud source repos create $CSR_REPO_NAME
```

- Use `$CSR_REPO_NAME` for the name of the repository.

#### Terraform

Use the [`google_sourcerepo_repository`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sourcerepo_repository) Terraform resource.
</details><br/>

👉 Configure the gcloud helper

<details>
<summary>gcloud</summary>

```sh
git config --global credential.https://source.developers.google.com.helper gcloud.sh
```
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

## References 🔗

- [Version control with Cloud Workstations](https://cloud.google.com/workstations/docs/version-control#clone_a_repository)
- [Cloud Source Repositories](https://cloud.google.com/source-repositories)
- [Clone using the gcloud CLI](https://cloud.google.com/source-repositories/docs/cloning-repositories#clone-using-the-cloud-sdk)
- [`gcloud source repos`](https://cloud.google.com/sdk/gcloud/reference/source/repos)
