#!/bin/bash

#change these to match your MinGW installation:
# platform name, for configure scripts
HOST="i686-w64-mingw32" 
# prefix for MinGW executables (e.g. if MinGW gcc is named i686-w64-mingw32-gcc, use "i686-w64-mingw32-")
MINGW_BIN_PREFIX="i686-w64-mingw32-"
# where to install the libraries
# you'll probably want to set this to the location where all the existing MinGW bin/lib/include folders are
MINGW_INSTALL_DIR="/usr/i686-w64-mingw32" 


#
# Script to download, compile (including files for static linking) 
# and install libraries for compiling Powder Toy using MinGW, 
#
# Copyright (c) 2011-2013 jacksonmj
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#

export AR=${MINGW_BIN_PREFIX}ar
export CC=${MINGW_BIN_PREFIX}gcc
export RANLIB=${MINGW_BIN_PREFIX}ranlib
export WINDRES=${MINGW_BIN_PREFIX}windres
export STRIP=${MINGW_BIN_PREFIX}strip
export PREFIX=${MINGW_INSTALL_DIR}
MAKE="make -j 16"



log_error()
{
	error_msg=${1}
	if test "${errors}" = ""; then
		errors=${error_msg}
	else
		errors=${errors}"\n"${error_msg}
	fi
	printf "\033[1;31m${error_msg}\033[m\n"
}

make_lib()
{
	lib=$1
	eval ${lib}_successful_make=0
	eval filename=\$${lib}_filename
	eval url=\$${lib}_url
	if test "${filename}" = ""; then
		log_error "Library name \"${lib}\" not recognised"
		return 1
	fi
	if test ! -f ${filename}; then
		printf "\033[1m${filename} does not exist, downloading...\033[m\n"
		wget -O "${filename}" "${url}"
		if test $? -ne 0; then
			log_error "Unable to download ${url}"
			return 1
		fi
	fi
	eval md5=\$${lib}_md5
	if test "${md5}" != ""; then
		md5_test=`md5sum -b ${filename} | cut -d' ' -f 1`
		if test "${md5}" != "${md5_test}"; then
			log_error "Incorrect checksum for ${filename}"
			return 1
		fi
	fi
	eval sha256=\$${lib}_sha256
	if test "${sha256}" != ""; then
		sha256_test=`sha256sum -b ${filename} | cut -d' ' -f 1`
		if test "${sha256}" != "${sha256_test}"; then
			log_error "Incorrect checksum for ${filename}"
			return 1
		fi
	fi
	eval sha512=\$${lib}_sha521
	if test "${sha512}" != ""; then
		sha512_test=`sha512sum -b ${filename} | cut -d' ' -f 1`
		if test "${sha512}" != "${sha512_test}"; then
			log_error "Incorrect checksum for ${filename}"
			return 1
		fi
	fi
	eval folder=\$${lib}_folder
	eval extractfolder=\$${lib}_extractfolder
	if test "${extractfolder}" != ""; then
		rm -rf ${extractfolder}${folder}
	fi
	printf "\033[1mExtracting ${filename}...\033[m\n"
	mkdir -p ${extractfolder}
	tar -C ${extractfolder} -axf ${filename}
	if test $? -ne 0; then
		log_error "Unable to extract ${filename}"
		return 1
	fi
	printf "\033[1mCompiling ${lib}...\033[m\n"
	${lib}_compile ${extractfolder}${folder}
	if test $? -ne 0; then
		log_error "Failed to compile ${lib}"
		return 1
	fi
	printf "\033[1;32m${lib} compiled and ready to install\033[m\n\n"
	eval ${lib}_successful_make=1
	return 0
}

install_lib()
{
	lib=$1
	eval ${lib}_successful_install=0
	eval folder=\$${lib}_folder
	eval extractfolder=\$${lib}_extractfolder
	printf "\033[1mInstalling ${lib}...\033[m\n"
	${lib}_install ${extractfolder}${folder}
	if test $? -ne 0; then
		log_error "Failed to install ${lib}"
		return 1
	fi
	printf "\033[1;32m${lib} installed\033[m\n\n"
	eval ${lib}_successful_install=1
	return 0
}




