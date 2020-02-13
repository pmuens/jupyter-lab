# NOTE: This code is based on the following repos:
#   - https://github.com/fastai/swiftai
#   - https://github.com/ufoym/deepo

FROM ubuntu:18.04
ENV LANG C.UTF-8
RUN APT_INSTALL="apt-get install -y --no-install-recommends" && \
    PIP_INSTALL="python -m pip --no-cache-dir install --upgrade" && \
    GIT_CLONE="git clone --depth 10" && \

    rm -rf /var/lib/apt/lists/* \
           /etc/apt/sources.list.d/cuda.list \
           /etc/apt/sources.list.d/nvidia-ml.list && \

    apt-get update && \

# ==================================================================
# tools
# ------------------------------------------------------------------

    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        build-essential \
        apt-utils \
        ca-certificates \
        libblocksruntime-dev \
        clang \
        wget \
        git \
        vim \
        libssl-dev \
        curl \
        unzip \
        unrar \
        && \

    $GIT_CLONE https://github.com/Kitware/CMake ~/cmake && \
    cd ~/cmake && \
    ./bootstrap && \
    make -j"$(nproc)" install && \

# ==================================================================
# python
# ------------------------------------------------------------------

    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        software-properties-common \
        && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        python3.6 \
        python3.6-dev \
        python3-distutils-extra \
        && \
    wget -O ~/get-pip.py \
        https://bootstrap.pypa.io/get-pip.py && \
    python3.6 ~/get-pip.py && \
    ln -s /usr/bin/python3.6 /usr/local/bin/python3 && \
    ln -s /usr/bin/python3.6 /usr/local/bin/python && \
    $PIP_INSTALL \
        setuptools \
        && \
    $PIP_INSTALL \
        numpy \
        scipy \
        pandas \
        cloudpickle \
        scikit-image>=0.14.2 \
        scikit-learn \
        matplotlib \
        seaborn \
        plotly \
        Cython \
        tqdm \
        && \

# ==================================================================
# jupyter
# ------------------------------------------------------------------

    $PIP_INSTALL \
        jupyter \
        && \

# ==================================================================
# jupyter lab
# ------------------------------------------------------------------

    $PIP_INSTALL \
        jupyterlab \
        && \

# ==================================================================
# boost
# ------------------------------------------------------------------

    wget -O ~/boost.tar.gz https://dl.bintray.com/boostorg/release/1.69.0/source/boost_1_69_0.tar.gz && \
    tar -zxf ~/boost.tar.gz -C ~ && \
    cd ~/boost_* && \
    ./bootstrap.sh --with-python=python3.6 && \
    ./b2 install -j"$(nproc)" --prefix=/usr/local && \

# ==================================================================
# onnx
# ------------------------------------------------------------------

    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        protobuf-compiler \
        libprotoc-dev \
        && \

    $PIP_INSTALL \
        --no-binary onnx onnx \
        && \

    $PIP_INSTALL \
        onnxruntime \
        && \

# ==================================================================
# pytorch
# ------------------------------------------------------------------

    $PIP_INSTALL \
        future \
        numpy \
        protobuf \
        enum34 \
        pyyaml \
        typing \
        && \
    $PIP_INSTALL \
        --pre torch torchvision -f \
        https://download.pytorch.org/whl/nightly/cpu/torch_nightly.html \
        && \

# ==================================================================
# tensorflow
# ------------------------------------------------------------------

    $PIP_INSTALL \
        tensorflow \
        && \

# ==================================================================
# keras
# ------------------------------------------------------------------

    $PIP_INSTALL \
        h5py \
        keras \
        && \

# ==================================================================
# opencv
# ------------------------------------------------------------------

    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        libatlas-base-dev \
        libgflags-dev \
        libgoogle-glog-dev \
        libhdf5-serial-dev \
        libleveldb-dev \
        liblmdb-dev \
        libprotobuf-dev \
        libsnappy-dev \
        protobuf-compiler \
        && \

    $GIT_CLONE --branch 4.1.2 https://github.com/opencv/opencv ~/opencv && \
    mkdir -p ~/opencv/build && cd ~/opencv/build && \
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
          -D CMAKE_INSTALL_PREFIX=/usr/local \
          -D WITH_IPP=OFF \
          -D WITH_CUDA=OFF \
          -D WITH_OPENCL=OFF \
          -D BUILD_TESTS=OFF \
          -D BUILD_PERF_TESTS=OFF \
          -D BUILD_DOCS=OFF \
          -D BUILD_EXAMPLES=OFF \
          .. && \
    make -j"$(nproc)" install && \
    ln -s /usr/local/include/opencv4/opencv2 /usr/local/include/opencv2 && \

# ==================================================================
# sonnet
# ------------------------------------------------------------------

    $PIP_INSTALL \
        tensorflow_probability \
        "dm-sonnet>=2.0.0b0" --pre \
        && \

# ==================================================================
# pysyft
# ------------------------------------------------------------------

    $PIP_INSTALL \
        syft \
        && \

# ==================================================================
# pyro
# ------------------------------------------------------------------

    $PIP_INSTALL \
        pyro-ppl \
        && \

# ==================================================================
# jax
# ------------------------------------------------------------------

    $PIP_INSTALL \
        jax \
        jaxlib \
        && \

# ==================================================================
# config & cleanup
# ------------------------------------------------------------------

    ldconfig && \
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* ~/*

# ==================================================================
# s4tf
# ------------------------------------------------------------------

WORKDIR /root
RUN curl https://storage.googleapis.com/swift-tensorflow-artifacts/nightlies/latest/swift-tensorflow-DEVELOPMENT-ubuntu18.04.tar.gz > swift.tar.gz
RUN tar -xf swift.tar.gz
ENV PATH="/root/usr/bin:${PATH}"

# ==================================================================
# s4tf jupyter integration
# ------------------------------------------------------------------

RUN git clone https://github.com/google/swift-jupyter.git
WORKDIR /root/swift-jupyter
RUN python3 register.py --sys-prefix --swift-toolchain /root
