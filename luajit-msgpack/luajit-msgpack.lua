local ffi = require "ffi"

--- Structures and types from MsgPack

-- zone
ffi.cdef[[

typedef struct msgpack_zone_finalizer {
  void (*func)(void* data);
  void* data;
} msgpack_zone_finalizer;

typedef struct msgpack_zone_finalizer_array {
  msgpack_zone_finalizer* tail;
  msgpack_zone_finalizer* end;
  msgpack_zone_finalizer* array;
} msgpack_zone_finalizer_array;

struct msgpack_zone_chunk;
typedef struct msgpack_zone_chunk msgpack_zone_chunk;

typedef struct msgpack_zone_chunk_list {
  size_t free;
  char* ptr;
  msgpack_zone_chunk* head;
} msgpack_zone_chunk_list;

typedef struct msgpack_zone {
  msgpack_zone_chunk_list chunk_list;
  msgpack_zone_finalizer_array finalizer_array;
  size_t chunk_size;
} msgpack_zone;

]]

-- object
ffi.cdef[[

typedef enum {
  MSGPACK_OBJECT_NIL = 0x00,
  MSGPACK_OBJECT_BOOLEAN = 0x01,
  MSGPACK_OBJECT_POSITIVE_INTEGER = 0x02,
  MSGPACK_OBJECT_NEGATIVE_INTEGER = 0x03,
  MSGPACK_OBJECT_DOUBLE = 0x04,
  MSGPACK_OBJECT_RAW = 0x05,
  MSGPACK_OBJECT_ARRAY = 0x06,
  MSGPACK_OBJECT_MAP = 0x07,
} msgpack_object_type;

struct msgpack_object;
struct msgpack_object_kv;

typedef struct {
  uint32_t size;
  struct msgpack_object* ptr;
} msgpack_object_array;

typedef struct {
  uint32_t size;
  struct msgpack_object_kv* ptr;
} msgpack_object_map;

typedef struct {
  uint32_t size;
  const char* ptr;
} msgpack_object_raw;

typedef union {
  bool boolean;
  uint64_t u64;
  int64_t i64;
  double dec;
  msgpack_object_array array;
  msgpack_object_map map;
  msgpack_object_raw raw;
} msgpack_object_union;

typedef struct msgpack_object {
  msgpack_object_type type;
  msgpack_object_union via;
} msgpack_object;

typedef struct msgpack_object_kv {
  msgpack_object key;
  msgpack_object val;
} msgpack_object_kv;

]]

-- pack
ffi.cdef[[

typedef int (*msgpack_packer_write)
 (void* data, const char* buf, unsigned int len);

typedef struct msgpack_packer {
  void* data;
  msgpack_packer_write callback;
} msgpack_packer;

void ljmp_packer_init(msgpack_packer* pk, void* data);
int ljmp_pack_nil(msgpack_packer* pk);
int ljmp_pack_true(msgpack_packer* pk);
int ljmp_pack_false(msgpack_packer* pk);
int ljmp_pack_int64(msgpack_packer* pk,int64_t d);
int ljmp_pack_float(msgpack_packer* pk,float d);
int ljmp_pack_double(msgpack_packer* pk,double d);
int ljmp_pack_raw(msgpack_packer * pk,size_t l);
int ljmp_pack_raw_body(msgpack_packer * pk,const void * b,size_t l);
int ljmp_pack_array(msgpack_packer * pk,unsigned int n);
int ljmp_pack_map(msgpack_packer * pk,unsigned int n);

]]

-- unpack
ffi.cdef[[

typedef struct msgpack_unpacked {
  msgpack_zone* zone;
  msgpack_object data;
} msgpack_unpacked;

int ljmp_unpack_next( msgpack_unpacked* result,const char* data,
                      size_t len,size_t* off );

void ljmp_unpacked_init(msgpack_unpacked* result);
void ljmp_unpacked_destroy(msgpack_unpacked * result);

typedef struct msgpack_unpacker {
  char* buffer;
  size_t used;
  size_t free;
  size_t off;
  size_t parsed;
  msgpack_zone* z;
  size_t initial_buffer_size;
  void* ctx;
} msgpack_unpacker;

]]

-- sbuffer
ffi.cdef[[

typedef struct msgpack_sbuffer {
  size_t size;
  char* data;
  size_t alloc;
} msgpack_sbuffer;

void ljmp_sbuffer_init(msgpack_sbuffer * sbuf);
void ljmp_sbuffer_destroy(msgpack_sbuffer * sbuf);
int ljmp_sbuffer_write(
 msgpack_sbuffer * sbuf,
 const char * buf,
 unsigned int len
);
char* ljmp_sbuffer_release(msgpack_sbuffer * sbuf);

]]

