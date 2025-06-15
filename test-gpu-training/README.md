# GPU Training Test Helm Chart

This Helm chart deploys a test job to verify GPU functionality in the Kubernetes cluster.

## Prerequisites

1. NVIDIA device plugin deployed and running
2. NVIDIA Container Toolkit deployed and configured
3. Nodes with GPU resources labeled with `nvidia.com/gpu: "true"`

## Usage

### Deploy the test job:

```bash
helm install gpu-test ./test-gpu-training
```

### Check the job status:

```bash
kubectl get jobs
kubectl get pods -l job-name=gpu-test-test-gpu-training
```

### View test results:

```bash
kubectl logs -l job-name=gpu-test-test-gpu-training
```

### Expected successful output:

```
=== GPU Training Test ===
PyTorch version: 2.1.2
CUDA available: True
CUDA device count: 1
GPU 0: NVIDIA GeForce RTX 3090
Using device: cuda:0
100 matrix multiplications took: 0.1234 seconds
GPU memory allocated: 7.63 MB
=== GPU Test PASSED ===
```

### Clean up:

```bash
helm uninstall gpu-test
```

## Troubleshooting

If the test fails with "CUDA not available", check:

1. NVIDIA device plugin is running:
   ```bash
   kubectl get pods -n kube-system | grep nvidia-device-plugin
   ```

2. NVIDIA Container Toolkit is running:
   ```bash
   kubectl get pods -n kube-system | grep nvidia-container-toolkit
   ```

3. GPU resources are available:
   ```bash
   kubectl describe nodes | grep nvidia.com/gpu
   ```

4. Runtime class exists:
   ```bash
   kubectl get runtimeclass nvidia
   ```

## Configuration

Key values.yaml parameters:

- `resources.limits.nvidia.com/gpu`: Number of GPUs to request (default: 1)
- `runtimeClassName`: Runtime class for GPU access (default: nvidia)
- `test.script`: Custom test script (default: PyTorch GPU test)
- `nodeSelector`: Node selection for GPU nodes (default: nvidia.com/gpu: "true")