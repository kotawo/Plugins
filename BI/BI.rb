#==============================================================================
# Better Itemfinder by Kotaro [v19.1]
#============================================================================== 
# Config   
# Paste this line into your items.txt with a new ID the (first number) if that
# already exists.
# 690,ITEMFINDEROFF,Itemfinder,Itemfinders,8,0,"A device used for finding items. If there is a hidden item nearby when it is used, it emits a signal.",2,0,6,
# Also cut the ITEMFINDEROFF.png from the Plugins folder and paste it into Graphics/Items
arrowMap = ChangelingSprite.new(240,140,@viewport) 
#==============================================================================
ItemHandlers::UseInField.add(:ITEMFINDER,proc { |item|
    $PokemonBag.pbChangeItem(:ITEMFINDER,:ITEMFINDEROFF)
    arrowMap.visible = false
    pbMessage(_INTL("The Item Finder was turned off."))
    next 1
})  
ItemHandlers::UseInField.add(:ITEMFINDEROFF,proc { |item|
    $PokemonBag.pbChangeItem(:ITEMFINDEROFF,:ITEMFINDER)
    pbMessage(_INTL("The Item Finder was turned on."))
    next 1
})
#==============================================================================
if PBDayNight.isNight?
  ITEMFINDERTINT = true
else
  ITEMFINDERTINT = false
end
#==============================================================================
def updateDirection(arrowMap)
    event = pbClosestHiddenItem
    tinting=ITEMFINDERTINT
    id=Settings::EXCLAMATION_ANIMATION_ID
    arrowMap.visible = true
    arrowMap.addBitmap("down","Plugins/BI/Graphics/downArrow")
    arrowMap.addBitmap("left","Plugins/BI/Graphics/leftArrow")
    arrowMap.addBitmap("right","Plugins/BI/Graphics/rightArrow")
    arrowMap.addBitmap("up","Plugins/BI/Graphics/upArrow")
    arrowMap.addBitmap("no","Plugins/BI/Graphics/noItem")
    pbDayNightTint(arrowMap)    
    if !event
      arrowMap.changeBitmap("no")
    else
      offsetX = event.x-$game_player.x
      offsetY = event.y-$game_player.y
      if offsetX==0 && offsetY==0   # Standing on the item, play exclamation mark + spin around
        $scene.spriteset.addUserAnimation(id,$game_player.x-0.2,$game_player.y-0.5,tinting,2)
        4.times do
          pbWait(Graphics.frame_rate*2/10)
          $game_player.turn_right_90
        end
        $scene.spriteset.addUserAnimation(id,$game_player.x-0.2,$game_player.y-0.5,tinting,2)
        pbWait(Graphics.frame_rate*3/10) 
      else   # Item is nearby, create the arrow to locate it
        direction = $game_player.direction
        if offsetX.abs>offsetY.abs
          direction = (offsetX<0) ? 4 : 6
        else
          direction = (offsetY<0) ? 8 : 2
        end
        case direction
        when 2 then arrowMap.changeBitmap("down")
        when 4 then arrowMap.changeBitmap("left")
        when 6 then arrowMap.changeBitmap("right")
        when 8 then arrowMap.changeBitmap("up")
        end
      end
    end
end  
#==============================================================================
Events.onStepTaken += proc {
    if (GameData::Item.exists?(:ITEMFINDER) && $PokemonBag.pbHasItem?(:ITEMFINDER))
      updateDirection(arrowMap)
    else
      arrowMap.visible = false  
    end
} 
#==============================================================================