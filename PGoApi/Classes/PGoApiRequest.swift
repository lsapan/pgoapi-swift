//
//  PgoApi.swift
//  pgomap
//
//  Based on https://github.com/tejado/pgoapi/blob/master/pgoapi/pgoapi.py
//
//  Created by Luke Sapan on 7/20/16.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation
import ProtocolBuffers
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}



internal struct PGoApiMethod {
    internal let id: Pogoprotos.Networking.Requests.RequestType
    internal let message: GeneratedMessage
    internal let parser: (Data) -> GeneratedMessage
}

public struct PGoLocation {
    public var lat:Double = 0
    public var long:Double = 0
    public var alt:Double = 6
    public var horizontalAccuracy: Double = 3.9
    public var verticalAccuracy: Double = 6.1
    public var speed: Double? = nil
    public var course: Double? = nil
    public var floor: UInt32? = nil
    public init() {}
}

public struct PGoSession {
    public var requestId: UInt64 = 0
    public var timeSinceStart:UInt64 = 0
    public var realisticStartTimeAdjustment:UInt64 = 0
    public var downloadSettingsHash: String? = nil
    public var sessionHash: Data? = nil
    public var challengeUrl: String? = nil
    public init() {}
}

internal struct PGoApiSettings {
    internal var refreshAuthTokens: Bool = true
    internal var useResponseObjects: Bool = false
    internal var showMessages: Bool = true
    internal var checkChallenge: Bool = true
}

internal struct platformRequestSettings {
    internal var useSensorInfo: Bool = true
    internal var useActivityStatus: Bool = true
    internal var useDeviceInfo: Bool = true
    internal var useLocationFix: Bool = true
    internal var randomizedTimeSnapshot = UInt64.random(100, max: 500)
}

public struct PGoDeviceInfo {
    public var deviceId = "5c69d67d886f48eba071794fc48d0ee60c13cf52"
    public var devicePlatform: Pogoprotos.Enums.Platform = .ios
    public var androidBoardName: String? = nil
    public var androidBootloader: String? = nil
    public var deviceBrand: String? = "Apple"
    public var deviceModel: String? = "iPhone"
    public var deviceModelIdentifier: String? = nil
    public var deviceModelBoot: String? = "iPhone8,2"
    public var hardwareManufacturer: String? = "Apple"
    public var hardwareModel: String? = "N66mAP"
    public var firmwareBrand: String? = "iPhone OS"
    public var firmwareTags: String? = nil
    public var firmwareType: String? = "9.3.3"
    public var firmwareFingerprint: String? = nil
    public init() {}
}

open class PGoApiRequest {
    open var Location = PGoLocation()
    open var auth: PGoAuth?
    open var session = PGoSession()
    open var device = PGoDeviceInfo()
    internal var locationFix = LocationFixes()

    internal var unknown6Settings = platformRequestSettings()
    internal var ApiSettings = PGoApiSettings()
    
    internal var methodList: [PGoApiMethod] = []
    
    public init(auth: PGoAuth, session: PGoSession? = nil, Location: PGoLocation? = nil, device: PGoDeviceInfo? = nil) {
        self.auth = auth
        
        if session != nil {
            self.session = session!
        } else {
            self.session.requestId = UInt64.random(4611686018427388000, max: 9223372036854776000)
            self.session.timeSinceStart = getTimestamp()
            self.session.realisticStartTimeAdjustment = UInt64.random(1000, max: 2000)
        }
        
        if Location != nil {
            self.Location = Location!
        } else {
            self.Location.horizontalAccuracy = Double(Float.random(min: 3.5, max: 5.0))
            self.Location.verticalAccuracy = Double(Float.random(min: 5.0, max: 7.0))
            self.Location.alt = Double(Float.random(min: 6, max: 100))
        }
        
        if device != nil {
            self.device = device!
        } else {
            self.device.deviceId = Data.randomBytes(20).getHexString
        }
    }
    
    internal func getTimestamp() -> UInt64 {
        return UInt64(Date().timeIntervalSince1970 * 1000.0)
    }
    
    internal func getTimestampSinceStart() -> UInt64 {
        return getTimestamp() - session.timeSinceStart
    }
    
    open func debugMessage(_ message:String) {
        if ApiSettings.showMessages {
            print(message)
        }
    }
    
    open func refreshAuthToken() {
        self.auth!.authToken = nil
        debugMessage("Attempting to refresh auth token..")
    }
    
