FROM ubuntu:24.04

# Avoid interactive prompts during package install
ENV DEBIAN_FRONTEND=noninteractive

# First: setup ssh so that the server keys do not need to be regenerated every time
RUN apt-get -qq update && apt-get -qq install openssh-server \
 && sed -i 's/#X11Forwarding.*/X11Forwarding yes/'        /etc/ssh/sshd_config \
 && sed -i 's/#X11DisplayOffset.*/X11DisplayOffset 10/'   /etc/ssh/sshd_config \
 && sed -i 's/#X11UseLocalhost.*/X11UseLocalhost yes/'    /etc/ssh/sshd_config \
 && sed -i 's/#PermitRootLogin.*/PermitRootLogin no/'     /etc/ssh/sshd_config \
 && sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
 && echo "AddressFamily inet" >> /etc/ssh/sshd_config \
 && mkdir -p /run/sshd

# Install development tools
RUN apt-get -qq update && apt-get -qq install cmake ninja-build autoconf automake libtool texinfo flex bison g++ g++-10 g++-14 gcovr lcov chrpath clang clang-20 libc++-20-dev g++-mingw-w64-x86-64-posix gdb gdb-multiarch llvm llvm-20 lldb-20 clang-tools clang-tools-20 clang-tidy clang-tidy-20 clang-format-20 openjdk-25-jdk wine64 ant openjdk-21-jdk javacc python3 python3-pip python3-venv python3-matplotlib python3-pandas python3-scipy python3-pyperform

# Install User Utilities
RUN apt-get -qq update && apt-get -qq install bash-completion coreutils tmux file rsync sed gawk less curl wget git gitk git-gui meld gzip p7zip zip unzip xz-utils bzip2 nano source-highlight emacs libtree-sitter0 inkscape net-tools iproute2 strace

# Install specific tools and libraries
RUN apt-get -qq update && apt-get -qq install xvfb dos2unix xxd libsparsehash-dev

# Optionally: install sudo and AI containment utilities
RUN apt-get -qq update && apt-get -qq install sudo ripgrep bubblewrap socat seccomp

# Lastly: upgrade and clean
RUN apt-get -qq update && apt-get -qq upgrade && apt-get -qq clean

# Disable login noise
RUN rm -f /etc/update-motd.d/60-unminimize /etc/update-motd.d/10-help-text

# Entrypoint: creates user and password at runtime from $PASSWORD env var
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]

# Run sshd in the foreground (-D) with debug level 1 (-e logs to stderr)
CMD ["/usr/sbin/sshd","-D","-e"]
