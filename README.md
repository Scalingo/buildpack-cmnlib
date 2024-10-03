# Scalingo's Common Library for Buildpacks

A library of Bash functions commonly used in Scalingo's buildpacks.

These functions mainly allow for standardized and homogeneous outputs, and
prevent code rewriting thanks to commonly used utilities.


## Installing

The library is available at `https://<s3_url>/<bucket>/<version>/cmnlib.sh`,
with `<version>` being either `latest` or a specific release.

Place the following instruction towards the top of the `bin/compile` file of
the buildpack to download and import the library:

```bash
source /dev/stdin <<< "$( curl --silent --location --retry 3 "https://<s3_url>/<bucket>/<version>/std.sh" )" \
    || { printf "Unable to load cmnlib, aborting." >&2; exit 1; }
```

## Using the Library

### Output Functions

All output functions can be called with either a string argument or with a Bash
heredoc.

#### **`cmn::output::info`**

Outputs an informational message on `stdout`.

Can be called with a string argument or with a Bash heredoc.

:bulb: Examples:

```bash
# Calling:
cmn::output::info "This is an example."

# Would output:
        This is an example.
```

```bash
# Calling:
cmn::output::info <<- EOM
    This is an informative message.
    That should be useful to understand what's going on.
    EOM

# Would output:
        This is an informative message.
        That should be useful to understand what's going on.
```

#### **`cmn::output::warn`**

Outputs a warning message on `stdout`.

Can be called with a string argument or with a Bash heredoc.

:bulb: Examples:

```bash
# Calling:
cmn::output::warn "This is a warning."

# Would output:
 !      This is a warning.
```

```bash
# Calling:
cmn::output::warn <<- EOM
    This is a warning message.
    That should be useful to understand what's going on.
    EOM

# Would output:
 !      This is a warning message.
 !      That should be useful to understand what's going on.
```

#### **`cmn::output::err`**

Outputs an error message on both `stdout` and `stderr`.

Can be called with a string argument or with a Bash heredoc.

When the`DEBUG` environment variable is set (to any value), prints out
a traceback.

:bulb: Examples:

```bash
# Calling:
cmn::output::err "This is an error."

# Would output:
 !!     This is an error.
```

```bash
# Calling:
cmn::output::err <<- EOM
    This is an error message.
    That should be useful to understand what's going on.
    EOM

# Would output:
 !!     This is an error message.
 !!     That should be useful to understand what's going on.
```

```bash
# Calling:
export DEBUG=yes
cmn::output::err "This is another error."

# Would output:
 !!     This is another error.
 !!     Traceback:
 !!     bin/compile: main: 89
```

#### **`cmn::output::debug`**

Outputs a debug message on `stdout`.

Can be called with a string argument or with a Bash heredoc.

**Only prints out when the `DEBUG` environment variable is set (to any value).**

:bulb: Example:

```bash
# Calling:
cmn::output::debug "This is a debug message."

# Would be skipped because DEBUG is not set
# Would not output anything.
```

```bash
# Calling:
export DEBUG=yes
cmn::output::debug "This is a debug message."

# Would output:
 *      bin/compile: main: 34: This is a debug message.
```

```bash
# Calling:
export DEBUG=yes
cmn::output::debug <<- EOM
    This is a debug message.
    That should be useful to understand what's going on.
    EOM

# Would output:
 *      bin/compile: main: 34: This is a debug message.
 *      bin/compile: main: 34: That should be useful to understand what's going on.
```


### Trap Functions

#### **`cmn::trap::setup`**

