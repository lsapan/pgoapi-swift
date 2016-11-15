//
//  PGoSignature.swift
//  pgoapi
//
//  Created by PokemonGoSucks on 2016-09-06.
//
//

import Foundation


internal class simpleLocationFixBuilder {
    internal var timestampSnapshot: UInt64 = 0
    internal var latitude: Float = 0
    internal var longitude: Float = 0
    internal var altitude: Float = 0
    internal var speed: Float = 0
    internal var course: Float = 0
    internal var verticalAccuracy: Float? = nil
    internal var floor: UInt32? = nil
    internal var horizontalAccuracy: Float = 0
}

internal class LocationFixes {
    internal var builders: Array<simpleLocationFixBuilder> =  []
    internal var timeStamp: UInt64 = 0
    internal var lastTimeSnap:UInt64 = 0
    internal var count: Int = 28
    internal var errorChance: UInt32 = 25
}

internal class LocationFix {
    fileprivate let api: PGoApiRequest
    
    internal init(api: PGoApiRequest) {
        self.api = api
        self.update()
    }
    
    fileprivate func getTimeStampFix() -> UInt64 {
        return self.api.getTimestampSinceStart() + self.api.session.realisticStartTimeAdjustment - 500
    }
    
    fileprivate func generatedByCount(count: Int, startTime: UInt64? = 0) {
        for i in 0..<count {
            let newTime = 1000 * UInt64(count-i) - UInt64.random(0, max: 100) + 100
            self.api.locationFix.builders.insert(generate(timeStamp: newTime), at: 0)
        }
    }
    
    fileprivate func getCount() -> Int {
        var count: Int = 0
        let timestampFix = getTimeStampFix()
        if timestampFix > UInt64(self.api.locationFix.count * 1000) {
            count = self.api.locationFix.count
        } else {
            count = Int(round(Double(timestampFix)/1000))
        }
        return count
    }
    
    fileprivate func getLastTimeSnapshot() -> UInt64 {
        return self.api.locationFix.builders.first!.timestampSnapshot
    }
    
    fileprivate func update() {
        if self.api.locationFix.builders.count == 0 {
            generatedByCount(count: getCount())
        } else {
            let missing = getCount() - self.api.locationFix.builders.count
            let timeAdd = getTimeStampFix() - self.api.locationFix.lastTimeSnap
            if missing > 0 {
                for i in 0..<self.api.locationFix.builders.count {
                    self.api.locationFix.builders[i].timestampSnapshot += timeAdd
                }
                generatedByCount(count: missing)
            } else {
                let countRemoved = Int(round(Double(timeAdd)/1000))
                for _ in 0..<countRemoved {
                    self.api.locationFix.builders.removeLast()
                }
                for i in 0..<self.api.locationFix.builders.count {
                    self.api.locationFix.builders[i].timestampSnapshot += timeAdd
                }
                generatedByCount(count: countRemoved)
            }
        }
        self.api.locationFix.lastTimeSnap = getTimeStampFix()
        self.api.locationFix.timeStamp = getLastTimeSnapshot()
    }
    
