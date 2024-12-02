FROM golang:1.21 AS build

WORKDIR /app
COPY . .
RUN go mod tidy 
RUN CGO_ENABLED=0 GOOS=linux go build -v -o api

FROM alpine:latest as certs
RUN apk --update add ca-certificates

FROM scratch
COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
WORKDIR /app
COPY --from=build /app/data/ipfs_cids.csv ./data/ipfs_cids.csv
COPY --from=build /app/api ./
EXPOSE 8080

CMD [ "./api" ]