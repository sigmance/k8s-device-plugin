# NVIDIA Device Plugin Helm Chart - Fixed for GPU Runtime

This Helm chart deploys the NVIDIA Device Plugin with **fixes applied** for proper GPU runtime support in the Rancher-based Kubernetes cluster.

## Problem Solved

This chart contains critical fixes for GPU runtime issues where containers could not access GPUs despite the device plugin advertising GPU resources. The original configuration lacked proper security context and device access.

## Key Fixes Applied

### 1. **Security Context Fix**
The device plugin now runs with proper privileges to access GPU hardware:

```yaml
securityContext:
  privileged: true
  allowPrivilegeEscalation: true
  capabilities:
    add:
    - ALL
```

### 2. **Device Access Fix**
Added `/dev` directory mount for GPU device node access:

```yaml
volumeMounts:
  - name: dev
    mountPath: /dev
volumes:
  - name: dev
    hostPath:
      path: /dev
```

### 3. **Driver Configuration Fix**
Proper NVIDIA driver root and discovery strategy:

```yaml
nvidiaDriverRoot: "/driver-root"
deviceDiscoveryStrategy: "nvml"
```

## Installation

### Prerequisites

1. **Rancher container** with fixed containerd configuration (see `../../rancher/setup_cluster.sh`)
2. **Kubernetes cluster** with GPU nodes properly labeled
3. **NVIDIA drivers** installed on the host system
4. **Helm 3.x** installed

### Quick Installation

```bash
# Navigate to the chart directory
cd infrastructure-project/k8s-device-plugin/deployments/helm/nvidia-device-plugin/

# Install with the fixed configuration
helm install nvidia-device-plugin . \
  --namespace nvidia \
  --create-namespace \
  --set driver.enabled=false \
  --set deviceDiscoveryStrategy=nvml \
  --set nvidiaDriverRoot=/usr
```

### Detailed Installation

```bash
# 1. Create namespace (if not exists)
kubectl create namespace nvidia

# 2. Install the device plugin with all required settings
helm install nvidia-device-plugin . \
  --namespace nvidia \
  --set driver.enabled=false \
  --set deviceDiscoveryStrategy=nvml \
  --set nvidiaDriverRoot=/usr \
  --set securityContext.privileged=true \
  --set securityContext.allowPrivilegeEscalation=true \
  --set nodeSelector."nvidia\.com/gpu"="true"
```

### Installation for Different Environments

#### Production Environment
```bash
helm install nvidia-device-plugin . \
  --namespace nvidia \
  --create-namespace \
  --set driver.enabled=false \
  --set deviceDiscoveryStrategy=nvml \
  --set nvidiaDriverRoot=/usr \
  --set priorityClassName=system-node-critical \
  --wait
```

#### Development Environment
```bash
helm install nvidia-device-plugin . \
  --namespace nvidia \
  --create-namespace \
  --set driver.enabled=false \
  --set deviceDiscoveryStrategy=nvml \
  --set nvidiaDriverRoot=/usr \
  --set resources.requests.memory=100Mi \
  --set resources.limits.memory=500Mi
```

## Verification

### 1. Check Device Plugin Status

```bash
# Verify pod is running
kubectl get pods -n nvidia
# Expected: nvidia-device-plugin-xxx  1/1  Running

# Check logs for successful initialization
kubectl logs -n nvidia $(kubectl get pods -n nvidia --no-headers | grep nvidia-device-plugin | awk '{print $1}')
# Expected: "Starting GRPC server for 'nvidia.com/gpu'"
#           "Registered device plugin for 'nvidia.com/gpu' with Kubelet"
```

### 2. Verify GPU Advertisement

```bash
# Check node GPU resources
kubectl describe node <node-name> | grep nvidia.com/gpu
# Expected: nvidia.com/gpu: 2 (or your actual GPU count)
```

### 3. Test GPU Access

Create a test pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-test
  namespace: default
spec:
  runtimeClassName: nvidia
  restartPolicy: Never
  containers:
  - name: gpu-test
    image: nvidia/cuda:11.8-runtime-ubuntu20.04
    command: ["nvidia-smi"]
    resources:
      limits:
        nvidia.com/gpu: 1
