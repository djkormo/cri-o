#!/usr/bin/env bats

#
# This file is used to hook each test in $NRITEST_BINARY to
# BATS as a separate test case for more granular test result
# reporting. It needs to be updated whenever test cases are
# added to or removed from the test binary.
#

load helpers

function setup() {
	setup_test
	NRITEST_BINARY=${NRITEST_BINARY:-${CRIO_ROOT}/test/nri/nri.test}
	NRITEST_LOG="$TESTDIR/nri.test.log"
	NRI_SOCKET="$TESTDIR/nri.sock"
	enable_nri
}

function enable_nri() {
	touch "$TESTDIR/nri.conf"
	cat << EOF > "$CRIO_CONFIG_DIR/zz-nri.conf"
[crio.nri]
enable_nri = true
nri_config_file = "$TESTDIR/nri.conf"
nri_listen = "$NRI_SOCKET"
EOF
}

function teardown() {
	if [ -f "$NRITEST_LOG" ]; then
		echo "# --- nri.test.log :: ---"
		cat "$NRITEST_LOG"
		echo "# --- --- ---"
		echo "# --- environment :: ---"
		env
		echo "# --- --- ---"
		echo "# --- user and groups :: ---"
		id -a
		echo "# --- --- ---"
		echo "# --- mounts :: ---"
		mount
		echo "# --- --- ---"
	fi
	cleanup_test
}

function run_test() {
	# shellcheck disable=SC2153
	$NRITEST_BINARY \
		--crio-socket "unix://$CRIO_SOCKET" \
		--nri-socket "unix://$NRI_SOCKET" \
		--cgroup-manager "$CONTAINER_CGROUP_MANAGER" "$@" >&"$NRITEST_LOG"

	if [[ "$status" -ne "0" ]]; then
		# shellcheck disable=SC2034
		BATS_ERROR_SUFFIX=", expected exit status 0, got $status"
		return 1
	fi
}

@test "run NRI PluginRegistration test" {
	start_crio
	run_test -test.run TestPluginRegistration
}

@test "run NRI PluginSynchronization test" {
	start_crio
	run_test -test.run TestPluginSynchronization
}

@test "run NRI PodEvents test" {
	start_crio
	run_test -test.run TestPodEvents
}

@test "run NRI ContainerEvents test" {
	start_crio
	run_test -test.run TestContainerEvents
}

@test "run NRI MountInjection test" {
	if [ "$KUBERNETES_PROVIDER" = "local" ]; then
		skip "skip host bind-mount test (ci/prow)"
	fi
	start_crio
	run_test -test.run TestMountInjection
}

@test "run NRI EnvironmentInjection test" {
	start_crio
	run_test -test.run TestEnvironmentInjection
}

@test "run NRI AnnotationInjection test" {
	start_crio
	run_test -test.run TestAnnotationInjection
}

@test "run NRI DeviceInjection test" {
	if [[ -n "$TEST_USERNS" ]]; then
		skip "skip test for user namespace"
	fi
	start_crio
	run_test -test.run TestDeviceInjection
}

@test "run NRI CpusetAdjustment test" {
	start_crio
	run_test -test.run TestCpusetAdjustment
}

@test "run NRI MemsetAdjustment test" {
	start_crio
	run_test -test.run TestMemsetAdjustment
}

@test "run NRI CpusetAdjustmentUpdate test" {
	start_crio
	run_test -test.run TestCpusetAdjustmentUpdate
}

@test "run NRI MemsetAdjustmentUpdate test" {
	start_crio
	run_test -test.run TestMemsetAdjustmentUpdate
}
