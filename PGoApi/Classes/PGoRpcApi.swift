//
//  RPC.swift
//  pgomap
//
//  Based on https://github.com/tejado/pgoapi/blob/master/pgoapi/rpc_api.py
//
//  Created by Luke Sapan on 7/20/16.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation
import Alamofire
import ProtocolBuffers


internal class PGoRpcApi {
    private let intent: PGoApiIntent
    private var auth: PGoAuth
    private let delegate: PGoApiDelegate?
    private let subrequests: [PGoApiMethod]
    private let api: PGoApiRequest
    private var manager: Manager?
    private var responseObject: PGoResponseObject?
    private var unknown6Builder: platformRequest?
    
    internal init(subrequests: [PGoApiMethod], intent: PGoApiIntent, auth: PGoAuth, api: PGoApiRequest, delegate: PGoApiDelegate?) {
        manager = auth.manager
        manager!.session.configuration.HTTPAdditionalHeaders = [
            "User-Agent": "Niantic App"
        ]
        
        self.subrequests = subrequests
        self.intent = intent
        self.auth = auth
        self.delegate = delegate
        self.api = api
        self.unknown6Builder = platformRequest(auth: auth, api: api)
        if self.api.ApiSettings.useResponseObjects {
            self.responseObject = PGoResponseObject()
        }
    }
    
    internal func request() {
        let requestData = buildMainRequest().data()
        
        manager!.request(.POST, auth.endpoint, parameters: [:], encoding: .Custom({
            (convertible, params) in
            let mutableRequest = convertible.URLRequest.copy() as! NSMutableURLRequest
            mutableRequest.HTTPBody = requestData
            return (mutableRequest, nil)
        })).responseData { response in
            let statusCode = response.response?.statusCode
            if statusCode != 200 {
                print("Unexpected response code, should be 200, got \(statusCode)")
                self.delegate?.didReceiveApiError(self.intent, statusCode: statusCode)
                return
            }
            
            self.api.debugMessage("Got a response!")
            self.delegate?.didReceiveApiResponse(self.intent, response: self.parseMainResponse(response.result.value!))
        }
    }
    
    private func buildMainRequest() -> Pogoprotos.Networking.Envelopes.RequestEnvelope {
        self.api.debugMessage("Generating main request...")
        
        let requestBuilder = Pogoprotos.Networking.Envelopes.RequestEnvelope.Builder()
        requestBuilder.statusCode = 2
        requestBuilder.requestId = self.api.session.requestId
        
        requestBuilder.latitude = self.api.Location.lat
        requestBuilder.longitude = self.api.Location.long
        requestBuilder.accuracy = self.api.Location.horizontalAccuracy
        
        if auth.authToken == nil {
            requestBuilder.authInfo = unknown6Builder!.generateAuthInfo()
        } else {
            requestBuilder.authTicket = auth.authToken!
        }
        
        self.api.debugMessage("Generating subrequests...")
        for subrequest in subrequests {
            self.api.debugMessage("Processing \(subrequest)...")
            let subrequestBuilder = Pogoprotos.Networking.Requests.Request.Builder()
            subrequestBuilder.requestType = subrequest.id
            subrequestBuilder.requestMessage = subrequest.message.data()
            let subData = try! subrequestBuilder.build()
            requestBuilder.requests += [subData]
            unknown6Builder!.requestHashes.append(unknown6Builder!.hashRequest(subData.data()))
        }
        
        requestBuilder.platformRequests = [unknown6Builder!.build()]
        
        self.api.session.requestId += 1
        
        if self.api.unknown6Settings.useLocationFix {
            requestBuilder.msSinceLastLocationfix = Int64(self.api.locationFix.timestamp)
        } else {
            requestBuilder.msSinceLastLocationfix = Int64(UInt64.random(100, max: 300))
        }
        
        self.api.debugMessage("Building request...")
        return try! requestBuilder.build()
    }
    
    private func parseMainResponse(data: NSData) -> PGoApiResponse {
        self.api.debugMessage("Parsing main response...")
        
        let response = try! Pogoprotos.Networking.Envelopes.ResponseEnvelope.parseFromData(data)
        
        if response.statusCode == .BadRequest {
            self.auth.banned = true
            print("WARNING: Account may be banned.")
            self.delegate?.didReceiveApiException(intent, exception: .Banned)
        } else if response.statusCode == .Redirect {
            auth.endpoint = "https://\(response.apiUrl)/rpc"
            print("New endpoint: \(auth.endpoint)")
        } else if response.statusCode == .InvalidAuthToken {
            print("Auth token is expired.")
            if (self.api.ApiSettings.refreshAuthTokens) {
                self.api.refreshAuthToken()
            } else {
                auth.expired = true
                self.delegate?.didReceiveApiException(intent, exception: .AuthTokenExpired)
            }
        } else if response.statusCode == .InvalidRequest {
            print("Warning! Request was invalid.")
            self.delegate?.didReceiveApiException(intent, exception: .InvalidRequest)
        } else if response.statusCode == .InvalidPlatformRequest {
            print("Warning! Platform request is invalid. Try adding a delay of 10 seconds.")
            self.delegate?.didReceiveApiException(intent, exception: .DelayRequired)
        } else if response.statusCode == .SessionInvalidated {
            print("Warning! Session is invalid.")
            self.delegate?.didReceiveApiException(intent, exception: .SessionInvalidated)
        } else if response.statusCode == .Unknown {
            print("Warning! Unknown error.")
            self.delegate?.didReceiveApiException(intent, exception: .Unknown)
        }
        
        if response.hasAuthTicket {
            auth.authToken = response.authTicket
        }
        
        let subresponses = parseSubResponses(response)
        return PGoApiResponse(response: response, subresponses: subresponses, object: responseObject)
    }
    
