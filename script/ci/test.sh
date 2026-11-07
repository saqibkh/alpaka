#!/usr/bin/env bash

#
# Copyright 2026 Simeon Ehrig
# SPDX-License-Identifier: MPL-2.0
#

# shellcheck source=script/ci/utils/default.sh
source "${APCI_ALPAKA_ROOT}/script/ci/utils/default.sh"

script_msg "Run CTest (test.sh)"

LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-""}

if [[ "$APCI_ONEAPI" != 0 ]]; then
    if [[ ! "${APCI_IMAGE_NAME}" =~ "intel/oneapi" ]]; then
        load_variable_if_not_exist ONEAPI_PATH
        # shellcheck source=script/ci/install/oneapi/setvars.sh
        source "${APCI_ALPAKA_ROOT}/script/ci/install/oneapi/setvars.sh"
        export LD_LIBRARY_PATH="/opt/intel/oneapi/compiler/${APCI_ONEAPI}/lib/:${LD_LIBRARY_PATH}"
    fi
    echo_green "sycl-ls"
    sycl-ls
fi

for sanitizer in ASAN TSAN LSAN UBSAN; do
    flag="APCI_SANITIZER_${sanitizer}"
    opt="${sanitizer}_OPTIONS"

    if [[ "${!flag}" == "ON" ]]; then
        load_variable_if_not_exist "${opt}"
    fi
done

parse_compiler_version "$APCI_DEVICE_COMPILER"

if [[ "${APCI_RUN_CTEST}" == "ON" ]]; then
    load_variable_if_not_exist APCI_CMAKE_BIN_PATH

    CTEST_CMD=("${APCI_CMAKE_BIN_PATH}/ctest" --test-dir /build --output-on-failure)

    if [[ "${APCI_PANTHEONSIM:-0}" != 0 ]]; then
        # shellcheck source=script/ci/pantheonsim/env.sh
        source "${APCI_ALPAKA_ROOT}/script/ci/pantheonsim/env.sh"
        # shellcheck source=script/ci/pantheonsim/config.sh
        source "${APCI_ALPAKA_ROOT}/script/ci/pantheonsim/config.sh"

        # Some tests return early and pass if no CUDA device is available.
        # Therefore, check that the simulated GPU is visible before running the tests.
        echo_green "nvidia-smi -L"
        _gpu_list=$("${APCI_PANTHEONSIM_BUILD_DIR}/bin/nvidia-smi" -L)
        echo "${_gpu_list}"
        if ! grep -q "^GPU 0:" <<<"${_gpu_list}"; then
            exit_error "The simulated GPU ${APCI_PANTHEONSIM} is not visible. The tests would not run on a GPU."
        fi

        CTEST_CMD=("${APCI_VGPU}" run "${CTEST_CMD[@]}" --timeout 300 -E "${APCI_PANTHEONSIM_CTEST_EXCLUDE}")
    fi

    echo_green \
        "$(echo_if_not_empty LD_LIBRARY_PATH)" \
        "$(echo_if_not_empty_and_set ASAN_OPTIONS)" \
        "$(echo_if_not_empty_and_set TSAN_OPTIONS)" \
        "$(echo_if_not_empty_and_set LSAN_OPTIONS)" \
        "$(echo_if_not_empty_and_set UBSAN_OPTIONS)" \
        "${CTEST_CMD[*]}"

    "${CTEST_CMD[@]}"
else
    echo_yellow "Skip running ctest"
fi
