//
//  Unknown6Builder.swift
//  pgoapi
//
//  Created by PokemonGoSucks on 2016-09-06.
//
//

import Foundation


internal class LocationFixes {
    internal var builders: Array<Pogoprotos.Networking.Envelopes.Signature.LocationFix.Builder> =  []
    internal var timestamp:UInt64 = 0
    internal var lastTimesnap:UInt64 = 0
    internal var count: Int = 3
}

internal class LocationFix {
    private let api: PGoApiRequest
    
    internal init(api: PGoApiRequest) {
        self.api = api
        self.update()
    }
    
    private func generateByCount(startAt: Int) {
        let minFloor = floor(500/Double(self.api.locationFix.count))
        let maxFloor = floor(750/Double(self.api.locationFix.count))
        
        for i in startAt..<self.api.locationFix.count {
            let minValue:UInt64 = 500 - (UInt64(minFloor) * UInt64(i))
            let maxValue:UInt64 = 750 - (UInt64(maxFloor) * UInt64(i))
            
            let newFix = generate(UInt64.random(minValue, max: maxValue))
            self.api.locationFix.builders.append(newFix)
        }
    }
    
    private func getTimeSnapshot() -> UInt64 {
        return self.api.getTimestamp() - self.api.locationFix.lastTimesnap
    }
    
    private func getLastTimeSnapshot() -> UInt64 {
        return self.api.locationFix.builders.last!.timestampSnapshot
    }
    
    private func update() {
        self.api.locationFix.lastTimesnap = self.api.getTimestamp()
        if self.api.locationFix.builders.count == 0 {
            generateByCount(0)
        } else {
            var countRemoved = 0
            for i in 0..<self.api.locationFix.count {
                self.api.locationFix.builders[i].timestampSnapshot += getTimeSnapshot()
                if self.api.locationFix.builders[i].timestampSnapshot < 1500 {
                    countRemoved += 1
                }
            }
            self.api.locationFix.builders.removeRange(Range(start: 0, end: countRemoved))
            generateByCount(self.api.locationFix.count - countRemoved)
        }
        self.api.locationFix.timestamp = getLastTimeSnapshot()
    }
    
    private func generate(timeStamp: UInt64) -> Pogoprotos.Networking.Envelopes.Signature.LocationFix.Builder {
        let locFix = Pogoprotos.Networking.Envelopes.Signature.LocationFix.Builder()
        locFix.provider = "fused"
        locFix.timestampSnapshot = self.api.getTimestampSinceStart() + timeStamp
        locFix.latitude = Float(self.api.Location.lat) + Float.random(min: -0.01, max: 0.01)
        locFix.longitude = Float(self.api.Location.long) + Float.random(min: -0.01, max: 0.01)
        locFix.altitude = Float(self.api.Location.alt) + Float.random(min: -0.01, max: 0.01)
        if self.api.Location.speed != nil {
            locFix.speed = Float(self.api.Location.speed!) + Float.random(min: -0.01, max: 0.01)
        } else {
            locFix.speed = Float.random(min: 0.1, max: 3.0)
        }
        if self.api.Location.speed != nil {
            locFix.course = Float(self.api.Location.course!) + Float.random(min: -0.01, max: 0.01)
        } else {
            locFix.course = Float.random(min: 0, max: 360)
        }
        if self.api.Location.floor != nil {
            locFix.floor = self.api.Location.floor!
        }
        locFix.course = Float(self.api.Location.horizontalAccuracy) + Float.random(min: -0.01, max: 0.01)
        locFix.providerStatus = 3
        locFix.locationType = 1
        return locFix
    }
}

internal class platformRequest {
    private let encrypt: PGoEncrypt
    private var locationHex: Array<UInt8>
    private var authInfo: NSData? = nil
    private var auth: PGoAuth
    private let api: PGoApiRequest
    internal let locationFix: LocationFix
    internal var requestHashes:Array<UInt64> = []
    
    internal init(auth: PGoAuth, api: PGoApiRequest) {
        self.locationHex = []
        self.encrypt = PGoEncrypt()
        self.auth = auth
        self.api = api
        self.locationFix = LocationFix(api: api)
    }
    