    open func makeRequest(intent: PGoApiIntent, delegate: PGoApiDelegate?) {
        // analogous to call in pgoapi.py
        
        if methodList.count == 0 {
            delegate?.didReceiveApiException(intent, exception: .noApiMethodsCalled)
            debugMessage("makeRequest() called without any methods in methodList.")
            return
        }
        
        if self.auth != nil {
            if !self.auth!.loggedIn {
                debugMessage("makeRequest() called without being logged in.")
                delegate?.didReceiveApiException(intent, exception: .notLoggedIn)
                return
            }
            
            if self.auth!.authToken != nil {
                if (self.auth!.authToken?.expireTimestampMs < getTimestamp()) {
                    debugMessage("Auth token has expired.")
                    if (ApiSettings.refreshAuthTokens) {
                        refreshAuthToken()
                    } else {
                        delegate?.didReceiveApiException(intent, exception: .authTokenExpired)
                        return
                    }
                }
            }
            
            if self.auth!.banned {
                delegate?.didReceiveApiException(intent, exception: .banned)
                return
            } else if self.auth!.expired {
                if (ApiSettings.refreshAuthTokens) {
                    refreshAuthToken()
                } else {
                    delegate?.didReceiveApiException(intent, exception: .authTokenExpired)
                    return
                }
            }
            
        } else {
            delegate?.didReceiveApiException(intent, exception: .noAuth)
            debugMessage("makeRequest() called without initializing auth.")
            return
        }
        
        if ApiSettings.checkChallenge {
            checkChallenge(debug: true)
        }
        
        let request = PGoRpcApi(subrequests: methodList, intent: intent, auth: self.auth!, api: self, delegate: delegate)
        request.request()
        methodList.removeAll()
    }
    
    open func setLocation(latitude: Double, longitude: Double, altitude: Double? = 6.0, horizontalAccuracy: Double? = 3.9, floor: UInt32? = nil, speed: Double? = nil, course: Double? = nil) {
        Location.lat = latitude
        Location.long = longitude
        Location.alt = altitude!
        Location.horizontalAccuracy = horizontalAccuracy!
        Location.speed = speed
        Location.course = course
        Location.floor = floor
    }
    
    open func getChallengeURL() -> String? {
        return self.session.challengeUrl
    }
    
