//
//  Extensions.swift
//  pgomap
//
//  Created by Luke Sapan on 7/20/16.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation
import ProtocolBuffers


extension NSRange {
    func rangeForString(str: String) -> Range<String.Index>? {
        guard location != NSNotFound else { return nil }
        return str.startIndex.advancedBy(location) ..< str.startIndex.advancedBy(location + length)
    }
}

extension NSData {
    func getUInt8Array() -> Array<UInt8> {
        return Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(self.bytes), count: self.length))
    }
    func getUInt32Array() -> Array<UInt32> {
        return Array(UnsafeBufferPointer(start: UnsafePointer<UInt32>(self.bytes), count: self.length))
    }
}

extension GeneratedMessage {
    func parseMessage(intent: PGoApiIntent) -> AnyObject? {
        switch intent {
            case .PlayerUpdate:
                return self as! Pogoprotos.Networking.Responses.PlayerUpdateResponse
            case .GetPlayer:
                return self as! Pogoprotos.Networking.Responses.GetPlayerResponse
            case .GetInventory:
                return self as! Pogoprotos.Networking.Responses.GetInventoryResponse
            case .DownloadSettings:
                return self as! Pogoprotos.Networking.Responses.DownloadSettingsResponse
            case .DownloadItemTemplates:
                return self as! Pogoprotos.Networking.Responses.DownloadItemTemplatesResponse
            case .DownloadRemoteConfigVersion:
                return self as! Pogoprotos.Networking.Responses.DownloadRemoteConfigVersionResponse
            case .FortSearch:
                return self as! Pogoprotos.Networking.Responses.FortSearchResponse
            case .EncounterPokemon:
                return self as! Pogoprotos.Networking.Responses.EncounterResponse
            case .CatchPokemon:
                return self as! Pogoprotos.Networking.Responses.CatchPokemonResponse
            case .FortDetails:
                return self as! Pogoprotos.Networking.Responses.FortDetailsResponse
            case .GetMapObjects:
                return self as! Pogoprotos.Networking.Responses.GetMapObjectsResponse
            case .FortDeployPokemon:
                return self as! Pogoprotos.Networking.Responses.FortDeployPokemonResponse
            case .FortRecallPokemon:
                return self as! Pogoprotos.Networking.Responses.FortRecallPokemonResponse
            case .ReleasePokemon:
                return self as! Pogoprotos.Networking.Responses.ReleasePokemonResponse
            case .UseItemPotion:
                return self as! Pogoprotos.Networking.Responses.UseItemPotionResponse
            case .UseItemCapture:
                return self as! Pogoprotos.Networking.Responses.UseItemCaptureResponse
            case .UseItemRevive:
                return self as! Pogoprotos.Networking.Responses.UseItemReviveResponse
            case .GetPlayerProfile:
                return self as! Pogoprotos.Networking.Responses.GetPlayerProfileResponse
            case .EvolvePokemon:
                return self as! Pogoprotos.Networking.Responses.EvolvePokemonResponse
            case .GetHatchedEggs:
                return self as! Pogoprotos.Networking.Responses.GetHatchedEggsResponse
            case .EncounterTutorialComplete:
                return self as! Pogoprotos.Networking.Responses.EncounterTutorialCompleteResponse
            case .LevelUpRewards:
                return self as! Pogoprotos.Networking.Responses.LevelUpRewardsResponse
            case .CheckAwardedBadges:
                return self as! Pogoprotos.Networking.Responses.CheckAwardedBadgesResponse
            case .UseItemGym:
                return self as! Pogoprotos.Networking.Responses.UseItemGymResponse
            case .GetGymDetails:
                return self as! Pogoprotos.Networking.Responses.GetGymDetailsResponse
            case .StartGymBattle:
                return self as! Pogoprotos.Networking.Responses.StartGymBattleResponse
            case .AttackGym:
                return self as! Pogoprotos.Networking.Responses.AttackGymResponse
            case .RecycleInventoryItem:
                return self as! Pogoprotos.Networking.Responses.RecycleInventoryItemResponse
            case .CollectDailyBonus:
                return self as! Pogoprotos.Networking.Responses.CollectDailyBonusResponse
            case .UseItemXpBoost:
                return self as! Pogoprotos.Networking.Responses.UseItemXpBoostResponse
            case .UseItemEggIncubator:
                return self as! Pogoprotos.Networking.Responses.UseItemEggIncubatorResponse
            case .UseIncense:
                return self as! Pogoprotos.Networking.Responses.UseIncenseResponse
            case .GetIncensePokemon:
                return self as! Pogoprotos.Networking.Responses.GetIncensePokemonResponse
            case .IncenseEncounter:
                return self as! Pogoprotos.Networking.Responses.IncenseEncounterResponse
            case .AddFortModifier:
                return self as! Pogoprotos.Networking.Responses.AddFortModifierResponse
            case .DiskEncounter:
                return self as! Pogoprotos.Networking.Responses.DiskEncounterResponse
            case .CollectDailyDefenderBonus:
                return self as! Pogoprotos.Networking.Responses.CollectDailyBonusResponse
            case .UpgradePokemon:
                return self as! Pogoprotos.Networking.Responses.UpgradePokemonResponse
            case .SetFavoritePokemon:
                return self as! Pogoprotos.Networking.Responses.SetFavoritePokemonResponse
            case .NicknamePokemon:
                return self as! Pogoprotos.Networking.Responses.NicknamePokemonResponse
            case .EquipBadge:
                return self as! Pogoprotos.Networking.Responses.EquipBadgeResponse
            case .SetContactSettings:
                return self as! Pogoprotos.Networking.Responses.SetContactSettingsResponse
            case .GetAssetDigest:
                return self as! Pogoprotos.Networking.Responses.GetAssetDigestResponse
            case .GetDownloadUrls:
                return self as! Pogoprotos.Networking.Responses.GetDownloadUrlsResponse
            case .GetSuggestedCodenames:
                return self as! Pogoprotos.Networking.Responses.GetSuggestedCodenamesResponse
            case .CheckCodenameAvailable:
                return self as! Pogoprotos.Networking.Responses.CheckCodenameAvailableResponse
            case .ClaimCodename:
                return self as! Pogoprotos.Networking.Responses.ClaimCodenameResponse
            case .SetAvatar:
                return self as! Pogoprotos.Networking.Responses.SetAvatarResponse
            case .SetPlayerTeam:
                return self as! Pogoprotos.Networking.Responses.SetPlayerTeamResponse
            case .MarkTutorialComplete:
                return self as! Pogoprotos.Networking.Responses.MarkTutorialCompleteResponse
            case .Echo:
                return self as! Pogoprotos.Networking.Responses.EchoResponse
            case .SfidaActionLog:
                return self as! Pogoprotos.Networking.Responses.SfidaActionLogResponse
            default:
                return self
        }
        return self
    }
}