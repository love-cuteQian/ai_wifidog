#.rst:
# FindOpenSSL
# -----------
#
# Try to find the OpenSSL encryption library
#
# Once done this will define
#
# ::
#
#   OPENSSL_ROOT_DIR - Set this variable to the root installation of OpenSSL
#
#
#
# Read-Only variables:
#
# ::
#
#   OPENSSL_FOUND - System has the OpenSSL library
#   OPENSSL_INCLUDE_DIR - The OpenSSL include directory
#   OPENSSL_CRYPTO_LIBRARY - The OpenSSL crypto library
#   OPENSSL_SSL_LIBRARY - The OpenSSL SSL library
#   OPENSSL_LIBRARIES - All OpenSSL libraries
#   OPENSSL_VERSION - This is set to $major.$minor.$revision$patch (eg. 0.9.8s)

#=============================================================================
# Copyright 2006-2009 Kitware, Inc.
# Copyright 2006 Alexander Neundorf <neundorf@kde.org>
# Copyright 2009-2011 Mathieu Malaterre <mathieu.malaterre@gmail.com>
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# (To distribute this file outside of CMake, substitute the full
#  License text for the above reference.)

if (UNIX)
  find_package(PkgConfig QUIET)
  pkg_check_modules(_OPENSSL QUIET openssl)
endif ()

if (WIN32)
  # http://www.slproweb.com/products/Win32OpenSSL.html
  set(_OPENSSL_ROOT_HINTS
    ${OPENSSL_ROOT_DIR}
    "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\OpenSSL (32-bit)_is1;Inno Setup: App Path]"
    "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\OpenSSL (64-bit)_is1;Inno Setup: App Path]"
    ENV OPENSSL_ROOT_DIR
    )
  file(TO_CMAKE_PATH "$ENV{PROGRAMFILES}" _programfiles)
  set(_OPENSSL_ROOT_PATHS
    "${_programfiles}/OpenSSL"
    "${_programfiles}/OpenSSL-Win32"
    "${_programfiles}/OpenSSL-Win64"
    "C:/OpenSSL/"
    "C:/OpenSSL-Win32/"
    "C:/OpenSSL-Win64/"
    )
  unset(_programfiles)
else ()
  set(_OPENSSL_ROOT_HINTS
    ${OPENSSL_ROOT_DIR}
    ENV OPENSSL_ROOT_DIR
    )
endif ()

set(_OPENSSL_ROOT_HINTS_AND_PATHS
    HINTS ${_OPENSSL_ROOT_HINTS}
    PATHS ${_OPENSSL_ROOT_PATHS}
    )

find_path(OPENSSL_INCLUDE_DIR
  NAMES
    openssl/ssl.h
  ${_OPENSSL_ROOT_HINTS_AND_PATHS}
  HINTS
    ${_OPENSSL_INCLUDEDIR}
  PATH_SUFFIXES
    include
)

