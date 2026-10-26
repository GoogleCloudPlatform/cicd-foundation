#!/usr/bin/env bats

# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load test_helper.bash

setup() {
  export MOCK_BIN="${BATS_TEST_TMPDIR}/mock_bin"
  export MOCK_LOG="${BATS_TEST_TMPDIR}/mock_calls.log"
  export APP_DIR="${BATS_TEST_TMPDIR}/sample-app"
  mkdir -p "${MOCK_BIN}" "${APP_DIR}/envs/base" "${APP_DIR}/envs/dev" "${APP_DIR}/envs/prod"
  : > "${MOCK_LOG}"

  cat > "${APP_DIR}/skaffold.yaml" <<'EOF'
apiVersion: skaffold/v4beta11
kind: Config
metadata:
  name: sample-app
EOF

  cat > "${APP_DIR}/envs/base/.env" <<'EOF'
PUBLIC_SERVICES="frontend api"
TEAM="core"
EOF

  cat > "${APP_DIR}/envs/dev/.env" <<'EOF'
PROJECT_ID="test-proj"
REGION="europe-west1"
EOF

  cat > "${APP_DIR}/envs/prod/.env" <<'EOF'
PROJECT_ID="prod-proj"
REGION="europe-west1"
EOF

  cat > "${APP_DIR}/envs/base/service.yaml.tmpl" <<'EOF'
env: ${ENV}
team_prefix: ${TEAM_PREFIX}
project: ${PROJECT_ID}
EOF

  # Create mock external binaries in MOCK_BIN
  for tool in skaffold gcloud poetry uv pip; do
    cat > "${MOCK_BIN}/${tool}" <<EOF
#!/bin/sh
echo "MOCK_${tool}: \$*" >> "${MOCK_LOG}"
if [ "${tool}" = "poetry" ] && [ "\$1" = "export" ]; then
  echo "flask==3.0.0" > requirements.txt
elif [ "${tool}" = "uv" ] && [ "\$1" = "export" ]; then
  echo "flask==3.1.0" > requirements.txt
fi
exit 0
EOF
    chmod +x "${MOCK_BIN}/${tool}"
  done

  export PATH="${MOCK_BIN}:${PATH}"
}

@test "common.sh getOpts parses short and long flags and sets OPT_SHIFT" {
  run bash -c '
    usage() { echo "USAGE"; }
    . "'"${BIN_DIR}"'/common.sh"
    getOpts "$@"
    shift "$OPT_SHIFT"
    echo "APP=$APP ROOT_DIR=$ROOT_DIR REM=$*"
  ' _ --app my-app --directory /tmp/dir dev
  [ "$status" -eq 0 ]
  [[ "$output" == *"APP=my-app ROOT_DIR=/tmp/dir REM=dev"* ]]
}

@test "common.sh getOpts supports --app= and --directory= equals syntax" {
  run bash -c '
    usage() { echo "USAGE"; }
    . "'"${BIN_DIR}"'/common.sh"
    getOpts "$@"
    shift "$OPT_SHIFT"
    echo "APP=$APP ROOT_DIR=$ROOT_DIR REM=$*"
  ' _ --app=demo --directory=/srv/demo run
  [ "$status" -eq 0 ]
  [[ "$output" == *"APP=demo ROOT_DIR=/srv/demo REM=run"* ]]
}

@test "common.sh checkDependencies fails with exit 1 when binary is missing" {
  run bash -c '
    . "'"${BIN_DIR}"'/common.sh"
    checkDependencies nonexistent_binary_xyz_123
  '
  [ "$status" -eq 1 ]
  [[ "$output" == *"nonexistent_binary_xyz_123 required but not found!"* ]]
}

@test "common.sh getRootDir exits with code 3 when outside app dir without --app or --directory" {
  run bash -c '
    cd "'"${BATS_TEST_TMPDIR}"'"
    usage() { echo "USAGE_CALLED"; }
    . "'"${BIN_DIR}"'/common.sh"
    getRootDir
  '
  [ "$status" -eq 3 ]
  [[ "$output" == *"skaffold.yaml not found!"* ]]
  [[ "$output" == *"USAGE_CALLED"* ]]
}

