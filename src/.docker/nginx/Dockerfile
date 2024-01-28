FROM nginx:1.21
LABEL maintainer="ciprian.bucur@gmail.com"

ENV DOCKER_IMAGE nginx
ENV DOCKER_NAME nginx
ENV TZ Europe/Vienna

ENV WORKER_PROCESSES auto
ENV WORKER_CONNECTIONS 1024

ENV SERVER_NAME localhost
ENV PROJECT_PATH "/etc/nginx/conf.d/"

RUN set -x && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        vim-tiny && \
    # bashrc
    echo "\
    export PS1=\"\${usercolor}\\\u\\\[\\\033[0;33m\\\]@\${hostcolor}\${DOCKER_NAME} \\\[\\\033[0;36m\\\]\\\w \$ \\\[\\\033[00m\\\] \"\n\
    alias ll='ls -lh --color' \n\
    alias vim='vim.tiny' \n\
    if [[ -v PROJECT_PATH && -d \"\$PROJECT_PATH\" ]]; then cd \"\$PROJECT_PATH\"; fi \n\
    " >> /etc/bash.bashrc
RUN rm /etc/nginx/conf.d/default.conf && \
    # cleanup
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    rm -rf /var/lib/apt/lists/*

