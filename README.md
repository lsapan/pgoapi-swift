# pgoapi-swift - a Pokemon Go API library for Swift

This library allows you to communicate with the Pokemon GO servers as if you are a native client.

#### The master branch supports the legacy pgoapi (0.35.0) in Swift 2.2.
#### Please use the [Swift3.0 - Version 45 branch.](https://github.com/lsapan/pgoapi-swift/tree/Swift3.0---Version-45)

## Requirements
Swift 3.0 - Version 45 branch:
- Xcode 8.1
- iOS 9+/OSX 10.11+

Note: Older Swift versions are not supported anymore.

## Features
- [x] Authentication (both PTC and Google)
- [x] All implemented API requests in POGOProtos (player details, inventory, map objects..)
- [x] Platform request and signature builder
- [x] Support for the new niahash
- [x] and much *(much!)* more.

## Documentation
[See the documentation](https://github.com/lsapan/pgoapi-swift/wiki/Documentation) for details on classes, protocols, structs, enums and functions used in the framework.

## Protos
To update the protos, compile the [Swift3.0 branch of alexeyxo/protobuf-swift](https://github.com/alexeyxo/protobuf-swift/tree/ProtoBuf3.0-Swift3.0) and run the build script (./scripts/build.sh). Afterwards, pull the latest version of [AeonLucid/POGOProtos](https://github.com/AeonLucid/POGOProtos) and use protos_update.sh or run these commands:
```
cd POGOProtos
python compile_single.py --lang=swift --out=../PGoApi/Classes/protos/
```

## Contributing
Any contribution would be greatly appreciated!

## Credits
Special thanks to https://github.com/tejado/pgoapi for the python implemention as well as https://github.com/AeonLucid/POGOProtos for specing out the protos.
