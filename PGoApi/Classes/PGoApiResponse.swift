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
    public var playerUpdate: Pogoprotos.Networking.Responses.PlayerUpdateResponse? = nil
    public var getPlayer: Pogoprotos.Networking.Responses.GetPlayerResponse? = nil
    public var getInventory: Pogoprotos.Networking.Responses.GetInventoryResponse? = nil
    public var downloadSettings: Pogoprotos.Networking.Responses.DownloadSettingsResponse? = nil
    public var downloadItemTemplates: Pogoprotos.Networking.Responses.DownloadItemTemplatesResponse? = nil
    public var downloadRemoteConfigVersion: Pogoprotos.Networking.Responses.DownloadRemoteConfigVersionResponse? = nil
    public var fortSearch: Pogoprotos.Networking.Responses.FortSearchResponse? = nil
    public var encounterPokemon: Pogoprotos.Networking.Responses.EncounterResponse? = nil
    public var catchPokemon: Pogoprotos.Networking.Responses.CatchPokemonResponse? = nil
    public var fortDetails: Pogoprotos.Networking.Responses.FortDetailsResponse? = nil
    public var getMapObjects: Pogoprotos.Networking.Responses.GetMapObjectsResponse? = nil
    public var fortDeployPokemon: Pogoprotos.Networking.Responses.FortDeployPokemonResponse? = nil
    public var fortRecallPokemon: Pogoprotos.Networking.Responses.FortRecallPokemonResponse? = nil
    public var releasePokemon: Pogoprotos.Networking.Responses.ReleasePokemonResponse? = nil
    public var useItemPotion: Pogoprotos.Networking.Responses.UseItemPotionResponse? = nil
    public var useItemCapture: Pogoprotos.Networking.Responses.UseItemCaptureResponse? = nil
    public var useItemRevive: Pogoprotos.Networking.Responses.UseItemReviveResponse? = nil
    public var getPlayerProfile: Pogoprotos.Networking.Responses.GetPlayerProfileResponse? = nil
    public var evolvePokemon: Pogoprotos.Networking.Responses.EvolvePokemonResponse? = nil
    public var getHatchedEggs: Pogoprotos.Networking.Responses.GetHatchedEggsResponse? = nil
    public var encounterTutorialComplete: Pogoprotos.Networking.Responses.EncounterTutorialCompleteResponse? = nil
    public var levelUpRewards: Pogoprotos.Networking.Responses.LevelUpRewardsResponse? = nil
    public var checkAwardedBadges: Pogoprotos.Networking.Responses.CheckAwardedBadgesResponse? = nil
    public var useItemGym: Pogoprotos.Networking.Responses.UseItemGymResponse? = nil
    public var getGymDetails: Pogoprotos.Networking.Responses.GetGymDetailsResponse? = nil
    public var startGymBattle: Pogoprotos.Networking.Responses.StartGymBattleResponse? = nil
    public var attackGym: Pogoprotos.Networking.Responses.AttackGymResponse? = nil
    public var recycleInventoryItem: Pogoprotos.Networking.Responses.RecycleInventoryItemResponse? = nil
    public var collectDailyBonus: Pogoprotos.Networking.Responses.CollectDailyBonusResponse? = nil
    public var useItemXpBoost: Pogoprotos.Networking.Responses.UseItemXpBoostResponse? = nil
    public var useItemEggIncubator: Pogoprotos.Networking.Responses.UseItemEggIncubatorResponse? = nil
    public var useIncense: Pogoprotos.Networking.Responses.UseIncenseResponse? = nil
    public var getIncensePokemon: Pogoprotos.Networking.Responses.GetIncensePokemonResponse? = nil
    public var incenseEncounter: Pogoprotos.Networking.Responses.IncenseEncounterResponse? = nil
    public var addFortModifier: Pogoprotos.Networking.Responses.AddFortModifierResponse? = nil
    public var diskEncounter: Pogoprotos.Networking.Responses.DiskEncounterResponse? = nil
    public var collectDailyDefenderBonus: Pogoprotos.Networking.Responses.CollectDailyBonusResponse? = nil
    public var upgradePokemon: Pogoprotos.Networking.Responses.UpgradePokemonResponse? = nil
    public var setFavoritePokemon: Pogoprotos.Networking.Responses.SetFavoritePokemonResponse? = nil
    public var nicknamePokemon: Pogoprotos.Networking.Responses.NicknamePokemonResponse? = nil
    public var equipBadge: Pogoprotos.Networking.Responses.EquipBadgeResponse? = nil
    public var setContactSettings: Pogoprotos.Networking.Responses.SetContactSettingsResponse? = nil
    public var getAssetDigest: Pogoprotos.Networking.Responses.GetAssetDigestResponse? = nil
    public var getDownloadUrls: Pogoprotos.Networking.Responses.GetDownloadUrlsResponse? = nil
    public var getSuggestedCodenames: Pogoprotos.Networking.Responses.GetSuggestedCodenamesResponse? = nil
    public var checkCodenameAvailable: Pogoprotos.Networking.Responses.CheckCodenameAvailableResponse? = nil
    public var claimCodename: Pogoprotos.Networking.Responses.ClaimCodenameResponse? = nil
    public var setAvatar: Pogoprotos.Networking.Responses.SetAvatarResponse? = nil
    public var setPlayerTeam: Pogoprotos.Networking.Responses.SetPlayerTeamResponse? = nil
    public var markTutorialComplete: Pogoprotos.Networking.Responses.MarkTutorialCompleteResponse? = nil
    public var echo: Pogoprotos.Networking.Responses.EchoResponse? = nil
    public var sfidaActionLog: Pogoprotos.Networking.Responses.SfidaActionLogResponse? = nil
    public var checkChallenge: Pogoprotos.Networking.Responses.CheckChallengeResponse? = nil
    public var verifyChallenge: Pogoprotos.Networking.Responses.VerifyChallengeResponse? = nil
    public var registerBackgroundDevice: Pogoprotos.Networking.Responses.RegisterBackgroundDeviceResponse? = nil
}