@test "common.sh generate renders env manifests and exports poetry/uv requirements" {
  mkdir -p "${APP_DIR}/src/svc-poetry" "${APP_DIR}/src/svc-uv"
  cat > "${APP_DIR}/src/svc-poetry/pyproject.toml" <<'EOF'
[build-system]
build-backend = "poetry.core.masonry.api"
EOF
  cat > "${APP_DIR}/src/svc-uv/pyproject.toml" <<'EOF'
[build-system]
build-backend = "hatchling.build"
EOF

  run bash "${BIN_DIR}/generate.sh"
  # Running outside APP_DIR without skaffold.yaml fails with exit 3
  [ "$status" -eq 3 ]

  run bash -c 'cd "'"${APP_DIR}"'" && bash "'"${BIN_DIR}"'/generate.sh"'
  [ "$status" -eq 0 ]
  [ -f "${APP_DIR}/envs/dev/service.yaml" ]
  [ -f "${APP_DIR}/envs/prod/service.yaml" ]
  grep -q "env: dev" "${APP_DIR}/envs/dev/service.yaml"
  grep -q "team_prefix: core-" "${APP_DIR}/envs/dev/service.yaml"
  grep -q "project: test-proj" "${APP_DIR}/envs/dev/service.yaml"
  grep -q "flask==3.0.0" "${APP_DIR}/src/svc-poetry/requirements.txt"
  grep -q "flask==3.1.0" "${APP_DIR}/src/svc-uv/requirements.txt"
}

@test "cloudrun.sh --help prints usage and exits 0 under both bash and sh" {
  run bash "${BIN_DIR}/cloudrun.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]

  run sh "${BIN_DIR}/cloudrun.sh" -h
  [ "$status" -eq 0 ]
  [[ "$output" == *"--directory"* ]]
}

@test "cloudrun.sh rejects unknown command with exit 2 and missing envs with exit 4" {
  run bash "${BIN_DIR}/cloudrun.sh" --directory "${APP_DIR}" bogus
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown command: bogus"* ]]

  rm -f "${APP_DIR}/envs/dev/.env"
  unset PROJECT_ID REGION
  run bash "${BIN_DIR}/cloudrun.sh" --directory "${APP_DIR}" dev
  [ "$status" -eq 4 ]
  [[ "$output" == *"Not all environment variables have been set:"* ]]
}

@test "cloudrun.sh dev runs skaffold dev without applyIAM" {
  run bash "${BIN_DIR}/cloudrun.sh" --directory "${APP_DIR}" dev
  [ "$status" -eq 0 ]
  grep -q "MOCK_skaffold: dev -f ${APP_DIR}/skaffold.yaml --cloud-run-project=test-proj --cloud-run-location=europe-west1" "${MOCK_LOG}"
  if grep -q "MOCK_gcloud:" "${MOCK_LOG}"; then
    return 1
  fi
}

@test "cloudrun.sh run deploys via skaffold and applies IAM bindings" {
  run bash "${BIN_DIR}/cloudrun.sh" --directory "${APP_DIR}" run
  [ "$status" -eq 0 ]
  grep -q "MOCK_skaffold: run -f ${APP_DIR}/skaffold.yaml --cloud-run-project=test-proj --cloud-run-location=europe-west1" "${MOCK_LOG}"
  grep -q "MOCK_gcloud: run services add-iam-policy-binding frontend --region europe-west1 --member=allUsers --role=roles/run.invoker" "${MOCK_LOG}"
  grep -q "MOCK_gcloud: run services add-iam-policy-binding api --region europe-west1 --member=allUsers --role=roles/run.invoker" "${MOCK_LOG}"
}

@test "cloudrun.sh iam applies IAM bindings without running skaffold" {
  run bash "${BIN_DIR}/cloudrun.sh" --directory "${APP_DIR}" iam
  [ "$status" -eq 0 ]
  if grep -q "MOCK_skaffold:" "${MOCK_LOG}"; then
    return 1
  fi
  grep -q "MOCK_gcloud: run services add-iam-policy-binding frontend" "${MOCK_LOG}"
}

