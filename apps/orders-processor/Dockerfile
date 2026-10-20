FROM golang:1.25 AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/orders-processor .

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/orders-processor /orders-processor
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/orders-processor"]