    open func verifyToken(token: String, delegate: PGoApiDelegate?) {
        var privateMethods: [PGoApiMethod] = []
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.VerifyChallengeMessage.Builder()
        messageBuilder.token = token
        privateMethods.append(PGoApiMethod(id: .verifyChallenge, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.VerifyChallengeResponse.parseFrom(data: data)
        }))
        let request = PGoRpcApi(subrequests: privateMethods, intent: .verifyChallenge, auth: self.auth!, api: self, delegate: delegate)
        request.request()
    }
    
    open func setApiSettings(refreshAuthTokens: Bool? = true, useResponseObjects: Bool? = false, showMessages: Bool? = true, checkChallenge: Bool? = true) {
        ApiSettings.refreshAuthTokens = refreshAuthTokens!
        ApiSettings.useResponseObjects = useResponseObjects!
        ApiSettings.showMessages = showMessages!
        ApiSettings.checkChallenge = checkChallenge!
    }
    
    open func setPlatformRequestSettings(useActivityStatus: Bool? = true, useDeviceInfo: Bool? = true, useSensorInfo: Bool? = true, useLocationFix: Bool? = true) {
        unknown6Settings.useActivityStatus = useActivityStatus!
        unknown6Settings.useDeviceInfo = useDeviceInfo!
        unknown6Settings.useSensorInfo = useSensorInfo!
        unknown6Settings.useLocationFix = useLocationFix!
    }
    
    open func setLocationFixSettings(locationFixCount: Int? = 28, errorChance: UInt32? = 25) {
        locationFix.count = locationFixCount!
        locationFix.errorChance = errorChance!
    }
    
    open func setDevice(deviceId: String? = nil, androidBoardName: String? = nil, androidBootloader: String? = nil, deviceModel: String? = nil, deviceBrand: String? = nil, deviceModelIdentifier: String? = nil, deviceModelBoot: String? = nil, hardwareManufacturer: String? = nil, hardwareModel: String? = nil, firmwareBrand: String? = nil, firmwareTags: String? = nil, firmwareType: String? = nil, firmwareFingerprint: String? = nil, devicePlatform: Pogoprotos.Enums.Platform? = .ios) {
        if deviceId != nil {
            self.device.deviceId = deviceId!
        }
        self.device.androidBoardName = androidBoardName
        self.device.devicePlatform = devicePlatform!
        self.device.androidBootloader = androidBootloader
        self.device.deviceBrand = deviceBrand
        self.device.deviceModel = deviceModel
        self.device.deviceModelIdentifier = deviceModelIdentifier
        self.device.deviceModelBoot = deviceModelBoot
        self.device.hardwareManufacturer = hardwareManufacturer
        self.device.hardwareModel = hardwareModel
        self.device.firmwareBrand = firmwareBrand
        self.device.firmwareTags = firmwareTags
        self.device.firmwareType = firmwareType
        self.device.firmwareFingerprint = firmwareFingerprint
    }
    
    open func simulateAppStart() {
        getPlayer()
        heartBeat()
        downloadRemoteConfigVersion()
    }
    
    open func heartBeat() {
        getHatchedEggs()
        getInventory()
        checkAwardedBadges()
        downloadSettings()
    }
    
    open func updatePlayer() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.PlayerUpdateMessage.Builder()
        messageBuilder.latitude = Location.lat
        messageBuilder.longitude = Location.long
        methodList.append(PGoApiMethod(id: .playerUpdate, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.PlayerUpdateResponse.parseFrom(data: data)
        }))
    }
    
    open func registerBackgroundDevice(deviceId: String, deviceType: String) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.RegisterBackgroundDeviceMessage.Builder()
        messageBuilder.deviceId = deviceId
        messageBuilder.deviceType = deviceType
        methodList.append(PGoApiMethod(id: .registerBackgroundDevice, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.RegisterBackgroundDeviceResponse.parseFrom(data: data)
        }))
    }
    
    open func getPlayer(country: String? = "US", language: String? = "en", timeZone: String? = nil) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetPlayerMessage.Builder()
        let playerLocale = Pogoprotos.Networking.Requests.Messages.GetPlayerMessage.PlayerLocale.Builder()
        playerLocale.language = language!
        playerLocale.country = country!
        if timeZone != nil {
            playerLocale.timezone = timeZone!
        }
        messageBuilder.playerLocale = try! playerLocale.build()
        methodList.append(PGoApiMethod(id: .getPlayer, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetPlayerResponse.parseFrom(data: data)
        }))
    }
    
    open func getInventory(lastTimestampMs: Int64? = nil, itemBeenSeen: Int32? = nil) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetInventoryMessage.Builder()
        if lastTimestampMs != nil {
            messageBuilder.lastTimestampMs = lastTimestampMs!
        }
        if itemBeenSeen != nil {
            messageBuilder.itemBeenSeen = itemBeenSeen!
        }
        methodList.append(PGoApiMethod(id: .getInventory, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetInventoryResponse.parseFrom(data: data)
        }))
    }
    
    open func downloadSettings() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.DownloadSettingsMessage.Builder()
        if (session.downloadSettingsHash != nil) {
            messageBuilder.hash = session.downloadSettingsHash!
        }
        methodList.append(PGoApiMethod(id: .downloadSettings, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.DownloadSettingsResponse.parseFrom(data: data)
        }))
    }
    
    open func downloadItemTemplates() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.DownloadItemTemplatesMessage.Builder()
        methodList.append(PGoApiMethod(id: .downloadItemTemplates, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.DownloadItemTemplatesResponse.parseFrom(data: data)
        }))
    }
    
    open func downloadRemoteConfigVersion(deviceModel: String? = nil, deviceManufacturer: String? = nil, locale: String? = nil, appVersion: UInt32? = PGoVersion.versionInt) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.DownloadRemoteConfigVersionMessage.Builder()
        messageBuilder.platform = device.devicePlatform
        if deviceModel != nil {
            messageBuilder.deviceModel = deviceModel!
        }
        if deviceManufacturer != nil {
            messageBuilder.deviceManufacturer = deviceManufacturer!
        }
        if locale != nil {
            messageBuilder.locale = locale!
        }
        messageBuilder.appVersion = appVersion!
        methodList.append(PGoApiMethod(id: .downloadRemoteConfigVersion, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.DownloadRemoteConfigVersionResponse.parseFrom(data: data)
        }))
    }
    
    open func fortSearch(fortId: String, fortLatitude: Double, fortLongitude: Double) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.FortSearchMessage.Builder()
        messageBuilder.fortId = fortId
        messageBuilder.fortLatitude = fortLatitude
        messageBuilder.fortLongitude = fortLongitude
        messageBuilder.playerLatitude = Location.lat
        messageBuilder.playerLongitude = Location.long
        methodList.append(PGoApiMethod(id: .fortSearch, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.FortSearchResponse.parseFrom(data: data)
        }))
    }
    
    open func encounterPokemon(encounterId: UInt64, spawnPointId: String) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.EncounterMessage.Builder()
        messageBuilder.encounterId = encounterId
        messageBuilder.spawnPointId = spawnPointId
        messageBuilder.playerLatitude = Location.lat
        messageBuilder.playerLongitude = Location.long
        methodList.append(PGoApiMethod(id: .encounter, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.EncounterResponse.parseFrom(data: data)
        }))
    }
    
    open func catchPokemon(encounterId: UInt64, spawnPointId: String, pokeball: Pogoprotos.Inventory.Item.ItemId, hitPokemon: Bool? = nil, normalizedReticleSize: Double? = nil, normalizedHitPosition: Double? = nil, spinModifier: Double? = nil) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.CatchPokemonMessage.Builder()
        messageBuilder.encounterId = encounterId
        messageBuilder.spawnPointId = spawnPointId
        messageBuilder.pokeball = pokeball
        
        if hitPokemon == nil {
            messageBuilder.hitPokemon = true
        } else {
            messageBuilder.hitPokemon = hitPokemon!
        }
        
        if normalizedReticleSize == nil {
            messageBuilder.normalizedReticleSize = 1.95 + Double(Float.random(min: 0, max: 0.05))
        } else {
            messageBuilder.normalizedReticleSize = normalizedReticleSize!
        }
        
        if normalizedHitPosition == nil {
            messageBuilder.normalizedHitPosition = 1.0
        } else {
            messageBuilder.normalizedHitPosition = normalizedHitPosition!
        }
        
        if spinModifier == nil {
            messageBuilder.spinModifier = 0.85 + Double(Float.random(min: 0, max: 0.15))
        } else {
            messageBuilder.spinModifier = spinModifier!
        }
        
        methodList.append(PGoApiMethod(id: .catchPokemon, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.CatchPokemonResponse.parseFrom(data: data)
        }))
    }
    
    open func fortDetails(fortId: String, fortLatitude: Double, fortLongitude: Double) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.FortDetailsMessage.Builder()
        messageBuilder.fortId = fortId
        messageBuilder.latitude = fortLatitude
        messageBuilder.longitude = fortLongitude
        methodList.append(PGoApiMethod(id: .fortDetails, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.FortDetailsResponse.parseFrom(data: data)
        }))
    }
    
    open func generateS2Cells(lat: Double, long: Double) -> Array<UInt64> {
        let cell = S2CellId(p: S2LatLon(latDegrees: lat, lonDegrees: long).toPoint()).parent(15)
        let cells = cell.getEdgeNeighbors()
        var unfiltered: [S2CellId] = []
        var filtered: [UInt64] = []
        unfiltered.append(contentsOf: cells)
        for ce in cells {
            unfiltered.append(contentsOf: ce.getAllNeighbors(15))
        }
        for item in unfiltered {
            if !filtered.contains(item.id) {
                filtered += [item.id]
            }
        }
        return filtered
    }
    
    open func getMapObjects(cellIds: Array<UInt64>? = nil, sinceTimestampMs: Array<Int64>? = nil) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetMapObjectsMessage.Builder()
        messageBuilder.latitude = Location.lat
        messageBuilder.longitude = Location.long
        
        if cellIds != nil {
            messageBuilder.cellId = cellIds!
            
        } else {
            let cells = generateS2Cells(lat: Location.lat, long: Location.long)
            messageBuilder.cellId = cells
        }
        
        if sinceTimestampMs != nil {
            messageBuilder.sinceTimestampMs = sinceTimestampMs!
        } else {
            var timeStamps: Array<Int64> = []
            for _ in messageBuilder.cellId {
                timeStamps.append(0)
            }
            messageBuilder.sinceTimestampMs = timeStamps
        }
        
        methodList.append(PGoApiMethod(id: .getMapObjects, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetMapObjectsResponse.parseFrom(data: data)
        }))
    }
    
    open func fortDeployPokemon(fortId: String, pokemonId:UInt64) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.FortDeployPokemonMessage.Builder()
        messageBuilder.fortId = fortId
        messageBuilder.pokemonId = pokemonId
        messageBuilder.playerLatitude = Location.lat
        messageBuilder.playerLongitude = Location.long
        methodList.append(PGoApiMethod(id: .fortDeployPokemon, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.FortDeployPokemonResponse.parseFrom(data: data)
        }))
    }
    
    open func fortRecallPokemon(fortId: String, pokemonId:UInt64) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.FortRecallPokemonMessage.Builder()
        messageBuilder.fortId = fortId
        messageBuilder.pokemonId = pokemonId
        messageBuilder.playerLatitude = Location.lat
        messageBuilder.playerLongitude = Location.long
        methodList.append(PGoApiMethod(id: .fortRecallPokemon, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.FortRecallPokemonResponse.parseFrom(data: data)
        }))
    }
    
    open func releasePokemon(pokemonId:UInt64) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.ReleasePokemonMessage.Builder()
        messageBuilder.pokemonId = pokemonId
        methodList.append(PGoApiMethod(id: .releasePokemon, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.ReleasePokemonResponse.parseFrom(data: data)
        }))
    }
    
    open func useItemPotion(itemId: Pogoprotos.Inventory.Item.ItemId, pokemonId:UInt64) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.UseItemPotionMessage.Builder()
        messageBuilder.itemId = itemId
        messageBuilder.pokemonId = pokemonId
        methodList.append(PGoApiMethod(id: .useItemPotion, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.UseItemPotionResponse.parseFrom(data: data)
        }))
    }
    
    open func useItemCapture(itemId: Pogoprotos.Inventory.Item.ItemId, encounterId:UInt64, spawnPointId: String) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.UseItemCaptureMessage.Builder()
        messageBuilder.itemId = itemId
        messageBuilder.encounterId = encounterId
        messageBuilder.spawnPointId = spawnPointId
        methodList.append(PGoApiMethod(id: .useItemCapture, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.UseItemCaptureResponse.parseFrom(data: data)
        }))
    }
    
    open func useItemRevive(itemId: Pogoprotos.Inventory.Item.ItemId, pokemonId: UInt64) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.UseItemReviveMessage.Builder()
        messageBuilder.itemId = itemId
        messageBuilder.pokemonId = pokemonId
        methodList.append(PGoApiMethod(id: .useItemRevive, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.UseItemReviveResponse.parseFrom(data: data)
        }))
    }
    
    open func getPlayerProfile(playerName: String) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetPlayerProfileMessage.Builder()
        messageBuilder.playerName = playerName
        methodList.append(PGoApiMethod(id: .getPlayerProfile, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetPlayerProfileResponse.parseFrom(data: data)
        }))
    }
    
    open func evolvePokemon(pokemonId: UInt64) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.EvolvePokemonMessage.Builder()
        messageBuilder.pokemonId = pokemonId
        methodList.append(PGoApiMethod(id: .evolvePokemon, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.EvolvePokemonResponse.parseFrom(data: data)
        }))
    }
    
    open func getHatchedEggs() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetHatchedEggsMessage.Builder()
        methodList.append(PGoApiMethod(id: .getHatchedEggs, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetHatchedEggsResponse.parseFrom(data: data)
        }))
    }
    
    open func encounterTutorialComplete(pokemonId: Pogoprotos.Enums.PokemonId) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.EncounterTutorialCompleteMessage.Builder()
        messageBuilder.pokemonId = pokemonId
        methodList.append(PGoApiMethod(id: .encounterTutorialComplete, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.EncounterTutorialCompleteResponse.parseFrom(data: data)
        }))
    }
    
    open func levelUpRewards(level:Int32) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.LevelUpRewardsMessage.Builder()
        messageBuilder.level = level
        methodList.append(PGoApiMethod(id: .levelUpRewards, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.LevelUpRewardsResponse.parseFrom(data: data)
        }))
    }
    
    open func checkAwardedBadges() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.CheckAwardedBadgesMessage.Builder()
        methodList.append(PGoApiMethod(id: .checkAwardedBadges, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.CheckAwardedBadgesResponse.parseFrom(data: data)
        }))
    }
    
    open func useItemGym(itemId: Pogoprotos.Inventory.Item.ItemId, gymId: String) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.UseItemGymMessage.Builder()
        messageBuilder.itemId = itemId
        messageBuilder.gymId = gymId
        messageBuilder.playerLatitude = Location.lat
        messageBuilder.playerLongitude = Location.long
        methodList.append(PGoApiMethod(id: .useItemGym, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.UseItemGymResponse.parseFrom(data: data)
        }))
    }
    
    open func getGymDetails(gymId: String, gymLatitude: Double, gymLongitude: Double, clientVersion: String? = PGoVersion.versionString) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetGymDetailsMessage.Builder()
        messageBuilder.gymId = gymId
        messageBuilder.playerLatitude = Location.lat
        messageBuilder.playerLongitude = Location.long
        messageBuilder.gymLatitude = gymLatitude
        messageBuilder.gymLongitude = gymLongitude
        messageBuilder.clientVersion = clientVersion!
        methodList.append(PGoApiMethod(id: .getGymDetails, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetGymDetailsResponse.parseFrom(data: data)
        }))
    }
    
    open func startGymBattle(gymId: String, attackingPokemonIds: Array<UInt64>, defendingPokemonId: UInt64) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.StartGymBattleMessage.Builder()
        messageBuilder.gymId = gymId
        messageBuilder.attackingPokemonIds = attackingPokemonIds
        messageBuilder.defendingPokemonId = defendingPokemonId
        methodList.append(PGoApiMethod(id: .startGymBattle, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.StartGymBattleResponse.parseFrom(data: data)
        }))
    }
    
    open func attackGym(gymId: String, battleId: String, attackActions: Array<Pogoprotos.Data.Battle.BattleAction>, lastRetrievedAction: Pogoprotos.Data.Battle.BattleAction) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.AttackGymMessage.Builder()
        messageBuilder.gymId = gymId
        messageBuilder.battleId = battleId
        messageBuilder.attackActions = attackActions
        messageBuilder.lastRetrievedAction = lastRetrievedAction
        messageBuilder.playerLongitude = Location.lat
        messageBuilder.playerLatitude = Location.long
        
        methodList.append(PGoApiMethod(id: .attackGym, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.AttackGymResponse.parseFrom(data: data)
        }))
    }
    
    open func recycleInventoryItem(itemId: Pogoprotos.Inventory.Item.ItemId, itemCount: Int32) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.RecycleInventoryItemMessage.Builder()
        messageBuilder.itemId = itemId
        messageBuilder.count = itemCount
        methodList.append(PGoApiMethod(id: .recycleInventoryItem, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.RecycleInventoryItemResponse.parseFrom(data: data)
        }))
    }
    
    open func collectDailyBonus() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.CollectDailyBonusMessage.Builder()
        methodList.append(PGoApiMethod(id: .collectDailyBonus, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.CollectDailyBonusResponse.parseFrom(data: data)
        }))
    }
    
    open func useItemXPBoost(itemId: Pogoprotos.Inventory.Item.ItemId) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.UseItemXpBoostMessage.Builder()
        messageBuilder.itemId = itemId
        methodList.append(PGoApiMethod(id: .useItemXpBoost, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.UseItemXpBoostResponse.parseFrom(data: data)
        }))
    }
    
    open func useItemEggIncubator(itemId: String, pokemonId: UInt64) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.UseItemEggIncubatorMessage.Builder()
        messageBuilder.itemId = itemId
        messageBuilder.pokemonId = pokemonId
        methodList.append(PGoApiMethod(id: .useItemEggIncubator, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.UseItemEggIncubatorResponse.parseFrom(data: data)
        }))
    }
    
    open func useIncense(itemId: Pogoprotos.Inventory.Item.ItemId) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.UseIncenseMessage.Builder()
        messageBuilder.incenseType = itemId
        methodList.append(PGoApiMethod(id: .useIncense, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.UseIncenseResponse.parseFrom(data: data)
        }))
    }
    
    open func getIncensePokemon() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetIncensePokemonMessage.Builder()
        messageBuilder.playerLatitude = Location.lat
        messageBuilder.playerLongitude = Location.long
        methodList.append(PGoApiMethod(id: .getIncensePokemon, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetIncensePokemonResponse.parseFrom(data: data)
        }))
    }
    
    open func incenseEncounter(encounterId: UInt64, encounterLocation: String) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.IncenseEncounterMessage.Builder()
        messageBuilder.encounterId = encounterId
        messageBuilder.encounterLocation = encounterLocation
        methodList.append(PGoApiMethod(id: .incenseEncounter, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.IncenseEncounterResponse.parseFrom(data: data)
        }))
    }
    
    open func addFortModifier(itemId: Pogoprotos.Inventory.Item.ItemId, fortId: String) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.AddFortModifierMessage.Builder()
        messageBuilder.modifierType = itemId
        messageBuilder.fortId = fortId
        messageBuilder.playerLatitude = Location.lat
        messageBuilder.playerLongitude = Location.long
        methodList.append(PGoApiMethod(id: .addFortModifier, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.AddFortModifierResponse.parseFrom(data: data)
        }))
    }
    
    open func diskEncounter(encounterId: UInt64, fortId: String) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.DiskEncounterMessage.Builder()
        messageBuilder.encounterId = encounterId
        messageBuilder.fortId = fortId
        messageBuilder.playerLatitude = Location.lat
        messageBuilder.playerLongitude = Location.long
        methodList.append(PGoApiMethod(id: .diskEncounter, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.DiskEncounterResponse.parseFrom(data: data)
        }))
    }
    
    open func collectDailyDefenderBonus(encounterId: UInt64, fortId: String) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.CollectDailyDefenderBonusMessage.Builder()
        methodList.append(PGoApiMethod(id: .collectDailyDefenderBonus, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.CollectDailyDefenderBonusResponse.parseFrom(data: data)
        }))
    }
    
    open func upgradePokemon(pokemonId: UInt64) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.UpgradePokemonMessage.Builder()
        messageBuilder.pokemonId = pokemonId
        methodList.append(PGoApiMethod(id: .upgradePokemon, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.UpgradePokemonResponse.parseFrom(data: data)
        }))
    }
    
    open func setFavoritePokemon(pokemonId: Int64, isFavorite: Bool) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.SetFavoritePokemonMessage.Builder()
        messageBuilder.pokemonId = pokemonId
        messageBuilder.isFavorite = isFavorite
        methodList.append(PGoApiMethod(id: .setFavoritePokemon, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.SetFavoritePokemonResponse.parseFrom(data: data)
        }))
    }
    
    open func nicknamePokemon(pokemonId: UInt64, nickname: String) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.NicknamePokemonMessage.Builder()
        messageBuilder.pokemonId = pokemonId
        messageBuilder.nickname = nickname
        methodList.append(PGoApiMethod(id: .nicknamePokemon, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.NicknamePokemonResponse.parseFrom(data: data)
        }))
    }
    
    open func equipBadge(badgeType: Pogoprotos.Enums.BadgeType) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.EquipBadgeMessage.Builder()
        messageBuilder.badgeType = badgeType
        methodList.append(PGoApiMethod(id: .equipBadge, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.EquipBadgeResponse.parseFrom(data: data)
        }))
    }
    
    open func setContactSettings(sendMarketingEmails: Bool, sendPushNotifications: Bool) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.SetContactSettingsMessage.Builder()
        let contactSettings = Pogoprotos.Data.Player.ContactSettings.Builder()
        contactSettings.sendMarketingEmails = sendMarketingEmails
        contactSettings.sendPushNotifications = sendPushNotifications
        try! messageBuilder.contactSettings = contactSettings.build()
        methodList.append(PGoApiMethod(id: .setContactSettings, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.SetContactSettingsResponse.parseFrom(data: data)
        }))
    }
    
    open func getAssetDigest(deviceModel: String?, deviceManufacturer: String?, locale: String?, appVersion: UInt32? = PGoVersion.versionInt) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetAssetDigestMessage.Builder()
        messageBuilder.platform = device.devicePlatform
        if deviceModel != nil {
            messageBuilder.deviceModel = deviceModel!
        }
        if deviceManufacturer != nil {
            messageBuilder.deviceManufacturer = deviceManufacturer!
        }
        if locale != nil {
            messageBuilder.locale = locale!
        }
        messageBuilder.appVersion = appVersion!
        methodList.append(PGoApiMethod(id: .getAssetDigest, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetAssetDigestResponse.parseFrom(data: data)
        }))
    }
    
    open func getDownloadURLs(assetId: Array<String>) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetDownloadUrlsMessage.Builder()
        messageBuilder.assetId = assetId
        methodList.append(PGoApiMethod(id: .getDownloadUrls, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetDownloadUrlsResponse.parseFrom(data: data)
        }))
    }
    
    open func getSuggestedCodenames() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetSuggestedCodenamesMessage.Builder()
        methodList.append(PGoApiMethod(id: .getSuggestedCodenames, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetSuggestedCodenamesResponse.parseFrom(data: data)
        }))
    }
    
    open func checkCodenameAvailable(codename: String) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.CheckCodenameAvailableMessage.Builder()
        messageBuilder.codename = codename
        methodList.append(PGoApiMethod(id: .checkCodenameAvailable, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.CheckCodenameAvailableResponse.parseFrom(data: data)
        }))
    }
    
    open func claimCodename(codename: String) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.ClaimCodenameMessage.Builder()
        messageBuilder.codename = codename
        methodList.append(PGoApiMethod(id: .claimCodename, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.ClaimCodenameResponse.parseFrom(data: data)
        }))
    }
    
    open func setAvatar(skin: Int32, hair: Int32, shirt: Int32, pants: Int32, hat: Int32, shoes: Int32, gender: Pogoprotos.Enums.Gender, eyes: Int32, backpack: Int32) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.SetAvatarMessage.Builder()
        
        let playerAvatar = Pogoprotos.Data.Player.PlayerAvatar.Builder()
        playerAvatar.backpack = backpack
        playerAvatar.skin = skin
        playerAvatar.hair = hair
        playerAvatar.shirt = shirt
        playerAvatar.pants = pants
        playerAvatar.hat = hat
        playerAvatar.gender = gender
        playerAvatar.eyes = eyes
        
        try! messageBuilder.playerAvatar = playerAvatar.build()
        
        methodList.append(PGoApiMethod(id: .setAvatar, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.SetAvatarResponse.parseFrom(data: data)
        }))
    }
    
    open func setPlayerTeam(teamColor: Pogoprotos.Enums.TeamColor) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.SetPlayerTeamMessage.Builder()
        messageBuilder.team = teamColor
        methodList.append(PGoApiMethod(id: .setPlayerTeam, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.SetPlayerTeamResponse.parseFrom(data: data)
        }))
    }
    
    open func markTutorialComplete(tutorialState: Array<Pogoprotos.Enums.TutorialState>, sendMarketingEmails: Bool, sendPushNotifications: Bool) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.MarkTutorialCompleteMessage.Builder()
        messageBuilder.tutorialsCompleted = tutorialState
        messageBuilder.sendMarketingEmails = sendMarketingEmails
        messageBuilder.sendPushNotifications = sendPushNotifications
        methodList.append(PGoApiMethod(id: .markTutorialComplete, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.MarkTutorialCompleteResponse.parseFrom(data: data)
        }))
    }
    
    open func echo() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.EchoMessage.Builder()
        methodList.append(PGoApiMethod(id: .echo, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.EchoResponse.parseFrom(data: data)
        }))
    }
    
    open func sfidaActionLog() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.SfidaActionLogMessage.Builder()
        methodList.append(PGoApiMethod(id: .sfidaActionLog, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.SfidaActionLogResponse.parseFrom(data: data)
        }))
    }
    
    open func getBuddyWalked() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetBuddyWalkedMessage.Builder()
        methodList.append(PGoApiMethod(id: .getBuddyWalked, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetBuddyWalkedResponse.parseFrom(data: data)
        }))

    }
 
    open func setBuddyPokemon(pokemonId: UInt64) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.SetBuddyPokemonMessage.Builder()
        messageBuilder.pokemonId = pokemonId
        methodList.append(PGoApiMethod(id: .setBuddyPokemon, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.SetBuddyPokemonResponse.parseFrom(data: data)
        }))
        
    }
    
    open func checkChallenge(debug: Bool? = nil) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.CheckChallengeMessage.Builder()
        if debug != nil {
            messageBuilder.debugRequest = debug!
        }
        methodList.insert(PGoApiMethod(id: .checkChallenge, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.CheckChallengeResponse.parseFrom(data: data)
        }), at: 1)
    }
    
    open func verifyChallenge(token: String) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.VerifyChallengeMessage.Builder()
        messageBuilder.token = token
        methodList.append(PGoApiMethod(id: .verifyChallenge, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.VerifyChallengeResponse.parseFrom(data: data)
        }))
    }
}
