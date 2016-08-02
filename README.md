# pgoapi-swift - a Pokemon Go API for Swift

This API is very much a work in progress, but it allows you to authenticate to the servers, as well as request information about the player, inventory, etc.

This should be more than enough to get anyone going, especially since all of the protos are transpiled to Swift and are working.

Special thanks to https://github.com/tejado/pgoapi and https://github.com/AeonLucid/POGOProtos for making this possible.

### Installation
You can install PGoApi with CocoaPods. It isn't fully published yet, but you can install it from git:

```
use_frameworks!
pod 'PGoApi', :git => 'https://github.com/lsapan/pgoapi-swift', :branch => 'master'
pod 'ProtocolBuffers-Swift', :git => 'https://github.com/alexeyxo/protobuf-swift', :branch => 'ProtoBuf3.0-Swift2.0'
```

Be sure to include ProtocolBuffers-Swift as shown above.

### Usage
Start by simply adding `import PGoApi` to the top of your file.

The API makes use of delegates, and a practical working example is in `Example/PGoApi/ViewController.swift`. It handles logging in, updating the API endpoint, etc.

To summarize, create an instance of `PGoApiRequest` and call whichever RPC commands you'd like to run (optionally with parameters). Once you've queued up the commands you'd like, call `makeRequest` to fire off the request and subrequests. Your delegate should implement `didReceiveApiResponse` and `didReceiveApiError` to handle the response (or lack thereof).

### Protos
Updating the protos is a bit tricky, I'll add more information on that later. For now, the protos are fresh and should be good for awhile.

### Contributing
In short: please do! The example app needs some love, and it'd be great to get that fleshed out so others can get going faster.
