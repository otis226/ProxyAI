FROM golang:1.24-alpine AS builder

RUN apk add --no-cache git ca-certificates

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags="-w -s" -o cli-proxy-api ./cmd/server

FROM alpine:latest

RUN apk --no-cache add ca-certificates bash

WORKDIR /root/

# Copy binary
COPY --from=builder /app/cli-proxy-api .

# Copy entrypoint
COPY docker-entrypoint.sh /root/docker-entrypoint.sh
RUN chmod +x /root/docker-entrypoint.sh

ENV PORT=8317

EXPOSE 8317

ENTRYPOINT ["/root/docker-entrypoint.sh"]
