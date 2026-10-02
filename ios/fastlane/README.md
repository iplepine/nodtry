fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Push a new beta build to TestFlight

### ios release

```sh
[bundle exec] fastlane ios release
```

Build, upload and submit for review; RELEASES AUTOMATICALLY once approved

Use release_manual when the release must go live at a chosen time (e.g. the 둘운완 pivot)

### ios release_manual

```sh
[bundle exec] fastlane ios release_manual
```

Build, upload and submit for review; you release manually in App Store Connect after approval

### ios upload_assets

```sh
[bundle exec] fastlane ios upload_assets
```

Upload screenshots + metadata only, do NOT submit for review

### ios metadata_only

```sh
[bundle exec] fastlane ios metadata_only
```

Update App Store metadata + screenshots only, do NOT submit for review

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