```

```bash
# Apply and check results
kubectl apply -f gpu-test.yaml
kubectl logs gpu-test
# Expected: GPU information displayed
```

### 4. Test PyTorch GPU Access

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pytorch-gpu-test
  namespace: default
spec:
  runtimeClassName: nvidia
  restartPolicy: Never
  containers:
  - name: pytorch-test
    image: pytorch/pytorch:latest
    command:
      - python
      - -c
      - "import torch; print('CUDA available:', torch.cuda.is_available()); print('GPU count:', torch.cuda.device_count())"
    env:
      - name: NVIDIA_VISIBLE_DEVICES
        value: "all"
      - name: NVIDIA_DRIVER_CAPABILITIES
        value: "compute,utility"
    resources:
      limits:
        nvidia.com/gpu: 1
```

## Configuration Options

### Essential Settings (Already configured in values.yaml)

| Parameter | Value | Description |
|-----------|-------|-------------|
| `nvidiaDriverRoot` | `"/driver-root"` | Path to NVIDIA drivers in container |
| `deviceDiscoveryStrategy` | `"nvml"` | Strategy for GPU discovery |
| `securityContext.privileged` | `true` | Required for hardware access |
| `securityContext.allowPrivilegeEscalation` | `true` | Required for device access |

### Optional Settings

| Parameter | Default | Description |
|-----------|---------|-------------|
| `driver.enabled` | `false` | Whether to deploy NVIDIA driver (disable for pre-installed) |
| `gfd.enabled` | `false` | Enable GPU Feature Discovery |
| `nodeSelector` | `nvidia.com/gpu: "true"` | Node selection criteria |
| `priorityClassName` | `system-node-critical` | Pod priority class |

## Upgrading

```bash
# Upgrade with same settings
helm upgrade nvidia-device-plugin . \
  --namespace nvidia \
  --set driver.enabled=false \
  --set deviceDiscoveryStrategy=nvml \
  --set nvidiaDriverRoot=/usr

# Check upgrade status
helm status nvidia-device-plugin -n nvidia
```

## Uninstalling

```bash
# Remove the device plugin
helm uninstall nvidia-device-plugin -n nvidia

# Optionally remove the namespace
kubectl delete namespace nvidia
```

## Troubleshooting

### Device Plugin CrashLoopBackOff

```bash
# Check logs for errors
kubectl logs -n nvidia <device-plugin-pod>

# Common issues:
# 1. "Driver Not Loaded" - Check privileged security context
# 2. "NVML Unknown Error" - Check /dev mount and device access
# 3. Mount errors - Verify volume mount configuration
```

### No GPUs Advertised

```bash
# Verify node has GPU label
kubectl get nodes --show-labels | grep nvidia.com/gpu

# Check device plugin daemonset
kubectl describe daemonset nvidia-device-plugin -n nvidia

# Verify GPU hardware on node
kubectl debug node/<node-name> -it --image=busybox -- ls /dev/nvidia*
```

### Container Cannot Access GPU

```bash
# Verify runtime class exists
kubectl get runtimeclass nvidia

# Check containerd configuration on node
kubectl debug node/<node-name> -it --image=busybox -- cat /etc/containerd/config.toml

# Test with privileged pod
kubectl run gpu-debug --rm -it --image=nvidia/cuda:11.8-runtime-ubuntu20.04 --privileged -- nvidia-smi
```

## Chart Structure

```
nvidia-device-plugin/
├── Chart.yaml                     # Chart metadata
├── values.yaml                    # Default configuration (FIXED)
├── templates/
│   ├── daemonset-device-plugin.yml # Main device plugin deployment (FIXED)
│   ├── configmap.yml              # Configuration management
│   ├── role.yml                   # RBAC permissions
│   ├── role-binding.yml           # RBAC bindings
│   └── service-account.yml        # Service account
└── charts/
    └── node-feature-discovery-chart-0.16.6.tgz
```

## Related Documentation

- **Main Fix Documentation**: `../../../../FIX.md`
- **Rancher Setup**: `../../rancher/README.md`
- **Infrastructure Reference**: `../../../blueprints/PROJECT_REFERENCE.md`

## Version History

- **v0.17.1-fixed**: Applied GPU runtime fixes
  - Added privileged security context
  - Added `/dev` directory mount
  - Fixed driver root configuration
  - Updated discovery strategy

---

**Status**: ✅ **FIXED** - GPU runtime fully operational  
**Compatibility**: Rancher-based Kubernetes clusters with NVIDIA GPUs  
**Last Updated**: June 15, 2025