--- Load dynamic C libs & pre-allocate objects

local mp,mpx = ffi.load("msgpackc"),ffi.load("luajitmsgpack")
local buffer = ffi.new("msgpack_sbuffer")
local packer = ffi.new("msgpack_packer")
local msg = ffi.new("msgpack_unpacked")

--- packers

local packers = {}

packers.dynamic = function(data)
  return packers[type(data)](data)
end

packers["nil"] = function(data)
  mpx.ljmp_pack_nil(packer)
end

packers.boolean = function(data)
  if data then
    mpx.ljmp_pack_true(packer)
  else
    mpx.ljmp_pack_false(packer)
  end
end

packers.number = function(data)
  if math.ceil(data) == data then
    mpx.ljmp_pack_int64(packer,data)
  else -- could be float to save memory
    mpx.ljmp_pack_double(packer,data)
  end
end

packers.string = function(data)
  mpx.ljmp_pack_raw(packer,#data)
  mpx.ljmp_pack_raw_body(packer,data,#data)
end

packers["function"] = function(data)
  error("unimplemented")
end

packers.userdata = function(data)
  error("unimplemented")
end

packers.thread = function(data)
  error("unimplemented")
end

packers.table = function(data)
  local is_map,ndata,nmax = false,0,0
  for k,_ in pairs(data) do
    if type(k) == "number" then
      if k > nmax then nmax = k end
    else is_map = true end
    ndata = ndata+1
  end
  if is_map then -- pack as map
    mpx.ljmp_pack_map(packer,ndata)
    for k,v in pairs(data) do
      packers[type(k)](k)
      packers[type(v)](v)
    end
  else -- pack as array
    mpx.ljmp_pack_array(packer,nmax)
    for i=1,nmax do packers[type(data[i])](data[i]) end
  end
end

--- unpackers

local unpackers = {}

unpackers.dynamic = function(obj)
  return unpackers[obj.type](obj)
end

unpackers[mp.MSGPACK_OBJECT_NIL] = function(obj)
  return nil
end

unpackers[mp.MSGPACK_OBJECT_BOOLEAN] = function(obj)
  return obj.via.boolean
end

unpackers[mp.MSGPACK_OBJECT_POSITIVE_INTEGER] = function(obj)
  return tonumber(obj.via.u64)
end

unpackers[mp.MSGPACK_OBJECT_NEGATIVE_INTEGER] = function(obj)
  return tonumber(obj.via.i64)
end

unpackers[mp.MSGPACK_OBJECT_DOUBLE] = function(obj)
  return tonumber(obj.via.dec)
end

unpackers[mp.MSGPACK_OBJECT_RAW] = function(obj)
  return ffi.string(obj.via.raw.ptr,obj.via.raw.size)
end

unpackers[mp.MSGPACK_OBJECT_ARRAY] = function(obj)
  local r = {}
  for i=1,obj.via.array.size do
    r[i] = unpackers.dynamic(obj.via.array.ptr[i-1])
  end
  return r
end

unpackers[mp.MSGPACK_OBJECT_MAP] = function(obj)
  local r = {}
  local x,k,v
  for i=1,obj.via.map.size do
    x = obj.via.map.ptr[i-1]
    k = unpackers.dynamic(x.key)
    v = unpackers.dynamic(x.val)
    r[k] = v
  end
  return r
end

--- Main functions

local lj_pack = function(data)
  mpx.ljmp_sbuffer_init(buffer)
  mpx.ljmp_packer_init(packer,buffer)
  packers.dynamic(data)
  local s = ffi.string(buffer.data,buffer.size)
  mpx.ljmp_sbuffer_destroy(buffer)
  return s
end

local lj_unpack = function(s,offset)
  if offset == nil then offset = 0 end
  if type(s) ~= "string" then return false,"invalid argument" end
  mpx.ljmp_unpacked_init(msg)
  mpx.ljmp_sbuffer_init(buffer)
  mpx.ljmp_sbuffer_write(buffer,s,#s)
  local off = ffi.new("size_t[1]")
  off[0] = offset
  local rval = mpx.ljmp_unpack_next(msg,buffer.data,buffer.size,off)
  if rval ~= 0 then return nil end
  local data = unpackers.dynamic(msg.data)
  mpx.ljmp_unpacked_destroy(msg)
  mpx.ljmp_sbuffer_destroy(buffer)
  return tonumber(off[0]),data
end

return {
  pack = lj_pack,
  unpack = lj_unpack,
}