    fileprivate func generate(timeStamp: UInt64) -> simpleLocationFixBuilder {
        let locFix = simpleLocationFixBuilder()
        locFix.timestampSnapshot = timeStamp
        let chance = arc4random_uniform(100)
        if chance < UInt32(self.api.locationFix.errorChance) {
            if self.api.Location.lat < 0 {
                locFix.latitude = -360
            } else {
                locFix.latitude = 360
            }
            if self.api.Location.long < 0 {
                locFix.longitude = -360
            } else {
                locFix.longitude = 360
            }
        } else {
            locFix.latitude = Float(self.api.Location.lat) + Float.random(min: -0.01, max: 0.01)
            locFix.longitude = Float(self.api.Location.long) + Float.random(min: -0.01, max: 0.01)
        }
        locFix.altitude = Float(self.api.Location.alt) + Float.random(min: -0.01, max: 0.01)
        if self.api.device.devicePlatform == .ios {
            locFix.verticalAccuracy = Float(self.api.Location.verticalAccuracy) + Float.random(min: -0.01, max: 0.01)
        }
        
        locFix.horizontalAccuracy = Float(self.api.Location.horizontalAccuracy) + Float.random(min: -0.01, max: 0.01)
        if self.api.Location.speed != nil {
            locFix.speed = Float(self.api.Location.speed!) + Float.random(min: -0.01, max: 0.01)
        } else {
            locFix.speed = Float.random(min: 0.1, max: 3.0)
        }
        if self.api.Location.course != nil {
            locFix.course = Float(self.api.Location.course!) + Float.random(min: -0.01, max: 0.01)
        } else {
            locFix.course = Float.random(min: 0, max: 360)
        }
        if self.api.Location.floor != nil {
            locFix.floor = self.api.Location.floor!
        }
        return locFix
    }
}

internal class platformRequest {
    fileprivate var locationHex: Array<UInt8>
    fileprivate var authInfo: Data? = nil
    fileprivate var auth: PGoAuth
    fileprivate let api: PGoApiRequest
    internal let locationFix: LocationFix
    internal var requestHashes:Array<UInt64> = []
    
    internal init(auth: PGoAuth, api: PGoApiRequest) {
        self.locationHex = []
        self.auth = auth
        self.api = api
        self.locationFix = LocationFix(api: api)
    }
    
    fileprivate func locationToHex(_ lat: Double, long: Double, accuracy: Double) -> Array<UInt8> {
        var LocationData: Array<UInt8> = []
        LocationData.append(contentsOf: UnsafeConverter.bytes(lat).reversed())
        LocationData.append(contentsOf: UnsafeConverter.bytes(long).reversed())
        LocationData.append(contentsOf: UnsafeConverter.bytes(accuracy).reversed())
        return LocationData
    }
    
    fileprivate func getAuthData() -> Array<UInt8> {
        var authData: Array<UInt8> = []
        
        if auth.authToken != nil {
            authData = auth.authToken!.data().getUInt8Array()
        } else {
            authData = self.authInfo!.getUInt8Array()
        }

        return authData
    }
    
    internal func generateAuthInfo() -> Pogoprotos.Networking.Envelopes.RequestEnvelope.AuthInfo {
        let authInfoBuilder = Pogoprotos.Networking.Envelopes.RequestEnvelope.Builder().getAuthInfoBuilder()
        let authInfoTokenBuilder = authInfoBuilder.getTokenBuilder()
        authInfoBuilder.provider = auth.authType.description
        authInfoTokenBuilder.contents = auth.accessToken!
        authInfoTokenBuilder.unknown2 = 59
        let authData = try! authInfoBuilder.build()
        self.authInfo = authData.data()
        return authData
    }
    
    fileprivate func hashAuthTicket() -> UInt32 {
        let firstHash = niahash.hash32(buffer: getAuthData())
        return niahash.hash32Salt(buffer: self.locationHex, salt: firstHash)
    }
    
    fileprivate func hashLocation() -> UInt32 {
        self.locationHex = locationToHex(self.api.Location.lat, long:self.api.Location.long, accuracy: self.api.Location.horizontalAccuracy)
        return niahash.hash32(buffer: self.locationHex)
    }
    
    internal func hashRequest(_ requestData:Data) -> UInt64 {
        let firstHash = niahash.hash64(buffer: getAuthData())
        return niahash.hash64Salt64(buffer: requestData.getUInt8Array(), salt: firstHash)
    }
    
