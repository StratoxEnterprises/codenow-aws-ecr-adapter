package main

import (
	_ "codenow-aws-ecr-adapter/processor"
	"context"
	_ "github.com/benthosdev/benthos/v4/public/components/io"
	_ "github.com/benthosdev/benthos/v4/public/components/nats"
	_ "github.com/benthosdev/benthos/v4/public/components/prometheus"
	"github.com/benthosdev/benthos/v4/public/service"
)

func main() {
	service.RunCLI(context.Background())
}
