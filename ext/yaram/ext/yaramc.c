#include <ruby/ruby.h>
#include <sys/stat.h>
#include "ruby/io.h"

#include "ruby/ruby.h"
#include "ruby/io.h"
#include <ctype.h>
#include <errno.h>
#include "ruby/util.h"

static VALUE rb_yaram_mbox_mkfifo(VALUE, VALUE);
static VALUE rb_yaram_mbox_write_unblocked(VALUE, VALUE, VALUE);

static int io_fflush(rb_io_t *);
static VALUE rb_io_get_write_io(VALUE);


void Init_yaram() {
    VALUE rb_mYaram, rb_cYaramMbox;
    
    rb_mYaram = rb_define_module("Yaram");
    rb_cYaramMbox = rb_define_class_under(rb_mYaram, "Mailbox", rb_cObject);
    rb_define_method(rb_cYaramMbox, "mkfifo", rb_yaram_mbox_mkfifo, 1);
    rb_define_method(rb_cYaramMbox, "write_unblocked", rb_yaram_mbox_write_unblocked, 2);
}

/*
 * Gives us access to the mkfifo system call so that
 * we don't need to rely on exec.
 */
static VALUE
rb_yaram_mbox_mkfifo(VALUE self, VALUE name)
{
    if (rb_type(name) != T_STRING)
        rb_raise(rb_eArgError, "name must be a string");
    if (mkfifo(RSTRING_PTR(name), S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP) < 0)
        rb_raise(rb_eException, "can't create named pipe");
    return name;
}

/*#define GetOpenFile(obj,fp) rb_io_check_closed((fp) = RFILE(rb_io_taint_check(obj))->fptr)*/
/*
 *  call-seq:
 *     #write_unblocked(string)   -> integer
 *
 *  Writes the given string to <em>ios</em> using
 *  the write(2) system call. It assumes that O_NONBLOCK 
 *  is already set forthe underlying file descriptor.
 *
 *  Over ~100,000 calls it is about 0.043 seconds faster.
 *
 *  It returns the number of bytes written.
 */
static VALUE
rb_yaram_mbox_write_unblocked(VALUE self, VALUE io, VALUE str)
{
    rb_io_t *fptr;
    long n;

    rb_secure(4);
    if (TYPE(str) != T_STRING)
	    str = rb_obj_as_string(str);

    io = rb_io_get_write_io(io);
    GetOpenFile(io, fptr);
    rb_io_check_writable(fptr);

    if (io_fflush(fptr) < 0)
        rb_sys_fail(0);

    n = write(fptr->fd, RSTRING_PTR(str), RSTRING_LEN(str));

    if (n == -1) {
        if (errno == EWOULDBLOCK || errno == EAGAIN)
            rb_mod_sys_fail(rb_mWaitWritable, "write would block");
        rb_sys_fail_path(fptr->pathv);
    }

    return LONG2FIX(n);
}


/*
 * Support functions for write_unblocked.
 * They originate from Ruby's io.c. We redefine them here 
 * because in that file they are declared with static, so
 * they aren't accessible here.
 * 
 */

static int io_fflush(rb_io_t *fptr){
    rb_io_check_closed(fptr);
    if (fptr->wbuf_len == 0)
        return 0;
    if (!rb_thread_fd_writable(fptr->fd)) {
        rb_io_check_closed(fptr);
    }
    while (fptr->wbuf_len > 0 && io_flush_buffer(fptr) != 0) {
	if (!rb_io_wait_writable(fptr->fd))
	    return -1;
        rb_io_check_closed(fptr);
    }
    return 0;
}

static VALUE 
rb_io_get_write_io(VALUE io)
{
    VALUE write_io;
    rb_io_check_initialized(RFILE(io)->fptr);
    write_io = RFILE(io)->fptr->tied_io_for_writing;
    if (write_io) {
        return write_io;
    }
    return io;
}

