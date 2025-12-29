#---------------------------------------------------------------------------
# Police Trainer Card Scene Modified by SCREAM DONT USE
# Version: 1.0
# Author: Mr. Gela
#Credits =  Mr. Gela, DeepBlue PacificWaves, komeiji514, Skyflyer,scream
#Website = https://reliccastle.com/resources/388/
#---------------------------------------------------------------------------

# Overhauls the classic Trainer Card from Pokémon Essentials
class Player < Trainer
  # These need to be initialized
  # A swinging number, increases and decreases with progress
  attr_accessor(:score)
  # Changes the Trainer Card, similar to achievements
  attr_accessor(:stars)
  # Date and time
  attr_accessor(:halloffame)
  # Fake Trainer Class
  attr_accessor(:tclass)
  # Rank progress counter (0-100)
  attr_accessor(:rank_progress)

  def score
    @score=0 if !@score
    return @score
  end

  def stars
    @stars=0 if !@stars
    return @stars
  end

  def halloffame
    @halloffame=[] if !@halloffame
    return @halloffame
  end

  def tclass
    @tclass="Entrenador Pokémon" if !@tclass
    return @tclass
  end

  def rank_progress
    @rank_progress=0 if !@rank_progress
    return @rank_progress
  end




  

  def increase_rank_progress(amount)
    @rank_progress ||= 0
    @stars ||= 0

    @rank_progress += amount
    @rank_progress = 100 if @rank_progress > 100

    if @rank_progress >= 100
      @rank_progress = 0
      @stars += 1
      pbMessage(_INTL("¡Has ascendido al rango {1}!", getRankName(@stars))) rescue nil
    end
  end

  def publicID(id = nil)   # Portion of the ID which is visible on the Trainer Card
    return id ? id&0xFFFF : @id&0xFFFF
  end

  def fullname2
    return _INTL("{1} {2}", $player.tclass, $player.name)
  end

  def initialize(name, trainer_type)
    super
    @character_ID          = -1
    @outfit                = 0
    @badges                = [false] * 8
    @money                 = GameData::Metadata.get.start_money
    @coins                 = 0
    @battle_points         = 0
    @soot                  = 0
    @pokedex               = Pokedex.new
    @has_pokedex           = false
    @has_pokegear          = false
    @has_running_shoes     = false
    @seen_storage_creator  = false
    @mystery_gift_unlocked = false
    @mystery_gifts         = []
    @score = 0
    @stars = 0
    @halloffame = []
    @tclass = "Entrenador Pokémon"
    @rank_progress = 0
  end

  def getForeignID(number = nil)   # Random ID other than this Trainer's ID
    fid = 0
    fid = number if number != nil
    loop do
      fid = rand(256)
      fid |= rand(256) << 8
      fid |= rand(256) << 16
      fid |= rand(256) << 24
      break if fid != @id
    end
    return fid
  end

  def setForeignID(other, number = nil)
    @id=other.getForeignID(number)
  end
end

class HallOfFame_Scene # Minimal change to store HoF time into a variable

  def writeTrainerData
    totalsec = Graphics.frame_count / Graphics.frame_rate
    hour = totalsec / 60 / 60
    min = totalsec / 60 % 60
    # Store time of first Hall of Fame in $player.halloffame if not array is empty
    if $player.halloffame = []
      $player.halloffame.push(pbGetTimeNow)
      $player.halloffame.push(totalsec)
    end
    pubid=sprintf("%05d", $player.publicID($player.id))
    lefttext= _INTL("Nombre<r>{1}<br>", $player.name)
    lefttext+=_INTL("Nº ID<r>{1}<br>", pubid)
    lefttext+=_ISPRINTF("Tiempo<r>{1:02d}:{2:02d}<br>", hour, min)
    lefttext+=_INTL("Pokédex<r>{1}/{2}<br>",
        $player.pokedex.owned_count, $player.pokedex.seen_count)
    @sprites["messagebox"] = Window_AdvancedTextPokemon.new(lefttext)
    @sprites["messagebox"].viewport = @viewport
    @sprites["messagebox"].width = 192 if @sprites["messagebox"].width < 192
    @sprites["msgwindow"] = pbCreateMessageWindow(@viewport)
    pbMessageDisplay(@sprites["msgwindow"],
        _INTL("¡Campeón de la liga!\n¡Enhorabuena!\\^"))
  end

