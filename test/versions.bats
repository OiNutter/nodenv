#!/usr/bin/env bats

load test_helper

create_version() {
  mkdir -p "${NODENV_ROOT}/versions/$1"
}

setup() {
  mkdir -p "$NODENV_TEST_DIR"
  cd "$NODENV_TEST_DIR"
}

stub_system_node() {
  local stub="${NODENV_TEST_DIR}/bin/node"
  mkdir -p "$(dirname "$stub")"
  touch "$stub" && chmod +x "$stub"
}

@test "no versions installed" {
  stub_system_node
  assert [ ! -d "${NODENV_ROOT}/versions" ]
  run nodenv-versions
  assert_success "* system (set by ${NODENV_ROOT}/version)"
}

@test "bare output no versions installed" {
  assert [ ! -d "${NODENV_ROOT}/versions" ]
  run nodenv-versions --bare
  assert_success ""
}

@test "single version installed" {
  stub_system_node
  create_version "1.9"
  run nodenv-versions
  assert_success
  assert_output <<OUT
* system (set by ${NODENV_ROOT}/version)
  1.9
OUT
}

@test "single version bare" {
  create_version "1.9"
  run nodenv-versions --bare
  assert_success "1.9"
}

@test "multiple versions" {
  stub_system_node
  create_version "1.8.7"
  create_version "1.9.3"
  create_version "2.0.0"
  run nodenv-versions
  assert_success
  assert_output <<OUT
* system (set by ${NODENV_ROOT}/version)
  1.8.7
  1.9.3
  2.0.0
OUT
}

@test "indicates current version" {
  stub_system_node
  create_version "1.9.3"
  create_version "2.0.0"
  NODENV_VERSION=1.9.3 run nodenv-versions
  assert_success
  assert_output <<OUT
  system
* 1.9.3 (set by NODENV_VERSION environment variable)
  2.0.0
OUT
}

@test "bare doesn't indicate current version" {
  create_version "1.9.3"
  create_version "2.0.0"
  NODENV_VERSION=1.9.3 run nodenv-versions --bare
  assert_success
  assert_output <<OUT
1.9.3
2.0.0
OUT
}

@test "globally selected version" {
  stub_system_node
  create_version "1.9.3"
  create_version "2.0.0"
  cat > "${NODENV_ROOT}/version" <<<"1.9.3"
  run nodenv-versions
  assert_success
  assert_output <<OUT
  system
* 1.9.3 (set by ${NODENV_ROOT}/version)
  2.0.0
OUT
}

@test "per-project version" {
  stub_system_node
  create_version "1.9.3"
  create_version "2.0.0"
  cat > ".node-version" <<<"1.9.3"
  run nodenv-versions
  assert_success
  assert_output <<OUT
  system
* 1.9.3 (set by ${NODENV_TEST_DIR}/.node-version)
  2.0.0
OUT
}
