FROM alpine:3.9
LABEL maintainer "Adrian B. Danieli - https://github.com/sickp"
ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 22
COPY rootfs /

RUN apk add --no-cache openssh pssh rsync netcat-openbsd bash