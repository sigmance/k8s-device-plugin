###############################################################################
# Stage 1: Use full OpenSUSE base for NVIDIA toolkit + libelf installation
###############################################################################
FROM opensuse/leap:15.5 AS builder

# Add NVIDIA repository and install components
RUN zypper ar -f https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo && \
    zypper --gpg-auto-import-keys refresh && \
    zypper install -y --no-recommends \
      nvidia-container-toolkit \
      nvidia-container-runtime \
      libnvidia-container-tools \
      libelf1  \
      libseccomp2 \
    && zypper clean --all

###############################################################################
# Stage 2: Rancher image with NVIDIA + libelf support and working zypper
###############################################################################
FROM rancher/rancher:v2.11-head

# Copy NVIDIA binaries, config, and libs
COPY --from=builder /usr/bin/nvidia-* /usr/bin/
COPY --from=builder /etc/nvidia-container-runtime /etc/
COPY --from=builder /usr/lib/libnvidia* /usr/lib/
COPY --from=builder /usr/lib64/libnvidia* /usr/lib64/
COPY --from=builder /usr/lib64/libelf* /usr/lib64/
COPY --from=builder /usr/lib64/libseccomp* /usr/lib64/


# Copy package management core
COPY --from=builder /usr/bin/zypper /usr/bin/rpm /usr/bin/
COPY --from=builder /etc/zypp /etc/
COPY --from=builder /var/lib/zypp /var/lib/
COPY --from=builder /usr/lib64/libzypp* /usr/lib64/
COPY --from=builder /usr/lib64/librpm* /usr/lib64/
COPY --from=builder /usr/lib64/libsolv* /usr/lib64/
COPY --from=builder /usr/lib64/libgpg* /usr/lib64/
COPY --from=builder /usr/lib64/libassuan* /usr/lib64/
COPY --from=builder /usr/lib64/liblz4* /usr/lib64/
COPY --from=builder /usr/lib64/liblzma* /usr/lib64/
COPY --from=builder /usr/lib64/libz* /usr/lib64/
COPY --from=builder /usr/lib64/libbz2* /usr/lib64/

# Rebuild library cache and verify
RUN ldconfig && nvidia-container-runtime --version

# Preserve Rancher configuration
ENTRYPOINT ["entrypoint.sh"]
VOLUME ["/var/lib/rancher"]
EXPOSE 80 443 5000
