# Rancher GPU Setup - Fixed Configuration

This directory contains the **FIXED** configuration for setting up GPU support in the Rancher-based Kubernetes cluster.

## Problem Solved

The original configuration had a critical issue where the containerd default runtime was set to "nvidia", causing all pods to fail when the nvidia runtime wasn't properly configured. This has been fixed.

## Key Changes Made

### 1. Containerd Configuration Fix

**Before (Broken):**
```toml
[plugins.cri.containerd]
  default_runtime_name = "nvidia"  # This caused all pods to fail
```

**After (Fixed):**
```toml
[plugins.cri.containerd]
  default_runtime_name = "runc"    # Safe default, nvidia runtime is optional
```

### 2. Proper Runtime Configuration

The nvidia runtime is now properly configured as an optional runtime:

```toml
[plugins.cri.containerd.runtimes.nvidia]
  runtime_type = "io.containerd.runc.v2"

[plugins.cri.containerd.runtimes.nvidia.options]
  BinaryName = "/usr/bin/nvidia-container-runtime"
  SystemdCgroup = false
```

### 3. Device Plugin Requirements

The NVIDIA Device Plugin requires:
- **Privileged security context** for hardware access
- **Device node access** via `/dev` mount
- **Proper driver root** configuration (`/driver-root`)

## Usage

### 1. Build and Run Rancher Container

```bash
# Build the custom Rancher image with NVIDIA support
docker build -t rancher-nvidia .

# Run with GPU access (adjust paths as needed)
docker run -d \
  --name rancher \
  --privileged \
  --runtime=nvidia \
  --gpus all \
  --device /dev/nvidia0:/dev/nvidia0 \
  --device /dev/nvidia1:/dev/nvidia1 \
  --device /dev/nvidiactl:/dev/nvidiactl \
  --device /dev/nvidia-uvm:/dev/nvidia-uvm \
  --device /dev/nvidia-uvm-tools:/dev/nvidia-uvm-tools \
  --restart=unless-stopped \
  -p 80:80 \
  -p 443:443 \
  -p 5000:5000 \
  -v /lib/modules:/lib/modules \
  -v /path/to/cluster-data:/root/cluster-data \
  rancher-nvidia
```

### 2. Apply Fixed Containerd Configuration

```bash
# Run the setup script to apply the fixed containerd config
./setup_cluster.sh
```

### 3. Deploy NVIDIA Device Plugin

Use the **updated helm chart** with proper security context:

```bash
cd ../deployments/helm/nvidia-device-plugin/

helm install nvidia-device-plugin . \
  --namespace nvidia \
  --create-namespace \
  --set driver.enabled=false \
  --set deviceDiscoveryStrategy=nvml \
  --set nvidiaDriverRoot=/usr
```

### 4. Verify GPU Access

Test with a simple pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-test
spec:
  runtimeClassName: nvidia
  containers:
  - name: gpu-test
    image: nvidia/cuda:11.8-runtime-ubuntu20.04
    command: ["nvidia-smi"]
    resources:
      limits:
        nvidia.com/gpu: 1
```

Expected result: GPU information displayed successfully.

## Files in This Directory

- **`Dockerfile`**: Custom Rancher image with NVIDIA Container Toolkit
- **`setup_cluster.sh`**: Script to apply fixed containerd configuration
- **`README.md`**: This documentation file

## Troubleshooting

### Check Device Plugin Status

```bash
kubectl get pods -n nvidia
kubectl logs <device-plugin-pod> -n nvidia
```

### Verify GPU Advertisement

```bash
kubectl describe node <node-name> | grep nvidia.com/gpu
# Should show: nvidia.com/gpu: 2
```

### Test Container GPU Access

```bash
kubectl exec <gpu-pod> -- nvidia-smi
```

## Related Documentation

- **Main Fix Documentation**: `../../../FIX.md`
- **Helm Chart**: `../deployments/helm/nvidia-device-plugin/`
- **Infrastructure Reference**: `../../blueprints/PROJECT_REFERENCE.md`

---

**Status**: ✅ **FIXED** - GPU runtime fully operational
**Last Updated**: June 15, 2025