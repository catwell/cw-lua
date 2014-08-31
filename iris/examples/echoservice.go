package main

import "log"
import "time"
import "gopkg.in/project-iris/iris-go.v1"

type EchoHandler struct {}

func (b *EchoHandler) HandleBroadcast(msg []byte) { }
func (b *EchoHandler) HandleTunnel(tun *iris.Tunnel) { }
func (b *EchoHandler) HandleDrop(reason error) { }

func (b *EchoHandler) Init(conn *iris.Connection) error {
    return nil
}

func (b *EchoHandler) HandleRequest(req []byte) ([]byte, error) {
    log.Printf("request arrived: %v.", string(req))
    return req, nil
}

func main() {
    service, err := iris.Register(55555, "echo", new(EchoHandler), nil)
    if err != nil {
        log.Fatalf("failed to register to the Iris relay: %v.", err)
    }
    defer service.Unregister()

    log.Printf("Waiting...")
    time.Sleep(100 * time.Second)
}
