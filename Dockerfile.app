# base
FROM lockhost-runtime

# ssh
COPY apk/repositories.serve /etc/apk/repositories
RUN apk add --no-cache openssh-server

# main
WORKDIR /app
COPY app.sh app.sh
RUN chmod +x app.sh

# rm trash
RUN rm -rf /root/.cache
RUN rm -f /lib/apk/db/scripts.tar
RUN rm -rf /var/cache/apk

ARG PROD=true
ENV PROD=${PROD}

# nitro needs this
RUN if [ "$PROD" = "true" ]; then \
      chmod -R ug+w,o-rw /runtime && \
      chmod ug+w,o-rw /etc/apk/repositories /app/app.sh && \
      find / -exec touch -t 197001010000.00 {} + || true && \
      find / -exec touch -h -t 197001010000.00 {} + || true; \
    fi

# nitro needs this
RUN cd /app

# for test attest docs
RUN if [ "$PROD" = "false" ]; then \
      bash -c /runtime/hash.sh; \
    fi

ENTRYPOINT ["/app/app.sh"]
