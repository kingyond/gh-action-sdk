# OpenWrt GitHub Action SDK

GitHub CI action to build packages via SDK using official OpenWrt SDK Docker
containers. This is primary used to test build OpenWrt repositories but can
also be used for downstream projects maintaining their own package
repositories.

## Example usage

The following YAML code can be used to build all packages of a repository and
store created `ipk` files as artifacts.

```yaml
name: Test Build

on:
  pull_request:
    branches:
      - master

jobs:
  build:
    name: ${{ matrix.arch }} build
    runs-on: ubuntu-latest
    strategy:
      matrix:
        arch:
          - x86_64
          - mips_24kc

    steps:
      - uses: actions/checkout@v2
        with:
          fetch-depth: 0

      - name: Build
        uses: cielpy/gh-action-sdk@master
        env:
          ARCH: ${{ matrix.arch }}

      - name: Store packages
        uses: actions/upload-artifact@v2
        with:
          name: ${{ matrix.arch}}-packages
          path: bin/packages/${{ matrix.arch }}/packages/*.ipk
```

## Environmental variables

The action reads a few env variables:

* `ARCH` determines the used OpenWrt SDK Docker container.
* `EXTRA_FEEDS` are added to the `feeds.conf`, where `|` are replaced by white
  spaces.
* `KEY_BUILD` can be a private Signify/`usign` key to sign the packages feed.
* `V` changes the build verbosity level.
* `PACKAGES` define which packages should be compiled, supporte multiple line
* `INDEX` enable build index of packages. Set 1 to enable.
* `SCRIPT_BEFORE_BUILD` script need run before build, with string format, not file path.
* `FEEDS_NEED_INSTALL`, which feed need install.
* `CUSTOM_PKG_DIR` to build current repositories as a package, this var name the package folder.
* `CUSTOM_SRC_DIR` this var name for the src folder.