    private func setResponseObject(intent: Pogoprotos.Networking.Requests.RequestType, parsedData: GeneratedMessage) {
        switch intent {
        case .GetPlayer:
            responseObject!.GetPlayer = parsedData as? Pogoprotos.Networking.Responses.GetPlayerResponse
        case .GetInventory:
            responseObject!.GetInventory = parsedData as? Pogoprotos.Networking.Responses.GetInventoryResponse
        case .DownloadSettings:
            responseObject!.DownloadSettings = parsedData as? Pogoprotos.Networking.Responses.DownloadSettingsResponse
        case .DownloadItemTemplates:
            responseObject!.DownloadItemTemplates = parsedData as? Pogoprotos.Networking.Responses.DownloadItemTemplatesResponse
        case .DownloadRemoteConfigVersion:
            responseObject!.DownloadRemoteConfigVersion = parsedData as? Pogoprotos.Networking.Responses.DownloadRemoteConfigVersionResponse
        case .FortSearch:
            responseObject!.FortSearch = parsedData as? Pogoprotos.Networking.Responses.FortSearchResponse
        case .Encounter:
            responseObject!.EncounterPokemon = parsedData as? Pogoprotos.Networking.Responses.EncounterResponse
        case .CatchPokemon:
            responseObject!.CatchPokemon = parsedData as? Pogoprotos.Networking.Responses.CatchPokemonResponse
        case .FortDetails:
            responseObject!.FortDetails = parsedData as? Pogoprotos.Networking.Responses.FortDetailsResponse
        case .GetMapObjects:
            responseObject!.GetMapObjects = parsedData as? Pogoprotos.Networking.Responses.GetMapObjectsResponse
        case .FortDeployPokemon:
            responseObject!.FortDeployPokemon = parsedData as? Pogoprotos.Networking.Responses.FortDeployPokemonResponse
        case .FortRecallPokemon:
            responseObject!.FortRecallPokemon = parsedData as? Pogoprotos.Networking.Responses.FortRecallPokemonResponse
        case .ReleasePokemon:
            responseObject!.ReleasePokemon = parsedData as? Pogoprotos.Networking.Responses.ReleasePokemonResponse
        case .UseItemPotion:
            responseObject!.UseItemPotion = parsedData as? Pogoprotos.Networking.Responses.UseItemPotionResponse
        case .UseItemCapture:
            responseObject!.UseItemCapture = parsedData as? Pogoprotos.Networking.Responses.UseItemCaptureResponse
        case .UseItemRevive:
            responseObject!.UseItemRevive = parsedData as? Pogoprotos.Networking.Responses.UseItemReviveResponse
        case .GetPlayerProfile:
            responseObject!.GetPlayerProfile = parsedData as? Pogoprotos.Networking.Responses.GetPlayerProfileResponse
        case .EvolvePokemon:
            responseObject!.EvolvePokemon = parsedData as? Pogoprotos.Networking.Responses.EvolvePokemonResponse
        case .GetHatchedEggs:
            responseObject!.GetHatchedEggs = parsedData as? Pogoprotos.Networking.Responses.GetHatchedEggsResponse
        case .EncounterTutorialComplete:
            responseObject!.EncounterTutorialComplete = parsedData as? Pogoprotos.Networking.Responses.EncounterTutorialCompleteResponse
        case .LevelUpRewards:
            responseObject!.LevelUpRewards = parsedData as? Pogoprotos.Networking.Responses.LevelUpRewardsResponse
        case .CheckAwardedBadges:
            responseObject!.CheckAwardedBadges = parsedData as? Pogoprotos.Networking.Responses.CheckAwardedBadgesResponse
        case .UseItemGym:
            responseObject!.UseItemGym = parsedData as? Pogoprotos.Networking.Responses.UseItemGymResponse
        case .GetGymDetails:
            responseObject!.GetGymDetails = parsedData as? Pogoprotos.Networking.Responses.GetGymDetailsResponse
        case .StartGymBattle:
            responseObject!.StartGymBattle = parsedData as? Pogoprotos.Networking.Responses.StartGymBattleResponse
        case .AttackGym:
            responseObject!.AttackGym = parsedData as? Pogoprotos.Networking.Responses.AttackGymResponse
        case .RecycleInventoryItem:
            responseObject!.RecycleInventoryItem = parsedData as? Pogoprotos.Networking.Responses.RecycleInventoryItemResponse
        case .CollectDailyBonus:
            responseObject!.CollectDailyBonus = parsedData as? Pogoprotos.Networking.Responses.CollectDailyBonusResponse
        case .UseItemXpBoost:
            responseObject!.UseItemXpBoost = parsedData as? Pogoprotos.Networking.Responses.UseItemXpBoostResponse
        case .UseItemEggIncubator:
            responseObject!.UseItemEggIncubator = parsedData as? Pogoprotos.Networking.Responses.UseItemEggIncubatorResponse
        case .UseIncense:
            responseObject!.UseIncense = parsedData as? Pogoprotos.Networking.Responses.UseIncenseResponse
        case .GetIncensePokemon:
            responseObject!.GetIncensePokemon = parsedData as? Pogoprotos.Networking.Responses.GetIncensePokemonResponse
        case .IncenseEncounter:
            responseObject!.IncenseEncounter = parsedData as? Pogoprotos.Networking.Responses.IncenseEncounterResponse
        case .AddFortModifier:
            responseObject!.AddFortModifier = parsedData as? Pogoprotos.Networking.Responses.AddFortModifierResponse
        case .DiskEncounter:
            responseObject!.DiskEncounter = parsedData as? Pogoprotos.Networking.Responses.DiskEncounterResponse
        case .CollectDailyDefenderBonus:
            responseObject!.CollectDailyBonus = parsedData as? Pogoprotos.Networking.Responses.CollectDailyBonusResponse
        case .UpgradePokemon:
            responseObject!.UpgradePokemon = parsedData as? Pogoprotos.Networking.Responses.UpgradePokemonResponse
        case .SetFavoritePokemon:
            responseObject!.SetFavoritePokemon = parsedData as? Pogoprotos.Networking.Responses.SetFavoritePokemonResponse
        case .NicknamePokemon:
            responseObject!.NicknamePokemon = parsedData as? Pogoprotos.Networking.Responses.NicknamePokemonResponse
        case .EquipBadge:
            responseObject!.EquipBadge = parsedData as? Pogoprotos.Networking.Responses.EquipBadgeResponse
        case .SetContactSettings:
            responseObject!.SetContactSettings = parsedData as? Pogoprotos.Networking.Responses.SetContactSettingsResponse
        case .GetAssetDigest:
            responseObject!.GetAssetDigest = parsedData as? Pogoprotos.Networking.Responses.GetAssetDigestResponse
        case .GetDownloadUrls:
            responseObject!.GetDownloadUrls = parsedData as? Pogoprotos.Networking.Responses.GetDownloadUrlsResponse
        case .GetSuggestedCodenames:
            responseObject!.GetSuggestedCodenames = parsedData as? Pogoprotos.Networking.Responses.GetSuggestedCodenamesResponse
        case .CheckCodenameAvailable:
            responseObject!.CheckCodenameAvailable = parsedData as? Pogoprotos.Networking.Responses.CheckCodenameAvailableResponse
        case .ClaimCodename:
            responseObject!.ClaimCodename = parsedData as? Pogoprotos.Networking.Responses.ClaimCodenameResponse
        case .SetAvatar:
            responseObject!.SetAvatar = parsedData as? Pogoprotos.Networking.Responses.SetAvatarResponse
        case .SetPlayerTeam:
            responseObject!.SetPlayerTeam = parsedData as? Pogoprotos.Networking.Responses.SetPlayerTeamResponse
        case .MarkTutorialComplete:
            responseObject!.MarkTutorialComplete = parsedData as? Pogoprotos.Networking.Responses.MarkTutorialCompleteResponse
        case .Echo:
            responseObject!.Echo = parsedData as? Pogoprotos.Networking.Responses.EchoResponse
        case .SfidaActionLog:
            responseObject!.SfidaActionLog as Pogoprotos.Networking.Responses.SfidaActionLogResponse!
        case .CheckChallenge:
            responseObject!.CheckChallenge as Pogoprotos.Networking.Responses.CheckChallengeResponse!
        case .VerifyChallenge:
            responseObject!.VerifyChallenge as Pogoprotos.Networking.Responses.VerifyChallengeResponse!
        default:
            return
        }
    }
    
    private func parseSubResponses(response: Pogoprotos.Networking.Envelopes.ResponseEnvelope) -> [GeneratedMessage] {
        self.api.debugMessage("Parsing subresponses...")
        
        var subresponses: [GeneratedMessage] = []
        for (idx, subresponseData) in response.returns.enumerate() {
            let subrequest = subrequests[idx]
            let parsedData = subrequest.parser(subresponseData)
            subresponses.append(parsedData)
            if self.api.ApiSettings.useResponseObjects {
                if responseObject == nil {
                    responseObject = PGoResponseObject()
                }
                setResponseObject(subrequest.id, parsedData: parsedData)
            }
        }
        return subresponses
    }
}