if(WIN32 AND NOT CYGWIN)
  if(MSVC)
    # /MD and /MDd are the standard values - if someone wants to use
    # others, the libnames have to change here too
    # use also ssl and ssleay32 in debug as fallback for openssl < 0.9.8b
    # TODO: handle /MT and static lib
    # In Visual C++ naming convention each of these four kinds of Windows libraries has it's standard suffix:
    #   * MD for dynamic-release
    #   * MDd for dynamic-debug
    #   * MT for static-release
    #   * MTd for static-debug

    # Implementation details:
    # We are using the libraries located in the VC subdir instead of the parent directory eventhough :
    # libeay32MD.lib is identical to ../libeay32.lib, and
    # ssleay32MD.lib is identical to ../ssleay32.lib
    find_library(LIB_EAY_DEBUG
      NAMES
        libeay32MDd
        libeay32d
      ${_OPENSSL_ROOT_HINTS_AND_PATHS}
      PATH_SUFFIXES
        "lib"
        "VC"
        "lib/VC"
    )

    find_library(LIB_EAY_RELEASE
      NAMES
        libeay32MD
        libeay32
      ${_OPENSSL_ROOT_HINTS_AND_PATHS}
      PATH_SUFFIXES
        "lib"
        "VC"
        "lib/VC"
    )

    find_library(SSL_EAY_DEBUG
      NAMES
        ssleay32MDd
        ssleay32d
      ${_OPENSSL_ROOT_HINTS_AND_PATHS}
      PATH_SUFFIXES
        "lib"
        "VC"
        "lib/VC"
    )

    find_library(SSL_EAY_RELEASE
      NAMES
        ssleay32MD
        ssleay32
        ssl
      ${_OPENSSL_ROOT_HINTS_AND_PATHS}
      PATH_SUFFIXES
        "lib"
        "VC"
        "lib/VC"
    )

    set(LIB_EAY_LIBRARY_DEBUG "${LIB_EAY_DEBUG}")
    set(LIB_EAY_LIBRARY_RELEASE "${LIB_EAY_RELEASE}")
    set(SSL_EAY_LIBRARY_DEBUG "${SSL_EAY_DEBUG}")
    set(SSL_EAY_LIBRARY_RELEASE "${SSL_EAY_RELEASE}")

    include(${CMAKE_CURRENT_LIST_DIR}/SelectLibraryConfigurations.cmake)
    select_library_configurations(LIB_EAY)
    select_library_configurations(SSL_EAY)

    mark_as_advanced(LIB_EAY_LIBRARY_DEBUG LIB_EAY_LIBRARY_RELEASE
                     SSL_EAY_LIBRARY_DEBUG SSL_EAY_LIBRARY_RELEASE)
    set( OPENSSL_SSL_LIBRARY ${SSL_EAY_LIBRARY} )
    set( OPENSSL_CRYPTO_LIBRARY ${LIB_EAY_LIBRARY} )
    set( OPENSSL_LIBRARIES ${SSL_EAY_LIBRARY} ${LIB_EAY_LIBRARY} )
  elseif(MINGW)
    # same player, for MinGW
    set(LIB_EAY_NAMES libeay32)
    set(SSL_EAY_NAMES ssleay32)
    if(CMAKE_CROSSCOMPILING)
      list(APPEND LIB_EAY_NAMES crypto)
      list(APPEND SSL_EAY_NAMES ssl)
    endif()
    find_library(LIB_EAY
      NAMES
        ${LIB_EAY_NAMES}
      ${_OPENSSL_ROOT_HINTS_AND_PATHS}
      PATH_SUFFIXES
        "lib"
        "lib/MinGW"
    )

    find_library(SSL_EAY
      NAMES
        ${SSL_EAY_NAMES}
      ${_OPENSSL_ROOT_HINTS_AND_PATHS}
      PATH_SUFFIXES
        "lib"
        "lib/MinGW"
    )

    mark_as_advanced(SSL_EAY LIB_EAY)
    set( OPENSSL_SSL_LIBRARY ${SSL_EAY} )
    set( OPENSSL_CRYPTO_LIBRARY ${LIB_EAY} )
    set( OPENSSL_LIBRARIES ${SSL_EAY} ${LIB_EAY} )
    unset(LIB_EAY_NAMES)
    unset(SSL_EAY_NAMES)
  else()
    # Not sure what to pick for -say- intel, let's use the toplevel ones and hope someone report issues:
    find_library(LIB_EAY
      NAMES
        libeay32
      ${_OPENSSL_ROOT_HINTS_AND_PATHS}
      HINTS
        ${_OPENSSL_LIBDIR}
      PATH_SUFFIXES
        lib
    )

    find_library(SSL_EAY
      NAMES
        ssleay32
      ${_OPENSSL_ROOT_HINTS_AND_PATHS}
      HINTS
        ${_OPENSSL_LIBDIR}
      PATH_SUFFIXES
        lib
    )

    mark_as_advanced(SSL_EAY LIB_EAY)
    set( OPENSSL_SSL_LIBRARY ${SSL_EAY} )
    set( OPENSSL_CRYPTO_LIBRARY ${LIB_EAY} )
    set( OPENSSL_LIBRARIES ${SSL_EAY} ${LIB_EAY} )
  endif()
