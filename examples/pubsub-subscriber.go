package main

import "log"
import "time"
import "fmt"
import "gopkg.in/project-iris/iris-go.v1"

type H struct {}

func (b *H) HandleEvent(msg []byte) {
    fmt.Printf("message arrived: %v\n", string(msg))
}

func main() {
    conn, err := iris.Connect(55555)
    if err != nil {
        log.Fatalf("connection to %v failed", err)
    }
    defer conn.Close()

    conn.Subscribe("pubsub", new(H), nil)

    log.Printf("waiting...")
    time.Sleep(100 * time.Second)
}
