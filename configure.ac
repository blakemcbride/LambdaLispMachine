#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.69])
AC_INIT([ld], [0.98.3], [dseagrav@lunar-tokyo.net])
AC_CONFIG_SRCDIR([src/kernel.c])
AC_CONFIG_HEADERS([src/config.h])
AC_CONFIG_MACRO_DIR([m4])
AM_INIT_AUTOMAKE

# Checks for programs.
AC_PROG_CC

# Conditionalize XBEEP
AC_ARG_ENABLE([use_xbeep],
	[AS_HELP_STRING([--enable-use-xbeep], [Enable superior XBEEP hack @<:@default=yes@:>@])])

# Conditionalize UTUN
AC_ARG_ENABLE([use_utun],
	[AS_HELP_STRING([--enable-use-utun], [Use UTUN frame diverter with BPF @<:@default=no@:>@])])

AS_IF([test "x$enable_use_utun" = "xyes"], [
	CFLAGS="$CFLAGS -DUSE_UTUN"
	])

# Conditionalize 2x2 support
AC_ARG_ENABLE([config_2x2],
	[AS_HELP_STRING([--enable-config-2x2], [Use 2x2 Lambda configuration @<:@default=no@:>@])])

AS_IF([test "x$enable_config_2x2" = "xyes"], [
	CFLAGS="$CFLAGS -DCONFIG_2X2"
	])

# Conditionalize physical keyboard support
AC_ARG_ENABLE([config_physkbd],
	[AS_HELP_STRING([--enable-config-physkbd], [Use physical Lambda keyboard @<:@default=no@:>@])])

AS_IF([test "x$enable_config_physkbd" = "xyes"], [
	CFLAGS="$CFLAGS -DCONFIG_PHYSKBD"
	])

# Conditionalize physical mouse support
AC_ARG_ENABLE([config_physms],
	[AS_HELP_STRING([--enable-config-physms], [Use physical Mouse Systems mouse @<:@default=no@:>@])])

AS_IF([test "x$enable_config_physms" = "xyes"], [
	CFLAGS="$CFLAGS -DCONFIG_PHYSMS"
	])

# Checks for libraries.
AC_ARG_WITH([FUSE],
	[AS_HELP_STRING([--with-FUSE],
		[support FUSE-based LMFS filesystem @<:@default=check@:>@])],
	[],
	[with_FUSE=check])

# SDL3 is used for the console
PKG_CHECK_MODULES([SDL3], [sdl3 >= 3.2.0], [],
	[AC_MSG_ERROR([*** SDL3 (version 3.2.0 or later) development files not found!])])
CFLAGS="$CFLAGS $SDL3_CFLAGS"
LIBS="$LIBS $SDL3_LIBS"

# XBEEP
AS_IF([test "x$enable_use_xbeep" != "xno"], [
	CFLAGS="$CFLAGS -DXBEEP"
	])

# Check for FUSE
LIBFUSE=
AS_IF([test "x$with_FUSE" != xno],
		    [PKG_CHECK_MODULES([fuse], [fuse],
		    [LIB_FUSE=TRUE],
		    [if test "x$with_FUSE" != xcheck; then
		      AC_MSG_FAILURE([--with-FUSE was given, but test for FUSE failed])
	 	     fi])])

# Checks for header files.
AC_CHECK_HEADERS([fcntl.h netdb.h netinet/in.h arpa/inet.h stddef.h stdint.h stdlib.h string.h strings.h])
AC_CHECK_HEADERS([ sys/ioctl.h sys/socket.h sys/time.h unistd.h termios.h utime.h])
AC_CHECK_HEADERS([linux/if.h], [], [],
[[#ifdef HAVE_SYS_SOCKET_H
#include <sys/socket.h>
#endif
]])
AC_CHECK_HEADERS([linux/if_tun.h], [], [],
[[#ifdef HAVE_SYS_SOCKET_H
#include <sys/socket.h>
#endif
]])
AC_CHECK_HEADERS([net/bpf.h])

# Check for structure members
AC_CHECK_MEMBERS([struct stat.st_blksize])

# Do we have libyaml?
AC_CHECK_HEADERS([yaml.h], [LIBS="$LIBS -lyaml"])

# Checks for typedefs, structures, and compiler characteristics.
AC_CHECK_HEADER_STDBOOL
AC_TYPE_INT32_T
AC_TYPE_INT64_T
AC_TYPE_OFF_T
AC_TYPE_SIZE_T
AC_TYPE_SSIZE_T
AC_TYPE_UINT16_T
AC_TYPE_UINT32_T
AC_TYPE_UINT64_T
AC_TYPE_UINT8_T
AC_TYPE_UID_T

AX_CHECK_COMPILE_FLAG([-Wno-packed-bitfield-compat], [CFLAGS="$CFLAGS -Wno-packed-bitfield-compat"], [], [-Werror])

# Checks for library functions.
AC_FUNC_MALLOC
AC_FUNC_REALLOC
AC_STRUCT_ST_BLOCKS
AC_CHECK_FUNCS([atexit bzero inet_ntoa gethostbyname memset socket strcasecmp strdup strtol strchr])
AC_CHECK_FUNCS([gettimeofday mkdir strerror strstr utime])

# Path propagation
CFLAGS="$CFLAGS -DSYSCONFDIR=${sysconfdir}"

# Done
AC_CONFIG_FILES([Makefile
                 src/Makefile])
# Also make tools
AC_CONFIG_FILES([tools/Makefile])
# If we have FUSE, make lmfuse
AM_CONDITIONAL([COND_LMFUSE],[test "$LIB_FUSE" = TRUE])
AC_CONFIG_FILES([tools/lmfuse/Makefile])
AC_OUTPUT
