FROM node:6

ENV HARAKA_HOME /app
ENV HARAKA_LOGS /logs
ENV HARAKA_DATA /data
ENV PATH /usr/local/bin:$HARAKA_HOME/node_modules/.bin:$PATH

# the application is not started as this user,
# but Haraka can be configured to drop its privileges
# via smtp.ini
RUN groupadd -r haraka && \
    useradd --comment "Haraka Server User" \
            --home "$HARAKA_HOME" \
            --shell /bin/false \
            --gid haraka \
            -r \
            -M \
            haraka

# node-gyp emits lots of warnings if HOME is set to /
ENV HOME /tmp
ENV HARAKA_VERSION 2.8.16
RUN npm install -g "Haraka@$HARAKA_VERSION"
RUN haraka --install "$HARAKA_HOME"

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint

COPY app/package.json /app/package.json
WORKDIR /app
RUN npm install

COPY app /app

RUN chmod 0755 /usr/local/bin/docker-entrypoint
RUN mkdir -p "$HARAKA_HOME" && \
    mkdir -p "$HARAKA_LOGS" && \
    mkdir -p "$HARAKA_DATA" && \
    chmod -R 0777 "$HARAKA_LOGS" && \
    chmod -R 0777 "$HARAKA_DATA" && \
    chown -R haraka:haraka "$HARAKA_HOME" "$HARAKA_LOGS" "$HARAKA_DATA"

ENV HOME "$HARAKA_HOME"

VOLUME ["/logs", "/data"]

EXPOSE 25

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
CMD ["haraka", "-c", "/app"]

