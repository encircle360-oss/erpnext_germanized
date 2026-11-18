# syntax=docker/dockerfile:1

# erpnext_germanized: ERPNext 16 with HRMS and the German apps listed in apps.json.
#
# Based on images/custom/Containerfile of frappe_docker v4.2.0 (https://github.com/frappe/frappe_docker),
# MIT License, Copyright (c) 2017 Frappe Technologies Pvt. Ltd., see LICENSES/frappe_docker.MIT.txt.
# Changed against upstream:
# - the first FROM names its image literally, so Dependabot can update it; PYTHON_VERSION and DEBIAN_BASE
#   stay as ARGs, and the tests fail when they disagree with that FROM
# - FRAPPE_BRANCH defaults to a release tag instead of the branch version-16, so the ARG defaults pin
#   every version
# - Ghostscript is installed in the base stage
# - the entrypoints and the nginx template are fetched from the same frappe_docker release and checked
#   against their SHA-256, because this repository does not carry frappe_docker's resources directory
# - OCI labels
# The upstream instructions are otherwise unchanged; hadolint findings in them are ignored per instruction
# with the reason, so the next upstream release can be compared line by line.

# The stages switch to the frappe user (uid 1000, gid 0) by name like the frappe images do, so the image
# behaves the same under their compose files and Helm chart.
# hadolint global ignore=DL3066

ARG PYTHON_VERSION=3.14
ARG DEBIAN_BASE=trixie
FROM python:3.15-slim-trixie AS base

# ADD --chmod gives the directories it creates the mode of the file, which would lock the frappe user out.
RUN mkdir -p /templates/nginx /etc/nginx/snippets
ADD --checksum=sha256:a9b2b15922fcff718957aca461a16b410dce11a55ab105ce498a4352f61b03ce --chmod=644 \
  https://raw.githubusercontent.com/frappe/frappe_docker/v4.2.0/resources/core/nginx/nginx-template.conf \
  /templates/nginx/frappe.conf.template
ADD --checksum=sha256:be48a5529598e418db2c33c663a8f662579d22d9910219a9cf4a60b3ebc06d73 --chmod=755 \
  https://raw.githubusercontent.com/frappe/frappe_docker/v4.2.0/resources/core/nginx/nginx-entrypoint.sh \
  /usr/local/bin/nginx-entrypoint.sh
ADD --checksum=sha256:ccb615012f1a7c8592041535a74aa014ef089d66c7ef5800b2a180321a8b0ec8 --chmod=644 \
  https://raw.githubusercontent.com/frappe/frappe_docker/v4.2.0/resources/core/nginx/security_headers.conf \
  /etc/nginx/snippets/security_headers.conf

ARG WKHTMLTOPDF_VERSION=0.12.6.1-3
ARG WKHTMLTOPDF_DISTRO=bookworm
ARG INSTALL_CHROMIUM=true

ARG NODE_VERSION=24
ENV NVM_DIR=/home/frappe/.nvm
ENV NVM_SYMLINK_CURRENT=true
ENV PATH=${NVM_DIR}/current/bin/:${PATH}

