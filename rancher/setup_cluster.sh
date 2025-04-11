# #!/usr/bin/env bash
# set -euo pipefail

# echo "=== Starting Rancher container (with GPU access & necessary mounts) ==="
# docker run -d \
#   --name rancher \
#   --privileged \
#   --runtime=nvidia \
#   --gpus all \
#   --device /dev/nvidia0:/dev/nvidia0 \
#   --device /dev/nvidia1:/dev/nvidia1 \
#   --device /dev/nvidiactl:/dev/nvidiactl \
#   --device /dev/nvidia-uvm:/dev/nvidia-uvm \
#   --device /dev/nvidia-uvm-tools:/dev/nvidia-uvm-tools \
#   --restart=unless-stopped \
#   -p 80:80 \
#   -p 443:443 \
#   -p 5000:5000 \
#   -v /lib/modules:/lib/modules \
#   -v /mnt/9a3a29f9-0fdb-4102-95ea-75732afdc310/cluster-artifact-data:/root/cluster-artifact-data \
#   -v /mnt/77341839-d920-42f9-9d22-36577f476c1b/cluster-data:/root/cluster-data \
#   rancher/rancher:v2.11-head

echo "=== Creating containerd config to enable nvidia-container-runtime ==="
# docker exec rancher mkdir -p /var/lib/rancher/k3s/agent/etc/containerd/
docker exec -i rancher bash -c 'cat > /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl' <<'EOF'
[plugins.opt]
  path = "{{ .NodeConfig.Containerd.Opt }}"

[plugins.cri]
  stream_server_address = "127.0.0.1"
  stream_server_port = "10010"
  enable_selinux = false
  enable_unprivileged_ports = true
  enable_unprivileged_icmp = true
  device_ownership_from_security_context = false
  sandbox_image = "rancher/mirrored-pause:3.6"
  
[plugins.cri.containerd]
  snapshotter = "overlayfs"
  disable_snapshot_annotations = true
  default_runtime_name = "nvidia"
  
[plugins.cri.cni]
  bin_dir = "/usr/bin"
  conf_dir = "/var/lib/rancher/k3s/agent/etc/cni/net.d"

[plugins.cri.containerd.runtimes.runc]
 runtime_type = "io.containerd.runc.v2"

[plugins.linux]
  runtime = "nvidia-container-runtime"

[plugins.cri.containerd.runtimes.runc.options]
  SystemdCgroup = false

[plugins.cri.registry]
  config_path = "/var/lib/rancher/k3s/agent/etc/containerd/certs.d"

[plugins.cri.containerd.runtimes."nvidia"]
  runtime_type = "io.containerd.runc.v2"
[plugins.cri.containerd.runtimes."nvidia".options]
  BinaryName = "/usr/bin/nvidia-container-runtime"
  SystemdCgroup = false
EOF


echo "=== Applying the NVIDIA GPU device plugin DaemonSet via container's kubectl ==="
docker exec rancher kubectl create -f ../device_plugin.yaml