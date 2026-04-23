import Foundation

@Observable
final class ResultViewModel {
    var canClaimMissionBonus: Bool = false
    var missionBonusClaimed: Bool = false
    var missionBonusXP: Int = 0

    func checkMissionBonus() {
        let mission = DataStore.loadDailyMission()
        canClaimMissionBonus = mission.playCount >= DailyMission.requiredPlays && !mission.claimed
        missionBonusClaimed = mission.claimed
    }

    func claimMissionBonus(gameVM: GameViewModel) {
        if let xp = DataStore.claimDailyMissionBonus() {
            missionBonusXP = xp
            _ = DataStore.addXP(xp, to: &gameVM.playerData)
            DataStore.savePlayerData(gameVM.playerData)
            missionBonusClaimed = true
            canClaimMissionBonus = false
        }
    }
}
