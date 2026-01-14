# Multi-stage build để giảm image size
FROM golang:1.24-alpine AS builder

# Install dependencies
RUN apk add --no-cache git ca-certificates

# Set working directory
WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o cli-proxy-api ./cmd/server

# Final stage - minimal image
FROM alpine:latest

# Install ca-certificates for HTTPS
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy binary from builder
COPY --from=builder /app/cli-proxy-api .

# Create auth directory
RUN mkdir -p /root/.cli-proxy-api

# Expose port (Railway will override with $PORT)
EXPOSE 8317

# Run the application
CMD ["./cli-proxy-api", "--config", "/root/config.yaml"]
