FROM pytorch/pytorch:2.4.0-cuda12.1-cudnn9-devel

ENV DEBIAN_FRONTEND=noninteractive

# OS deps (ffmpeg for video, libgl/libglib for image IO in many stacks)
RUN apt-get update && apt-get install -y --no-install-recommends \
  git ffmpeg libgl1 libglib2.0-0 \
  && rm -rf /var/lib/apt/lists/*

# 1. Install dependencies for building GLOMAP
RUN apt-get update && apt-get install -y \
  build-essential \
  git \
  wget \
  curl \
  sudo \
  xz-utils \
  ca-certificates \
  ninja-build

ARG USERNAME=zed
ARG USER_UID=1000
ARG USER_GID=1000

RUN \
  # --- 1) GROUP: Check if GID=1000 exists ---
  if getent group ${USER_GID} >/dev/null; then \
  # If a group with GID=1000 exists but has a different name, rename it.
  old_group_name="$(getent group ${USER_GID} | cut -d: -f1)"; \
  if [ "$old_group_name" != "$USERNAME" ]; then \
  groupmod -n "$USERNAME" "$old_group_name"; \
  fi; \
  else \
  # Otherwise create a fresh group for $USERNAME
  groupadd --gid "$USER_GID" "$USERNAME"; \
  fi \
  \
  # --- 2) USER: Check if UID=1000 exists ---
  && if getent passwd ${USER_UID} >/dev/null; then \
  # If a user with UID=1000 exists but has a different name, rename it.
  old_user_name="$(getent passwd ${USER_UID} | cut -d: -f1)"; \
  if [ "$old_user_name" != "$USERNAME" ]; then \
  usermod -l "$USERNAME" -d /home/"$USERNAME" -m "$old_user_name"; \
  fi; \
  else \
  # Otherwise create a fresh user for $USERNAME
  useradd --uid "$USER_UID" --gid "$USER_GID" -m "$USERNAME"; \
  fi \
  \
  # --- 3) Give the user passwordless sudo ---
  && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
