#!/usr/bin/env bats

load test_helper

setup() {
  export PATH="${NODENV_TEST_DIR}/bin:$PATH"
}

create_executable() {
  local name="$1"
  local bin="${NODENV_TEST_DIR}/bin"
  mkdir -p "$bin"
  sed -Ee '1s/^ +//' > "${bin}/$name"
  chmod +x "${bin}/$name"
}

@test "creates shims and versions directories" {
  assert [ ! -d "${NODENV_ROOT}/shims" ]
  assert [ ! -d "${NODENV_ROOT}/versions" ]
  run nodenv-init -
  assert_success
  assert [ -d "${NODENV_ROOT}/shims" ]
  assert [ -d "${NODENV_ROOT}/versions" ]
}

@test "auto rehash" {
  run nodenv-init -
  assert_success
  assert_line "command nodenv rehash 2>/dev/null"
}

@test "setup shell completions" {
  root="$(cd $BATS_TEST_DIRNAME/.. && pwd)"
  run nodenv-init - bash
  assert_success
  assert_line "source '${root}/test/../libexec/../completions/nodenv.bash'"
}

@test "detect parent shell" {
  SHELL=/bin/false run nodenv-init -
  assert_success
  assert_line "export NODENV_SHELL=bash"
}

@test "detect parent shell from script" {
  mkdir -p "$NODENV_TEST_DIR"
  cd "$NODENV_TEST_DIR"
  cat > myscript.sh <<OUT
#!/bin/sh
eval "\$(nodenv-init -)"
echo \$NODENV_SHELL
OUT
  chmod +x myscript.sh
  run ./myscript.sh
  assert_success
  assert_output "sh"
}

@test "skip shell completions (fish)" {
  root="$(cd $BATS_TEST_DIRNAME/.. && pwd)"
  run nodenv-init - fish
  assert_success
  local line="$(grep '^source' <<<"$output")"
  [ -z "$line" ] || flunk "did not expect line: $line"
}

@test "posix shell instructions" {
  run nodenv-init bash
  assert [ "$status" -eq 1 ]
  assert_line 'eval "$(nodenv init - bash)"'
}

@test "fish instructions" {
  run nodenv-init fish
  assert_failure 1
  assert_line 'status --is-interactive; and nodenv init - fish | source'
}

@test "option to skip rehash" {
  run nodenv-init - --no-rehash
  assert_success
  refute_line "nodenv rehash 2>/dev/null"
}

@test "adds shims to PATH" {
  export PATH="${BATS_TEST_DIRNAME}/../libexec:/usr/bin:/bin:/usr/local/bin"
  run nodenv-init - bash
  assert_success
  assert_line -n 0 'export PATH="'${NODENV_ROOT}'/shims:${PATH}"'
}

@test "adds shims to PATH (fish)" {
  export PATH="${BATS_TEST_DIRNAME}/../libexec:/usr/bin:/bin:/usr/local/bin"
  run nodenv-init - fish
  assert_success
  assert_line -n 0 "set -gx PATH '${NODENV_ROOT}/shims' \$PATH"
}

@test "can add shims to PATH more than once" {
  export PATH="${NODENV_ROOT}/shims:$PATH"
  run nodenv-init - bash
  assert_success
  assert_line -n 0 'export PATH="'${NODENV_ROOT}'/shims:${PATH}"'
}

@test "can add shims to PATH more than once (fish)" {
  export PATH="${NODENV_ROOT}/shims:$PATH"
  run nodenv-init - fish
  assert_success
  assert_line -n 0 "set -gx PATH '${NODENV_ROOT}/shims' \$PATH"
}

@test "outputs sh-compatible syntax" {
  run nodenv-init - bash
  assert_success
  assert_line '  case "$command" in'

  run nodenv-init - zsh
  assert_success
  assert_line '  case "$command" in'
}

@test "outputs sh-compatible case syntax" {
  create_executable nodenv-commands <<!
#!$BASH
echo -e 'rehash\nshell'
!
  run nodenv-init - bash
  assert_success
  assert_line '  rehash|shell)'

  create_executable nodenv-commands <<!
#!$BASH
echo
!
  run nodenv-init - bash
  assert_success
  assert_line '  /)'
}

@test "outputs fish-specific syntax (fish)" {
  run nodenv-init - fish
  assert_success
  assert_line '  switch "$command"'
  refute_line '  case "$command" in'
}
