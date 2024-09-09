# Exercise 1: Source Repositories 📝

Having opened your Cloud Workstation, let's deploy an Hello World application to GKE Autopilot!

First, let's fork and/or clone the following Git repository:

```
https://github.com/googlecloudplatform/cicd-foundation
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
git clone https://github.com/googlecloudplatform/cicd-foundation
```

#### References 🔗

- [git-clone](https://git-scm.com/docs/git-clone)
</details>

### Open Folder

👉 press `Control`+`K` + `Control`+`O`, select the new folder and press `Enter`

## Working with a private repository

Eventually, you may want to work with your own, private source repository when you push changes that shall be applied in your real-life environment.

### Secure Source Manager

A Secure Source Manager (SSM) instance has been provisioned, e.g., by a central-IT team.
Also a Git repository within this instance has been created with write permissions for you.

To work with Secure Source Manager configure the `gcloud` helper (cf. [documentation](https://cloud.google.com/secure-source-manager/docs/use-git#install_git_and)):

```sh
git config --global credential.'https://*.*.sourcemanager.dev'.helper gcloud.sh
```
</details><br/>

👉 Add the Git repository as a remote repository

<details>
<summary>gcloud</summary>

```sh
export GOOGLE_IDENTITY="alex@example.com"
export SSM_INSTANCE_NAME="cicd-foundation"

export TEAM=$(echo "${GOOGLE_IDENTITY%%@*}" | tr -dc '[:alnum:]')
export PROJECT_NUMBER=$(gcloud projects describe $GOOGLE_CLOUD_PROJECT --format='value(projectNumber)')
export GIT_URL="https://${SSM_INSTANCE_NAME}-${PROJECT_NUMBER}-git.${REGION}.sourcemanager.dev/${GOOGLE_CLOUD_PROJECT}/${TEAM}.git"

git remote add private $GIT_URL

```
</details><br/>

👉 Push to the remote repository.

<details>
<summary>git</summary>

```sh
git push --all private
```
</details>

## Set the namespace

In the following files set the namespace to your team identifier:
- [`envs/base/kustomization.yaml`](../../apps/go-hello-world/envs/base/kustomization.yaml)
- [`envs/base/namespace.yaml`](../../apps/go-hello-world/envs/base/namespace.yaml)

You can use the following commands to output your team identifier (specify your Google Identity):
```sh
export GOOGLE_IDENTITY="alex@example.com"
export TEAM=$(echo "${GOOGLE_IDENTITY%%@*}" | tr -dc '[:alnum:]')
echo $TEAM
```

This namespace will be used across all the environments (unless overwritten).

Finally, commit and push your changes to your repository.

<details>
<summary>git</summary>

```sh
git add .
git commit -m "setting namespace"
git push private
```
</details>

## References 🔗

- [Version control with Cloud Workstations](https://cloud.google.com/workstations/docs/version-control#clone_a_repository)
- [Secure Source Manager](https://cloud.google.com/secure-source-manager)
  - [Use Git source code management](https://cloud.google.com/secure-source-manager/docs/use-git)
