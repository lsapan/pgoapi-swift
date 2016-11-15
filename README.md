# pgoapi-swift - a Pokemon Go API library for Swift

This library allows you to communicate with the Pokemon GO servers as if you are a native client.

API Version: 1.15.0 (iOS)

Pogoprotos Version: 2.1.0 (fully implemented)

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

## Installation
The fastest way to get up and running is with CocoaPods. It isn't published in the CocoaPods repo yet due to dependency issues, but you can still easily use it by adding the following to your Podfile:
```
use_frameworks!
pod 'PGoApi', :git => 'https://github.com/lsapan/pgoapi-swift', :branch => 'Swift3.0---Version-45'
pod 'ProtocolBuffers-Swift', :git => 'https://github.com/alexeyxo/protobuf-swift', :branch => 'ProtoBuf3.0-Swift3.0'
```

Be sure to include ProtocolBuffers-Swift as shown above.

## Usage
At a high level, there are two steps to using the library. Login with one of the `PGoAuth` subclasses (PTC or Google), and send off your requests.

#### Logging in
Use a `PGoAuth` subclass and `PGoAuthDelegate` to login. This example uses PTC, but you can use the `GPSOAuth` class if you wish to login with Google.
```
class LoginExample: UIViewController, PGoAuthDelegate {
    var auth: PtcOAuth!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        auth = PtcOAuth()
        auth.login(withUsername: "username", withPassword: "password")
    }
    
    func didReceiveAuth() {
        print("Yeah, we logged in!")
    }
    
    func didNotReceiveAuth() {
        print("Aww, shucks.")
    }
}
```

#### Making Requests
The API makes use of delegates, and a practical working example is in `Example/PGoApi/ViewController.swift`. It handles logging in, updating the API endpoint, etc.

To summarize, create an instance of `PGoApiRequest` and call whichever RPC commands you'd like to run (optionally with parameters). Once you've queued up the commands you'd like, call `makeRequest` to fire off the request and subrequests. Your delegate should implement `didReceiveApiResponse`, `didReceiveApiException` and `didReceiveApiError` to handle the response (or lack thereof).

## Documentation
[See the documentation](https://github.com/lsapan/pgoapi-swift/wiki/Documentation) for details on methods, structs, enums and functions.

## Protos
To update the protos, compile the [Swift3.0 branch of alexeyxo/protobuf-swift](https://github.com/alexeyxo/protobuf-swift/tree/ProtoBuf3.0-Swift3.0) and run the build script (./scripts/build.sh). Afterwards, pull the latest version of [AeonLucid/POGOProtos](https://github.com/AeonLucid/POGOProtos) and use protos_update.sh or run these commands:
```
cd POGOProtos
python compile_single.py --lang=swift --out=../PGoApi/Classes/protos/
```

## Contributing
Any contribution would be greatly appreciated!

## Credits
Special thanks to https://github.com/tejado/pgoapi for the python implemention as well as  https://github.com/AeonLucid/POGOProtos for specing out the protos.
