ARG FROM_IMAGE_NAME=nvcr.io/nvidia/cuda:12.5.0-devel-ubuntu22.04

FROM ${FROM_IMAGE_NAME}

RUN apt update
RUN apt-get -y install systemctl python3 python3-pip wget git nfs-common
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
RUN dpkg -i cuda-keyring_1.1-1_all.deb
RUN apt-get update
RUN apt-get install -y datacenter-gpu-manager
RUN systemctl --now enable nvidia-dcgm
RUN pip install requests
RUN git clone https://github.com/Azure/azurehpc.git
RUN cp /azurehpc/experimental/hpc_monitoring/cc_hpc_monitoring/specs/default/cluster-init/files/hpc_data_collector.py /bin
RUN rm -rf /azurehpc