bzip2_url="https://sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz"
bzip2_sha512="083f5e675d73f3233c7930ebe20425a533feedeaaa9d8cc86831312a6581cefbe6ed0d08d2fa89be81082f2a5abdabca8b3c080bf97218a1bd59dc118a30b9f3"
bzip2_filename="bzip2-1.0.8.tar.gz"
bzip2_folder="/bzip2-1.0.8"
bzip2_extractfolder="tpt-libs"
bzip2_compile()
{
	pushd $1 > /dev/null
	#mingw does not like backslashes in include file paths, fix it:
	cat bzip2.c | sed -e 's|sys\\stat.h|sys/stat.h|' > bzip2.c.fixed
	rm bzip2.c && mv bzip2.c.fixed bzip2.c
	$MAKE bzip2 bzip2recover CC=$CC AR=$AR RANLIB=$RANLIB PREFIX=$PREFIX
	result=$?
	popd > /dev/null
	return $result
}
bzip2_install()
{
	pushd $1 > /dev/null
	$MAKE install CC=$CC AR=$AR RANLIB=$RANLIB PREFIX=$MINGW_INSTALL_DIR
	result=$?
	popd > /dev/null
	return $result
}

fftw_url="http://www.fftw.org/fftw-3.3.3.tar.gz"
fftw_md5="0a05ca9c7b3bfddc8278e7c40791a1c2"
fftw_filename="fftw-3.3.3.tar.gz"
fftw_folder="/fftw-3.3.3"
fftw_extractfolder="tpt-libs"
fftw_compile()
{
	pushd $1 > /dev/null
	./configure --host=$HOST --build=`./config.guess` --prefix=$MINGW_INSTALL_DIR --enable-shared --enable-static --disable-alloca --with-our-malloc16 --disable-threads --disable-fortran --enable-portable-binary --enable-float --enable-sse && \
	$MAKE
	result=$?
	popd > /dev/null
	return $result
}
fftw_install()
{
	pushd $1 > /dev/null
	$MAKE install
	result=$?
	popd > /dev/null
	return $result
}

