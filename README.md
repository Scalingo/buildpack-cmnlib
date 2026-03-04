# Scalingo's Common Library for Buildpacks

A library of Bash functions commonly used in Scalingo's buildpacks.

These functions mainly allow for standardized and homogeneous outputs, and
prevent code rewriting thanks to commonly used utilities.


## Installing

Put the `cmnlib.sh` file in a directory named `vendor`, at the root of the
buildpack:

```
% tree my-buildpack
my-buildpack
├── bin
│   ├── compile
│   ├── detect
│   └── release
└── vendor
    └── cmnlib.sh
```

Put the following instructions at the very beginning of the `bin/compile` file
of the buildpack to import the library:

```bash
#!/usr/bin/env bash
# usage: bin/compile <build_dir> <cache_dir> <env_dir>

# shellcheck disable=SC1090
source "$( readlink -f "$( dirname "${0}" )/../vendor/cmnlib.sh" )"
```


## Using the Library

### Output Functions

#### **`cmn::output::info`**

Outputs an informational message on `stdout`.\
Can be called with a string argument or with a Bash heredoc.

<details>
<summary>Examples</summary>

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
</details>

#### **`cmn::output::warn`**

Outputs a warning message on `stdout`.\
Can be called with a string argument or with a Bash heredoc.

<details>
<summary>Examples</summary>

```bash
# Calling:
cmn::output::warn "This is a warning."

Would output:
 !   This is a warning.
```

```bash
# Calling:
cmn::output::warn <<- EOM
    This is a warning message.
    That should be useful to understand what's going on.
    EOM

# Would output:
 !   This is a warning message.
 !   That should be useful to understand what's going on.
```
</details>

#### **`cmn::output::err`**

Outputs an error message on `stderr`.\
Can be called with a string argument or with a Bash heredoc.

