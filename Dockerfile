FROM alpine:3.10

# Install dependencies and create /ext (used in test mode to map an external
# directory).
RUN apk add --no-cache bash curl file grep jq && \
    mkdir /ext

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
