#!/usr/bin/env bats

load test_helper

setup_file() {
  if ! command -v "pack" &>/dev/null; then
    add-apt-repository --yes ppa:cncf-buildpacks/pack-cli
    apt-get update
    apt-get --yes install pack-cli
  fi
}

setup() {
  create_app
}

teardown() {
  destroy_app
}

@test "(builder-pack:set)" {
  run /bin/bash -c "dokku builder:set $TEST_APP selected pack"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku buildpacks:set-property $TEST_APP stack heroku/buildpacks:20"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run deploy_app python dokku@dokku.me:$TEST_APP inject_requirements_txt
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output_contains 'Building with buildpack 1' 0
  assert_output_contains 'Installing requirements with pip'

  run /bin/bash -c "dokku builder-pack:set $TEST_APP projecttoml-path nonexistent.toml"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku ps:rebuild $TEST_APP"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output_contains 'Building with buildpack 1' 0
  assert_output_contains 'Installing requirements with pip'

  run /bin/bash -c "dokku builder-pack:set $TEST_APP projecttoml-path project2.toml"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku ps:rebuild $TEST_APP"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output_contains 'Building with buildpack 1'
  assert_output_contains 'Installing requirements with pip' 0

  run /bin/bash -c "dokku builder-pack:set $TEST_APP projecttoml-path"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku ps:rebuild $TEST_APP"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output_contains 'Building with buildpack 1' 0
  assert_output_contains 'Installing requirements with pip'
}

inject_requirements_txt() {
  local APP="$1"
  local APP_REPO_DIR="$2"
  [[ -z "$APP" ]] && local APP="$TEST_APP"
  echo "flask" >>"$APP_REPO_DIR/requirements.txt"
}
