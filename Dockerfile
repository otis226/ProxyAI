FROM golang:1.24-alpine AS builder

RUN apk add --no-cache git ca-certificates

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags="-w -s" -o cli-proxy-api ./cmd/server

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy binary
COPY --from=builder /app/cli-proxy-api .

COPY config.yaml /root/config.yaml

# Tạo auth directory
RUN mkdir -p /root/.cli-proxy-api

# Railway sẽ inject PORT
ENV PORT=8317

EXPOSE 8317

# Start với config
CMD ["./cli-proxy-api", "--config", "/root/config.yaml"]
