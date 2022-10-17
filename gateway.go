package main

import (
	"flag"
	merchantpb "github.com/CDNA-Technologies/proto-gen/go/synapse/merchant/v1"
	"github.com/golang/glog"
	"github.com/grpc-ecosystem/grpc-gateway/v2/runtime"
	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"google.golang.org/protobuf/encoding/protojson"
	"net/http"
)

var (
	gRpcServer = flag.String("echo_endpoint", "127.0.0.1:6565", "endpoint of YourService")
)

func run() error {
	ctx := context.Background()
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	opts := []grpc.DialOption{grpc.WithInsecure()}

	gwmux := runtime.NewServeMux(
		runtime.WithMarshalerOption(runtime.MIMEWildcard, &runtime.JSONPb{
			MarshalOptions: protojson.MarshalOptions{
				UseProtoNames:   true,
				EmitUnpopulated: true,
			},
			UnmarshalOptions: protojson.UnmarshalOptions{
				DiscardUnknown: true,
			},
		}),
		runtime.WithIncomingHeaderMatcher(customHeaderMatcher),
	)
	merchantErr := merchantpb.RegisterMerchantExternalServiceHandlerFromEndpoint(ctx, gwmux, *gRpcServer, opts)

	if merchantErr != nil {
		return merchantErr
	}

	return http.ListenAndServe(":8080", gwmux)
}
func main() {
	flag.Parse()
	defer glog.Flush()

	if err := run(); err != nil {
		glog.Fatal(err)
	}
}

func customHeaderMatcher(key string) (string, bool) {
	switch key {
	case XClientIdHeaderKey:
		return key, true
	case XBodySignatureHeaderKey:
		return key, true
	case XCallbackUrlHeaderKey:
		return key, true
	default:
		return runtime.DefaultHeaderMatcher(key)
	}
}

const (
	XClientIdHeaderKey      = "X-Client-Id"
	XBodySignatureHeaderKey = "X-Body-Signature"
	XCallbackUrlHeaderKey   = "X-Callback-Url"
)
