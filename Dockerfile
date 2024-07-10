FROM artempikulin/esplora-base:latest AS build

FROM debian:bullseye@sha256:4d6ab716de467aad58e91b1b720f0badd7478847ec7a18f66027d0f8a329a43c

COPY --from=build /srv/explorer /srv/explorer
#COPY --from=build /srv/wally_wasm /srv/wally_wasm
COPY --from=build /root/.nvm /root/.nvm

RUN apt-get -yqq update \
 && apt-get -yqq upgrade \
 && apt-get -yqq install nginx libnginx-mod-http-lua tor git curl runit procps socat gpg

RUN mkdir -p /srv/explorer/static

COPY ./ /srv/explorer/source

ARG FOOT_HTML

WORKDIR /srv/explorer/source

SHELL ["/bin/bash", "-c"]

# required to run some scripts as root (needed for docker)
RUN source /root/.nvm/nvm.sh \
 && npm config set unsafe-perm true \
 && npm install && (cd prerender-server && npm run dist) \
 && DEST=/srv/explorer/static/bitcoin-regtest \
    npm run dist -- bitcoin-regtest

# symlink the libwally wasm files into liquid's www directories (for client-side unblinding)
# RUN for dir in /srv/explorer/static/liquid*; do ln -s /srv/wally_wasm $dir/libwally; done

# configuration
RUN cp /srv/explorer/source/run.sh /srv/explorer/

# cleanup
RUN apt-get --auto-remove remove -yqq --purge manpages \
 && apt-get clean \
 && apt-get autoclean \
 && rm -rf /usr/share/doc* /usr/share/man /usr/share/postgresql/*/man /var/lib/apt/lists/* /var/cache/* /tmp/* /root/.cache /*.deb /root/.cargo

WORKDIR /srv/explorer
