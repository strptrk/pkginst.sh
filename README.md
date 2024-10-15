# What does this do?

The purpose of this script is to make it easier to quickly install a set of packages on various distributions.
Originally intended to be included in dotfiles repositories.

# Usage
The script expects a list of packages to install in a specific format, because
it does not do any conversion between package names between distributions.

For example, the utility [fd](https://github.com/sharkdp/fd) is named differently:

On Ubuntu, the binary is `fdfind` while the package is called `fd-find`.

On Arch Linux, both the binary and the package is called `fd`.

To install `fd` on either:
```sh
./pkginst.sh "{fd,fdfind}:{fd,fd-find}"
```

Any number of targets can be specified:
```sh
./pkginst.sh "{fd,fdfind}:{fd,fd-find}" "rg:ripgrep" "cmake"
```

## Package specification

For each package argument, the script is going to check if the package is installed,
and in case it is not, it will attempt to install it.

Checking if the package is installed can be done with using either the executable name or the package name.
- 1: `package_name`: the script will check if `package_name` is installed and attempt to install it in case it isn't.
- 2: `{package_name1,package_name2...}`: the script will check if `package_name1` is installed and attempt to install it in case it isn't,
    but keep trying with `package_name2` ... and so on if the installation fails.
- 3: `executable:package_name`: the script will check if `executable` can be run and to install `package_name` in case it cannot be.
- 4: `executable:{package_name1,package_name2,...}`: the script will check if `executable` can be run and to install `package_name` in case it cannot be,
    but keep trying with `package_name2` ... and so on if the installation fails.
- 5: `{executable1,executable2,...}:package_name`: the script will check if any of `executable1`, `executable2`, ... can be run and attempt to install `package_name` in case none of them can be.
- 6: `{executable1,executable2,...}:{package_name1,package_name2,...}`: the script will check if any of `executable1`, `executable2`, ... can be run
    and attempt to install `package_name1`, `package_name2`, ... in case none of them can be.

## Options
- -h: Display help page.
- -p: Set properties for package manager.
      Format is -p key="value"
      Possible keys are:
      - `install`: command to install a package.
      - `installed`: command to check if a package is installed.
      - `sudoprog`: command for privilege escalation (you can leave it empty).
      Example:
      `./pkginst.sh -p install="pacman -S --noconfirm" -p installed="pacman -Q" -p sudoprog="doas" "rg:ripgrep"`

- -v: Increase verbosity level. By default `pkginst.sh` does not print anything.
      Use twice to enable debugging logs as well.
      Use thrice to enable package manager outputs.
- -V: Display script version

# Tests
Docker containers are used to test the scripts with some of the distributions that it supports.
```sh
make test
```
To clean up the built docker images, run:
```sh
make clean-docker
```

# Contributing
I wrote this for myself, so prefer pull requests to simple feature requests :)
