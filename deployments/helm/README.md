# NVIDIA Device Plugin Helm Chart Deployment

## Overview

This document describes how to properly deploy the NVIDIA Device Plugin Helm chart on openSUSE-based Rancher clusters with custom NVIDIA Container Toolkit integration.

## Prerequisites

1. **Custom Rancher Image**: A Rancher container built with NVIDIA Container Toolkit support for openSUSE
2. **Container Runtime**: Containerd configured with `nvidia-container-runtime` as default runtime
3. **GPU Hardware**: NVIDIA GPUs available on the cluster nodes
4. **NVIDIA Drivers**: Host system with NVIDIA drivers installed

## Installation

### Basic Installation Command

```bash
helm install nvidia-device-plugin ./nvidia-device-plugin \
  --namespace nvidia \
  --create-namespace \
  --set driver.enabled=false \
  --set deviceDiscoveryStrategy=nvml \
  --set nvidiaDriverRoot=/usr
```

### Key Configuration Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `driver.enabled` | `false` | Disable driver installation (using host drivers) |
| `deviceDiscoveryStrategy` | `nvml` | Use NVML library for GPU detection |
| `nvidiaDriverRoot` | `/usr` | Path to NVIDIA libraries on host |

### Upgrade Command

```bash
helm upgrade nvidia-device-plugin ./nvidia-device-plugin \
  --namespace nvidia \
  --set driver.enabled=false \
  --set deviceDiscoveryStrategy=nvml \
  --set nvidiaDriverRoot=/usr
```

## Troubleshooting

### Common Issues and Solutions

#### Issue: "Incompatible strategy detected auto"

**Error Message:**
```
E0615 11:32:10.631201       1 factory.go:112] Incompatible strategy detected auto
E0615 11:32:10.631206       1 factory.go:113] If this is a GPU node, did you configure the NVIDIA Container Toolkit?
```

**Root Cause:** 
- Default `deviceDiscoveryStrategy: auto` cannot detect GPUs
- The device plugin cannot determine the appropriate discovery method

**Solution:**
Set explicit discovery strategy: `--set deviceDiscoveryStrategy=nvml`

#### Issue: "Failed to initialize NVML: ERROR_LIBRARY_NOT_FOUND"

**Error Message:**
```
E0615 11:44:17.967419       1 factory.go:93] Failed to initialize NVML: ERROR_LIBRARY_NOT_FOUND.
```

**Root Cause:**
- Device plugin pod cannot access NVIDIA libraries
- Missing volume mount for NVIDIA driver libraries
- Default `nvidiaDriverRoot` is not set or incorrect

**Solution:**
Set driver root path: `--set nvidiaDriverRoot=/usr`

This mounts the host's `/usr` directory (containing NVIDIA libraries) into the pod at `/driver-root`.

## Verification

### Check Device Plugin Status

```bash
# Verify pod is running
kubectl get pods -n nvidia

# Check logs for successful initialization
kubectl logs -n nvidia -l app.kubernetes.io/name=nvidia-device-plugin

# Verify GPU resources are advertised
kubectl describe node <node-name> | grep nvidia.com/gpu
```

### Expected Output

Successful deployment should show:
- Pod status: `Running`
- Logs: `Registered device plugin for 'nvidia.com/gpu' with Kubelet`
- Node capacity: `nvidia.com/gpu: <number-of-gpus>`

## Technical Details

### Why Standard GPU Operator Won't Work

The NVIDIA GPU Operator is designed for Ubuntu-based systems and cannot be used on openSUSE-based Rancher clusters because:

1. **Driver Installation**: GPU Operator expects Ubuntu package management and drivers
2. **Container Toolkit**: Assumes Ubuntu-specific installation paths and methods
3. **System Dependencies**: Built for Ubuntu/RHEL ecosystem, not openSUSE

### Custom Solution Architecture

1. **Custom Rancher Image**: Built with openSUSE + NVIDIA Container Toolkit
2. **Host Driver Integration**: Uses existing host NVIDIA drivers
3. **Library Access**: Mounts host NVIDIA libraries via `nvidiaDriverRoot`
4. **Direct Device Plugin**: Deploys only the device plugin, not the full operator

### Container Runtime Configuration

The working containerd configuration sets:
```toml
[plugins.cri.containerd]
  default_runtime_name = "nvidia"

[plugins.cri.containerd.runtimes."nvidia"]
  runtime_type = "io.containerd.runc.v2"
[plugins.cri.containerd.runtimes."nvidia".options]
  BinaryName = "/usr/bin/nvidia-container-runtime"
```

## Deployment History

This solution was developed to resolve GPU access issues on openSUSE-based Rancher clusters where:
- Standard GPU Operator deployment failed due to OS incompatibility
- Default device plugin configuration couldn't detect GPUs
- NVML library access required custom volume mounting

The final working configuration combines explicit GPU discovery strategy with proper library path mounting to enable GPU scheduling in Kubernetes workloads.