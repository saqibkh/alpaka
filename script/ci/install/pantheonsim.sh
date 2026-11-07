#!/usr/bin/env bash

#
# Copyright 2026 Saqib Khan
# SPDX-License-Identifier: MPL-2.0
#

: "${APCI_ALPAKA_ROOT?'APCI_ALPAKA_ROOT is not defined. Root directory of the alpaka project'}"
# shellcheck source=script/ci/utils/default.sh
source "${APCI_ALPAKA_ROOT}/script/ci/utils/default.sh"

# Build the PantheonSim GPU simulator (https://github.com/pantheongpu/pantheonsim). It runs the PTX of
# CUDA programs on the CPU, therefore the job does not need a GPU.
#
# Configuration via environment variables:
# - APCI_PANTHEONSIM: The simulated GPU, e.g. nvidia/h100 (`vgpu list-gpus`). 0 disables the simulator.
# - APCI_PANTHEONSIM_BUILD_DIR: Where the simulator is built. The directory can be cached between jobs.
#       If it already contains a build, the build is skipped.
# - APCI_PANTHEONSIM_SRC_DIR: Where the source code of the simulator is cloned (optional).
# - APCI_PANTHEONSIM_GIT_URL: Source of the simulator (optional).
# - APCI_PANTHEONSIM_GIT_REV: Commit of the simulator (optional).

if [[ "${APCI_PANTHEONSIM:-0}" != 0 ]]; then
    if [[ "$APCI_OS_NAME" != "Linux" ]]; then
        exit_error "Install PantheonSim script does not support Windows or MacOS"
    fi

    : "${APCI_CUDA?'PantheonSim simulates a CUDA GPU, therefore the CUDA version must be specified'}"

    script_msg "Install PantheonSim"

    APCI_PANTHEONSIM_GIT_URL="${APCI_PANTHEONSIM_GIT_URL:-https://github.com/pantheongpu/pantheonsim.git}"
    # the simulator version which was used to validate the alpaka tests
    APCI_PANTHEONSIM_GIT_REV="${APCI_PANTHEONSIM_GIT_REV:-735c26269c305319d294d463b53fda054a5aa0f9}"
    APCI_PANTHEONSIM_SRC_DIR="${APCI_PANTHEONSIM_SRC_DIR:-/opt/pantheonsim-src}"
    APCI_PANTHEONSIM_BUILD_DIR="${APCI_PANTHEONSIM_BUILD_DIR:-/opt/pantheonsim-build}"

    load_variable_if_not_exist APCI_CMAKE_BIN_PATH
    load_variable_if_not_exist APCI_CXX_COMPILER
    load_variable_if_not_exist CMAKE_CUDA_COMPILER

    # the simulator is built against the headers of the CUDA toolkit, which it finds via the nvcc in the PATH
    PATH="$(dirname "${CMAKE_CUDA_COMPILER}"):${PATH}"
    export PATH

    if [[ -x "${APCI_PANTHEONSIM_BUILD_DIR}/vgpu" ]]; then
        echo_yellow "${APCI_PANTHEONSIM_BUILD_DIR}/vgpu already exist. Skip build."
    else
        _pantheonsim_src_dir="${APCI_PANTHEONSIM_SRC_DIR}"
        mkdir -p "${_pantheonsim_src_dir}"
        echo_run git -C "${_pantheonsim_src_dir}" init --quiet
        echo_run git -C "${_pantheonsim_src_dir}" fetch --quiet --depth 1 "${APCI_PANTHEONSIM_GIT_URL}" "${APCI_PANTHEONSIM_GIT_REV}"
        echo_run git -C "${_pantheonsim_src_dir}" checkout --quiet FETCH_HEAD

        # The C compiler needs to be the same GCC version as the C++ compiler, otherwise the link time optimization fails.
        _pantheonsim_cc="$(dirname "${APCI_CXX_COMPILER}")/$(basename "${APCI_CXX_COMPILER}" | sed 's/g++/gcc/')"

        # the simulator needs to be built with the shared CUDA libraries from the toolkit
        echo_run "${APCI_CMAKE_BIN_PATH}/cmake" -S "${_pantheonsim_src_dir}" -B "${APCI_PANTHEONSIM_BUILD_DIR}" \
            -G Ninja -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_CXX_COMPILER="${APCI_CXX_COMPILER}" -DCMAKE_C_COMPILER="${_pantheonsim_cc}"
        echo_run "${APCI_CMAKE_BIN_PATH}/cmake" --build "${APCI_PANTHEONSIM_BUILD_DIR}" -j"${APCI_BUILD_THREADS:-$(nproc)}"

        unset _pantheonsim_src_dir _pantheonsim_cc
    fi

    # vgpu finds the simulated CUDA libraries beside itself
    if [[ ! -e "${APCI_PANTHEONSIM_BUILD_DIR}/bin/vgpu" ]]; then
        ln -s ../vgpu "${APCI_PANTHEONSIM_BUILD_DIR}/bin/vgpu"
    fi

    echo_run "${APCI_PANTHEONSIM_BUILD_DIR}/vgpu" info --gpu "${APCI_PANTHEONSIM}"

    store_variable APCI_PANTHEONSIM_BUILD_DIR
else
    echo_green "Skipped install PantheonSim because it is not required for the job."
fi