else()

  find_library(OPENSSL_SSL_LIBRARY
    NAMES
      ssl
      ssleay32
      ssleay32MD
    ${_OPENSSL_ROOT_HINTS_AND_PATHS}
    HINTS
      ${_OPENSSL_LIBDIR}
    PATH_SUFFIXES
      lib
  )

  find_library(OPENSSL_CRYPTO_LIBRARY
    NAMES
      crypto
    ${_OPENSSL_ROOT_HINTS_AND_PATHS}
    HINTS
      ${_OPENSSL_LIBDIR}
    PATH_SUFFIXES
      lib
  )

  mark_as_advanced(OPENSSL_CRYPTO_LIBRARY OPENSSL_SSL_LIBRARY)

  # compat defines
  set(OPENSSL_SSL_LIBRARIES ${OPENSSL_SSL_LIBRARY})
  set(OPENSSL_CRYPTO_LIBRARIES ${OPENSSL_CRYPTO_LIBRARY})

  set(OPENSSL_LIBRARIES ${OPENSSL_SSL_LIBRARY} ${OPENSSL_CRYPTO_LIBRARY})

endif()

function(from_hex HEX DEC)
  string(TOUPPER "${HEX}" HEX)
  set(_res 0)
  string(LENGTH "${HEX}" _strlen)

  while (_strlen GREATER 0)
    math(EXPR _res "${_res} * 16")
    string(SUBSTRING "${HEX}" 0 1 NIBBLE)
    string(SUBSTRING "${HEX}" 1 -1 HEX)
    if (NIBBLE STREQUAL "A")
      math(EXPR _res "${_res} + 10")
    elseif (NIBBLE STREQUAL "B")
      math(EXPR _res "${_res} + 11")
    elseif (NIBBLE STREQUAL "C")
      math(EXPR _res "${_res} + 12")
    elseif (NIBBLE STREQUAL "D")
      math(EXPR _res "${_res} + 13")
    elseif (NIBBLE STREQUAL "E")
      math(EXPR _res "${_res} + 14")
    elseif (NIBBLE STREQUAL "F")
      math(EXPR _res "${_res} + 15")
    else()
      math(EXPR _res "${_res} + ${NIBBLE}")
    endif()

    string(LENGTH "${HEX}" _strlen)
  endwhile()

  set(${DEC} ${_res} PARENT_SCOPE)
endfunction()

