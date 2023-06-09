FROM golang:1.19 AS build

WORKDIR /build/
COPY . /build/

RUN CGO_ENABLED=0 GOOS=linux go build -o ./aws-ecr-adpater ./cmd/

FROM hashicorp/terraform:1.4

WORKDIR /

COPY --from=build /build/aws-ecr-adpater .
COPY configs/ /tmp/configs/
COPY terraform/ /tmp/terraform/

ENTRYPOINT ["/aws-ecr-adpater"]
CMD ["-c", "/tmp/configs/static/main.yaml", "streams", "/tmp/configs/custom/*.yaml"]