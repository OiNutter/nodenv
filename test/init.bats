#!/usr/bin/env bats

load test_helper

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
  assert_line "nodenv rehash 2>/dev/null"
}

@test "setup shell completions" {
  root="$(cd $BATS_TEST_DIRNAME/.. && pwd)"
  run nodenv-init - bash
  assert_success
  assert_line "source '${root}/libexec/../completions/nodenv.bash'"
}

@test "detect parent shell" {
  root="$(cd $BATS_TEST_DIRNAME/.. && pwd)"
  SHELL=/bin/false run nodenv-init -
  assert_success
  assert_line "export NODENV_SHELL=bash"
}

@test "setup shell completions (fish)" {
  root="$(cd $BATS_TEST_DIRNAME/.. && pwd)"
  run nodenv-init - fish
  assert_success
  assert_line ". '${root}/libexec/../completions/nodenv.fish'"
}

@test "fish instructions" {
  run nodenv-init fish
  assert [ "$status" -eq 1 ]
  assert_line 'status --is-interactive; and . (nodenv init -|psub)'
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
  assert_line 0 'export PATH="'${NODENV_ROOT}'/shims:${PATH}"'
}

@test "adds shims to PATH (fish)" {
  export PATH="${BATS_TEST_DIRNAME}/../libexec:/usr/bin:/bin:/usr/local/bin"
  run nodenv-init - fish
  assert_success
  assert_line 0 "setenv PATH '${NODENV_ROOT}/shims' \$PATH"
}

@test "doesn't add shims to PATH more than once" {
  export PATH="${NODENV_ROOT}/shims:$PATH"
  run nodenv-init - bash
  assert_success
  refute_line 'export PATH="'${NODENV_ROOT}'/shims:${PATH}"'
}

@test "doesn't add shims to PATH more than once (fish)" {
  export PATH="${NODENV_ROOT}/shims:$PATH"
  run nodenv-init - fish
  assert_success
  refute_line 'setenv PATH "'${NODENV_ROOT}'/shims" $PATH ;'
}
