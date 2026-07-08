fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### release_both

```sh
[bundle exec] fastlane release_both
```

Release BOTH stores: bump the version once, then build+upload Android + iOS on the same version

----


## Android

### android release

```sh
[bundle exec] fastlane android release
```

Re-ship the CURRENT pubspec version to Google Play (NO bump — use release_both for a new release)

----


## iOS

### ios release

```sh
[bundle exec] fastlane ios release
```

Re-ship the CURRENT pubspec version to the App Store (NO bump — use release_both for a new release)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
