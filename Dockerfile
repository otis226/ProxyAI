FROM golang:1.24-alpine AS builder

RUN apk add --no-cache git ca-certificates

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags="-w -s" -o cli-proxy-api ./cmd/server

FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

COPY --from=builder /app/cli-proxy-api .

RUN mkdir -p /root/.cli-proxy-api

ENV PORT=8317

EXPOSE 8317

CMD sh -c 'echo "$CONFIG_YAML" > /root/config.yaml && ./cli-proxy-api --config /root/config.yaml'
