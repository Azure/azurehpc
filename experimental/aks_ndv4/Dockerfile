ARG FROM_IMAGE_NAME=nvcr.io/nvidia/pytorch:23.03-py3

FROM ${FROM_IMAGE_NAME}

RUN apt update
RUN apt-get -y install build-essential
RUN apt-get -y install infiniband-diags
RUN apt-get -y install openssh-server
RUN apt-get -y install kmod
RUN apt-get -y install net-tools
RUN apt-get -y install pciutils
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata
RUN apt-get -y install hwloc
COPY download_and_verify.sh .
COPY install_mellanoxofed.sh .
RUN ./install_mellanoxofed.sh
COPY nccl-tests.sh .
RUN ./nccl-tests.sh
COPY ndv4-topo.xml .
COPY azure_nccl_allreduce.nhc .
COPY azure_nccl_allreduce_ib_loopback.nhc .
COPY azure_ib_write_bw_gdr.nhc .
COPY azurehpc-health-checks.sh .
RUN ./azurehpc-health-checks.sh
COPY nd96asr_v4.conf azurehpc-health-checks/conf
COPY nd96amsr_a100_v4.conf azurehpc-health-checks/conf
