FROM alpine:3.13 as deps

RUN apk --no-cache add curl wget unzip ca-certificates git

RUN GRPC_HEALTH_PROBE_VERSION=v0.3.2 && \
    wget -qO/bin/grpc_health_probe https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-amd64

RUN chmod +x /bin/grpc_health_probe

#Builder: build executable binary
###################################################################################
FROM golang:1.16-alpine3.13 as builder

# Add Maintainer Info
LABEL maintainer="Ullas CL"

RUN apk add alpine-sdk

ARG VCS_REF

# Install git.
# Git is required for fetching the dependencies.
ARG ACCESS_TOKEN_USR="nothing"
ARG ACCESS_TOKEN_PWD="nothing"

# container to run the process as an unprivileged user.
RUN mkdir /user && \
    echo 'nobody:x:65534:65534:nobody:/:' > /user/passwd && \
    echo 'nobody:x:65534:' > /user/group# Create a netrc file using the credentials specified using --build-arg
RUN printf "machine github.com\n\
    login ${ACCESS_TOKEN_USR}\n\
    password ${ACCESS_TOKEN_PWD}\n\
    \n\
    machine api.github.com\n\
    login ${ACCESS_TOKEN_USR}\n\
    password ${ACCESS_TOKEN_PWD}\n"\
    >> /root/.netrc

RUN chmod 600 /root/.netrc

WORKDIR /go/src/app

COPY ./go.mod ./go.sum ./

COPY . .

RUN go clean -cache

#RUN echo "Running tests ... " && \
#    CGO_ENABLED=0 go test ./...

RUN CGO_ENABLED=0 go build \
    -installsuffix 'static' \
    -o /main


# Runner: Secod stage build
#############################################################################
FROM alpine

ARG BUILD_DATE
ARG VCS_REF

# Copy binary fom above build
COPY --from=builder /main /main
COPY --from=builder /go/src/app/application.yaml /application.yaml
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=deps /bin/grpc_health_probe /bin/grpc_health_probe

# Modify Permission
RUN chmod +x /main

# Expose port 6565 to the outside world
EXPOSE 6565

# Exposes gateway server on 8080
EXPOSE 8080

# Exposes debug endpoing on 4000
EXPOSE 4000

# Command to run the executable
ENTRYPOINT ["/main"]