Instructs the buildpack to catch the `EXIT`, `SIGHUP`, `SIGINT`, `SIGQUIT`,
`SIGABRT`, and `SIGTERM` signals and to call [`cmn::fail`](#cmnfail) when
it happens.

#### **`cmn::trap::teardown`**

Instructs the buildpack to stop catching the `EXIT`, `SIGHUP`, `SIGINT`,
`SIGQUIT`, `SIGABRT`, and `SIGTERM` signals.


### Flow

#### **`cmn::bp::start`**

Marks the begining of the buildpack.

Calls [`cmn::trap::setup`](#cmntrapsetup).

:point_right: Use this function at the beginning of the buildpack.

#### **`cmn::bp::finish`**

Outputs a success message and exits with a `0` return code, thus instructing
the platform that the buildpack ran successfully.

:point_right: Use this function as the last instruction of the buildpack, when
it succeeded.

Calls [`cmn::trap::teardown`](#cmntrapteardown).

#### **`cmnlib::bp::fail`**

Outputs an error message and exits with a `1` return code, thus instructing
the platform that the buildpack failed (and so did the build).

Calls [`cmn::trap::teardown`](#cmntrapteardown).

:point_right: Use this function as the last instruction of the buildpack, when
it failed.

#### **`cmn::step::start`**

Outputs a message marking the beginning of a buildpack *step*. A step is a
group of *tasks* that are logically bound.

:point_right: Use this function when the step is about to start.

#### **`cmn::step::finish`**

Outputs a success message marking the end of a buildpack step.

:point_right: Use this function when the step succeeded.

#### **`cmn::step::fail`**

Outputs an error message marking the end of a buildpack step.

:point_right: Use this function when the step failed.

#### **`cmn::task::start`**

Outputs a message marking the beginning of a buildpack *task*. A task is a
single instruction, such as downloading a file, extracting an archive, ...

:point_right: Use this function when the task is about to start.

#### **`cmn::task::finish`**

Outputs a success message marking the end of a task.

:point_right: Use this function when the task succeeded.

#### **`cmn::task::fail`**

Outputs an error message marking the end of a task.

:point_right: Use this function when the task failed.

Calls [`cmn::ouput::err`](#cmnoutputerr) with `$1` when `$1` is set.


### Utilities

#### **`cmn::file::sum`**

Computes the checksum of the given file.

Arguments:
- $1: file: file for which we want to compute a checksum
- $2: hash_algo: hashing algorithm (currently `md5`, `sha1` and `sha256` are
  supported)

:bulb: Example:

```bash
file="file.tar.gz"

checksum="$( cmn::file::check_sum "${file}" )"
```

#### **`cmn::file::check_checksum`**

Computes the checksum of a file and checks that it matches the one stored in
the reference file.\
`md5`, `sha1` and `sha256` hashing algorithm are currently supported.

Calls [`cmn::file::sum`](#cmnfilesum).

:bulb: Example:

```bash
file="file.tar.gz"
reference="file.tar.gz.md5"

cmn::task::start "Checking ${file} checksum"

if ! cmn::file::check_checksum "${file}" "${reference}"; then
    cmn::task::fail
    cmn::output::err <<- EOM
        Checksums do not match!"
        '${file}' has been deleted, since it's most likely corrupt.
        Now aborting.
    EOM
    exit 2
fi

cmn::task::finish
```

#### **`cmn::file::download`**

Downloads the file pointed by the given URL and stores it at the given path.

:bulb: Example:
```bash
file="https://example.org/file.tar.gz"
output="${CACHE_DIR}/file.tar.gz"

cmn::task::start "Downloading file.tar.gz"

if ! cmn::file::download "${file}" "${output}"; then
    cmn::task::fail "Unable to download file.tar.gz, aborting."
    exit
fi

cmn::task::finish
```


### String Functions

#### **`cmn::str::join`**

Outputs a string by joining all the arguments, separated by the given
separator.

:bulb: Example:
```bash
# With:
arr=( "one" "two" "three" )

# Calling:
cmn::str::join "," "${arr[@]}"

# Would output:
one,two,three

# Calling:
cmn::str::join "-" "one" "two" "three" "four"

# Would output:
one-two-three-four
```


### Environment Functions

#### **`cmn::env::read`**

Reads and exports environment variables stored as files in `$ENV_DIR`.\
Use towards the beginning of the buildpack, especially if it can be called
after another buildpack (with a multi-buildpack).

Calls [`cmn::env::list`](#cmnenvlist).

#### **`cmn::env::list`**

Lists available environement variables stored as files in `$ENV_DIR`.\
A few environment variables are ignored: `PATH`, `GIT_DIR`, `CPATH`, `CPPATH`,
`LD_PRELOAD`, `LIBRARY_PATH`, `LD_LIBRARY_PATH`, `JAVA_OPTS`,
`JAVA_TOOL_OPTIONS`, `BUILDPACK_URL` and `BUILD_DIR`.

Calls [`cmn::str::join`](#cmnstrjoin).
