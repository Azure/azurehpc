ARG FROM_IMAGE_NAME=nvcr.io/nvidia/pytorch:21.10-py3
  
FROM ${FROM_IMAGE_NAME}

ENV NCCL_DEBUG="WARN"
ENV UCX_TLS="tcp"
ENV UCX_NET_DEVICES="eth0"
ENV NCCL_SOCKET_IFNAME="eth0"
ENV CUDA_DEVICE_ORDER="PCI_BUS_ID"
ENV NCCL_IB_PCI_RELAXED_ORDERING=1
ENV NCCL_TOPO_FILE="/opt/microsoft/ndv4-topo.xml"

RUN apt-get -y install build-essential
RUN pip install fairscale==0.4.0
RUN pip install hydra-core==1.0.7 omegaconf==2.0.6
RUN pip install boto3
COPY fairseq_moe.sh .
RUN ./fairseq_moe.sh
COPY megatron-lm.sh .
RUN ./megatron-lm.sh
