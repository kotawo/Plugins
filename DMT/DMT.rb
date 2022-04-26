#===============================================================================
# Deep Marsh Tiles - By Vendily [v17]
# Updated for v19.1 by Mashirosakura & Kotaro
#==============================================================================
#Config	
#Amount of turns needed to break free from being stuck in the ground.
MARSHTILES_TURN_TIMES = 5
#Name of the SoundFile that should be played when the Player gets "unstuck". 
MARSHTILES_JUMP_SOUND = "Player jump"
#Set to true if you want double battles inside of marsh tiles
DOUBLE_BATTLE = false
#set to false if you don't want always bushes on which mean you don't pop out when you are moving from 1 bush to another
ALWAYSBUSHON = true
#Set the Numbers bellow to a number that hasn't been used as a Terrain ID
MARSH_ID 	              = 20
DEEPMARSH_ID 	          = 21
MARSHGRASS_ID           = 22
DEEPMARSHGRASS_ID       = 23
TALLMARSHGRASS_ID       = 24
TALLDEEPMARSHGRASS_ID   = 25
#Chance for the player to sink into the ground the base 3 would mean 1/3 and so on.
CHANCE = 3
#==============================================================================
module GameData
  class TerrainTag
    attr_accessor :stuck
    attr_accessor :mudfree
    attr_reader   :marsh
	  attr_reader   :deep_marsh
    alias __stuckfreemud initialize
    def initialize(hash)
      __stuckfreemud(hash)
        @stuck         	= hash[:stuck]       		    || false
        @mudfree       	= hash[:mudfree]      	    || false
        @marsh  	      = hash[:marsh]   	          || false
		    @deep_marsh 	  = hash[:deep_marsh]    	    || false
    end
  end
end  

GameData::Environment.register({
  :id          => :Mud,
  :name        => _INTL("Mud"),
  :battle_base => "mud"
})

GameData::TerrainTag.register({
  :id                     => :Marsh,
  :id_number              => MARSH_ID,
  :marsh                  => true,
  :must_walk              => true
}) 

GameData::TerrainTag.register({
  :id                     => :DeepMarsh,
  :id_number              => DEEPMARSH_ID,
  :deep_marsh             => true,
  :must_walk              => true
}) 

GameData::TerrainTag.register({
  :id                     => :MarshGrass,
  :id_number              => MARSHGRASS_ID,
  :shows_grass_rustle     => true,  
  :marsh                  => true,
  :land_wild_encounters   => true,
  :double_wild_encounters => DOUBLE_BATTLE,
  :battle_environment     => :Mud,  
  :must_walk              => true
})

GameData::TerrainTag.register({
  :id                     => :DeepMarshGrass,
  :id_number              => DEEPMARSHGRASS_ID,
  :shows_grass_rustle     => true,  
  :deep_marsh             => true,
  :land_wild_encounters   => true,
  :double_wild_encounters => DOUBLE_BATTLE,
  :battle_environment     => :Mud,  
  :must_walk              => true
})

GameData::TerrainTag.register({
  :id                     => :TallMarshGrass,
  :id_number              => TALLMARSHGRASS_ID,
  :deep_bush              => true, 
  :marsh                  => true,
  :land_wild_encounters   => true,
  :double_wild_encounters => DOUBLE_BATTLE,
  :battle_environment     => :Mud,  
  :must_walk              => true
})

GameData::TerrainTag.register({
  :id                     => :TallDeepMarshGrass,
  :id_number              => TALLDEEPMARSHGRASS_ID,
  :deep_bush              => true, 
  :deep_marsh             => true,
  :land_wild_encounters   => true,
  :double_wild_encounters => DOUBLE_BATTLE,
  :battle_environment     => :Mud,  
  :must_walk              => true
})
#==============================================================================
class PokemonGlobalMetadata
  attr_accessor :stuck
  attr_accessor :mudfree
  
  def stuck
    @stuck=false if !@stuck
    return @stuck
  end
