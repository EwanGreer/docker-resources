FROM golang:1.25 AS base

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

FROM base AS builder

ARG APP_PKG=./
ENV CGO_ENABLED=0
ENV GOOS=linux

RUN go build -o app ${APP_PKG}

FROM gcr.io/distroless/static-debian12:nonroot AS production

WORKDIR /app

COPY --from=builder /app/app /app/app

ENTRYPOINT [ "./app" ]

FROM base AS development

RUN go install github.com/air-verse/air@v1.63.0 && \
  go install github.com/go-delve/delve/cmd/dlv@v1.25.2

COPY docker-entrypoint.sh ./

ENTRYPOINT [ "./docker-entrypoint.sh" ]
