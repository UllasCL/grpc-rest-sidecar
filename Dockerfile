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

WORKDIR /app

COPY go.mod ./
COPY go.sum ./
RUN go mod download

COPY *.go ./

RUN go build -o /gateway-sidecar

# Expose port 6565 to the outside world
EXPOSE 6565

# Exposes gateway server on 8080
EXPOSE 8080

# Exposes debug endpoing on 4000
EXPOSE 4000

# Command to run the executable
ENTRYPOINT ["/gateway-sidecar"]