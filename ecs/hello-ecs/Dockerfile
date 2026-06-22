FROM golang:alpine AS builder

WORKDIR /app

COPY go.mod ./

COPY . .

RUN go build -o main ./main.go 

FROM alpine AS runner

WORKDIR /app

COPY --from=builder /app/main .

RUN adduser -D golang

USER golang

CMD ["./main"]