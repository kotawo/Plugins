#===============================================================================
#Moves that need changes need to be updated here to not cause issues since 
#evasion doesn't work anymore and instead raised glanced hit chance
#===============================================================================
class PokeBattle_Move
    #=============================================================================
    # Messages upon being hit
    #=============================================================================
    def pbHitEffectivenessMessages(user,target,numTargets=1)
      return if target.damageState.disguise
      if target.damageState.substitute
        @battle.pbDisplay(_INTL("The substitute took damage for {1}!",target.pbThis(true)))
      end
      if target.damageState.critical
        if numTargets>1
          @battle.pbDisplay(_INTL("A critical hit on {1}!",target.pbThis(true)))
        else
          @battle.pbDisplay(_INTL("A critical hit!"))
        end
      end
      if target.damageState.glanced               #by Kota
        if numTargets>1
          @battle.pbDisplay(_INTL("A glanced hit on {1}!",target.pbThis(true)))
        else
          @battle.pbDisplay(_INTL("A glanced hit!"))
        end
      end
      # Effectiveness message, for moves with 1 hit
      if !multiHitMove? && user.effects[PBEffects::ParentalBond]==0
        pbEffectivenessMessage(user,target,numTargets)
      end
      if target.damageState.substitute && target.effects[PBEffects::Substitute]==0
        target.effects[PBEffects::Substitute] = 0
        @battle.pbDisplay(_INTL("{1}'s substitute faded!",target.pbThis))
      end
    end
  end
  #===============================================================================
  # Increases the user's evasion by 1 stage. (Double Team)    #by Kota
  #===============================================================================
  class PokeBattle_Move_022 < PokeBattle_Move
    def pbMoveFailed?(user,targets)
      if user.effects[PBEffects::Glanced]>=6
        @battle.pbDisplay(_INTL("But it failed!"))
        return true
      end
      return false
    end
  
    def pbEffectGeneral(user)
      user.effects[PBEffects::Glanced] += 1
      @battle.pbDisplay(_INTL("{1} goes out of focus!",user.pbThis))
    end
  end
  #===============================================================================
  # Increases the user's evasion by 2 stages. Minimizes the user. (Minimize)      #by Kota
  #===============================================================================
  class PokeBattle_Move_034 < PokeBattle_Move
    def pbMoveFailed?(user,targets)
      if user.effects[PBEffects::Glanced]>=6
        @battle.pbDisplay(_INTL("But it failed!"))
        return true
      end
      return false
    end
  
    def pbEffectGeneral(user)
      user.effects[PBEffects::Glanced] += 2
      @battle.pbDisplay(_INTL("{1} goes out of focus!",user.pbThis))
    end
  end
  #===============================================================================
  # Decreases the target's evasion by 1 stage OR 2 stages. (Sweet Scent)    #by Kota
  #===============================================================================
  class PokeBattle_Move_048 < PokeBattle_Move
    def pbFailsAgainstTarget?(user,target)
      targetSide = target.pbOwnSide
      if targetSide.effects[PBEffects::Glanced]=0
        @battle.pbDisplay(_INTL("But it failed!"))
        return true
      end
      return false
    end
  
    def pbEffectGeneral(target)
      target.effects[PBEffects::Glanced] -= 1
      @battle.pbDisplay(_INTL("{1}'s vision clears!",target.pbThis))
    end
  end
  #===============================================================================
  # Decreases the target's evasion by 1 stage. Ends all barriers and entry
  # hazards for the target's side OR on both sides. (Defog)  #by Kota
  #===============================================================================
  class PokeBattle_Move_049 < PokeBattle_TargetStatDownMove
    def ignoresSubstitute?(user); return true; end
  
    def pbFailsAgainstTarget?(user,target)
      targetSide = target.pbOwnSide
      targetOpposingSide = target.pbOpposingSide
      return false if targetSide.effects[PBEffects::AuroraVeil]>0 ||
                      targetSide.effects[PBEffects::LightScreen]>0 ||
                      targetSide.effects[PBEffects::Reflect]>0 ||
                      targetSide.effects[PBEffects::Mist]>0 ||
                      targetSide.effects[PBEffects::Safeguard]>0
      return false if targetSide.effects[PBEffects::StealthRock] ||
                      targetSide.effects[PBEffects::Spikes]>0 ||
                      targetSide.effects[PBEffects::ToxicSpikes]>0 ||
                      targetSide.effects[PBEffects::StickyWeb]
      return false if Settings::MECHANICS_GENERATION >= 6 &&
                      (targetOpposingSide.effects[PBEffects::StealthRock] ||
                      targetOpposingSide.effects[PBEffects::Spikes]>0 ||
                      targetOpposingSide.effects[PBEffects::ToxicSpikes]>0 ||
                      targetOpposingSide.effects[PBEffects::StickyWeb])
      return false if Settings::MECHANICS_GENERATION >= 8 && @battle.field.terrain != :None
      if targetSide.effects[PBEffects::Glanced]=0     #by Kota
        @battle.pbDisplay(_INTL("But it failed!"))
        return true
      end
      return false
      return super
    end
    
    def pbEffectGeneral(target)           #by Kota
      target.effects[PBEffects::Glanced] -= 1
      @battle.pbDisplay(_INTL("{1}'s vision clears!",target.pbThis))
    end
  
    def pbEffectAgainstTarget(user,target)
      if target.pbCanLowerStatStage?(@statDown[0],user,self)
        target.pbLowerStatStage(@statDown[0],@statDown[1],user)
      end
      if target.pbOwnSide.effects[PBEffects::AuroraVeil]>0
        target.pbOwnSide.effects[PBEffects::AuroraVeil] = 0
        @battle.pbDisplay(_INTL("{1}'s Aurora Veil wore off!",target.pbTeam))
      end
      if target.pbOwnSide.effects[PBEffects::LightScreen]>0
        target.pbOwnSide.effects[PBEffects::LightScreen] = 0
        @battle.pbDisplay(_INTL("{1}'s Light Screen wore off!",target.pbTeam))
      end
      if target.pbOwnSide.effects[PBEffects::Reflect]>0
        target.pbOwnSide.effects[PBEffects::Reflect] = 0
        @battle.pbDisplay(_INTL("{1}'s Reflect wore off!",target.pbTeam))
      end
      if target.pbOwnSide.effects[PBEffects::Mist]>0
        target.pbOwnSide.effects[PBEffects::Mist] = 0
        @battle.pbDisplay(_INTL("{1}'s Mist faded!",target.pbTeam))
      end
      if target.pbOwnSide.effects[PBEffects::Safeguard]>0
        target.pbOwnSide.effects[PBEffects::Safeguard] = 0
        @battle.pbDisplay(_INTL("{1} is no longer protected by Safeguard!!",target.pbTeam))
      end
      if target.pbOwnSide.effects[PBEffects::StealthRock] ||
         (Settings::MECHANICS_GENERATION >= 6 &&
         target.pbOpposingSide.effects[PBEffects::StealthRock])
        target.pbOwnSide.effects[PBEffects::StealthRock]      = false
        target.pbOpposingSide.effects[PBEffects::StealthRock] = false if Settings::MECHANICS_GENERATION >= 6
        @battle.pbDisplay(_INTL("{1} blew away stealth rocks!",user.pbThis))
      end
      if target.pbOwnSide.effects[PBEffects::Spikes]>0 ||
         (Settings::MECHANICS_GENERATION >= 6 &&
         target.pbOpposingSide.effects[PBEffects::Spikes]>0)
        target.pbOwnSide.effects[PBEffects::Spikes]      = 0
        target.pbOpposingSide.effects[PBEffects::Spikes] = 0 if Settings::MECHANICS_GENERATION >= 6
        @battle.pbDisplay(_INTL("{1} blew away spikes!",user.pbThis))
      end
      if target.pbOwnSide.effects[PBEffects::ToxicSpikes]>0 ||
         (Settings::MECHANICS_GENERATION >= 6 &&
         target.pbOpposingSide.effects[PBEffects::ToxicSpikes]>0)
        target.pbOwnSide.effects[PBEffects::ToxicSpikes]      = 0
        target.pbOpposingSide.effects[PBEffects::ToxicSpikes] = 0 if Settings::MECHANICS_GENERATION >= 6
        @battle.pbDisplay(_INTL("{1} blew away poison spikes!",user.pbThis))
      end
      if target.pbOwnSide.effects[PBEffects::StickyWeb] ||
         (Settings::MECHANICS_GENERATION >= 6 &&
         target.pbOpposingSide.effects[PBEffects::StickyWeb])
        target.pbOwnSide.effects[PBEffects::StickyWeb]      = false
        target.pbOpposingSide.effects[PBEffects::StickyWeb] = false if Settings::MECHANICS_GENERATION >= 6
        @battle.pbDisplay(_INTL("{1} blew away sticky webs!",user.pbThis))
      end
      if Settings::MECHANICS_GENERATION >= 8 && @battle.field.terrain != :None
        case @battle.field.terrain
        when :Electric
          @battle.pbDisplay(_INTL("The electricity disappeared from the battlefield."))
        when :Grassy
          @battle.pbDisplay(_INTL("The grass disappeared from the battlefield."))
        when :Misty
          @battle.pbDisplay(_INTL("The mist disappeared from the battlefield."))
        when :Psychic
          @battle.pbDisplay(_INTL("The weirdness disappeared from the battlefield."))
        end
        @battle.field.terrain = :None
      end
    end
  end
  #===============================================================================