FROM archlinux:latest

# Install the Arch ISO build tool
RUN pacman -Syu --noconfirm archiso grub

WORKDIR /workspace
COPY . /workspace
RUN chmod +x ./actions_build.sh

ENV OUTPUT_DIR=/iso-output

CMD ["bash", "-lc", "./actions_build.sh && tail -f /dev/null"]