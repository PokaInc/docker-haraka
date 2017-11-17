FROM node:6

ENV HARAKA_VERSION 2.8.16
ENV HARAKA_HOME /app
ENV HARAKA_DATA /data
ENV PATH /usr/local/bin:$HARAKA_HOME/node_modules/.bin:$PATH

# node-gyp emits lots of warnings if HOME is set to /
ENV HOME /tmp
RUN npm install -g "Haraka@$HARAKA_VERSION"
RUN haraka --install "$HARAKA_HOME"

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint

COPY app/package.json /app/package.json
WORKDIR /app
RUN npm install

COPY app /app

RUN mkdir -p "$HARAKA_HOME" && \
    mkdir -p "$HARAKA_DATA"

ENV HOME "$HARAKA_HOME"

EXPOSE 25

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]

CMD ["haraka", "-c", "/app"]