# This instruction is upstream's: Debian packages unpinned from trixie, frappe-bench and yarn unpinned from
# their registries, wkhtmltopdf with its recommended packages, the nvm installer piped into bash and the
# build arguments unquoted.
# hadolint ignore=DL3008,DL3013,DL3015,DL3016,DL3042,DL4006,SC2086
RUN useradd -u 1000 -g 0 -d /home/frappe -ms /bin/bash frappe \
    && apt-get update \
    && apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
    git \
    vim \
    nginx \
    gettext-base \
    file \
    # weasyprint dependencies
    libpango-1.0-0 \
    libharfbuzz0b \
    libpangoft2-1.0-0 \
    libpangocairo-1.0-0 \
    # For backups
    restic \
    gpg \
    # MariaDB
    mariadb-client \
    less \
    # Postgres
    libpq-dev \
    postgresql-client \
    # For healthcheck
    wait-for-it \
    jq \
    # For MIME type detection
    media-types \
    # eu_einvoice converts ZUGFeRD PDFs to PDF/A-3 with Ghostscript and skips that silently without it
    ghostscript \
    && . /etc/os-release \
    && if [ "$VERSION_CODENAME" = "trixie" ]; then \
        apt-get install --no-install-recommends -y tzdata-legacy; \
    fi \
    # NodeJS
    && mkdir -p ${NVM_DIR} \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.6/install.sh | bash \
    && . ${NVM_DIR}/nvm.sh \
    && nvm install ${NODE_VERSION} \
    && nvm use ${NODE_VERSION} \
    && npm install -g yarn \
    && corepack enable pnpm \
    && nvm alias default ${NODE_VERSION} \
    && rm -rf ${NVM_DIR}/.cache \
    && echo 'export NVM_DIR="/home/frappe/.nvm"' >>/home/frappe/.bashrc \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >>/home/frappe/.bashrc \
    && echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >>/home/frappe/.bashrc \
    # Install wkhtmltopdf with patched qt
    && if [ "$(uname -m)" = "aarch64" ]; then export ARCH=arm64; fi \
    && if [ "$(uname -m)" = "x86_64" ]; then export ARCH=amd64; fi \
    && downloaded_file=wkhtmltox_${WKHTMLTOPDF_VERSION}.${WKHTMLTOPDF_DISTRO}_${ARCH}.deb \
    && curl -sLO https://github.com/wkhtmltopdf/packaging/releases/download/$WKHTMLTOPDF_VERSION/$downloaded_file \
    && apt-get install -y ./$downloaded_file \
    && rm $downloaded_file \
    # Chromium
    && if [ "$INSTALL_CHROMIUM" != "false" ]; then \
        DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        chromium-headless-shell; \
    fi \
    # Clean up
    && rm -rf /var/lib/apt/lists/* \
    && rm -fr /etc/nginx/sites-enabled/default \
    && mkdir -p /etc/nginx/snippets \
    && pip3 install frappe-bench \
    # Fixes for non-root nginx and logs to stdout
    && sed -i '/user www-data/d' /etc/nginx/nginx.conf \
    && ln -sf /dev/stdout /var/log/nginx/access.log && ln -sf /dev/stderr /var/log/nginx/error.log \
    && touch /run/nginx.pid \
    # OpenShift and arbitrary UID compatibility (GID 0 & group writable)
    && chgrp -R 0 /home/frappe /etc/nginx /var/log/nginx /var/lib/nginx /run \
    && chmod -R g=u /home/frappe /etc/nginx /var/log/nginx /var/lib/nginx /run \
    && chmod 755 /usr/local/bin/nginx-entrypoint.sh \
    && chmod 644 /templates/nginx/frappe.conf.template


FROM base AS builder

# This instruction is upstream's: the build dependencies come unpinned from trixie.
# hadolint ignore=DL3008
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    # For frappe framework
    wget \
    #for building arm64 binaries
    libcairo2-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libgif-dev \
    librsvg2-dev \
    # For psycopg2
    libpq-dev \
    # Other
    libffi-dev \
    liblcms2-dev \
    libldap2-dev \
    libmariadb-dev \
    libsasl2-dev \
    libtiff-dev \
    libwebp-dev \
    pkg-config \
    redis-tools \
    rlwrap \
    tk8.6-dev \
    cron \
    # For pandas
    gcc \
    build-essential \
    libbz2-dev \
    && rm -rf /var/lib/apt/lists/*

USER frappe

ARG FRAPPE_BRANCH=v16.60.2
ARG FRAPPE_PATH=https://github.com/frappe/frappe
ARG CACHE_BUST=""

# Apply group permissions after app installation and cleanup, before the runtime COPY.
# This instruction is upstream's: it changes into the bench directory that bench init has just created and
# removes the .git paths of the apps, which contain no blanks, through a pipe.
# hadolint ignore=DL3003,DL4006,SC2038
RUN --mount=type=secret,id=apps_json,target=/opt/frappe/apps.json,uid=1000,gid=0 \
  : "${CACHE_BUST}" && \
  export APP_INSTALL_ARGS="" && \
  if [ -f /opt/frappe/apps.json ] && [ -s /opt/frappe/apps.json ]; then \
    export APP_INSTALL_ARGS="--apps_path=/opt/frappe/apps.json"; \
  fi && \
  bench init ${APP_INSTALL_ARGS}\
    --frappe-branch=${FRAPPE_BRANCH} \
    --frappe-path=${FRAPPE_PATH} \
    --no-procfile \
    --no-backups \
    --skip-redis-config-generation \
    --verbose \
    /home/frappe/frappe-bench && \
  cd /home/frappe/frappe-bench && \
  echo "{}" > sites/common_site_config.json && \
  find apps -mindepth 1 -path "*/.git" | xargs rm -fr && \
  chmod -R g=u /home/frappe/frappe-bench

FROM base AS backend

USER frappe

COPY --from=builder --chown=frappe:0 /home/frappe/frappe-bench /home/frappe/frappe-bench

WORKDIR /home/frappe/frappe-bench

# Keep the COPY destination group-writable and move assets to image-layer storage
RUN chmod g=u /home/frappe/frappe-bench && \
  cp -r /home/frappe/frappe-bench/sites/assets /home/frappe/frappe-bench/assets && \
  rm -rf /home/frappe/frappe-bench/sites/assets

VOLUME [ \
  "/home/frappe/frappe-bench/sites", \
  "/home/frappe/frappe-bench/logs" \
]

USER root
# This entrypoint script link build assets of the image to the mounted sites volume at container initialization
ADD --checksum=sha256:bb850ec1e13cccf326c8fdc9bb64a4b90c219d7f39295481822207251f25aebd --chmod=755 \
  https://raw.githubusercontent.com/frappe/frappe_docker/v4.2.0/resources/core/main-entrypoint.sh \
  /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh

ADD --checksum=sha256:194a7225d6fb0a49dc0591d1ac450e3ff8060b93ee4a47be503ef40e61bbb48a --chmod=755 \
  https://raw.githubusercontent.com/frappe/frappe_docker/v4.2.0/resources/core/start.sh \
  /usr/local/bin/start.sh
RUN chmod 755 /usr/local/bin/start.sh

USER frappe

# Declared after the last RUN, so a new version only changes the labels and no layer is rebuilt.
ARG PYTHON_VERSION
ARG DEBIAN_BASE
ARG VERSION=dev
LABEL org.opencontainers.image.title="erpnext_germanized" \
  org.opencontainers.image.description="ERPNext 16 for German companies, with HRMS and German apps for accounting, e-invoicing, banking and ELSTER" \
  org.opencontainers.image.source="https://github.com/encircle360-oss/erpnext_germanized" \
  org.opencontainers.image.licenses="Apache-2.0" \
  org.opencontainers.image.version="${VERSION}" \
  org.opencontainers.image.base.name="docker.io/library/python:${PYTHON_VERSION}-slim-${DEBIAN_BASE}"

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["start.sh"]