    fileprivate func getSensorInfo() -> Pogoprotos.Networking.Envelopes.Signature.SensorInfo {
        let sensorInfoBuilder = Pogoprotos.Networking.Envelopes.Signature.SensorInfo.Builder()
        sensorInfoBuilder.timestampSnapshot = self.api.getTimestampSinceStart() + self.api.unknown6Settings.randomizedTimeSnapshot
        sensorInfoBuilder.linearAccelerationX = Double(Float.random(min: -0.2, max: 0.14))
        sensorInfoBuilder.linearAccelerationY = Double(Float.random(min: -0.2, max: 0.2))
        sensorInfoBuilder.linearAccelerationZ = Double(Float.random(min: -0.2, max: 0.4))
        sensorInfoBuilder.magneticFieldX = Double(Float.random(min: -55, max: 62))
        sensorInfoBuilder.magneticFieldY = Double(Float.random(min: -55, max: 62))
        sensorInfoBuilder.magneticFieldZ = Double(Float.random(min: -55, max: 5))
        sensorInfoBuilder.attitudePitch = Double(Float.random(min: 0, max: 0.07))
        sensorInfoBuilder.attitudeYaw = Double(Float.random(min: -2, max:  3))
        sensorInfoBuilder.attitudeRoll = Double(Float.random(min: -0.1, max: 0.2))
        sensorInfoBuilder.rotationRateX = Double(Float.random(min: -1, max: 1))
        sensorInfoBuilder.rotationRateY = Double(Float.random(min: -1, max:  1.4))
        sensorInfoBuilder.rotationRateZ = Double(Float.random(min: -1, max: 1))
        sensorInfoBuilder.gravityX = Double(Float.random(min: -0.5, max: 0.15))
        sensorInfoBuilder.gravityY = Double(Float.random(min: -0.6, max:  -0.07))
        sensorInfoBuilder.gravityZ = Double(Float.random(min: -1, max: -0.75))
        sensorInfoBuilder.status = 3
        return try! sensorInfoBuilder.build()
    }
    
    fileprivate func getActivityStatus() -> Pogoprotos.Networking.Envelopes.Signature.ActivityStatus {
        let activityDataBytes:[UInt8] = [72,1]
        let activityStatus = try! Pogoprotos.Networking.Envelopes.Signature.ActivityStatus.parseFrom(data:
            Data(bytes: activityDataBytes))
        return activityStatus
    }
    
    fileprivate func getDeviceInfo() -> Pogoprotos.Networking.Envelopes.Signature.DeviceInfo {
        let deviceInfoBuilder = Pogoprotos.Networking.Envelopes.Signature.DeviceInfo.Builder()
        deviceInfoBuilder.deviceId = self.api.device.deviceId
        if self.api.device.androidBoardName != nil {
            deviceInfoBuilder.androidBoardName = self.api.device.androidBoardName!
        }
        if self.api.device.androidBootloader != nil {
            deviceInfoBuilder.androidBootloader = self.api.device.androidBootloader!
        }
        if self.api.device.deviceBrand != nil {
            deviceInfoBuilder.deviceBrand = self.api.device.deviceBrand!
        }
        if self.api.device.deviceModel != nil {
            deviceInfoBuilder.deviceModel = self.api.device.deviceModel!
        }
        if self.api.device.deviceModelIdentifier != nil {
            deviceInfoBuilder.deviceModelIdentifier = self.api.device.deviceModelIdentifier!
        }
        if self.api.device.deviceModelBoot != nil {
            deviceInfoBuilder.deviceModelBoot = self.api.device.deviceModelBoot!
        }
        if self.api.device.hardwareManufacturer != nil {
            deviceInfoBuilder.hardwareManufacturer = self.api.device.hardwareManufacturer!
        }
        if self.api.device.hardwareModel != nil {
            deviceInfoBuilder.hardwareModel = self.api.device.hardwareModel!
        }
        if self.api.device.firmwareBrand != nil {
            deviceInfoBuilder.firmwareBrand = self.api.device.firmwareBrand!
        }
        if self.api.device.firmwareTags != nil {
            deviceInfoBuilder.firmwareTags = self.api.device.firmwareTags!
        }
        if self.api.device.firmwareType != nil {
            deviceInfoBuilder.firmwareType = self.api.device.firmwareType!
        }
        if self.api.device.firmwareFingerprint != nil {
            deviceInfoBuilder.firmwareFingerprint = self.api.device.firmwareFingerprint!
        }
        return try! deviceInfoBuilder.build()
    }
    
