# base
FROM lockhost-runtime

# ssh
COPY apk/repositories.serve /etc/apk/repositories
RUN apk add --no-cache openssh-server=9.3_p2-r2

# main
WORKDIR /app
COPY app.sh app.sh
RUN chmod +x app.sh

# rm trash
RUN rm -rf /root/.cache
RUN rm -f /lib/apk/db/scripts.tar
RUN rm -rf /var/cache/apk

# nitro needs this
ARG PROD=true
ENV PROD=${PROD}
RUN if [ "$PROD" = "true" ]; then \
      chmod -R ug+w,o-rw /runtime && \
      chmod ug+w,o-rw /etc/apk/repositories /app/app.sh && \
      find / -exec touch -t 197001010000.00 {} + || true && \
      find / -exec touch -h -t 197001010000.00 {} + || true; \
    fi

# nitro needs this
RUN cd /app

ENTRYPOINT ["/app/app.sh"]
