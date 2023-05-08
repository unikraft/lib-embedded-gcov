# lib-embedded-gcov

Unikraft port of [embedded-gcov](https://github.com/nasa-jpl/embedded-gcov).

## Step-by-step Instructions

Here you can find step-by-step instructions on obtaining coverage information for a Unikraft application.

For more information, see the documentation provided by [embedded-gcov](https://github.com/nasa-jpl/embedded-gcov).

### Step 1: Prepare the application

Initialization of gcov is done transparently to the application. `lib-embedded-gcov` adds the required GCC options for coverage, and at runtime, `__gcov_init()` is automatically called when Unikraft boots via constructors. Therefore no changes are required for initialization. However, if coverage collection must start at a later point, one can modify the application to call `gcov_clear_counters()` manually.

On the other hand, it is necessary to modify the application to call `__gcov_exit()` manually. This function causes `lib-embedded-gcov` to gather and output coverage information using the selected output method.

### Step 2: Select output method

In the `embedded-gcov` section of Kconfig, select the output method to use:
- `Console`: Writes coverage data to console output.
- `File`: Writes coverage data to a binary file.
- `Memory`: Writes coverage data into memory.

### Step 3: Run the application

**Console output:**
On QEMU, you can obtain the console output by passing the `logfile` parameter to the character device that implements the serial output:
```
 -chardev stdio,id=char0,logfile=serial.log,signal=off -serial chardev:char0
```
*NOTE*: It is essential not to use `-nographic` option here because that clashes with the redirection of standard output.

This QEMU run will dump console output into a text file named `serial.log`.

### Step 4: Generate coverage report

You must process the output to obtain coverage results in a pleasant viewing fashion. `lib-embedded-gcov` provides the `gcov_process.sh` script for that, which is essentially a wrapper around the tools provided by `embedded-gcov`.

Before executing the script below make sure you have the required dependencies installed, that is:
- `dox2unix`
- `lcov`

With the dependencies installed, invoke `gcov_process.sh` with parameters depending on the output method selected.

**Console output:**
```bash
lib-embedded-gcov/scripts/gcov_process.sh -c <console_output> <build_directory>
```

**Binary file / Memory output:**
```bash
lib-embedded-gcov/scripts/gcov_process.sh -b <binary_output> <build_directory>
```

`gcov_process.sh` will generate a lcov report and provide a link, as shown below:
```
...
Writing directory view page.
Overall coverage rate:
  lines......: 29.8% (2345 of 7858 lines)
  functions..: 36.3% (228 of 628 functions)

lcov report in file:///tmp/uk_embedded-gcov/app-helloworld/build/libembeddedgcov/origin/results/html/index.html
```
