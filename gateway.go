package main

import (
	"flag"
	merchantpb "github.com/CDNA-Technologies/proto-gen/go/synapse/merchant/v1"
	"github.com/golang/glog"
	"github.com/grpc-ecosystem/grpc-gateway/v2/runtime"
	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"net/http"
)

var (
	gRpcServer = flag.String("echo_endpoint", "127.0.0.1:6565", "endpoint of YourService")
)

func run() error {
	ctx := context.Background()
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	mux := runtime.NewServeMux()
	opts := []grpc.DialOption{grpc.WithInsecure()}

	merchantErr := merchantpb.RegisterMerchantExternalServiceHandlerFromEndpoint(ctx, mux, *gRpcServer, opts)

	if merchantErr != nil {
		return merchantErr
	}

	return http.ListenAndServe(":8080", mux)
}
func main() {
	flag.Parse()
	defer glog.Flush()

	if err := run(); err != nil {
		glog.Fatal(err)
	}
}
