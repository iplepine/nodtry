fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### deploy_all

```sh
[bundle exec] fastlane deploy_all
```

Build and upload Android (internal) + iOS (beta) simultaneously

### release_all

```sh
[bundle exec] fastlane release_all
```

Build and upload Android (production) + iOS (release) simultaneously

### upload_all

```sh
[bundle exec] fastlane upload_all
```

Upload only (skip build) - Android internal + iOS beta

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
