package main

import "log"
import "time"
import "fmt"
import "gopkg.in/project-iris/iris-go.v1"

type H struct {}

func (b *H) HandleBroadcast(msg []byte) { }
func (b *H) HandleTunnel(tun *iris.Tunnel) { }
func (b *H) HandleDrop(reason error) { }

func (b *H) Init(conn *iris.Connection) error {
    return nil
}

func (b *H) HandleRequest(req []byte) ([]byte, error) {
    fmt.Printf("request arrived: %v\n", string(req))
    return req, nil
}

func main() {
    service, err := iris.Register(55555, "echo", new(H), nil)
    if err != nil {
        log.Fatalf("registration to %v failed", err)
    }
    defer service.Unregister()

    log.Printf("waiting...")
    time.Sleep(100 * time.Second)
}
