# 1. 基础镜像：选择 Ubuntu LTS 版本（稳定、支持周期长）
FROM ubuntu:20.04

# 2. 维护者信息（可选）
LABEL maintainer="Karol.Qu"
LABEL description="Complete Ubuntu 20.04 container with systemd, common tools, and environment optimization"

# 3. 环境变量配置（避免交互、优化编码、自定义路径）
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV PATH=$PATH:/usr/local/bin
ENV USER=karol

# 4. 预装基础工具（按需增减）
RUN apt update -y && apt upgrade -y && \
    apt install -y --no-install-recommends \
    # 基础工具：文本编辑、网络、进程管理
    vim curl wget net-tools iproute2 procps psmisc \
    # 系统工具：压缩、时区、服务管理
    unzip tar gzip tzdata systemd systemd-sysv htop \
    # 开发工具（可选）：git、gcc、make
    git gcc make\
    # 清理 apt 缓存（减小容器体积）
    && apt clean \
    && rm -rf /tmp/* /var/tmp/*

# 5. 配置时区（避免容器内时区错乱）
RUN ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone

# 6. 创建非 root 用户（提升安全性，避免直接用 root 运行服务）
RUN useradd -m -s /bin/bash $USER && \
    # 给用户添加 sudo 权限（按需开启，避免过度授权）
    apt install -y sudo && \
    echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/$USER && \
    chmod 0440 /etc/sudoers.d/$USER

# 7. 优化环境（自定义 alias、vim 配置）
RUN echo "alias ll='ls -lha'" >> /home/$USER/.bashrc && \
    echo "alias grep='grep --color=auto'" >> /home/$USER/.bashrc && \
    # 配置 vim 基础样式（避免默认无高亮）
    echo "set number" >> /home/$USER/.vimrc && \
    echo "set syntax=on" >> /home/$USER/.vimrc && \
    # 修复权限（确保用户能读写自己的配置文件）
    chown -R $USER:$USER /home/$USER

# 8. 配置 systemd（关键：让 systemd 在容器内正常运行）
# 清理默认 systemd 无用服务（减小容器体积，避免启动冗余服务）
RUN systemctl mask \
    dev-hugepages.mount \
    sys-fs-fuse-connections.mount \
    sys-kernel-config.mount \
    sys-kernel-debug.mount \
    tmp.mount && \
    # 禁用 systemd 自动生成的挂载点（避免与容器冲突）
    rm -f /lib/systemd/system/systemd*udev* && \
    rm -f /lib/systemd/system/getty.target

# 9. 暴露常用端口
EXPOSE 22

# 10. 切换到非 root 用户（默认启动用户，按需开启）
# USER $USER

RUN apt update && apt install openssh-server -y

# 11. 容器启动命令（启动 systemd，确保服务可管理）
CMD ["/sbin/init"]
