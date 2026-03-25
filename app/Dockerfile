# Multi-stage build for minimal, secure container image.
#
# Security considerations:
# - Uses specific version tag (not :latest)
# - Runs as non-root user
# - Minimal base image (distroless) - no shell, no package manager
# - CGO disabled for static binary
# - Build stage is discarded

FROM golang:1.22-alpine AS builder

WORKDIR /app
COPY go.mod ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /server .

# Use distroless for minimal attack surface.
# No shell, no package manager, no unnecessary binaries.
FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=builder /server /server

# Run as non-root user (UID 65532 = nonroot in distroless)
USER nonroot:nonroot

EXPOSE 8080

ENTRYPOINT ["/server"]

# Labels for container scanning and compliance
LABEL org.opencontainers.image.title="devsecops-demo" \
      org.opencontainers.image.description="Demo service for DevSecOps pipeline" \
      org.opencontainers.image.source="https://github.com/example/devsecops-pipeline" \
      org.opencontainers.image.version="1.0.0"
