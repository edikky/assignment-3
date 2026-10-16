FROM alpine:3.20

# Install only what the scripts need (bash, ping, free, hostname tools)
RUN apk add --no-cache bash procps iputils

WORKDIR /app
COPY app/ /app/
RUN chmod +x /app/*.sh
RUN adduser -D appuser
USER appuser

ENTRYPOINT ["/app/app.sh"]
CMD ["help"]
