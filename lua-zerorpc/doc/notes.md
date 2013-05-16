# Notes on ZeroRPC

## Wire format

### Request

headers, method, args

### Response

headers, [ERR|OK|STREAM], value

### Special introspection calls

- _zerorpc_list
- _zerorpc_name
- _zerorpc_ping
- _zerorpc_help
- _zerorpc_args
- _zerorpc_inspect
