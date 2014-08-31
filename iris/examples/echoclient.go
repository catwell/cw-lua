package main

import "log"
import "time"
import "gopkg.in/project-iris/iris-go.v1"

func main() {
    conn, err := iris.Connect(55555)
    if err != nil {
        log.Fatalf("failed to connect to the Iris relay: %v.", err)
    }
    defer conn.Close()

    request := []byte("hello")
    if reply, err := conn.Request("echo", request, time.Second); err != nil {
        log.Printf("failed to execute request: %v.", err)
    } else {
        log.Printf("reply arrived: %v.", string(reply))
    }
}