end

class PokemonTrainerCard_Scene

  # Waits x frames
  def wait(frames)
    frames.times do
    Graphics.update
    end
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
    if @sprites["bg"]
       @sprites["bg"].ox -= 2
       @sprites["bg"].oy -= 2
    end
  end

  # Define rank names based on stars (rangos policiales)
  def getRankName(stars)
    case stars
    when 0
      return "Policía"
    when 1
      return "Cabo"
    when 2
      return "Sargento"
    when 3
      return "Teniente"
    when 4
      return "Capitán"
    when 5
      return "Comisario"
    else
      return "Desconocido"
    end
  end

  def pbStartScene
    @front = true
    @flip = false
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    addBackgroundPlane(@sprites, "bg", "Trainer Card/bg", @viewport)
    @sprites["card"] = IconSprite.new(128 * 2, 96 * 2, @viewport)
    @sprites["card"].setBitmap("Graphics/UI/Trainer Card/card_#{$player.stars}")
    @sprites["card"].zoom_x = 2 ; @sprites["card"].zoom_y = 2

    @sprites["card"].ox = @sprites["card"].bitmap.width / 2
    @sprites["card"].oy = @sprites["card"].bitmap.height / 2

    @sprites["bg"].zoom_x = 2 ; @sprites["bg"].zoom_y = 2
    @sprites["bg"].ox += 6
    @sprites["bg"].oy -= 26
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)

    @sprites["overlay"].x = 128 * 2
    @sprites["overlay"].y = 96 * 2
    @sprites["overlay"].ox=@sprites["overlay"].bitmap.width / 2
    @sprites["overlay"].oy=@sprites["overlay"].bitmap.height / 2

    # Crear sprite invisible del entrenador (necesario para el flip)
    @sprites["trainer"] = IconSprite.new(0, 0, @viewport)
    @sprites["trainer"].setBitmap(GameData::TrainerType.player_front_sprite_filename($player.trainer_type))
    @sprites["trainer"].visible = false  # Siempre invisible ya que está en la tarjeta
    @sprites["trainer"].ox = @sprites["trainer"].bitmap.width / 2
    @sprites["trainer"].oy = @sprites["trainer"].bitmap.height / 2

    pbDrawTrainerCardFront
    pbFadeInAndShow(@sprites) { pbUpdate }
  end


  def flip1
    # "Flip"
    7.times do
      @sprites["overlay"].zoom_y = 1.03
      @sprites["card"].zoom_y = 2.06
      @sprites["overlay"].zoom_x -= 0.1
      @sprites["trainer"].zoom_x -= 0.2 if @sprites["trainer"]
      @sprites["trainer"].x -= 12 if @sprites["trainer"]
      @sprites["card"].zoom_x -= 0.15
      pbUpdate
      wait(1)
    end
      pbUpdate
  end

  def flip2
    # UNDO "Flip"
    7.times do
      @sprites["overlay"].zoom_x += 0.1
      @sprites["trainer"].zoom_x += 0.2 if @sprites["trainer"]
      @sprites["trainer"].x += 12 if @sprites["trainer"]
      @sprites["card"].zoom_x += 0.15
      @sprites["overlay"].zoom_y = 1
      @sprites["card"].zoom_y = 2
      pbUpdate
      wait(1)
    end
      pbUpdate
  end

  def pbDrawTrainerCardFront
    flip1 if @flip==true
    @front=true
    @sprites["trainer"].visible = false if @sprites["trainer"]  # Siempre invisible
    @sprites["card"].setBitmap("Graphics/UI/Trainer Card/card_#{$player.stars}")
    @overlay  = @sprites["overlay"].bitmap
    @overlay.clear
    base   = Color.new(255, 255, 255)   # Blanco puro
    shadow = Color.new(60, 60, 60)      # Sombra gris oscura (suave)
    baseGold   = Color.new(255, 215, 120)   # Oro más brillante
    shadowGold = Color.new(120, 105, 60)    # Sombra más profunda

    if $player.stars == 5
      base   = baseGold
      shadow = shadowGold
    end
    totalsec = Graphics.frame_count / Graphics.frame_rate
    hour = totalsec / 60 / 60
    min = totalsec / 60 % 60
    time = _ISPRINTF("{1:02d}:{2:02d}", hour, min)
    $PokemonGlobal.startTime = pbGetTimeNow if !$PokemonGlobal.startTime
    starttime = _INTL("{1} {2}, {3}",
       pbGetAbbrevMonthName($PokemonGlobal.startTime.mon),
       $PokemonGlobal.startTime.day,
       $PokemonGlobal.startTime.year)
    
    # Get current rank name
    rankName = getRankName($player.stars)
    
    # Get rank progress
    progress = sprintf("%d/100", $player.rank_progress)
    
    textPositions = [                                 #X(derecha,aumentas el valor.),Y(Más abajo → incrementa Y.),Alineacion ,Color base, Color sombra
       [_INTL("Nº PLACA"), 45, 87, 0, base, shadow],
       [sprintf("%05d", $player.publicID($player.id)), 222, 86, 1, base, shadow],
       [_INTL("DINERO"), 45, 132, 0, base, shadow],
       [_INTL("${1}", $player.money.to_s_formatted), 222, 132, 1, base, shadow],
       [_INTL("ARRESTOS"), 45, 180, 0, base, shadow],
       [sprintf("%d", $player.badge_count), 200, 180, 1, base, shadow],
       [_INTL("TIEMPO"), 45, 227, 0, base, shadow],
       [time, 302 + 88 * 2 - 254, 227, 1, base, shadow],
       [_INTL("COMIENZO"), 45, 274, 0, base, shadow],
       [starttime, 162, 274, 0, base, shadow],
       
       [rankName, 410, 86, 2, base, shadow],
       
       [progress, 434, 275, 1, base, shadow]
    ]
    @sprites["overlay"].z += 10
    pbDrawTextPositions(@overlay, textPositions)
    flip2 if @flip == true
  end

  def pbDrawTrainerCardBack
    pbUpdate
    @flip = true
    flip1
    @front = false
    @sprites["card"].setBitmap("Graphics/UI/Trainer Card/card_#{$player.stars}b")
    @overlay  = @sprites["overlay"].bitmap
    @overlay.clear
     base   = Color.new(255, 255, 255)   # Blanco puro
    shadow = Color.new(60, 60, 60)      # Sombra gris oscura (suave)
    baseGold   = Color.new(255, 215, 120)   # Oro más brillante
    shadowGold = Color.new(120, 105, 60)    # Sombra más profunda
    if $player.stars == 5
      base   = baseGold
      shadow = shadowGold
    end
    hof=[]
    if $player.halloffame!=[]
      hof.push(_INTL("{1} {2}, {3}",
      pbGetAbbrevMonthName($player.halloffame[0].mon),
      $player.halloffame[0].day,
      $player.halloffame[0].year))
      hour = $player.halloffame[1] / 60 / 60
      min = $player.halloffame[1] / 60 % 60
      time=_ISPRINTF("{1:02d}:{2:02d}", hour, min)
      hof.push(time)
    else
      hof.push("--- --, ----")
      hof.push("--:--")
    end
    textPositions = [
      [_INTL("DEBUT HALL DE LA FAMA"), 45, 87, 0, base, shadow],
      [hof[0], 302 + 89 * 2, 70 - 48, 1, base, shadow],
      [hof[1], 302 + 89 * 2, 70 - 16, 1, base, shadow],
      
      # PUNTOS BATALLA movido aquí
      [_INTL("PUNTOS BATALLA"), 45, 132, 0, base, shadow],
      [sprintf("%d", $player.battle_points), 304, 128, 1, base, shadow],
      
      # These are meant to be Link Battle modes, use as you wish, see below
      #[_INTL(" "), 32 + 111 * 2, 112 - 16, 0, base, shadow],
      #[_INTL(" "), 32 + 176 * 2, 112 - 16, 0, base, shadow],

      [_INTL("V"), 72, 134, 0, base, shadow],
      [_INTL("D"), 104, 134, 0, base, shadow],

      [_INTL("V"), 72, 166, 0, base, shadow],
      [_INTL("D"), 104, 166, 0, base, shadow],

      # Customize "$game_variables[100]" to use whatever variable you'd like
      # Some examples: eggs hatched, berries collected,
      # total steps (maybe converted to km/miles? Be creative, dunno!)
      # Pokémon defeated, shiny Pokémon encountered, etc.
      # While I do not include how to create those variables, feel free to HMU
      # if you need some support in the process, or reply to the Relic Castle
      # thread.

      # LÍNEA DEL NOMBRE DEL PERSONAJE ELIMINADA
      #[_INTL($player.fullname2), 32, 118 - 16, 0, base, shadow],
      #[_INTL(" ", $game_variables[100]), 302 + 2 + 48 - 2, 112 - 16, 1, base, shadow],
      #[_INTL(" ", $game_variables[100]), 302 + 2 + 48 + 63 * 2, 112 - 16, 1, base, shadow],

      [_INTL("TEXTO 1"), 45, 182, 0, base, shadow],
      [_INTL("{1}", $game_variables[100]), 302 + 2 + 48 - 2, 118 + 32 - 16, 1, base, shadow],
      [_INTL("{1}", $game_variables[100]), 302 + 2 + 48 + 63 *2, 118 + 32 - 16, 1, base, shadow],

      [_INTL("TEXTO 2"), 45, 228, 0, base, shadow],
      [_INTL("{1}", $game_variables[100]), 302 + 2 + 48 - 2, 118 + 32 - 16 + 32, 1, base, shadow],
      [_INTL("{1}", $game_variables[100]), 302 + 2 + 48 + 63 * 2, 118 + 32 - 16 + 32, 1, base, shadow],
    ]
    @sprites["overlay"].z += 20
    pbDrawTextPositions(@overlay, textPositions)
    # Draw Badges on overlay (doesn't support animations, might support .gif)
    imagepos=[]
    # Draw Region 0 badges
    x = 64 - 28
    8.times do |i|
      if $player.badges[i + 0 * 8]
        imagepos.push(["Graphics/UI/Trainer Card/badges0", x, 104 * 2, i * 48, 0 * 48, 48, 48])
      end
      x += 48 + 8
    end
    # Draw Region 1 badges
    x = 64-28
    8.times do |i|
      if $player.badges[i + 1 * 8]
        imagepos.push(["Graphics/UI/Trainer Card/badges1", x, 104 * 2 + 52, i * 48, 0 * 48, 48, 48])
      end
      x += 48 + 8
    end
    #print(@sprites["overlay"].ox, @sprites["overlay"].oy, x)
    pbDrawImagePositions(@overlay, imagepos)
    flip2
  end

  def pbTrainerCard
    pbSEPlay("GUI trainer card open")
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::SPECIAL)
        if @front == true
		 pbSEPlay("GUI trainer card flip")
          pbDrawTrainerCardBack
          wait(3)
        else
		  pbSEPlay("GUI trainer card flip")
          pbDrawTrainerCardFront if @front == false
          wait(3)
        end
      end
      if Input.trigger?(Input::BACK)
	  pbPlayCloseMenuSE
        break
      end
    end
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end


class PokemonTrainerCardScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene
    @scene.pbTrainerCard
    @scene.pbEndScene
  end
end