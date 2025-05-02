# linux_binary_cache

## Overview

This repository contains Linux kernels for benchmarks which need Linux VMs as baselines.

`vmlinuz-5.15.0-105` is compiled from Linux 5.15.105 source code with default settings, except for enabling the Ext2 file system and disabling `SYSTEM_REVOCATION_KEYS` and `SYSTEM_TRUSTED_KEYS`. The kernel already includes VirtIO drivers such as `Virtio-Net` and `Virtio-Block`.

