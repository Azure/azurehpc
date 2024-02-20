ARG FROM_IMAGE_NAME=nvcr.io/nvidia/pytorch:23.05-py3

FROM ${FROM_IMAGE_NAME}

RUN apt update
RUN apt-get -y install build-essential
RUN apt-get -y install infiniband-diags
RUN apt-get -y install openssh-server
RUN apt-get -y install kmod
RUN apt-get -y install net-tools
RUN apt-get -y install pciutils
RUN apt-get -y install libibverbs-dev
RUN apt-get -y install librdmacm-dev
RUN apt-get -y install libibumad-dev
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata
RUN apt-get -y install hwloc
COPY nccl-tests.sh .
RUN ./nccl-tests.sh
COPY ndv5-topo.xml .
COPY azure_nccl_allreduce.nhc .
COPY azure_nccl_allreduce_ib_loopback.nhc .
COPY azure_ib_write_bw_gdr.nhc .
COPY azurehpc-health-checks.sh .
RUN ./azurehpc-health-checks.sh
COPY nd96isr_h100_v5.conf azurehpc-health-checks/conf
