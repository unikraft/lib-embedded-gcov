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
    - This requires the application to provide implementations for `open()`, `write()`, `close()`. The easiest way to do this is to build your application with [lib-musl](https://github.com/unikraft/lib-musl), which will provide these primitives.
    - This also requires a filesystem. One possibility is to use 9pfs on QEMU. In Kconfig:
        - In `plat` -> `kvm` -> `virtio` select:
            - `virtio PCI device support`
            - `virtio 9P device`
        - In `lib` -> `vfscore` select:
            - `Default root filesystem (9PFS)`
- `Memory`: Writes coverage data into memory.
    - `Address for coverage output` - The address to which the coverage results will be written. This option requires that the application has already mapped a region of sufficient size at this address.

### Step 3: Run the application

**Console output:**
On QEMU, you can obtain the console output by passing the `logfile` parameter to the character device that implements the serial output:
```
 -chardev stdio,id=char0,logfile=serial.log,signal=off -serial chardev:char0
```
*NOTE*: It is essential not to use `-nographic` option here because that clashes with the redirection of standard output.

This QEMU run will dump console output into a text file named `serial.log`.

**Binary file output:**
Following the previous example with 9pfs and QEMU:
- Create a directory that will serve as the mount point of the filesystem:
   `mkdir fs0`
- Configure 9pfs on QEMU:
      ```
      -fsdev local,id=myid,path=$(pwd)/fs0,security_model=none
      -device virtio-9p-pci,fsdev=myid,mount_tag=rootfs,disable-modern=on,disable-legacy=off
      ```

**Memory output:**

After `__gcov_exit()` is called, you can dump the coverage data into a file. The `gcov_output_buffer` symbol contains the base pointer of coverage memory, and the index of the last byte of coverage data will be located at `gcov_output_buffer + gcov_output_index`.

One way to extract coverage information is to attach to the running program with GDB and issue the following commands:
```
dump memory memdump.bin gcov_output_buffer gcov_output_buffer+gcov_output_index
```
This will dump coverage data into a binary file named `memory.bin`.

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

lcov report in file:///home/mpp/devel/unikraft_oss/uk_embedded-gcov/app-helloworld/build/libembeddedgcov/origin/results/html/index.html
```