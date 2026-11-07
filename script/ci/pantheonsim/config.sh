#!/usr/bin/env bash

#
# Copyright 2026 Saqib Khan
# SPDX-License-Identifier: MPL-2.0
#

# shellcheck disable=SC2034

# Selection of the tests, which are built and run with the CUDA backend on the PantheonSim GPU simulator.

# Catch2 unit tests, which are built (cmake --build --target) and run.
APCI_PANTHEONSIM_TARGETS=(
    unit_test_queue_queue
    unit_test_queue_kernelMD
    unit_test_queue_isEmpty
    unit_test_queue_blockingQueue
    unit_test_event_event
    unit_test_mem_alloc
    unit_test_mem_allocDeferred
    unit_test_mem_memcpy
    unit_test_mem_memset
    unit_test_mem_fill
    unit_test_mem_view
    unit_test_mem_lifetime
    unit_test_mem_memFenceBasic
    unit_test_mem_memFenceProducerConsumer
    unit_test_atomic_atomic
    unit_test_atomic_atomicAdd
    unit_test_block_block
    unit_test_sharedMem_sharedMem
    unit_test_deviceGlobalMem_deviceGlobalMem
    unit_test_device_deviceProperties
    unit_test_cvecKernelCall_cvecKernelCall
    unit_test_kernel_makeIdxMap
    unit_test_intrinsic_clz
    unit_test_intrinsic_ffs
    unit_test_intrinsic_popc
    unit_test_warp_activemask
    unit_test_warp_all
    unit_test_warp_any
    unit_test_warp_ballot
    unit_test_warp_getSize
    unit_test_warp_iota
    unit_test_warp_shfl
    unit_test_warp_shfl_down
    unit_test_warp_shfl_up
    unit_test_warp_shfl_xor
    unit_test_algorithm_concurrent
    unit_test_algorithm_iota
    unit_test_algorithm_reduce
    unit_test_algorithm_scan
    unit_test_algorithm_transform
    unit_test_algorithm_transformReduce
    unit_test_rand_uniformReal
    unit_test_platform_platform
)

# Regular expression for the ctest option -E.
# - Tests of targets that were not built are registered as *_NOT_BUILT.
# - The other tests depend on the queue state while a host function (cuLaunchHostFunc) is running.
#   The simulator does not model that yet.
APCI_PANTHEONSIM_CTEST_EXCLUDE='_NOT_BUILT|queue isEmpty|wait for event enqueued concurrently on a queue with a long-running host task|elapsed-time query waits for both events'
