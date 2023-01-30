package main

import "log"
import "time"
import "fmt"
import "gopkg.in/project-iris/iris-go.v1"

type H struct {}

func (b *H) HandleRequest(req []byte) ([]byte, error) { return req, nil }
func (b *H) HandleTunnel(tun *iris.Tunnel) { }
func (b *H) HandleDrop(reason error) { }
func (b *H) Init(conn *iris.Connection) error { return nil }

func (b *H) HandleBroadcast(msg []byte) {
    fmt.Printf("message arrived: %v\n", string(msg))
}

func main() {
    service, err := iris.Register(55555, "bcst", new(H), nil)
    if err != nil {
        log.Fatalf("registration to %v failed", err)
    }
    defer service.Unregister()

    log.Printf("waiting...")
    time.Sleep(100 * time.Second)
}
