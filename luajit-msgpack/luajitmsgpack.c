#include "msgpack.h"

void ljmp_sbuffer_init(msgpack_sbuffer * sbuf)
{ msgpack_sbuffer_init(sbuf); }

void ljmp_sbuffer_destroy(msgpack_sbuffer * sbuf)
{ msgpack_sbuffer_destroy(sbuf); }

int ljmp_sbuffer_write(
 msgpack_sbuffer * sbuf,
 const char * buf,
 unsigned int len
)
{ return msgpack_sbuffer_write((void *)sbuf,buf,len); }

void ljmp_packer_init(msgpack_packer * pk,void * data)
{ msgpack_packer_init(pk,data,msgpack_sbuffer_write); }

int ljmp_pack_nil(msgpack_packer* pk)
{ return msgpack_pack_nil(pk); }

int ljmp_pack_true(msgpack_packer* pk)
{ return msgpack_pack_true(pk); }

int ljmp_pack_false(msgpack_packer* pk)
{ return msgpack_pack_false(pk); }

int ljmp_pack_int64(msgpack_packer* pk,int64_t d)
{ return msgpack_pack_int64(pk,d); }

int ljmp_pack_float(msgpack_packer* pk,float d)
{ return msgpack_pack_float(pk,d); }

int ljmp_pack_double(msgpack_packer* pk,double d)
{ return msgpack_pack_double(pk,d); }

int ljmp_pack_raw(msgpack_packer * pk,size_t l)
{ return msgpack_pack_raw(pk,l); }

int ljmp_pack_raw_body(msgpack_packer * pk,const void * b,size_t l)
{ return msgpack_pack_raw_body(pk,b,l); }

int ljmp_pack_array(msgpack_packer * pk,unsigned int n)
{ return msgpack_pack_array(pk,n); }

int ljmp_pack_map(msgpack_packer * pk,unsigned int n)
{ return msgpack_pack_map(pk,n); }

void ljmp_unpacked_init(msgpack_unpacked * result)
{ msgpack_unpacked_init(result); }

void ljmp_unpacked_destroy(msgpack_unpacked * result)
{ msgpack_unpacked_destroy(result); }

int ljmp_unpack_next( msgpack_unpacked* result,const char* data,
                      size_t len,size_t* off )
{ return msgpack_unpack_next(result,data,len,off) ? 0 : -1; }
