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


public struct ApiMethod {
    let id: Pogoprotos.Networking.Requests.RequestType
    let message: GeneratedMessage
    let parser: NSData -> GeneratedMessage
}

public struct ApiResponse {
    public let response: GeneratedMessage
    public let subresponses: [GeneratedMessage]
}

public class PGoApiRequest {
    public var methodList: [ApiMethod] = []
    
    public init() {
        
    }

    public func makeRequest(intent: ApiIntent, delegate: PGoApiDelegate?) {  // analogous to call in pgoapi.py
        if methodList.count == 0 {
            print("makeRequest() called without any methods in methodList.")
            return
        }

        if !PGoAuth.sharedInstance.loggedIn {
            print("makeRequest() called without being logged in.")
            return
        }

        // TODO: Get player position
        // position stuff here...
        let request = RpcApi(subrequests: methodList, intent: intent, delegate: delegate)
        request.request(Api.endpoint)
    }

    public func simulateAppStart() {
        getPlayer()
        getHatchedEggs()
        getInventory()
        checkAwardedBadges()
        downloadSettings()
    }

    public func getPlayer() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetPlayerMessage.Builder()
        methodList.append(ApiMethod(id: .GetPlayer, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetPlayerResponse.parseFromData(data)
        }))
    }

    public func getHatchedEggs() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetHatchedEggsMessage.Builder()
        methodList.append(ApiMethod(id: .GetHatchedEggs, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetHatchedEggsResponse.parseFromData(data)
        }))
    }

    public func getInventory() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetInventoryMessage.Builder()
        methodList.append(ApiMethod(id: .GetInventory, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetInventoryResponse.parseFromData(data)
        }))
    }

    public func checkAwardedBadges() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.CheckAwardedBadgesMessage.Builder()
        methodList.append(ApiMethod(id: .CheckAwardedBadges, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.CheckAwardedBadgesResponse.parseFromData(data)
        }))
    }

    public func downloadSettings() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.DownloadSettingsMessage.Builder()
        messageBuilder.hash = Api.SettingsHash
        methodList.append(ApiMethod(id: .DownloadSettings, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.DownloadSettingsResponse.parseFromData(data)
        }))
    }

    public func getMapObjects(latitude: Double, longitude: Double) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetMapObjectsMessage.Builder()
        messageBuilder.latitude = latitude
        messageBuilder.longitude = longitude
        messageBuilder.sinceTimestampMs = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
        
        let cell = S2CellId(p: S2LatLon(latDegrees: latitude, lonDegrees: longitude).toPoint())
        var cells: [UInt64] = []
        
        var currentCell = cell
        for _ in 0..<10 {
            currentCell = currentCell.prev()
            cells.insert(currentCell.id, atIndex: 0)
        }
        
        cells.append(cell.id)
        
        currentCell = cell
        for _ in 0..<10 {
            currentCell = currentCell.next()
            cells.append(currentCell.id)
        }
        
        messageBuilder.cellId = cells
        methodList.append(ApiMethod(id: .GetMapObjects, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetMapObjectsResponse.parseFromData(data)
        }))
    }
}
