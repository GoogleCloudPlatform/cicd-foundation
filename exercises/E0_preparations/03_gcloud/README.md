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

# Preparation 3: Setup Google Cloud CLI

For a first time setup you can execute the following command as an alternative to the steps below:

```sh
gcloud init
```

#### References 🔗

- [Initializing the gcloud CLI](https://cloud.google.com/sdk/docs/initializing)

## Authentication

👉 Authenticate in a terminal using the Google Cloud CLI.

In contrast to the other steps such authentication will regularly be required.

<details>
<summary>gcloud</summary>

```sh
gcloud auth login
```

### Configure Trusted Domains

- select: "Trust `google.com` and all its subdomains"
- `Copy` the verification code after login
- close the window (e.g., `Control`+`W`)
- paste the verification code into the terminal (e.g., `Control`+`V`)
  and press `Enter`
</details>

## Set default GCP project

<details>
<summary>gcloud</summary>

```sh
gcloud config set project $GOOGLE_CLOUD_PROJECT
```

Replace `$GOOGLE_CLOUD_PROJECT` with a GCP project ID if this variable is not defined.

#### References 🔗

- [Run gcloud auth login](https://cloud.google.com/sdk/docs/authorizing#auth-login)
</details><br/>

⚠️ With gcloud you can always specify the `--project` option to explicitly select a (different) GCP project which may not be the active one.
