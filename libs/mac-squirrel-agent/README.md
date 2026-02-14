# mac_squirrel_agent

`mac_squirrel_agent` is a small Objective-C helper for handing off a prepared
update bundle to ShipIt.

## Build

Requirements:

- macOS + Xcode command line tools
- `Squirrel.framework`, `ReactiveObjC` or `ReactiveCocoa`, `Mantle.framework`

Build with defaults:

```bash
./build.sh
```

Build with custom framework location:

```bash
SQUIRREL_FRAMEWORK_DIR=/path/to/frameworks REACTIVE_FRAMEWORK=ReactiveCocoa ./build.sh
```