    fileprivate func getLocationFixes() -> [Pogoprotos.Networking.Envelopes.Signature.LocationFix] {
        var fixes: [Pogoprotos.Networking.Envelopes.Signature.LocationFix] = []
        for i in 0..<self.api.locationFix.builders.count {
            let locFix = Pogoprotos.Networking.Envelopes.Signature.LocationFix.Builder()
            locFix.provider = "fused"
            locFix.timestampSnapshot = self.api.locationFix.builders[i].timestampSnapshot + self.api.getTimestampSinceStart() + self.api.session.realisticStartTimeAdjustment - 500
            locFix.latitude = self.api.locationFix.builders[i].latitude
            locFix.longitude = self.api.locationFix.builders[i].longitude
            locFix.altitude = self.api.locationFix.builders[i].altitude
            locFix.speed = self.api.locationFix.builders[i].speed
            locFix.course = self.api.locationFix.builders[i].course
            if self.api.locationFix.builders[i].floor != nil {
                locFix.floor = self.api.locationFix.builders[i].floor!
            }
            if self.api.locationFix.builders[i].verticalAccuracy != nil {
                locFix.verticalAccuracy = self.api.locationFix.builders[i].verticalAccuracy!
            }
            locFix.horizontalAccuracy = self.api.locationFix.builders[i].horizontalAccuracy
            locFix.providerStatus = 3
            locFix.locationType = 1
            fixes.append(try! locFix.build())
        }
        return fixes
    }
    
    internal func build() -> Pogoprotos.Networking.Envelopes.RequestEnvelope.PlatformRequest {
        let signatureBuilder = Pogoprotos.Networking.Envelopes.Signature.Builder()
        
        signatureBuilder.locationHash2 = hashLocation().getInt32()
        signatureBuilder.locationHash1 = hashAuthTicket().getInt32()
        signatureBuilder.unknown25 = PGoVersion.versionHash
        signatureBuilder.timestamp = self.api.getTimestamp()
        signatureBuilder.timestampSinceStart = self.api.getTimestampSinceStart() + self.api.session.realisticStartTimeAdjustment
        signatureBuilder.requestHash = self.requestHashes
        
        if self.api.session.sessionHash == nil {
            self.api.session.sessionHash = Data.randomBytes(16)
        }
        signatureBuilder.sessionHash = self.api.session.sessionHash!
        
        if self.api.unknown6Settings.useLocationFix {
            signatureBuilder.locationFix = getLocationFixes()
        }
        
        if self.api.unknown6Settings.useActivityStatus {
            signatureBuilder.activityStatus = getActivityStatus()
        }
        
        if self.api.unknown6Settings.useDeviceInfo {
            signatureBuilder.deviceInfo = getDeviceInfo()
        }
        
        
        if self.api.unknown6Settings.useSensorInfo {
            signatureBuilder.sensorInfo = [getSensorInfo()]
        }
                
        let signature = try! signatureBuilder.build()
        
        let unknown6 = Pogoprotos.Networking.Envelopes.RequestEnvelope.PlatformRequest.Builder()
        let unknown2 = Pogoprotos.Networking.Platform.Requests.SendEncryptedSignatureRequest.Builder()
        
        unknown6.type = .sendEncryptedSignature
        
        let sigData = pcrypt.encrypt(input: signature.data().getUInt8Array(), iv: UInt32(self.api.getTimestampSinceStart()))
        unknown2.encryptedSignature = Data(bytes: sigData)
        
        unknown6.requestMessage = try! unknown2.build().data()
        let unknown6Version35 = try! unknown6.build()
                
        return unknown6Version35
    }

}
