# What does this do?

The purpose of `pkginst.sh` is to make it easier to quickly install a set of packages on various distributions.
Originally intended to be included in dotfiles repositories.

# Usage
The script expects a list of packages to install in a specific format, because
it does not do any conversion of package names between distributions.

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

To run the script without downloading:
```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/strptrk/pkginst.sh/main/pkginst.sh)" pkginst.sh -vv "{fd,fdfind}:{fd,fd-find}" "rg:ripgrep" "cmake"
```

## Package specification

For each package argument, the script is going to check if the package is installed,
and in case it is not, it will attempt to install it.

Checking if the package is installed can be done with using either the executable name or the package name.

| Format  | Description |
| ------------- | ------------- |
| `pkg` | the script will check if `pkg` is installed and attempt to install it in case it isn't. |
| `{pkg1,pkg2...}` | the script will check if `pkg1` is installed and attempt to install it in case it isn't, but keep trying with `pkg2` ... and so on if the installation fails. |
| `bin:pkg` | the script will check if `bin` can be run and to install `pkg` in case it cannot be. |
| `bin:{pkg1,pkg2,...}` | the script will check if `bin` can be run and to install `pkg1` in case it cannot be, but keep trying with `pkg2` ... and so on if the installation fails. |
| `{bin1,bin2,...}:pkg` | the script will check if any of `bin1`, `bin2`, ... can be run and attempt to install `pkg` in case none of them can be. |
| `{bin1,bin2,...}:{pkg1,pkg2,...}` | the script will check if any of `bin1`, `bin2`, ... can be run and attempt to install `pkg1`, `pkg2`, ... in case none of them can be. |

## Options
- -h: Display help page.
- -p: Set properties for package manager. Format is -p key="value". Possible keys are:

    | Property  | Description |
    | ------------- | ------------- |
    | `install`  | command to install a package.  |
    | `installed`  | command to check if a package is installed.  |
    | `sudoprog`  | command for privilege escalation (you can leave it empty). |

    Example:
    ```sh
    ./pkginst.sh -p install="pacman -S --noconfirm" -p installed="pacman -Q" -p sudoprog="doas" "rg:ripgrep"
    ```

- -v: Increase verbosity level. By default `pkginst.sh` does not print anything. Use twice to enable debugging logs as well. Use thrice to enable package manager outputs.
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
I wrote this for myself, so prefer pull requests to feature requests :)