Calls [`cmn::output::traceback`](#cmnoutputtraceback) when the `_CMN_DEBUG_`
environment variable is set (to any value).

> [!TIP]
> When the `_CMN_DEBUG_` environment variable is set (to any value), prints out
  a traceback.

<details>
<summary>Examples</summary>

```bash
# Calling:
cmn::output::err "This is an error."

# Would output to stderr:
 !!  This is an error.
```

```bash
# Calling:
cmn::output::err <<- EOM
    This is an error message.
    That should be useful to understand what's going on.
    EOM

# Would output to stderr:
 !!  This is an error message.
 !!  That should be useful to understand what's going on.
```

```bash
# Calling:
export _CMN_DEBUG_=yes
cmn::output::err "This is another error."

# Would output to stderr:
 !!  This is another error.

 !!  Traceback:
 !!    bin/compile: main: 89
```
</details>

#### **`cmn::output::debug`**

Outputs a debug message on `stdout`.\
Can be called with a string argument or with a Bash heredoc.

> [!WARNING]
> Only prints out when the `_CMN_DEBUG_` environment variable is set (to any
  value).

<details>
<summary>Examples</summary>

```bash
# Calling:
cmn::output::debug "This is a debug message."

# Would be skipped because _CMN_DEBUG_ is not set
# Would not output anything.
```

```bash
# Calling:
export _CMN_DEBUG_=yes
cmn::output::debug "This is a debug message."

# Would output:
 *   bin/compile: main: 34: This is a debug message.
```

```bash
# Calling:
export _CMN_DEBUG_=yes
cmn::output::debug <<- EOM
    This is a debug message.
    That should be useful to understand what's going on.
    EOM

# Would output:
 *   bin/compile: main: 34: This is a debug message.
 *   bin/compile: main: 34: That should be useful to understand what's going on.
```
</details>

#### **`cmn::output::traceback`**

Outputs a traceback on `stderr`.

<details>
<summary>Examples</summary>

```bash
# Calling:
cmn::output::traceback

# Would output to stderr:
 !!  Traceback:
 !!    bin/compile: some_func: 12
 !!    bin/compile: main: 89
```
</details>

* * *

### Flow Functions

#### **`cmn::main::start`**

Configures Bash options, populates a few global variables and marks the
begining of the buildpack.\
Sets `errexit`, `errtrace`, and `pipefail`.
Setup traps for `EXIT`, `ERR`, `HUP`, `INT`, `QUIT`, `ABRT`, and `TERM`. \
Populates the following global variables:
- `build_dir`: Absolute path to the build directory
- `cache_dir`: Absolute path to the cache directory
- `env_dir`: Absolute path to the environment directory
- `buildpack_dir`: Absolute path to the directory containing the buildpack code
- `tmp_dir`: Absolute path to a usable temporary directory

> [!TIP]
> - Use this function at the beginning of the buildpack.
> - When the `_CMN_DEBUG_` environment variable is set (to any value), prints
    out the global variables set before.

#### **`cmn::main::finish`**

Outputs a success message and exits with a `0` return code, which informs
the platform that the buildpack ran successfully.

> [!TIP]
> Use this function as the last instruction of the buildpack, when it
  succeeded.

#### **`cmn::main::fail`**

Outputs an error message (if given) and immediately exits with the specified
return code (if given, defaults to `1`) , which instructs the platform that the
buildpack failed (and so did the build).

> [!TIP]
> Use this function as the last instruction of the buildpack, when it failed.

<details>
<summary>Examples</summary>

```bash
# Calling:
cmn::main::fail 2 "This is an error message."

# Would output to stderr:
 !! This is an error message

# And would exit with an exit code of 2.
```

```bash
# Calling:
cmn::main::fail 2

# Would output nothing
# And would immediately exit the script with an exit code of 2.
```

```bash
# Calling:
cmn::main::fail

# Would output nothing
# and would immediately exit the script with an exit code of 1.
```
</details>

#### **`cmn::output::traceback`**

Outputs a traceback on `stderr`.

<details>
<summary>Examples</summary>

```bash
# Calling:
cmn::output::traceback

# Would output to stderr:
 !!  Traceback:
 !!    bin/compile: some_func: 12
 !!    bin/compile: main: 89
```
</details>

#### **`cmn::step::start`**

Outputs a message marking the beginning of a buildpack *step*. A step is a
group of *tasks* that are logically bound.

> [!TIP]
> Use this function when the step is about to start.

#### **`cmn::task::start`**

Outputs a message marking the beginning of a buildpack *task*. A task is a
single instruction, such as downloading a file, extracting an archive, ...

> [!TIP]
> Use this function when the task is about to start.

#### **`cmn::task::finish`**

Outputs a success message marking the end of a task.

> [!TIP]
> Use this function when the task succeeded.

#### **`cmn::task::fail`**

Outputs an error message marking the end of a task.

Calls [`cmn::ouput::err`](#cmnoutputerr) with `$1` when `$1` is set.

> [!TIP]
> Use this function when a task failed, if the situation is recoverable. When
  it's not, please use [`cmn::main::fail`](#cmnmainfail).

* * *

### File Functions

#### **`cmn::file::validate_checksum`**

Computes the checksum of a file and checks that it matches the one stored in
the reference file.\
`md5`, `sha1`, `sha256`, and `sha512` hashing algorithms are currently
supported.

<details>
<summary>Example</summary>

```bash
file="file.tar.gz"
reference="file.tar.gz.md5"

cmn::task::start "Checking ${file} checksum"

cmn::file::validate_checksum "${file}" "${reference}" \
    || {
        rm -f "${file}"
        cmn::main::fail "${?}" <<- EOM
            Checksums do not match!
            '${file}' has been deleted, since it's most likely corrupt.
            Aborting.
            EOM
    }

cmn::task::finish
```
</details>

#### **`cmn::file::download`**

Downloads the file pointed by the given URL and stores it at the given path.

<details>
<summary>Example</summary>

```bash
file_url="https://example.org/file.tar.gz"
output="${CACHE_DIR}/file.tar.gz"

cmn::task::start "Downloading file.tar.gz"

cmn::file::download "${file_url}" "${output}" \
    || cmn::main::fail "${?}" <<- EOM
        Unable to download archive from '${file_url}'.
        Aborting.
        EOM

cmn::task::finish
```
</details>

#### **`cmn::file::download_and_check`**

Downloads a file from the specified URL and stores it at the specified path.\
Also downloads the checksum from the specified URL and stores it at the
specified path.\
Finally checks the hash of the downloaded file against the downloaded checksum.

Calls [`cmn::file::download`](#cmnfiledownload)\
Calls [`cmn::file::validate_checksum`](#cmnfilevalidate_checksum)\
Calls [`cmn::jobs::wait`](#cmnjobswait)

<details>
<summary>Example</summary>

```bash
archive_version="1.2.3"

cmn::task::start "Downloading archive ${archive_version}"

file_url="https://example.com/archive.tar.gz"
hash_url="https://example.com/archive.tar.gz.sha256"
file_path="${tmpdir}/archive.tar.gz"
hash_path="${tmpdir}/archive.tar.gz.sha256"

cmn::file::download_and_check "${file_url}" "${hash_url}" \
    "${file_path}" "${hash_path}" \
    || cmn::main::fail "${?}" <<- EOM
        Could not safely download archive ${archive_version}!
        EOM

cmn::task::finish
```
</details>

* * *

### Jobs Functions

#### **`cmn::jobs::wait`**

Waits for all child jobs running in background to finish.\
Returns the number of failed jobs (zero means they all succeeded).

<details>
<summary>Example</Summary>

```bash
# Start two downloads in background:
cmn::file::download "${file_url}" "${file_path}" &
cmn::file::download "${hash_url}" "${hash_path}" &

# Wait for them to be finished and successful before comparing checksums:
if cmn::jobs::wait; then
    cmn::file::check_checksum "${file_path}" "${hash_path}"
    [...]
fi
```
</details>

* * *

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

* * *

### Buildpack Functions

#### **`cmn::bp::run`**

Git-clone a buildpack and runs it.

<details>
<summary>Example</summary>

```bash
# Call the Apt Buildpack inside the running buildpack:

bp_url="https://github.com/Scalingo/apt-buildpack.git"
bp_output=""

if ! bp_output="$( cmn::bp::run "${bp_url}" \
        "${build_dir}" "${cache_dir}" "${env_dir}" )"
then
    cmn::main::fail 2 <<- EOM
        Failed to run apt-buildpack.
        Output:
        ${bp_output}
        EOM
fi
```
</details>
