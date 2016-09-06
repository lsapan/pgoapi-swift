//
//  PGoApiResponse.swift
//  pgoapi
//
//  Created by PokemonGoSucks on 2016-09-06.
//
//

import Foundation
import ProtocolBuffers


public struct PGoApiResponse {
    public let response: GeneratedMessage
    public let subresponses: [GeneratedMessage]
    public let object: PGoResponseObject?
}

public struct PGoResponseObject {
    public var PlayerUpdate: Pogoprotos.Networking.Responses.PlayerUpdateResponse? = nil
    public var GetPlayer: Pogoprotos.Networking.Responses.GetPlayerResponse? = nil
    public var GetInventory: Pogoprotos.Networking.Responses.GetInventoryResponse? = nil
    public var DownloadSettings: Pogoprotos.Networking.Responses.DownloadSettingsResponse? = nil
    public var DownloadItemTemplates: Pogoprotos.Networking.Responses.DownloadItemTemplatesResponse? = nil
    public var DownloadRemoteConfigVersion: Pogoprotos.Networking.Responses.DownloadRemoteConfigVersionResponse? = nil
    public var FortSearch: Pogoprotos.Networking.Responses.FortSearchResponse? = nil
    public var EncounterPokemon: Pogoprotos.Networking.Responses.EncounterResponse? = nil
    public var CatchPokemon: Pogoprotos.Networking.Responses.CatchPokemonResponse? = nil
    public var FortDetails: Pogoprotos.Networking.Responses.FortDetailsResponse? = nil
    public var GetMapObjects: Pogoprotos.Networking.Responses.GetMapObjectsResponse? = nil
    public var FortDeployPokemon: Pogoprotos.Networking.Responses.FortDeployPokemonResponse? = nil
    public var FortRecallPokemon: Pogoprotos.Networking.Responses.FortRecallPokemonResponse? = nil
    public var ReleasePokemon: Pogoprotos.Networking.Responses.ReleasePokemonResponse? = nil
    public var UseItemPotion: Pogoprotos.Networking.Responses.UseItemPotionResponse? = nil
    public var UseItemCapture: Pogoprotos.Networking.Responses.UseItemCaptureResponse? = nil
    public var UseItemRevive: Pogoprotos.Networking.Responses.UseItemReviveResponse? = nil
    public var GetPlayerProfile: Pogoprotos.Networking.Responses.GetPlayerProfileResponse? = nil
    public var EvolvePokemon: Pogoprotos.Networking.Responses.EvolvePokemonResponse? = nil
    public var GetHatchedEggs: Pogoprotos.Networking.Responses.GetHatchedEggsResponse? = nil
    public var EncounterTutorialComplete: Pogoprotos.Networking.Responses.EncounterTutorialCompleteResponse? = nil
    public var LevelUpRewards: Pogoprotos.Networking.Responses.LevelUpRewardsResponse? = nil
    public var CheckAwardedBadges: Pogoprotos.Networking.Responses.CheckAwardedBadgesResponse? = nil
    public var UseItemGym: Pogoprotos.Networking.Responses.UseItemGymResponse? = nil
    public var GetGymDetails: Pogoprotos.Networking.Responses.GetGymDetailsResponse? = nil
    public var StartGymBattle: Pogoprotos.Networking.Responses.StartGymBattleResponse? = nil
    public var AttackGym: Pogoprotos.Networking.Responses.AttackGymResponse? = nil
    public var RecycleInventoryItem: Pogoprotos.Networking.Responses.RecycleInventoryItemResponse? = nil
    public var CollectDailyBonus: Pogoprotos.Networking.Responses.CollectDailyBonusResponse? = nil
    public var UseItemXpBoost: Pogoprotos.Networking.Responses.UseItemXpBoostResponse? = nil
    public var UseItemEggIncubator: Pogoprotos.Networking.Responses.UseItemEggIncubatorResponse? = nil
    public var UseIncense: Pogoprotos.Networking.Responses.UseIncenseResponse? = nil
    public var GetIncensePokemon: Pogoprotos.Networking.Responses.GetIncensePokemonResponse? = nil
    public var IncenseEncounter: Pogoprotos.Networking.Responses.IncenseEncounterResponse? = nil
    public var AddFortModifier: Pogoprotos.Networking.Responses.AddFortModifierResponse? = nil
    public var DiskEncounter: Pogoprotos.Networking.Responses.DiskEncounterResponse? = nil
    public var CollectDailyDefenderBonus: Pogoprotos.Networking.Responses.CollectDailyBonusResponse? = nil
    public var UpgradePokemon: Pogoprotos.Networking.Responses.UpgradePokemonResponse? = nil
    public var SetFavoritePokemon: Pogoprotos.Networking.Responses.SetFavoritePokemonResponse? = nil
    public var NicknamePokemon: Pogoprotos.Networking.Responses.NicknamePokemonResponse? = nil
    public var EquipBadge: Pogoprotos.Networking.Responses.EquipBadgeResponse? = nil
    public var SetContactSettings: Pogoprotos.Networking.Responses.SetContactSettingsResponse? = nil
    public var GetAssetDigest: Pogoprotos.Networking.Responses.GetAssetDigestResponse? = nil
    public var GetDownloadUrls: Pogoprotos.Networking.Responses.GetDownloadUrlsResponse? = nil
    public var GetSuggestedCodenames: Pogoprotos.Networking.Responses.GetSuggestedCodenamesResponse? = nil
    public var CheckCodenameAvailable: Pogoprotos.Networking.Responses.CheckCodenameAvailableResponse? = nil
    public var ClaimCodename: Pogoprotos.Networking.Responses.ClaimCodenameResponse? = nil
    public var SetAvatar: Pogoprotos.Networking.Responses.SetAvatarResponse? = nil
    public var SetPlayerTeam: Pogoprotos.Networking.Responses.SetPlayerTeamResponse? = nil
    public var MarkTutorialComplete: Pogoprotos.Networking.Responses.MarkTutorialCompleteResponse? = nil
    public var Echo: Pogoprotos.Networking.Responses.EchoResponse? = nil
    public var SfidaActionLog: Pogoprotos.Networking.Responses.SfidaActionLogResponse? = nil
    public var CheckChallenge: Pogoprotos.Networking.Responses.CheckChallengeResponse? = nil
    public var VerifyChallenge: Pogoprotos.Networking.Responses.VerifyChallengeResponse? = nil
}