@test "cloudrun.sh delete runs skaffold delete without applyIAM" {
  run bash "${BIN_DIR}/cloudrun.sh" --directory "${APP_DIR}" delete
  [ "$status" -eq 0 ]
  grep -q "MOCK_skaffold: delete -f ${APP_DIR}/skaffold.yaml" "${MOCK_LOG}"
  if grep -q "MOCK_gcloud:" "${MOCK_LOG}"; then
    return 1
  fi
}

@test "run.sh starts target uv service and returns 1 for missing service" {
  mkdir -p "${APP_DIR}/src/alpha" "${APP_DIR}/src/beta"
  cat > "${APP_DIR}/src/alpha/Procfile" <<'EOF'
web: echo ALPHA_STARTED
EOF
  cat > "${APP_DIR}/src/beta/pyproject.toml" <<'EOF'
[build-system]
build-backend = "hatchling.build"
EOF
  cat > "${APP_DIR}/src/beta/Procfile" <<'EOF'
web: echo BETA_STARTED
EOF

  run bash "${BIN_DIR}/run.sh" --directory "${APP_DIR}" beta
  [ "$status" -eq 0 ]
  [[ "$output" == *"ignoring service alpha"* ]]
  [[ "$output" == *"starting service: beta"* ]]
  grep -q "MOCK_uv: sync" "${MOCK_LOG}"
  grep -q "MOCK_uv: run sh -c echo BETA_STARTED" "${MOCK_LOG}"

  run bash "${BIN_DIR}/run.sh" --directory "${APP_DIR}" missing-svc
  [ "$status" -eq 1 ]
  [[ "$output" == *"did not find a service to start"* ]]
}

@test "test.sh runs skaffold build and skaffold test and cleans up temp file" {
  run bash "${BIN_DIR}/test.sh" --directory "${APP_DIR}"
  [ "$status" -eq 0 ]
  grep -q "MOCK_skaffold: build -f ${APP_DIR}/skaffold.yaml --file-output=" "${MOCK_LOG}"
  grep -q "MOCK_skaffold: test -f ${APP_DIR}/skaffold.yaml --build-artifacts=" "${MOCK_LOG}"

  local artifact_path
  artifact_path=$(sed -n 's/.*--file-output=//p' "${MOCK_LOG}" | head -n 1)
  [ -n "${artifact_path}" ]
  [ ! -e "${artifact_path}" ]
}

@test "relative ./ invocation inside bin/ resolves REPO_ROOT for --app and generate.sh --all" {
  local fake_repo="${BATS_TEST_TMPDIR}/fake_repo"
  mkdir -p "${fake_repo}/bin" "${fake_repo}/apps/non-skaffold-dir"
  cp "${BIN_DIR}/common.sh" "${BIN_DIR}/generate.sh" "${BIN_DIR}/cloudrun.sh" "${fake_repo}/bin/"
  chmod +x "${fake_repo}/bin/"*.sh
  cp -R "${APP_DIR}" "${fake_repo}/apps/sample-app"
  rm -f "${fake_repo}/apps/sample-app/envs/dev/service.yaml" "${fake_repo}/apps/sample-app/envs/prod/service.yaml"

  cat > "${fake_repo}/apps/.env" <<'EOF'
SHARED_PARENT_VAR="loaded-from-apps-env"
EOF

  run bash -c 'cd "'"${fake_repo}"'/bin" && ./generate.sh --all'
  [ "$status" -eq 0 ]
  [ -f "${fake_repo}/apps/sample-app/envs/dev/service.yaml" ]
  [ -f "${fake_repo}/apps/sample-app/envs/prod/service.yaml" ]

  run bash -c 'cd "'"${fake_repo}"'/bin" && ./cloudrun.sh --app sample-app dev'
  [ "$status" -eq 0 ]
  grep -q "MOCK_skaffold: dev -f ${fake_repo}/apps/sample-app/skaffold.yaml" "${MOCK_LOG}"

  run bash -c 'cd "'"${fake_repo}"'/apps/sample-app" && "'"${fake_repo}"'/bin/cloudrun.sh" --directory . iam'
  [ "$status" -eq 0 ]
  [[ "$output" == *"reading environment file ${fake_repo}/apps/.env"* ]]
}
