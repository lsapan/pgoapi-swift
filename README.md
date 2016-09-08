# pgoapi-swift - a Pokemon Go API library for Swift

This library allows you to communicate with the Pokemon GO servers as if you are a native client.

It supports:

- Authentication (both PTC and Google)
- Player Information
- Map Objects and Pokemon
- Inventory
- and much *(much!)* more.

## Installation
The fastest way to get up and running is with CocoaPods. It isn't published in the CocoaPods repo yet due to dependency issues, but you can still easily use it by adding the following to your Podfile:
```
use_frameworks!
pod 'PGoApi', :git => 'https://github.com/lsapan/pgoapi-swift', :branch => 'master'
pod 'ProtocolBuffers-Swift', :git => 'https://github.com/alexeyxo/protobuf-swift', :branch => 'ProtoBuf3.0-Swift2.0'
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

For more details, [see the documentation](https://github.com/lsapan/pgoapi-swift/wiki/Documentation).

## Protos
I'll add documentation on how to update the protos here later. That said, I update them very regularly so you shouldn't need to worry about it.

## Contributing
In short: please do! The example app needs some love, and it'd be great to get that fleshed out so others can get going faster.

## Credits
Special thanks to https://github.com/tejado/pgoapi for the python implemention as well as  https://github.com/AeonLucid/POGOProtos for specing out the protos.
