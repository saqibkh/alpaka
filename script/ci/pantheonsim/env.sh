#!/usr/bin/env bash

#
# Copyright 2026 Saqib Khan
# SPDX-License-Identifier: MPL-2.0
#

# shellcheck disable=SC2034

# Set up the environment to use the PantheonSim GPU simulator, which was installed by install/pantheonsim.sh.
# The simulated GPU is selected via APCI_PANTHEONSIM, e.g. nvidia/h100.
#
# The simulated GPU is only visible for programs, which are started via `vgpu run`.

: "${APCI_ALPAKA_ROOT?'APCI_ALPAKA_ROOT is not defined. Root directory of the alpaka project'}"
# shellcheck source=script/ci/utils/default.sh
source "${APCI_ALPAKA_ROOT}/script/ci/utils/default.sh"

load_variable_if_not_exist APCI_PANTHEONSIM_BUILD_DIR

export VGPU_GPU="${APCI_PANTHEONSIM}"
export VGPU_SHIM_DIR="${APCI_PANTHEONSIM_BUILD_DIR}/shim"
APCI_VGPU="${APCI_PANTHEONSIM_BUILD_DIR}/vgpu"
