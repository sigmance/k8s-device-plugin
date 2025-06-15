# Helm Charts for GPU Device Plugin

This directory contains Helm charts for deploying GPU support in the Kubernetes cluster.

## Available Charts

### NVIDIA Device Plugin (Fixed)

**Location**: `nvidia-device-plugin/`  
**Status**: ✅ **FIXED** - GPU runtime issues resolved  
**Description**: Deploys NVIDIA Device Plugin with critical fixes for GPU access

## Quick Start

### Prerequisites

1. **Rancher container** with fixed containerd configuration
2. **NVIDIA drivers** installed on GPU nodes
3. **Helm 3.x** installed

### Installation Command

```bash
# Navigate to the chart directory
cd nvidia-device-plugin/

# Install with the working configuration
helm install nvidia-device-plugin . \
  --namespace nvidia \
  --create-namespace \
  --set driver.enabled=false \
  --set deviceDiscoveryStrategy=nvml \
  --set nvidiaDriverRoot=/usr
```

### Verification

```bash
# Check device plugin status
kubectl get pods -n nvidia

# Verify GPU advertisement
kubectl describe node <node-name> | grep nvidia.com/gpu
# Expected: nvidia.com/gpu: <your-gpu-count>

# Test GPU access
kubectl run gpu-test --rm -it --image=nvidia/cuda:11.8-runtime-ubuntu20.04 \
  --overrides='{"spec":{"runtimeClassName":"nvidia","containers":[{"name":"gpu-test","image":"nvidia/cuda:11.8-runtime-ubuntu20.04","command":["nvidia-smi"],"resources":{"limits":{"nvidia.com/gpu":"1"}}}]}}' \
  --restart=Never
```

## Fixed Issues

The charts in this directory contain fixes for:

### 1. Device Plugin Security Context
- Added `privileged: true` for hardware access
- Proper capabilities for device node access

### 2. Device Access
- Added `/dev` directory mount for GPU device nodes
- Proper volume configurations

### 3. Driver Configuration
- Correct `nvidiaDriverRoot` path (`/driver-root`)
- Proper NVML discovery strategy

### 4. Runtime Configuration
- Compatible with fixed containerd configuration
- Supports both `runc` and `nvidia` runtimeClass

## Documentation

Each chart contains its own detailed README:

- **[NVIDIA Device Plugin README](nvidia-device-plugin/README.md)** - Complete installation and troubleshooting guide

## Related Documentation

- **[Main Fix Documentation](../../../FIX.md)** - Complete problem analysis and solution
- **[Rancher Setup](../rancher/README.md)** - Infrastructure setup guide
- **[Infrastructure Reference](../../blueprints/PROJECT_REFERENCE.md)** - Architecture documentation

## Support

For issues or questions:

1. Check the individual chart README files
2. Review the main fix documentation
3. Verify prerequisite infrastructure setup

---

**Last Updated**: June 15, 2025  
**Status**: Production ready with GPU runtime fixes applied