if(OPENSSL_INCLUDE_DIR AND EXISTS "${OPENSSL_INCLUDE_DIR}/openssl/opensslv.h")
  file(STRINGS "${OPENSSL_INCLUDE_DIR}/openssl/opensslv.h" openssl_version_str
       REGEX "^#[\t ]*define[\t ]+OPENSSL_VERSION_NUMBER[\t ]+0x([0-9a-fA-F])+.*")

  if(openssl_version_str)
    # The version number is encoded as 0xMNNFFPPS: major minor fix patch status
    # The status gives if this is a developer or prerelease and is ignored here.
    # Major, minor, and fix directly translate into the version numbers shown in
    # the string. The patch field translates to the single character suffix that
    # indicates the bug fix state, which 00 -> nothing, 01 -> a, 02 -> b and so
    # on.

    string(REGEX REPLACE "^.*OPENSSL_VERSION_NUMBER[\t ]+0x([0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F]).*$"
           "\\1;\\2;\\3;\\4;\\5" OPENSSL_VERSION_LIST "${openssl_version_str}")
    list(GET OPENSSL_VERSION_LIST 0 OPENSSL_VERSION_MAJOR)
    list(GET OPENSSL_VERSION_LIST 1 OPENSSL_VERSION_MINOR)
    from_hex("${OPENSSL_VERSION_MINOR}" OPENSSL_VERSION_MINOR)
    list(GET OPENSSL_VERSION_LIST 2 OPENSSL_VERSION_FIX)
    from_hex("${OPENSSL_VERSION_FIX}" OPENSSL_VERSION_FIX)
    list(GET OPENSSL_VERSION_LIST 3 OPENSSL_VERSION_PATCH)

    if (NOT OPENSSL_VERSION_PATCH STREQUAL "00")
      from_hex("${OPENSSL_VERSION_PATCH}" _tmp)
      # 96 is the ASCII code of 'a' minus 1
      math(EXPR OPENSSL_VERSION_PATCH_ASCII "${_tmp} + 96")
      unset(_tmp)
      # Once anyone knows how OpenSSL would call the patch versions beyond 'z'
      # this should be updated to handle that, too. This has not happened yet
      # so it is simply ignored here for now.
      string(ASCII "${OPENSSL_VERSION_PATCH_ASCII}" OPENSSL_VERSION_PATCH_STRING)
    endif ()

    set(OPENSSL_VERSION "${OPENSSL_VERSION_MAJOR}.${OPENSSL_VERSION_MINOR}.${OPENSSL_VERSION_FIX}${OPENSSL_VERSION_PATCH_STRING}")
  else ()
    # Since OpenSSL 3.0.0, the new version format is MAJOR.MINOR.PATCH and
    # a new OPENSSL_VERSION_STR macro contains exactly that
    file(STRINGS "${OPENSSL_INCLUDE_DIR}/openssl/opensslv.h" OPENSSL_VERSION_STR
         REGEX "^#[\t ]*define[\t ]+OPENSSL_VERSION_STR[\t ]+\"([0-9])+\\.([0-9])+\\.([0-9])+\".*")
    string(REGEX REPLACE "^.*OPENSSL_VERSION_STR[\t ]+\"([0-9]+\\.[0-9]+\\.[0-9]+)\".*$"
           "\\1" OPENSSL_VERSION_STR "${OPENSSL_VERSION_STR}")

    set(OPENSSL_VERSION "${OPENSSL_VERSION_STR}")

    # Setting OPENSSL_VERSION_MAJOR OPENSSL_VERSION_MINOR and OPENSSL_VERSION_FIX
    string(REGEX MATCHALL "([0-9])+" OPENSSL_VERSION_NUMBER "${OPENSSL_VERSION}")
    list(POP_FRONT OPENSSL_VERSION_NUMBER
      OPENSSL_VERSION_MAJOR
      OPENSSL_VERSION_MINOR
      OPENSSL_VERSION_FIX)

    unset(OPENSSL_VERSION_NUMBER)
    unset(OPENSSL_VERSION_STR)
  endif ()
endif ()

include(${CMAKE_CURRENT_LIST_DIR}/FindPackageHandleStandardArgs.cmake)

if (OPENSSL_VERSION)
  find_package_handle_standard_args(OpenSSL
    REQUIRED_VARS
      OPENSSL_LIBRARIES
      OPENSSL_INCLUDE_DIR
    VERSION_VAR
      OPENSSL_VERSION
    FAIL_MESSAGE
      "Could NOT find OpenSSL, try to set the path to OpenSSL root folder in the system variable OPENSSL_ROOT_DIR"
  )
else ()
  find_package_handle_standard_args(OpenSSL "Could NOT find OpenSSL, try to set the path to OpenSSL root folder in the system variable OPENSSL_ROOT_DIR"
    OPENSSL_LIBRARIES
    OPENSSL_INCLUDE_DIR
  )
endif ()

mark_as_advanced(OPENSSL_INCLUDE_DIR OPENSSL_LIBRARIES)
