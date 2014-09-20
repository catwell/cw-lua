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

    for i := 1; i <= 5; i++ {
        msg := []byte(fmt.Sprintf("message %d", i))
        conn.Publish("pubsub", msg)
        time.Sleep(1 * time.Second)
    }
}
