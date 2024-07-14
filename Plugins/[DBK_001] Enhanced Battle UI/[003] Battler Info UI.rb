#===============================================================================
# Battle Info UI
#===============================================================================
class Battle::Scene
  #-----------------------------------------------------------------------------
  # Handles the controls for the Battle Info UI.
  #-----------------------------------------------------------------------------
  def pbOpenBattlerInfo(battler, battlers)
    return if @enhancedUIToggle != :battler
    ret = nil
    idx = 0
    battlerTotal = battlers.flatten
    for i in 0...battlerTotal.length
      idx = i if battler == battlerTotal[i]
    end
    maxSize = battlerTotal.length - 1
    idxEffect = 0
    effects = pbGetDisplayEffects(battler)
    effctSize = effects.length - 1
    pbUpdateBattlerInfo(battler, effects, idxEffect)
    cw = @sprites["fightWindow"]
    @sprites["leftarrow"].x = -2
    @sprites["leftarrow"].y = 71
    @sprites["leftarrow"].visible = true
    @sprites["rightarrow"].x = Graphics.width - 38
    @sprites["rightarrow"].y = 71
    @sprites["rightarrow"].visible = true
    loop do
      pbUpdate(cw)
      pbUpdateSpriteHash(@sprites)
      break if Input.trigger?(Input::BACK)
      if Input.trigger?(Input::LEFT)
        idx -= 1
        idx = maxSize if idx < 0
        doFullRefresh = true
      elsif Input.trigger?(Input::RIGHT)
        idx += 1
        idx = 0 if idx > maxSize
        doFullRefresh = true
      elsif Input.repeat?(Input::UP) && effects.length > 1
        idxEffect -= 1
        idxEffect = effctSize if idxEffect < 0
        doRefresh = true
      elsif	Input.repeat?(Input::DOWN) && effects.length > 1
        idxEffect += 1
        idxEffect = 0 if idxEffect > effctSize
        doRefresh = true
      elsif Input.trigger?(Input::JUMPDOWN)
        if cw.visible
          ret = 1
          break
        elsif @battle.pbCanUsePokeBall?(@sprites["enhancedUIPrompts"].battler)
          ret = 2
          break
        end
      elsif Input.trigger?(Input::JUMPUP) || Input.trigger?(Input::USE)
        ret = []
        if battler.opposes?
          ret.push(1)
          @battle.allOtherSideBattlers.reverse.each_with_index do |b, i| 
            next if b.index != battler.index
            ret.push(i)
          end
        else
          ret.push(0)
          @battle.allSameSideBattlers.each_with_index do |b, i| 
            next if b.index != battler.index
            ret.push(i)
          end
        end
        pbPlayDecisionSE
        break
      end
      if doFullRefresh
        battler = battlerTotal[idx]
        effects = pbGetDisplayEffects(battler)
        effctSize = effects.length - 1
        idxEffect = 0
        doRefresh = true
      end
      if doRefresh
        pbPlayCursorSE
        pbUpdateBattlerInfo(battler, effects, idxEffect)
        doRefresh = false
        doFullRefresh = false
      end
    end
    @sprites["leftarrow"].visible = false
    @sprites["rightarrow"].visible = false
    return ret
  end
  
  #-----------------------------------------------------------------------------
  # Draws the Battle Info UI.
  #-----------------------------------------------------------------------------
  def pbUpdateBattlerInfo(battler, effects, idxEffect = 0)
    @enhancedUIOverlay.clear
    pbUpdateBattlerIcons
    return if @enhancedUIToggle != :battler
    xpos = 28
    ypos = 24
    iconX = xpos + 28
    iconY = ypos + 62
    panelX = xpos + 240
    #---------------------------------------------------------------------------
    # General UI elements.
    poke = (battler.opposes?) ? battler.displayPokemon : battler.pokemon
    imagePos = [[@path + "info_bg", 0, 0],
                [@path + "info_bg_data", 0, 0],
                [@path + "info_gender", xpos + 146, ypos + 24, poke.gender * 22, 0, 22, 20]]
    textPos  = [[_INTL("{1}", poke.name), iconX + 82, iconY - 16, :center, BASE_DARK, SHADOW_DARK],
                [_INTL("Nv. {1}", battler.level), xpos + 16, ypos + 106, :left, BASE_LIGHT, SHADOW_LIGHT],
                [_INTL("Turno {1}", @battle.turnCount + 1), Graphics.width - xpos - 32, ypos + 6, :center, BASE_LIGHT, SHADOW_LIGHT]]
    #---------------------------------------------------------------------------
    # Battler icon.
    @battle.allBattlers.each do |b|
      @sprites["info_icon#{b.index}"].x = iconX
      @sprites["info_icon#{b.index}"].y = iconY
      @sprites["info_icon#{b.index}"].visible = (b.index == battler.index)
    end            
    #---------------------------------------------------------------------------
    # Battler HP.
    if battler.hp > 0
      w = battler.hp * 96 / battler.totalhp.to_f
      w = 1 if w < 1
      w = ((w / 2).round) * 2
      hpzone = 0
      hpzone = 1 if battler.hp <= (battler.totalhp / 2).floor
      hpzone = 2 if battler.hp <= (battler.totalhp / 4).floor
      imagePos.push(["Graphics/UI/Battle/overlay_hp", 86, 88, 0, hpzone * 6, w, 6])
    end
    # Battler status.
    if battler.status != :NONE
      iconPos = GameData::Status.get(battler.status).icon_position
      imagePos.push(["Graphics/UI/statuses", xpos + 86, ypos + 104, 0, iconPos * 16, 44, 16])
    end
    # Shininess
    imagePos.push(["Graphics/UI/shiny", xpos + 142, ypos + 104]) if poke.shiny?
    # Owner
    if !battler.wild?
      imagePos.push([@path + "info_owner", xpos - 34, ypos + 4])
      textPos.push([@battle.pbGetOwnerFromBattlerIndex(battler.index).name, xpos + 32, ypos + 6, :center, BASE_LIGHT, SHADOW_LIGHT])
    end
    # Battler's last move used.
    if battler.lastMoveUsed
      movename = GameData::Move.get(battler.lastMoveUsed).name
      movename = movename[0..12] + "..." if movename.length > 16
      textPos.push([_INTL("Used: {1}", movename), xpos + 348, ypos + 106, :center, BASE_LIGHT, SHADOW_LIGHT])
    end
    #---------------------------------------------------------------------------
    # Battler info for player-owned Pokemon.
    if battler.pbOwnedByPlayer?
      imagePos.push(
        [@path + "info_owner", xpos + 36, iconY + 10],
        [@path + "info_cursor", panelX, 64, 0, 0, 218, 24],
        [@path + "info_cursor", panelX, 88, 0, 0, 218, 24]
      )
      textPos.push(
        [_INTL("Abil."), xpos + 272, ypos + 44, :center, BASE_LIGHT, SHADOW_LIGHT],
        [_INTL("Item"), xpos + 272, ypos + 68, :center, BASE_LIGHT, SHADOW_LIGHT],
        [_INTL("{1}", battler.abilityName), xpos + 376, ypos + 44, :center, BASE_DARK, SHADOW_DARK],
        [_INTL("{1}", battler.itemName), xpos + 376, ypos + 68, :center, BASE_DARK, SHADOW_DARK],
        [sprintf("%d/%d", battler.hp, battler.totalhp), iconX + 74, iconY + 12, :center, BASE_LIGHT, SHADOW_LIGHT]
      )
    end
    #---------------------------------------------------------------------------
    pbAddWildIconDisplay(xpos, ypos, battler, imagePos)
    pbAddStatsDisplay(xpos, ypos, battler, imagePos, textPos)
    pbDrawImagePositions(@enhancedUIOverlay, imagePos)
    pbDrawTextPositions(@enhancedUIOverlay, textPos)
    pbAddTypesDisplay(xpos, ypos, battler, poke)
    pbAddEffectsDisplay(xpos, ypos, panelX, effects, idxEffect)
  end
  
  #-----------------------------------------------------------------------------
  # Draws additional icons on wild Pokemon to display cosmetic attributes.
  #-----------------------------------------------------------------------------
  def pbAddWildIconDisplay(xpos, ypos, battler, imagePos)
    return if !battler.wild?
    images = []
    pkmn = battler.pokemon
    #---------------------------------------------------------------------------
    # Checks if the wild Pokemon has at least one Shiny Leaf.
    if defined?(pkmn.shiny_leaf) && pkmn.shiny_leaf > 0
      images.push([Settings::POKEMON_UI_GRAPHICS_PATH + "leaf", 12, 10])
    end
    #---------------------------------------------------------------------------
    # Checks if the wild Pokemon's size is small or large.
    if defined?(pkmn.scale)
      case pkmn.scale
      when 0..59
        images.push([Settings::MEMENTOS_GRAPHICS_PATH + "size_icon", 6, 2, 0, 0, 28, 28])
      when 196..255
        images.push([Settings::MEMENTOS_GRAPHICS_PATH + "size_icon", 6, 4, 28, 0, 28, 28])
      end
    end
    #---------------------------------------------------------------------------
    # Checks if the wild Pokemon has a mark.
    if defined?(pkmn.memento) && pkmn.hasMementoType?(:mark)
      images.push([Settings::MEMENTOS_GRAPHICS_PATH + "memento_icon", 6, 4, 0, 0, 28, 28])
    end
    #---------------------------------------------------------------------------
    # Draws all cosmetic icons.
    if !images.empty?
      offset = images.length - 1
      baseX = xpos + 328 - offset * 26
      baseY = ypos + 42
      images.each_with_index do |img, i|
        imagePos.push([@path + "info_extra", baseX + (50 * i), baseY])
        img[1] += baseX + (50 * i)
        img[2] += baseY
        imagePos.push(img)
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Draws the battler's stats and stat stages.
  #-----------------------------------------------------------------------------
  def pbAddStatsDisplay(xpos, ypos, battler, imagePos, textPos)
    [[:ATTACK,          _INTL("Ataque")],
     [:DEFENSE,         _INTL("Defensa")], 
     [:SPECIAL_ATTACK,  _INTL("At. Esp")], 
     [:SPECIAL_DEFENSE, _INTL("Def. Esp")], 
     [:SPEED,           _INTL("Velocidad")], 
     [:ACCURACY,        _INTL("Precisión")], 
     [:EVASION,         _INTL("Evasión")],
     _INTL("Prob. Crít.")
    ].each_with_index do |stat, i|
      if stat.is_a?(Array)
        color = SHADOW_LIGHT
        if battler.pbOwnedByPlayer?
          battler.pokemon.nature_for_stats.stat_changes.each do |s|
            if stat[0] == s[0]
              color = Color.new(136, 96, 72)  if s[1] > 0 # Red Nature text.
              color = Color.new(64, 120, 152) if s[1] < 0 # Blue Nature text.
            end
          end
        end
        textPos.push([stat[1], xpos + 17, ypos + 138 + (i * 24), :left, BASE_LIGHT, color])
        stage = battler.stages[stat[0]]
      else
        textPos.push([stat, xpos + 17, ypos + 138 + (i * 24), :left, BASE_LIGHT, SHADOW_LIGHT])
        stage = battler.effects[PBEffects::FocusEnergy]
      end
      if stage != 0
        arrow = (stage > 0) ? 0 : 18
        stage.abs.times do |t| 
          imagePos.push([@path + "info_stats", xpos + 104 + (t * 18), ypos + 138 + (i * 24), arrow, 0, 18, 18])
        end
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Draws the battler's typing.
  #-----------------------------------------------------------------------------
  def pbAddTypesDisplay(xpos, ypos, battler, poke)
    #---------------------------------------------------------------------------
    # Gets display types (considers Illusion)
    illusion = battler.effects[PBEffects::Illusion] && !battler.pbOwnedByPlayer?
    if battler.tera?
      displayTypes = (illusion) ? poke.types.clone : battler.pbPreTeraTypes
    elsif illusion
      displayTypes = poke.types.clone
      displayTypes.push(battler.effects[PBEffects::ExtraType]) if battler.effects[PBEffects::ExtraType]
    else
      displayTypes = battler.pbTypes(true)
    end
    #---------------------------------------------------------------------------
    # Displays the "???" type on newly encountered species, or battlers with no typing.
    unknown_species = !(
	  !@battle.internalBattle ||
      battler.pbOwnedByPlayer? ||
      $player.pokedex.owned?(poke.species) ||
      $player.pokedex.battled_count(poke.species) > 0
    )
    unknown_species = false if Settings::SHOW_TYPE_EFFECTIVENESS_FOR_NEW_SPECIES
    unknown_species = true if battler.celestial?
    displayTypes = [:QMARKS] if unknown_species || displayTypes.empty?
    #---------------------------------------------------------------------------
    # Draws each display type. Maximum of 3 types.
    typeY = (displayTypes.length >= 3) ? ypos + 6 : ypos + 34
    typebitmap = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
    displayTypes.each_with_index do |type, i|
      break if i > 2
      type_number = GameData::Type.get(type).icon_position
      type_rect = Rect.new(0, type_number * 28, 64, 28)
      @enhancedUIOverlay.blt(xpos + 170, typeY + (i * 30), typebitmap.bitmap, type_rect)
    end
    #---------------------------------------------------------------------------
    # Draws Tera type.
    showTera = defined?(battler.tera_type) && battler.pokemon.terastal_able?
    if battler.tera? || showTera && (battler.pbOwnedByPlayer? || !@battle.internalBattle)
      pkmn = (illusion) ? poke : battler
      pbDrawImagePositions(@enhancedUIOverlay, [[@path + "info_extra", xpos + 182, ypos + 95]])
      pbDisplayTeraType(pkmn, @enhancedUIOverlay, xpos + 186, ypos + 97, true)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Draws the effects in play that are affecting the battler.
  #-----------------------------------------------------------------------------
  def pbAddEffectsDisplay(xpos, ypos, panelX, effects, idxEffect)
    return if effects.empty?
    idxLast = effects.length - 1
    offset = idxLast - 1
    if idxEffect < 4
      idxDisplay = idxEffect
    elsif [idxLast, offset].include?(idxEffect)
      idxDisplay = idxEffect
      idxDisplay -= 1 if idxDisplay == offset && offset < 5
    else
      idxDisplay = 3   
    end
    idxStart = (idxEffect > 3) ? idxEffect - 3 : 0
    if idxLast - idxEffect > 0
      idxEnd = idxStart + 4
    else
      idxStart = (idxLast - 4 > 0) ? idxLast - 4 : 0
      idxEnd = idxLast
    end
    textPos = []
    imagePos = [
      [@path + "info_effects", xpos + 240, ypos + 258],
      [@path + "info_slider_base", panelX + 222, ypos + 134]
    ]
    #---------------------------------------------------------------------------
    # Draws the slider.
    #---------------------------------------------------------------------------
    if effects.length > 5
      imagePos.push([@path + "info_slider", panelX + 222, ypos + 134, 0, 0, 18, 19]) if idxEffect > 3
      imagePos.push([@path + "info_slider", panelX + 222, ypos + 235, 0, 19, 18, 19]) if idxEffect < idxLast - 1
      sliderheight = 82
      boxheight = (sliderheight * 4 / idxLast).floor
      boxheight += [(sliderheight - boxheight) / 2, sliderheight / 4].min
      boxheight = [boxheight.floor, 18].max
      y = ypos + 154
      y += ((sliderheight - boxheight) * idxStart / (idxLast - 4)).floor
      imagePos.push([@path + "info_slider", panelX + 222, y, 18, 0, 18, 4])
      i = 0
      while i * 7 < boxheight - 2 - 7
        height = [boxheight - 2 - 7 - (i * 7), 7].min
        offset = y + 2 + (i * 7)
        imagePos.push([@path + "info_slider", panelX + 222, offset, 18, 2, 18, height])
        i += 1
      end
      imagePos.push([@path + "info_slider", panelX + 222, y + boxheight - 6 - 7, 18, 9, 18, 12])
    end
    #---------------------------------------------------------------------------
    # Draws each effect and the cursor.
    #---------------------------------------------------------------------------
    effects[idxStart..idxEnd].each_with_index do |effect, i|
      real_idx = effects.find_index(effect)
      if i == idxDisplay || idxEffect == real_idx
        imagePos.push([@path + "info_cursor", panelX, ypos + 134 + (i * 24), 0, 48, 218, 24])
      else
        imagePos.push([@path + "info_cursor", panelX, ypos + 134 + (i * 24), 0, 24, 218, 24])
      end
      textPos.push([effect[0], xpos + 322, ypos + 138 + (i * 24), :center, BASE_DARK, SHADOW_DARK],
                   [effect[1], xpos + 426, ypos + 138 + (i * 24), :center, BASE_LIGHT, SHADOW_LIGHT])
    end
    pbDrawImagePositions(@enhancedUIOverlay, imagePos)
    pbDrawTextPositions(@enhancedUIOverlay, textPos)
    desc = effects[idxEffect][2]
    drawFormattedTextEx(@enhancedUIOverlay, xpos + 246, ypos + 268, 208, desc, BASE_LIGHT, SHADOW_LIGHT, 18)
  end
  
  #-----------------------------------------------------------------------------
  # Utility for getting an array of all effects that may be displayed.
  #-----------------------------------------------------------------------------
  def pbGetDisplayEffects(battler)
    display_effects = []
    #---------------------------------------------------------------------------
    # Special states.
    if battler.dynamax?
      if battler.effects[PBEffects::Dynamax] > 0 && !battler.isRaidBoss?
        tick = sprintf("%d/%d", battler.effects[PBEffects::Dynamax], Settings::DYNAMAX_TURNS)
      else
        tick = "--"
      end
      desc = _INTL("El Pokémon está Dinamaxizado.")
      display_effects.push([_INTL("Dinamax"), tick, desc])
    elsif battler.tera?
      data = GameData::Type.get(battler.tera_type).name
      desc = _INTL("El Pokémon se ha terastalizado al tipo {1}.", data)
      display_effects.push([_INTL("Terastalización"), "--", desc])
    end
    #---------------------------------------------------------------------------
    # Weather
    weather = battler.effectiveWeather
    if weather != :None
      if weather == :Hail
        name = GameData::BattleWeather.get(weather).name
        desc = _INTL("Pokémon que no son de hielo reciben daño. Ventisca siempre acierta.")
        if defined?(Settings::HAIL_WEATHER_TYPE)
          case Settings::HAIL_WEATHER_TYPE
          when 1
            name = _INTL("Nevada")
            desc = _INTL("Sube defensa de tipo hielo. Ventisca siempre acierta.")
          when 2
            name = _INTL("Granizo")
            desc = _INTL("Combina hielo y nieve.")
          end
        end
      else
        name = GameData::BattleWeather.get(weather).name
      end
      tick = (weather == @battle.field.weather) ? @battle.field.weatherDuration : 0
      tick = (tick > 0) ? sprintf("%d/%d", tick, 5) : "--"
      case weather
      when :Sun         then desc = _INTL("Aumenta daño tipo fuego y reduce daño agua.")
      when :HarshSun    then desc = _INTL("Aumenta daño tipo fuego y anula mov. agua.")
      when :Rain        then desc = _INTL("Aumenta daño tipo agua y reduce daño fuego.")
      when :HeavyRain   then desc = _INTL("Aumenta daño tipo agua y anula mov. fuego.")
      when :Snow        then desc = _INTL("Sube defensa de tipo hielo. Ventisca siempre acierta.")
      when :Sandstorm   then desc = _INTL("Aumenta Def. Esp tipo roca. Hace daño salvo Roca/Tierra/Acero.")
      when :StrongWinds then desc = _INTL("Tipo volador no recibe daño supereficaz.")
      when :ShadowSky   then desc = _INTL("Boosts Shadow moves. Non-Shadow Pokémon damaged each turn.")
      end
      display_effects.push([name, tick, desc])
    end
    #---------------------------------------------------------------------------
    # Terrain
    if @battle.field.terrain != :None && battler.affectedByTerrain?
      name = _INTL("{1} Terrain", GameData::BattleTerrain.get(@battle.field.terrain).name)
      tick = @battle.field.terrainDuration
      tick = (tick > 0) ? sprintf("%d/%d", tick, 5) : "--"
      case @battle.field.terrain
      when :Electric then desc = _INTL("Aumenta daño eléctrico, anula sueño si pisa el suelo.")
      when :Grassy   then desc = _INTL("Aumenta daño planta, recupera vida cada turno si pisa el suelo.")
      when :Psychic  then desc = _INTL("Aumenta daño psíquico, anula movimientos de prioridad si pisa el suelo.")
      when :Misty    then desc = _INTL("Reduce daño psíquico, anula cambios de estado si pisa el suelo.")
      end
      display_effects.push([name, tick, desc])
    end
    #---------------------------------------------------------------------------
    # Battler effects that affect other Pokemon.
    if @battle.allBattlers.any? { |b| b.effects[PBEffects::Imprison] }
      name = GameData::Move.get(:IMPRISON).name
      desc = _INTL("No puede usar movimientos conocidos por el usuario de {1}.", name)
      display_effects.push([name, "--", desc])
    end
    if @battle.allBattlers.any? { |b| b.effects[PBEffects::Uproar] > 0 }
      name = GameData::Move.get(:UPROAR).name
      desc = _INTL("No puede dormirse por el alboroto.")
      display_effects.push([name, "--", desc])
    end
    if @battle.allBattlers.any? { |b| b.effects[PBEffects::JawLock] == battler.index }
      name = _INTL("No Escape")
      desc = _INTL("No puede huír o ser cambiado.")
      display_effects.push([name, "--", desc])
    end
    #---------------------------------------------------------------------------
    # All other effects.
    $DELUXE_PBEFFECTS.each do |key, key_hash|
      key_hash.each do |type, effects|
        effects.each do |effect|
          next if !PBEffects.const_defined?(effect)
          tick = "--"
          eff = PBEffects.const_get(effect)
          case key
          when :field    then value = @battle.field.effects[eff]
          when :team     then value = battler.pbOwnSide.effects[eff]
          when :position then value = @battle.positions[battler.index].effects[eff]
          when :battler  then value = battler.effects[eff]
          end
          case type
          when :boolean then next if !value
          when :counter then next if value == 0
          when :index   then next if value < 0
          end
          case effect
          #---------------------------------------------------------------------
          when :AquaRing
            name = GameData::Move.get(:AQUARING).name
            desc = _INTL("Recupera PS cada turno.")
          #---------------------------------------------------------------------
          when :Ingrain
            name = GameData::Move.get(:INGRAIN).name
            desc = _INTL("Recupera PS cada turno, pero no puede ser cambiado.")
          #---------------------------------------------------------------------
          when :LeechSeed
            name = GameData::Move.get(:LEECHSEED).name
            desc = _INTL("Drena PS cada turno para curar al rival.")
          #---------------------------------------------------------------------
          when :Curse
            name = GameData::Move.get(:CURSE).name
            desc = _INTL("Recibe daño al final de cada turno.")
          #---------------------------------------------------------------------
          when :SaltCure
            name = GameData::Move.get(:SALTCURE).name
            desc = _INTL("Recibe daño al final de cada turno.")
          #---------------------------------------------------------------------
          when :Nightmare
            name = GameData::Move.get(:NIGHTMARE).name
            desc = _INTL("Recibe daño al final de cada turno mientras duerme.")
          #---------------------------------------------------------------------
          when :Rage
            name = GameData::Move.get(:RAGE).name
            desc = _INTL("Aumenta el ataque cada vez que es golpeado.")
          #---------------------------------------------------------------------
          when :Torment
            name = GameData::Move.get(:TORMENT).name
            desc = _INTL("No puede usar el mismo movimiento dos veces seguidas.")
          #---------------------------------------------------------------------
          when :Charge
            name = GameData::Move.get(:CHARGE).name
            desc = _INTL("El siguiente movimiento eléctrico usado duplica su potencia.")
          #---------------------------------------------------------------------
          when :Minimize
            name = GameData::Move.get(:MINIMIZE).name
            desc = _INTL("Recibe más daño al ser pisado.")
          #---------------------------------------------------------------------
          when :TarShot
            name = GameData::Move.get(:TARSHOT).name
            desc = _INTL("Es más vulnerable a movimientos de tipo fuego.")
          #---------------------------------------------------------------------
          when :Wish
            name = GameData::Move.get(:WISH).name
            desc = _INTL("Recupera PS el próximo turno.")
          #---------------------------------------------------------------------
          when :Foresight
            name = GameData::Move.get(:FORESIGHT).name
            if battler.pbHasType?(:GHOST)
              desc = _INTL("Las inmunidades del tipo Fantasma y los cambios de evasión son anulados.")
            else
              desc = _INTL("Los cambios de evasión son anulados.")
            end
          #---------------------------------------------------------------------
          when :MiracleEye
            name = GameData::Move.get(:MIRACLEEYE).name
            if battler.pbHasType?(:DARK)
              desc = _INTL("Las inmunidades del tipo Siniestro y los cambios de evasión son anulados.")
            else
              desc = _INTL("Los cambios de evasión son anulados.")
            end
          #---------------------------------------------------------------------
          when :Stockpile
            name = GameData::Move.get(:STOCKPILE).name
            tick = sprintf("+%d", value)
            desc = _INTL("Reserva aumenta sus estadísticas defensivas.")
          #---------------------------------------------------------------------
          when :Spikes
            name = GameData::Move.get(:SPIKES).name
            tick = sprintf("+%d", value)
            desc = _INTL("Recibe daño al entrar en contacto con el suelo.")
          #---------------------------------------------------------------------
          when :ToxicSpikes
            name = GameData::Move.get(:TOXICSPIKES).name
            tick = sprintf("+%d", value)
            desc = _INTL("Se envenena al entrar en contacto con el suelo.")
          #---------------------------------------------------------------------
          when :StealthRock
            name = GameData::Move.get(:STEALTHROCK).name
            tick = _INTL("+1")
            desc = _INTL("Recibe daño al entrar en batalla.")
          #---------------------------------------------------------------------
          when :Steelsurge
            name = GameData::Move.get(:GMAXSTEELSURGE).name
            tick = _INTL("+1")
            desc = _INTL("Recibe daño al entrar en batalla.")
          #---------------------------------------------------------------------
          when :StickyWeb
            name = GameData::Move.get(:STICKYWEB).name
            tick = _INTL("+1")
            desc = _INTL("Reduce velocidad al entrar en batalla.")
          #---------------------------------------------------------------------
          when :LaserFocus
            name = GameData::Move.get(:LASERFOCUS).name
            tick = sprintf("%d/%d", value, 2)
            desc = _INTL("El siguiente golpe será crítico.")
          #---------------------------------------------------------------------
          when :LockOn
            name = GameData::Move.get(:LOCKON).name
            tick = sprintf("%d/%d", value, 2)
            desc = _INTL("Movimientos contra él siempre golpean.")
          #---------------------------------------------------------------------
          when :ThroatChop
            name = GameData::Move.get(:THROATCHOP).name
            tick = sprintf("%d/%d", value, 2)
            desc = _INTL("No puede usar movimientos de sonido.")
          #---------------------------------------------------------------------
          when :FairyLock
            name = GameData::Move.get(:FAIRYLOCK).name
            tick = sprintf("%d/%d", value, 2)
            desc = _INTL("Nadie puede huir.")
          #---------------------------------------------------------------------
          when :Telekinesis
            name = GameData::Move.get(:TELEKINESIS).name
            tick = sprintf("%d/%d", value, 3)
            desc = _INTL("Levita pero no puede evadir movimientos.")
          #---------------------------------------------------------------------
          when :Encore
            name = GameData::Move.get(:ENCORE).name
            data = GameData::Move.get(battler.effects[PBEffects::EncoreMove]).name
            tick = sprintf("%d/%d", value, 3)
            desc = _INTL("Por culpa de {1}, solo puede usar {2}.", name, data)
          #---------------------------------------------------------------------
          when :Taunt
            name = GameData::Move.get(:TAUNT).name
            tick = sprintf("%d/%d", value, 4)
            desc = _INTL("Solo puede usar movimientos que causen daño.")
          #---------------------------------------------------------------------
          when :Tailwind
            name = GameData::Move.get(:TAILWIND).name
            tick = sprintf("%d/%d", value, 4)
            desc = _INTL("Duplica la velocidad.")
          #---------------------------------------------------------------------
          when :VineLash
            name = GameData::Move.get(:GMAXVINELASH).name
            tick = sprintf("%d/%d", value, 4)
            desc = _INTL("Si no es de tipo Planta recibe daño cada turno.")
          #---------------------------------------------------------------------
          when :Wildfire
            name = GameData::Move.get(:GMAXWILDFIRE).name
            tick = sprintf("%d/%d", value, 4)
            desc = _INTL("Si no es de tipo Fuego recibe daño cada turno.")
          #---------------------------------------------------------------------
          when :Cannonade
            name = GameData::Move.get(:GMAXCANNONADE).name
            tick = sprintf("%d/%d", value, 4)
            desc = _INTL("Si no es de tipo Agua recibe daño cada turno.")
          #---------------------------------------------------------------------
          when :Volcalith
            name = GameData::Move.get(:GMAXVOLCALITH).name
            tick = sprintf("%d/%d", value, 4)
            desc = _INTL("Si no es de tipo Roca recibe daño cada turno..")
          #---------------------------------------------------------------------
          when :MagnetRise
            name = GameData::Move.get(:MAGNETRISE).name
            tick = sprintf("%d/%d", value, 5)
            desc = _INTL("Levita, por lo que es inmune a movimientos de Tierra.")
          #---------------------------------------------------------------------
          when :HealBlock
            name = GameData::Move.get(:HEALBLOCK).name
            tick = sprintf("%d/%d", value, 5)
            desc = _INTL("No puede restaurar PS.")
          #---------------------------------------------------------------------
          when :Embargo
            name = GameData::Move.get(:EMBARGO).name
            tick = sprintf("%d/%d", value, 5)
            desc = _INTL("No puede usar objetos.")
          #---------------------------------------------------------------------
          when :MudSport, :MudSportField
            name = GameData::Move.get(:MUDSPORT).name
            tick = sprintf("%d/%d", value, 5) if effect == :MudSportField
            desc = _INTL("Reduce la potencia del tipo Eléctrico.")
          #---------------------------------------------------------------------
          when :WaterSport, :WaterSportField
            name = GameData::Move.get(:WATERSPORT).name
            tick = sprintf("%d/%d", value, 5) if effect == :WaterSportField
            desc = _INTL("Reduce la potencia del tipo Fuego.")
          #---------------------------------------------------------------------
          when :AuroraVeil
            name = GameData::Move.get(:AURORAVEIL).name
            tick = sprintf("%d/%d", value, 5)
            desc = _INTL("Reduce a la mitad el daño recibido de movimientos.")
          #---------------------------------------------------------------------
          when :Reflect
            name = GameData::Move.get(:REFLECT).name
            tick = sprintf("%d/%d", value, 5)
            desc = _INTL("Reduce a la mitad el daño recibido de movimientos físicos.")
          #---------------------------------------------------------------------
          when :LightScreen
            name = GameData::Move.get(:LIGHTSCREEN).name
            tick = sprintf("%d/%d", value, 5)
            desc = _INTL("Reduce a la mitad el daño recibido de movimientos especiales.")
          #---------------------------------------------------------------------
          when :Safeguard
            name = GameData::Move.get(:SAFEGUARD).name
            tick = sprintf("%d/%d", value, 5)
            desc = _INTL("Evita efectos de estado.")
          #---------------------------------------------------------------------
          when :Mist
            name = GameData::Move.get(:MIST).name
            tick = sprintf("%d/%d", value, 5)
            desc = _INTL("Las estadísticas no pueden ser reducidas.")
          #---------------------------------------------------------------------
          when :LuckyChant
            name = GameData::Move.get(:LUCKYCHANT).name
            tick = sprintf("%d/%d", value, 5)
            desc = _INTL("No puede recibir golpes críticos.")
          #---------------------------------------------------------------------
          when :Gravity
            name = GameData::Move.get(:GRAVITY).name
            tick = sprintf("%d/%d", value, 5)
            desc = _INTL("Ata al suelo y aumenta precisión")
          #---------------------------------------------------------------------
          when :MagicRoom
            name = GameData::Move.get(:MAGICROOM).name
            tick = sprintf("%d/%d", value, 5)
            desc = _INTL("Nadie puede usar objetos.")
          #---------------------------------------------------------------------
          when :WonderRoom
            name = GameData::Move.get(:WONDERROOM).name
            tick = sprintf("%d/%d", value, 5)
            desc = _INTL("Todos cambian Defensa y Defensa Especial.")
          #---------------------------------------------------------------------
          when :TrickRoom
            name = GameData::Move.get(:TRICKROOM).name
            tick = sprintf("%d/%d", value, 5)
            desc = _INTL("Invierte el orden de la velocidad.")
          #---------------------------------------------------------------------
          when :Trapping
            name = _INTL("Bound")
            desc = _INTL("Recibe daño al final de cada turno.")
          #---------------------------------------------------------------------
          when :Toxic
            name = _INTL("Badly Poisoned")
            desc = _INTL("Aumenta el daño recibido por veneno cada turno")
          #---------------------------------------------------------------------
          when :Confusion
            name = _INTL("Confusion")
            desc = _INTL("Puede pegarse a si mismo por la confusión.")
          #---------------------------------------------------------------------
          when :Outrage
            name = _INTL("Rampaging")
            desc = _INTL("Se enfada durante 2 a 3 turnos. Luego se confuse.")
          #---------------------------------------------------------------------
          when :GastroAcid
            name = _INTL("No Ability")
            desc = _INTL("Pierde su habilidad.")
          #---------------------------------------------------------------------
          when :FocusEnergy
            name = _INTL("Critical Hit Boost")
            desc = _INTL("Aumenta la probabilidad de golpe crítico.")
          #---------------------------------------------------------------------
          when :Attract
            name = _INTL("Infatuation")
            data = (battler.gender == 0) ? "hembras" : "machos"
            desc = _INTL("Es más probable que ataque a {1}.", data)
          #---------------------------------------------------------------------
          when :MeanLook, :NoRetreat, :JawLock, :Octolock
            name = _INTL("No Escape")
            desc = _INTL("No puede huír o ser cambiado.")
          #---------------------------------------------------------------------
          when :ZHealing
            name = _INTL("Z-Healing")
            desc = _INTL("Recupera PS al ser cambiado a esta posición.")
          #---------------------------------------------------------------------
          when :PerishSong
            name = _INTL("Counting Down")
            tick = value.to_s
            desc = _INTL("Todos se debilitarán en 3 turnos.")
          #---------------------------------------------------------------------
          when :FutureSightCounter
            name = _INTL("Future Attack")
            tick = value.to_s
            desc = _INTL("Recibirá el ataque en 2 turnos.")
          #---------------------------------------------------------------------
          when :Syrupy
            name = _INTL("Speed Down")
            tick = value.to_s
            desc = _INTL("Baja la velocidad durante 3 turnos.")
          #---------------------------------------------------------------------
          when :SlowStart
            name = _INTL("Slow Start")
            tick = value.to_s
            desc = _INTL("Estará debilitado durante 5 turnos.")
          #---------------------------------------------------------------------
          when :Yawn
            name = _INTL("Drowsy")
            tick = sprintf("%d/%d", value, 2)
            desc = _INTL("Se quedará dormido al final de su próximo turno.")
          #---------------------------------------------------------------------
          when :HyperBeam
            name = _INTL("Recharging")
            tick = sprintf("%d/%d", value, 2)
            desc = _INTL("Necesitará recargar en su próximo turno.")
          #---------------------------------------------------------------------
          when :GlaiveRush
            name = _INTL("Vulnerable")
            tick = sprintf("%d/%d", value, 2)
            desc = _INTL("No puede esquivar y recibe el doble de daño durante un turno.")
          #---------------------------------------------------------------------
          when :Splinters
            name = _INTL("Splinters")
            tick = sprintf("%d/%d", value, 3)
            desc = _INTL("Recibe daño al final de cada turno.")
          #---------------------------------------------------------------------
          when :Disable
            name = _INTL("Move Disabled")
            data = GameData::Move.get(battler.effects[PBEffects::DisableMove]).name
            tick = sprintf("%d/%d", value, 4)
            desc =_INTL("{1} ha sido desactivado.", data)
          #---------------------------------------------------------------------
          when :Rainbow
            name = _INTL("Rainbow")
            tick = sprintf("%d/%d", value, 4)
            desc = _INTL("Los efectos adicionales son más probables.")
          #---------------------------------------------------------------------
          when :Swamp
            name = _INTL("Swamp")
            tick = sprintf("%d/%d", value, 4)
            desc = _INTL("La velocidad se reduce a un 75%.")
          #---------------------------------------------------------------------
          when :SeaOfFire
            name = _INTL("Sea of Fire")
            tick = sprintf("%d/%d", value, 4)
            desc = _INTL("Si no es de tipo Fuego recibe daño cada turno.")
          #---------------------------------------------------------------------
          when :TwoTurnAttack
            if battler.semiInvulnerable?
              name = _INTL("Semi-Invulnerable")
              desc = _INTL("No puede ser golpeado por la mayoría de movimientos.")
            end
          #---------------------------------------------------------------------
          else next
          end
          display_effects.push([name, tick, desc])
        end
      end
    end
    display_effects.uniq!
    return display_effects
  end
end