sdl_directx_url="http://www.libsdl.org/extras/win32/common/directx-devel.tar.gz"
sdl_directx_md5="389a36e4d209c0a76bea7d7cb6315315"
sdl_directx_filename="directx-devel.tar.gz"
sdl_directx_folder=""
sdl_directx_extractfolder="tpt-libs/sdl-directx-devel"
sdl_directx_compile()
{
	cp -f $1/include/* ${sdl_extractfolder}${sdl_folder}/include/
	return $?
}

sdl_url="http://www.libsdl.org/release/SDL-1.2.15.tar.gz"
sdl_md5="9d96df8417572a2afb781a7c4c811a85"
sdl_filename="SDL-1.2.15.tar.gz"
sdl_folder="/SDL-1.2.15"
sdl_extractfolder="tpt-libs"
sdl_compile()
{
	printf "\033[1mGetting extra headers for SDL...\033[m\n"
	make_lib sdl_directx
	if test $? -ne 0; then
		return 1
	fi
	lib="sdl"
	pushd $1 > /dev/null
	./configure --host=$HOST --build=`build-scripts/config.guess` --prefix=$MINGW_INSTALL_DIR && \
	$MAKE WINDRES=$WINDRES
	result=$?
	popd > /dev/null
	return $result
}
sdl_install()
{
	pushd $1 > /dev/null
	$MAKE install
	result=$?
	popd > /dev/null
	return $result
}

pthread_url="https://sourceware.org/pub/pthreads-win32/pthreads-w32-2-9-1-release.tar.gz"
pthread_sha512="9c06e85310766834370c3dceb83faafd397da18a32411ca7645c8eb6b9495fea54ca2872f4a3e8d83cb5fdc5dea7f3f0464be5bb9af3222a6534574a184bd551"
pthread_filename="pthreads-w32-2-9-1-release.tar.gz"
pthread_folder="/pthreads-w32-2-9-1-release"
pthread_extractfolder="tpt-libs"
pthread_compile()
{
	pushd $1 > /dev/null
	$MAKE clean && \
	$MAKE GC CROSS=${MINGW_BIN_PREFIX} && \
	mv -f libpthreadGC2.a libpthreadGC2.dll.a && \
	$MAKE clean && \
	$MAKE clean GC-static CROSS=${MINGW_BIN_PREFIX}
	result=$?
	popd > /dev/null
	return $result
}
pthread_install()
{
	pushd $1 > /dev/null
	mkdir -p $MINGW_INSTALL_DIR/bin $MINGW_INSTALL_DIR/include $MINGW_INSTALL_DIR/lib && \
	cp -f pthreadGC2.dll $MINGW_INSTALL_DIR/bin/ && \
	cp -f pthread.h sched.h semaphore.h $MINGW_INSTALL_DIR/include/ && \
	cp -f libpthreadGC2.a $MINGW_INSTALL_DIR/lib/libpthread.a && \
	cp -f libpthreadGC2.dll.a $MINGW_INSTALL_DIR/lib/libpthread.dll.a && \
	result=$?
	popd > /dev/null
	return $result
}

regex_url="http://downloads.sourceforge.net/project/mingw/Other/UserContributed/regex/mingw-regex-2.5.1/mingw-libgnurx-2.5.1-src.tar.gz"
regex_md5="35c8fed3101ca1f253e9b6b1966661f6"
regex_filename="mingw-libgnurx-2.5.1-src.tar.gz"
regex_folder="/mingw-libgnurx-2.5.1"
regex_extractfolder="tpt-libs"
regex_compile()
{
	pushd $1 > /dev/null
	./configure --host=$HOST --prefix=$MINGW_INSTALL_DIR && \
	$MAKE
	if test $? -ne 0; then
		popd > /dev/null
		return 1
	fi
	rm -f libregex.a
	${AR} -rc libgnurx.a regex.o && \
	cp -p libgnurx.a libregex.a
	result=$?
	popd > /dev/null
	return $result
}
regex_install()
{
	pushd $1 > /dev/null
	$MAKE install && \
	mkdir -p $MINGW_INSTALL_DIR/lib && \
	cp -f libregex.a libgnurx.a $MINGW_INSTALL_DIR/lib/
	result=$?
	popd > /dev/null
	return $result
}

lua_url="http://www.lua.org/ftp/lua-5.1.4.tar.gz"
lua_md5="d0870f2de55d59c1c8419f36e8fac150"
lua_filename="lua-5.1.4.tar.gz"
lua_folder="/lua-5.1.4"
lua_extractfolder="tpt-libs"
lua_compile()
{
	pushd $1/src > /dev/null
	$MAKE LUA_A="liblua5.1.a" LUA_T="lua.exe" \
	CC="$CC" AR="$AR rcu" RANLIB="$RANLIB" lua.exe && \
	$MAKE LUA_A="liblua5.1.a" LUAC_T="luac.exe" \
	CC="$CC" AR="$AR rcu" RANLIB="$RANLIB" luac.exe 
	result=$?
	popd > /dev/null
	return $result
}
lua_install()
{
	pushd $1 > /dev/null
	$MAKE install RANLIB="$RANLIB" INSTALL_TOP="$MINGW_INSTALL_DIR" \
	INSTALL_INC="$MINGW_INSTALL_DIR/include/lua5.1/" \
	TO_BIN="lua.exe luac.exe" TO_LIB="liblua5.1.a"
	result=$?
	popd > /dev/null
	return $result
}

lua52_url="http://www.lua.org/ftp/lua-5.2.3.tar.gz"
lua52_md5="dc7f94ec6ff15c985d2d6ad0f1b35654"
lua52_filename="lua-5.2.3.tar.gz"
lua52_folder="/lua-5.2.3"
lua52_extractfolder="tpt-libs"
lua52_compile()
{
	pushd $1/src > /dev/null
	$MAKE LUA_A="liblua5.2.a" LUA_T="lua.exe" \
	CC="$CC" AR="$AR rcu" RANLIB="$RANLIB" lua.exe && \
	$MAKE LUA_A="liblua5.2.a" LUAC_T="luac.exe" \
	CC="$CC" AR="$AR rcu" RANLIB="$RANLIB" luac.exe 
	result=$?
	popd > /dev/null
	return $result
}
lua52_install()
{
	pushd $1 > /dev/null
	$MAKE install RANLIB="$RANLIB" INSTALL_TOP="$MINGW_INSTALL_DIR" \
	INSTALL_INC="$MINGW_INSTALL_DIR/include/lua5.2/" \
	TO_BIN="lua.exe luac.exe" TO_LIB="liblua5.2.a"
	result=$?
	popd > /dev/null
	return $result
}

luajit_url="http://luajit.org/download/LuaJIT-2.0.4.tar.gz"
luajit_md5="dd9c38307f2223a504cbfb96e477eca0"
luajit_filename="LuaJIT-2.0.4.tar.gz"
luajit_folder="/LuaJIT-2.0.4"
luajit_extractfolder="tpt-libs"
luajit_compile()
{
	pushd $1/src > /dev/null
	$MAKE CROSS=$MINGW_BIN_PREFIX TARGET_SYS=Windows\
	HOST_CC="gcc -m32" libluajit.a luajit.exe
	result=$?
	popd > /dev/null
	return $result
}
luajit_install()
{
	pushd $1 > /dev/null
	$MAKE install CROSS=$MINGW_BIN_PREFIX TARGET_SYS=Windows FILE_T=luajit.exe\
	HOST_CC="gcc -m32" PREFIX="$MINGW_INSTALL_DIR"
	result=$?
	popd > /dev/null
	return $result
}

zlib_url="http://zlib.net/zlib-1.2.11.tar.gz"
zlib_sha256="c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1"
zlib_filename="zlib-1.2.11.tar.gz"
zlib_folder="/zlib-1.2.11"
zlib_extractfolder="tpt-libs"
zlib_compile()
{
	pushd $1 > /dev/null
	$MAKE -f win32/Makefile.gcc CC="${CC}" AR="${AR}" RC="${WINDRES}" STRIP="${STRIP}" prefix="${MINGW_INSTALL_DIR}"
	result=$?
	popd > /dev/null
	return $result
}
zlib_install()
{
	pushd $1 > /dev/null
	$MAKE -f win32/Makefile.gcc install DESTDIR="${MINGW_INSTALL_DIR}" BINARY_PATH="/bin" INCLUDE_PATH="/include" LIBRARY_PATH="/lib"
	result=$?
	popd > /dev/null
	return $result
}


echo_usage()
{
	printf "
\033[1mInstructions for use:\033[m

  First, edit this script and change the variables at the start to
  match your MinGW installation. Then use these commands to download,
  compile, and install libraries:
  
    \033[1m"${0}"\033[m make \033[4mLIBRARY_NAME\033[m...
    \033[1msudo "${0}"\033[m install \033[4mLIBRARY_NAME\033[m...
    
  Valid LIBRARY_NAMEs are: \033[1mbzip2 fftw lua lua52 pthread regex sdl zlib\033[m
\n"
}


if test "${1}" = "make"; then
	shift
	for lib in "$@"
	do
		make_lib ${lib}
	done
	success_count=0
	fail_count=0
	for lib in "$@"
	do
		eval result=\${${lib}_successful_make}
		if test ${result} -eq 1; then
			success_count=`expr ${success_count} + 1`
		else
			fail_count=`expr ${fail_count} + 1`
		fi
	done
	if test $# -gt 0; then
		if test ${fail_count} -eq 0; then
			printf "\033[1mFinished\033[m\n"
			if test ${success_count} -eq 1; then
				printf "\033[1m${success_count} library ready to install\033[m\n"
			else
				printf "\033[1m${success_count} libraries ready to install\033[m\n"
			fi
			printf "\nInstall with:\n  sudo ${0} install $@\n\n"
		elif test $# -gt 1; then
			fail_list=""
			for lib in "$@"
			do
				eval result=\${${lib}_successful_make}
				if test ${result} -eq 0; then
					fail_list="${fail_list}${lib} "
				fi
			done
			if test ${fail_count} -eq 1; then
				printf "\n\n\033[1;31mErrors occurred while trying to download/compile ${fail_count} library\033[m\n"
			else
				printf "\n\n\033[1;31mErrors occurred while trying to download/compile ${fail_count} libraries\033[m\n"
			fi
			printf "Failed libraries: ${fail_list}\n\n"
			printf "Messages:\n${errors}\n"
		fi
	else
		echo_usage
	fi
elif test "${1}" = "install"; then
	shift
	for lib in "$@"
	do
		install_lib ${lib}
	done
	success_count=0
	fail_count=0
	for lib in "$@"
	do
		eval result=\${${lib}_successful_install}
		if test ${result} -eq 1; then
			success_count=`expr ${success_count} + 1`
		else
			fail_count=`expr ${fail_count} + 1`
		fi
	done
	if test $# -gt 0; then
		if test ${fail_count} -eq 0; then
			printf "\033[1mFinished\033[m\n"
			if test ${success_count} -eq 1; then
				printf "\033[1m${success_count} library successfully installed\033[m\n\n"
			else
				printf "\033[1m${success_count} libraries successfully installed\033[m\n\n"
			fi
		elif test $# -gt 1; then
			fail_list=""
			for lib in "$@"
			do
				eval result=\${${lib}_successful_install}
				if test ${result} -eq 0; then
					fail_list="${fail_list}${lib} "
				fi
			done
			if test ${fail_count} -eq 1; then
				printf "\n\n\033[1;31mErrors occurred while trying to install ${fail_count} library\033[m\n"
			else
				printf "\n\n\033[1;31mErrors occurred while trying to install ${fail_count} libraries\033[m\n"
			fi
			printf "Failed libraries: ${fail_list}\n\n"
			#printf "Messages:\n${errors}\n"
		fi
	else
		echo_usage
	fi
else
	echo_usage
fi



