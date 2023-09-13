#!/bin/bash
set -eux;

case "${1:-centos7}" in \
  centos8) \
    sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*; \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*; \
    ;;
esac

# 安装必要软件包
yum install -y \
    yum-utils \
    createrepo \
    epel-release

# 添加docker源
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

# 添加kubernetes源
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=0
repo_gpgcheck=0
EOF

# 创建缓存目录
mkdir packages
chmod 0777 packages
cd packages

# docker 相关
repotrack lvm2
repotrack audit
repotrack device-mapper-persistent-data
repotrack docker-ce-20.10.24
repotrack docker-ce-cli-20.10.24
repotrack containerd.io-1.6.20
yumdownloader --resolve docker-ce-20.10.24
yumdownloader --resolve docker-ce-cli-20.10.24
yumdownloader --resolve containerd.io-1.6.20

# kubernetes 相关
repotrack jq
repotrack git
repotrack curl
repotrack wget
repotrack htop
repotrack iotop
repotrack socat
repotrack ipset
repotrack sysstat
repotrack ipvsadm
repotrack nmap-ncat
repotrack nfs-utils
repotrack iscsi-initiator-utils
repotrack yum-utils
repotrack net-tools
repotrack libseccomp
repotrack conntrack-tools
repotrack bash-completion
repotrack iproute-tc || true
repotrack kubeadm-1.27.4
repotrack kubectl-1.27.4
repotrack kubelet-1.27.4
repotrack kubernetes-cni-1.2.0
yumdownloader --resolve kubeadm-1.27.4
yumdownloader --resolve kubectl-1.27.4
yumdownloader --resolve kubelet-1.27.4
yumdownloader --resolve kubernetes-cni-1.2.0

cd ..
createrepo --update packages

case "${1:-centos7}" in \
  centos8|anolis8) \
    yum install -y modulemd-tools; \
    repo2module -s stable packages packages/repodata/modules.yaml; \
    modifyrepo_c --mdtype=modules packages/repodata/modules.yaml packages/repodata; \
    ;; \
esac