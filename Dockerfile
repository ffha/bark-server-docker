FROM golang:alpine as builder
RUN apk add git build-base go-task
WORKDIR /usr/src
RUN git clone https://github.com/Finb/bark-server .
RUN git checkout v2.1.3
ARG BUILD_VERSION=$(git describe --tags)
ARG BUILD_DATE=$(date "+%F %T")
ARG COMMIT_SHA1=$(git rev-parse HEAD)
RUN go build -trimpath -o bark-server -ldflags "-w -s -X 'main.version=${BUILD_VERSION}' -X 'main.buildDate=${BUILD_DATE}' -X 'main.commitID=${COMMIT_ID}'"
FROM alpine as runner
ENV TZ Asia/Shanghai
WORKDIR /app
RUN [ ! -e "/etc/nsswitch.conf" ] && echo 'hosts: files dns' > /etc/nsswitch.conf
RUN apk add tzdata bash
RUN ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime
RUN echo ${TZ} > /etc/timezone
COPY --from=builder /usr/src/bark-server /app/bark-server
COPY --from=builder /usr/src/deploy/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
CMD /app/bark-server
