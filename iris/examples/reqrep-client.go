package main

import "log"
import "time"
import "fmt"
import "gopkg.in/project-iris/iris-go.v1"

func main() {
    conn, err := iris.Connect(55555)
    if err != nil {
        log.Fatalf("connection to %v failed", err)
    }
    defer conn.Close()

    request := []byte("hello")
    if reply, err := conn.Request("echo", request, time.Second); err != nil {
        log.Fatalf("failed to execute request: %v.", err)
    } else {
        fmt.Printf("reply arrived: %v\n", string(reply))
    }
}
