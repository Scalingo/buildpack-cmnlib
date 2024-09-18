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
source /dev/stdin <<< "$( curl --silent --location --retry 3 "https://<s3_url>/<bucket>/<version>/std.sh" )"
```

## Using

The following functions are available. We put them in a few categories:

### Output

#### **`cmnlib::info`**

Outputs an informational message on `stdout`.

#### **`cmnlib::warn`**

Outputs a warning message on `stdout`.

#### **`cmnlib::err`**

Outputs an error message on both `stdout` and `stderr`.


### Error Management

#### **`cmnlib::trap_setup`**

Instructs the buildpack to catch the `EXIT`, `SIGHUP`, `SIGINT`, `SIGQUIT`,
`SIGABRT`, and `SIGTERM` signals and to call `cmnlib::fail` when it happens.

#### **`cmnlib::trap_teardown`**

Instructs the buildpack to stop catching the `EXIT`, `SIGHUP`, `SIGINT`,
`SIGQUIT`, `SIGABRT`, and `SIGTERM` signals.


### Flow

#### **`cmnlib::start`**

Marks the begining of the buildpack.\
Calls [`cmnlib::trap_setup`](#cmnlibtrap_setup).

#### **`cmnlib::finish`**

Outputs a success message and exits with a `0` return code, thus instructing
the platform that the buildpack ran successfully.\
Use this function as the last instruction of the buildpack, when it
succeeded.\
Calls [`cmnlib::trap_teardown`](#cmnlibtrap_teardown).

#### **`cmnlib::fail`**

Outputs an error message and exits with a `1` return code, thus instructing
the platform that the buildpack failed (and so did the build).\
Calls [`cmnlib::trap_teardown`](#cmnlibtrap_teardown).

#### **`cmnlib::step_start`**

Outputs a message marking the beginning of a buildpack *step*. A step is a
group of *tasks* that are logically bound.\
Use this function when the step is about to start.

#### **`cmnlib::step_finish`**

Outputs a success message marking the end of a buildpack step.\
Use this function when the step succeeded.

#### **`cmnlib::step_fail`**

Outputs an error message marking the end of a buildpack step.\
Use this function when the step failed.

#### **`cmnlib::task_start`**

Outputs a message marking the beginning of a buildpack *task*. A task is a
single instruction, such as downloading a file, extracting an archive, ...\
Use this function when the task is about to start.

#### **`cmnlib::task_finish`**

Outputs a success message marking the end of a task.\
Use this function when the task succeeded.

#### **`cmnlib::task_fail`**

Outputs an error message marking the end of a task.\
Use this function when the task failed.\
Calls [`cmnlib::err`](#cmnliberr) with `$1` when `$1` is set.


### Utilities

#### **`cmnlib::check_file_checksum`**

Computes the checksum of a file and checks that it matches the one stored in
the reference file.\
`md5`, `sha1` and `sha256` hashing algorithm are currently supported.

Example:
```bash
file="file.tar.gz"
reference="file.tar.gz.md5"

cmnlib::task_start "Checking ${file} checksum"

if ! cmnlib::check_file_checksum "${file}" "${reference}"; then
    cmnlib::task_fail "Checksum does not match the reference, aborting."
    exit
fi

cmnlib::task_finish
```

#### **`cmnlib::download`**

Downloads the file pointed by the given URL and stores it at the given path.

Example:
```bash
file="https://example.org/file.tar.gz"
output="${CACHE_DIR}/file.tar.gz"

cmnlib::task_start "Downloading file.tar.gz"

if ! cmnlib::download "${file}" "${output}"; then
    cmnlib::task_fail "Unable to download file.tar.gz, aborting."
    exit
fi

cmnlib::task_finish
```

#### **`cmnlib::str_join`**

Outputs a string by joining all the arguments, separated by the given
separator.

Example:
```bash
arr=( "one" "two" "three" )

cmnlib::str_join "," "${arr[@]}"
# would output: "one,two,three"

cmnlib::str_join "-" "one" "two" "three" "four"
# would output: "one-two-three-four"
```


### Environment

#### **`cmnlib::read_env`**

Reads and exports environment variables stored as files in `$ENV_DIR`.\
Use towards the beginning of the buildpack, especially if it can be called
after another buildpack (with a multi-buildpack).\
Calls [`cmnlib::list_env_vars`](#cmnliblist_env_vars).

#### **`cmnlib::list_env_vars`**

Lists available environement variables stored as files in `$ENV_DIR`.\
A few environment variables are ignored: `PATH`, `GIT_DIR`, `CPATH`, `CPPATH`,
`LD_PRELOAD`, `LIBRARY_PATH`, `LD_LIBRARY_PATH`, `JAVA_OPTS`,
`JAVA_TOOL_OPTIONS`, `BUILDPACK_URL` and `BUILD_DIR`.\
Calls [`cmnlib::str_join`](#cmnlibstr_join).
