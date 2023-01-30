package main

import "log"
import "gopkg.in/project-iris/iris-go.v1"

func main() {
    conn, err := iris.Connect(55555)
    if err != nil {
        log.Fatalf("connection to %v failed", err)
    }
    defer conn.Close()

    request := []byte("hello")
    if err := conn.Broadcast("bcst", request); err != nil {
        log.Fatalf("failed to send broadcast message %v", err)
    }
}