    private func toByteArray<T>(value_: T) -> [UInt8] {
        var value = value_
        return withUnsafePointer(&value) {
            Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: 8))
        }
    }
    
    private func locationToHex(lat: Double, long: Double, accuracy: Double) -> Array<UInt8> {
        var LocationData: Array<UInt8> = []
        LocationData.appendContentsOf(toByteArray(lat).reverse())
        LocationData.appendContentsOf(toByteArray(long).reverse())
        LocationData.appendContentsOf(toByteArray(accuracy).reverse())
        return LocationData
    }
    
    private func getAuthData() -> Array<UInt8> {
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
    
    private func hashAuthTicket() -> UInt32 {
        let xxh32:xxhash = xxhash()
        let firstHash = xxh32.xxh32(0x61656632, input: getAuthData())
        return xxh32.xxh32(firstHash, input: self.locationHex)
    }
    
    private func hashLocation() -> UInt32 {
        let xxh32:xxhash = xxhash()
        self.locationHex = locationToHex(self.api.Location.lat, long:self.api.Location.long, accuracy: self.api.Location.horizontalAccuracy)
        return xxh32.xxh32(0x61656632, input: locationHex)
    }
    
    internal func hashRequest(requestData:NSData) -> UInt64 {
        let xxh64:xxhash = xxhash()
        let firstHash = xxh64.xxh64(0x61656632, input: getAuthData())
        return xxh64.xxh64(firstHash, input: requestData.getUInt8Array())
    }
    
    private func getSensorInfo() -> Pogoprotos.Networking.Envelopes.Signature.SensorInfo {
        let sensorInfoBuilder = Pogoprotos.Networking.Envelopes.Signature.SensorInfo.Builder()
        sensorInfoBuilder.timestampSnapshot = self.api.getTimestampSinceStart() + self.api.unknown6Settings.randomizedTimeSnapshot
        sensorInfoBuilder.linearAccelerationX = Double(Float.random(min: -0.2, max: 0.14))
        sensorInfoBuilder.linearAccelerationY = Double(Float.random(min: -0.2, max: 0.2))
        sensorInfoBuilder.linearAccelerationZ = Double(Float.random(min: -0.2, max: 0.4))
        sensorInfoBuilder.magneticFieldX = Double(Float.random(min: -55, max: 62))
        sensorInfoBuilder.magneticFieldY = Double(Float.random(min: -55, max: 62))
        sensorInfoBuilder.magneticFieldZ = Double(Float.random(min: -55, max: 5))
        sensorInfoBuilder.rotationVectorX = Double(Float.random(min: 0, max: 0.07))
        sensorInfoBuilder.rotationVectorY = Double(Float.random(min: -2, max:  3))
        sensorInfoBuilder.rotationVectorZ = Double(Float.random(min: -0.1, max: 0.2))
        sensorInfoBuilder.gyroscopeRawX = Double(Float.random(min: -1, max: 1))
        sensorInfoBuilder.gyroscopeRawY = Double(Float.random(min: -1, max:  1.4))
        sensorInfoBuilder.gyroscopeRawZ = Double(Float.random(min: -1, max: 1))
        sensorInfoBuilder.gravityX = Double(Float.random(min: -0.5, max: 0.15))
        sensorInfoBuilder.gravityY = Double(Float.random(min: -0.6, max:  -0.07))
        sensorInfoBuilder.gravityZ = Double(Float.random(min: -1, max: -0.75))
        sensorInfoBuilder.accelerometerAxes = 3
        return try! sensorInfoBuilder.build()
    }
    
    private func getActivityStatus() -> Pogoprotos.Networking.Envelopes.Signature.ActivityStatus {
        let activityStatusBuilder = Pogoprotos.Networking.Envelopes.Signature.ActivityStatus.Builder()
        return try! activityStatusBuilder.build()
    }
    
    private func getDeviceInfo() -> Pogoprotos.Networking.Envelopes.Signature.DeviceInfo {
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
    
    private func getLocationFixes() -> [Pogoprotos.Networking.Envelopes.Signature.LocationFix] {
        var fixes: [Pogoprotos.Networking.Envelopes.Signature.LocationFix] = []
        for i in 0..<self.api.locationFix.count {
            fixes.append(try! self.api.locationFix.builders[i].build())
        }
        return fixes
    }
    
    internal func build() -> Pogoprotos.Networking.Envelopes.RequestEnvelope.PlatformRequest {
        let signatureBuilder = Pogoprotos.Networking.Envelopes.Signature.Builder()
        
        signatureBuilder.locationHash2 = hashLocation()
        signatureBuilder.locationHash1 = hashAuthTicket()
        signatureBuilder.unknown25 = PGoVersion.versionHash
        signatureBuilder.timestamp = self.api.getTimestamp()
        signatureBuilder.timestampSinceStart = self.api.getTimestampSinceStart() + self.api.session.realisticStartTimeAdjustment
        signatureBuilder.requestHash = self.requestHashes
        
        if self.api.session.sessionHash == nil {
            self.api.session.sessionHash = NSData.randomBytes(16)
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
            signatureBuilder.sensorInfo = getSensorInfo()
        }
        
        let signature = try! signatureBuilder.build()
        
        let unknown6 = Pogoprotos.Networking.Envelopes.RequestEnvelope.PlatformRequest.Builder()
        let unknown2 = Pogoprotos.Networking.Platform.Requests.SendEncryptedSignatureRequest.Builder()
        
        unknown6.types = .SendEncryptedSignature
        
        let sigData = self.encrypt.encrypt(signature.data().getUInt8Array())
        unknown2.encryptedSignature = NSData(bytes: sigData, length: sigData.count)
        
        unknown6.requestMessage = try! unknown2.build().data()
        let unknown6Version35 = try! unknown6.build()
        
        return unknown6Version35
    }

}