end

class Game_Character
  def calculate_bush_depth
    if @tile_id > 0 || @always_on_top || jumping?
      @bush_depth = 0
    else
      deep_bush = regular_bush = false
      xbehind = @x + (@direction == 4 ? 1 : @direction == 6 ? -1 : 0)
      ybehind = @y + (@direction == 8 ? 1 : @direction == 2 ? -1 : 0)
      this_map = (self.map.valid?(@x, @y)) ? [self.map, @x, @y] : $MapFactory.getNewMap(@x, @y)
      if this_map[0].deepBush?(this_map[1], this_map[2]) && self.map.deepBush?(xbehind, ybehind)
        @bush_depth = Game_Map::TILE_HEIGHT
      elsif (!moving? && this_map[0].bush?(this_map[1], this_map[2])) || (self==$game_player && $PokemonGlobal.stuck)
        @bush_depth = 12
      elsif ALWAYSBUSHON == true && moving? && this_map[0].bush?(this_map[1], this_map[2]) && self.map.bush?(xbehind, ybehind) || (self==$game_player && $PokemonGlobal.stuck)
        @bush_depth = 12  		
      else
        @bush_depth = 0
      end
    end
  end
end
#==============================================================================
Events.onStepTakenFieldMovement+=proc {|sender,e|
  event = e[0] # Get the event affected by field movement
  if $scene.is_a?(Scene_Map)
	  chance = (1..CHANCE).to_a.sample  
    currentTag = $game_player.pbTerrainTag
    if event==$game_player && currentTag.deep_marsh && !$PokemonGlobal.mudfree
      pbStuckTile(event)
    elsif event==$game_player && currentTag.marsh && !$PokemonGlobal.mudfree && chance==3
      pbStuckTile(event)
    end
  end
}
#==============================================================================
def pbOnStepTaken(eventTriggered)
  if $game_player.move_route_forcing || pbMapInterpreterRunning?
    Events.onStepTakenFieldMovement.trigger(nil,$game_player)
    return
  end
  $PokemonGlobal.stepcount = 0 if !$PokemonGlobal.stepcount
  $PokemonGlobal.stepcount += 1
  $PokemonGlobal.stepcount &= 0x7FFFFFFF
  repel_active = ($PokemonGlobal.repel > 0)
  Events.onStepTaken.trigger(nil)
#  Events.onStepTakenFieldMovement.trigger(nil,$game_player)
  handled = [nil]
  Events.onStepTakenTransferPossible.trigger(nil,handled)
  return if handled[0]
  pbBattleOnStepTaken(repel_active) if !eventTriggered && !$game_temp.in_menu && $PokemonGlobal.stuck #by Kota
  $PokemonTemp.encounterTriggered = false   # This info isn't needed here
end
#==============================================================================
def pbStuckTile(event=nil)
  event = $game_player if !event
  return if !event
  $PokemonGlobal.stuck=true
  event.straighten
  event.calculate_bush_depth
  olddir=event.direction
  dir=olddir
  turntimes=0
  loop do
    break if turntimes>=MARSHTILES_TURN_TIMES
    Graphics.update
    Input.update
    pbUpdateSceneMap
    key=Input.dir4
    dir=key if key>0
    if dir!=olddir
      case dir
        when 2 then $game_player.turn_down
        when 4 then $game_player.turn_left
        when 6 then $game_player.turn_right
        when 8 then $game_player.turn_up
      end
      olddir=dir
      turntimes+=1
    end
  end
  event.center(event.x,event.y)
  event.straighten
  $PokemonGlobal.stuck=false
  $PokemonGlobal.mudfree=true
  event.jump(0,0)
  pbSEPlay(MARSHTILES_JUMP_SOUND)
  20.times do
    Graphics.update
    Input.update
    pbUpdateSceneMap
  end
  $PokemonGlobal.mudfree=false
end
#==============================================================================