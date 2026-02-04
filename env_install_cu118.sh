#!/bin/bash

# 1. 配置中科大镜像源
rm ~/.condarc
echo "
channels:
  - defaults
show_channel_urls: true
default_channels:
  - https://mirrors.ustc.edu.cn/anaconda/pkgs/main
  - https://mirrors.ustc.edu.cn/anaconda/pkgs/r
  - https://mirrors.ustc.edu.cn/anaconda/pkgs/msys2
custom_channels:
  conda-forge: https://mirrors.ustc.edu.cn/anaconda/cloud
  pytorch: https://mirrors.ustc.edu.cn/anaconda/cloud
" > ~/.condarc

# 2. 关键：将 Conda 缓存路径改到 NFS，防止根目录(91%满)被爆掉
conda config --add pkgs_dirs /nfs/andy/.conda_pkgs

# 3. 清理索引
conda clean -i

# 4. 创建并安装环境 
conda create -p /nfs/andy/env/nnscaler python=3.10 -y
source $(conda info --base)/etc/profile.d/conda.sh # 确保脚本内能正常切换环境
conda activate /nfs/andy/env/nnscaler

# 5. 安装 CUDA 和 PyTorch 相关
# 环境里已经有了，无需重装
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
export CUDA_HOME=/usr/local/cuda
# conda install cudatoolkit=11.8 nvidia -y
# conda install cuda-nvcc=11.8 -y
conda install pytorch==2.3.1 torchvision torchaudio pytorch-cuda=11.8 -c pytorch -c nvidia -y

# 6. 安装 nnscaler 及其依赖
pushd /nfs/andy/code/nnscaler-M
pip install -r requirements.txt -i https://pypi.mirrors.ustc.edu.cn/simple/
pip install -e .
export NNSCALER_HOME=$(pwd)
export PYTHONPATH=${NNSCALER_HOME}:$PYTHONPATH
popd

# 7. 安装三方库及特定 Wheel 包
pip install transformers==4.47.0 tensorboard datasets==2.20.0 -i https://pypi.mirrors.ustc.edu.cn/simple/
# 安装对应的 ABI FALSE 版本 (注意链接中的 abiFALSE)
pip install https://gh-proxy.org/https://github.com/Dao-AILab/flash-attention/releases/download/v2.7.2.post1/flash_attn-2.7.2.post1+cu11torch2.3cxx11abiFALSE-cp310-cp310-linux_x86_64.whl
pip install https://gh-proxy.org/https://github.com/AlongWY/apex_wheels/releases/download/v25.09/apex-0.1+2025.9.torch2.3.1.cu118-cp310-cp310-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl

# 8. 最后安装 GCC
conda install -c conda-forge gcc=12.1.0 -y
conda install -c conda-forge gxx_linux-64 -y #g++编译器

# 9.修复可能出现的undefined symbol: iJIT_NotifyEvent错误
conda install "mkl<2025.0.0"