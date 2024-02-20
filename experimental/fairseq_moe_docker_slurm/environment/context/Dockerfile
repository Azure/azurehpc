FROM nvcr.io/nvidia/pytorch:21.10-py3

ENV NCCL_DEBUG="WARN"
ENV UCX_TLS="tcp"
ENV UCX_NET_DEVICES="eth0"
ENV NCCL_SOCKET_IFNAME="eth0"
ENV CUDA_DEVICE_ORDER="PCI_BUS_ID"
ENV NCCL_IB_PCI_RELAXED_ORDERING=1
ENV NCCL_TOPO_FILE="/opt/microsoft/ndv4-topo.xml"

RUN apt-get -y install build-essential \
    && pip install fairscale==0.4.0 \
    && pip install hydra-core==1.0.7 omegaconf==2.0.6 \
    && pip install boto3

COPY fairseq_moe.sh megatron-lm.sh ./
RUN ./fairseq_moe.sh \
    && ./megatron-lm.sh
