# pgoapi-swift - a Pokemon Go API for Swift

This API is very much a work in progress, but it allows you to authenticate to the servers, as well as request information about the player, inventory, etc.

This should be more than enough to get anyone going, especially since all of the protos are transpiled to Swift and are working.

Special thanks to https://github.com/tejado/pgoapi and https://github.com/AeonLucid/POGOProtos for making this possible.

### Usage
The API makes use of delegates, and a practical working example is in `ExampleViewController.swift`. It handles logging in, updating the API endpoint, etc.

### Protos
Updating the protos is a bit tricky, I'll add more information on that later. For now, the protos are fresh and should be good for awhile.

### Contributing
In short: please do! I threw this together in a few hours, but I'd love help in really fleshing it out. Additionally, if someone could port the relevant portions of `CellId` from https://github.com/qedus/sphere/blob/master/sphere.py that would be immensely helpful. If not, I'll get to it when there's time. It's required in order to fully make the `GetMapObjects` call.

