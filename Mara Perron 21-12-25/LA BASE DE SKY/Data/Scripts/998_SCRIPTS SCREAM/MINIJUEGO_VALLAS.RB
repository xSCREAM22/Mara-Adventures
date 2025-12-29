class MinijuegoSaltarVallas
  def initialize
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999

    # Fondo del minijuego
    @fondo = Sprite.new(@viewport)
    @fondo.bitmap = Bitmap.new("Graphics/Pictures/MinijuegoVallas/Fondo") # Cambia por la imagen de fondo
    @fondo.z = 0 # El fondo debe estar detrás de todo

    # Jugador (Pokémon)
    @jugador = Sprite.new(@viewport)
    @jugador.bitmap = Bitmap.new("Graphics/Pictures/MinijuegoVallas/Player") # Cambia por la imagen de tu Pokémon
    @jugador.x = 10 # Posición X inicial del jugador
    @jugador.y = 90 # Posición Y inicial del jugador
    @jugador.z = 1 # El jugador debe estar sobre el fondo

    # Vallas
    @vallas = []
    @juego_terminado = false
    @puntuacion = 0
    @saltando = false
    @altura_salto = 0
    @gravedad = 1
    @velocidad_salto = 15
    @sprite_puntuacion = nil
    @vallas_saltadas = 0
    @vallas_totales = 10 # Número total de vallas
    @tiempo_inicial = Time.now
    @tiempo_limite = 120 # 120 segundos (2 minutos)
    @intervalo_valla = 3 # Intervalo de tiempo entre vallas (en segundos)
    @ultima_valla = Time.now
    @velocidad_jugador = 3 # Velocidad de movimiento horizontal del jugador
    @velocidad_fondo = 2 # Velocidad de desplazamiento del fondo
    @teclas_salto = [:UP, :DOWN, :LEFT, :RIGHT] # Teclas disponibles para saltar
    @tecla_actual = nil # Tecla actual que debe presionar el jugador para saltar
    @sprite_mensaje_valla = nil # Sprite para mostrar el mensaje de la tecla
  end

  def update
    actualizar_jugador
    actualizar_fondo
    actualizar_vallas
    verificar_colisiones
    dibujar_puntuacion
    verificar_tiempo
    verificar_victoria
    mostrar_mensaje_valla
    ralentizar_tiempo
  end

  def actualizar_jugador
    # Movimiento horizontal del jugador (solo hacia la izquierda y derecha)
    if Input.press?(Input::LEFT)
      @jugador.x -= @velocidad_jugador
    elsif Input.press?(Input::RIGHT)
      @jugador.x += @velocidad_jugador
    end

    # Limitar al jugador dentro de la pantalla
    @jugador.x = [@jugador.x, 0].max
    @jugador.x = [@jugador.x, Graphics.width - @jugador.bitmap.width].min

    # Salto del jugador
    if @tecla_actual && Input.trigger?(Input.const_get(@tecla_actual)) && !@saltando
      @saltando = true
      @altura_salto = @velocidad_salto
    end
    if @saltando
      @jugador.y -= @altura_salto
      @altura_salto -= @gravedad
      if @jugador.y >= 90 # Restablecer la posición Y del jugador
        @jugador.y = 90
        @saltando = false
      end
    end
  end

  def actualizar_fondo
    # Mover el fondo hacia la izquierda para simular que el jugador avanza
    @fondo.x -= @velocidad_fondo

    # Si el fondo se sale de la pantalla, lo reposicionamos para crear un efecto de bucle
    if @fondo.x + @fondo.bitmap.width <= Graphics.width
      @fondo.x = 0
    end
  end

  def actualizar_vallas
    # Generar una nueva valla cada @intervalo_valla segundos, hasta que se alcancen 10 vallas
    if Time.now - @ultima_valla >= @intervalo_valla && @vallas.size < @vallas_totales
      valla = Sprite.new(@viewport)
      valla.bitmap = Bitmap.new("Graphics/Pictures/MinijuegoVallas/Valla") # Cambia por la imagen de la valla
      valla.x = Graphics.width # Posición X inicial de la valla
      valla.y = 132 # Posición Y de la valla ajustada a 132
      valla.z = 1 # Las vallas deben estar sobre el fondo
      @vallas << valla
      @ultima_valla = Time.now
      @tecla_actual = @teclas_salto.sample # Asignar una tecla aleatoria para saltar
      mostrar_mensaje_valla # Mostrar el mensaje de la tecla
    end

    # Mover las vallas hacia la izquierda
    @vallas.each do |v|
      v.x -= @velocidad_fondo # Mover las vallas a la misma velocidad que el fondo
      # Eliminar la valla solo si ha salido completamente de la pantalla
      if v.x + v.bitmap.width < 0
        v.dispose
        @vallas.delete(v)
        # Si la valla sale de la pantalla sin ser saltada, se suma 1 a las vallas saltadas
        @vallas_saltadas += 1
      end
    end
  end

  def verificar_colisiones
    @vallas.each do |v|
      # Definir un margen de colisión más pequeño
      margen_x = 5 # Margen horizontal (ajusta este valor según sea necesario)
      margen_y = 5 # Margen vertical (ajusta este valor según sea necesario)

      # Coordenadas del jugador
      jugador_izquierda = @jugador.x + margen_x
      jugador_derecha = @jugador.x + @jugador.bitmap.width - margen_x
      jugador_arriba = @jugador.y + margen_y
      jugador_abajo = @jugador.y + @jugador.bitmap.height - margen_y

      # Coordenadas de la valla
      valla_izquierda = v.x + margen_x
      valla_derecha = v.x + v.bitmap.width - margen_x
      valla_arriba = v.y + margen_y
      valla_abajo = v.y + v.bitmap.height - margen_y

      # Verificar colisión solo si el jugador está en el suelo
      if !@saltando &&
         jugador_derecha > valla_izquierda && # Jugador a la derecha de la valla
         jugador_izquierda < valla_derecha && # Jugador a la izquierda de la valla
         jugador_abajo > valla_arriba && # Jugador por debajo de la parte superior de la valla
         jugador_arriba < valla_abajo    # Jugador por encima de la parte inferior de la valla
        # Si el jugador toca una valla, se restan 50 puntos
        @puntuacion -= 50
        # Eliminar la valla para evitar múltiples colisiones
        v.dispose
        @vallas.delete(v)
      end
    end
  end

  def dibujar_puntuacion
    # Si ya existe un sprite de puntuación, lo eliminamos
    @sprite_puntuacion.dispose if @sprite_puntuacion

    # Creamos un nuevo sprite para la puntuación
    @sprite_puntuacion = Sprite.new(@viewport)
    @sprite_puntuacion.bitmap = Bitmap.new(Graphics.width, Graphics.height)

    # Color del texto: #002445
    color_texto = Color.new(0, 36, 69) # RGB para #002445

    # Dibujar la puntuación y las vallas saltadas a la izquierda
    texto_puntuacion = "Puntuación: #{@puntuacion}  Vallas Saltadas: #{@vallas_saltadas}/#{@vallas_totales}"
    @sprite_puntuacion.bitmap.font.color = color_texto
    @sprite_puntuacion.bitmap.draw_text(10, 10, 400, 24, texto_puntuacion) # A la izquierda

    # Dibujar el cronómetro a la derecha
    tiempo_restante = [@tiempo_limite - (Time.now - @tiempo_inicial), 0].max
    tiempo_restante_entero = tiempo_restante.floor # Redondear hacia abajo para obtener solo segundos
    @sprite_puntuacion.bitmap.draw_text(Graphics.width - 150, 10, 140, 24, "Tiempo: #{tiempo_restante_entero}", 2) # A la derecha

    @sprite_puntuacion.z = 99999 # La puntuación debe estar sobre todo
  end

  def mostrar_mensaje_valla
    # Eliminar el mensaje anterior si existe
    @sprite_mensaje_valla.dispose if @sprite_mensaje_valla

    # Crear un nuevo sprite para el mensaje
    @sprite_mensaje_valla = Sprite.new(@viewport)
    @sprite_mensaje_valla.bitmap = Bitmap.new(Graphics.width, Graphics.height)

    # Color del texto: #002445
    color_texto = Color.new(0, 36, 69) # RGB para #002445

    # Dibujar el mensaje de la tecla en la parte superior central
    mensaje = "¡Presiona #{@tecla_actual.to_s.upcase} para saltar!"
    @sprite_mensaje_valla.bitmap.font.color = color_texto
    @sprite_mensaje_valla.bitmap.draw_text(Graphics.width / 2 - 100, 50, 200, 24, mensaje, 1) # Centrado

    @sprite_mensaje_valla.z = 99999 # El mensaje debe estar sobre todo
  end

  def ralentizar_tiempo
    # Ralentizar el tiempo cuando la valla esté muy cerca del jugador
    @vallas.each do |v|
      if v.x - @jugador.x < 100 # Si la valla está a menos de 100 píxeles del jugador
        @velocidad_fondo = 1 # Reducir la velocidad del fondo
        return
      end
    end
    @velocidad_fondo = 2 # Restaurar la velocidad normal del fondo
  end

  def verificar_tiempo
    # Verificar si se acabó el tiempo
    if Time.now - @tiempo_inicial >= @tiempo_limite
      @juego_terminado = true
      pbMessage("¡Se acabó el tiempo! Puntuación: #{@puntuacion}")
    end
  end

  def verificar_victoria
    # Verificar si se han saltado (o fallado) 10 vallas
    if @vallas_saltadas >= @vallas_totales
      @juego_terminado = true
      pbMessage("¡Fin del juego! Has saltado #{@vallas_saltadas} vallas. Puntuación: #{@puntuacion}")
    end
  end

  def main
    until @juego_terminado
      update
      Graphics.update
      Input.update
    end
    terminar_juego
  end

  def terminar_juego
    @fondo.dispose
    @jugador.dispose
    @vallas.each { |v| v.dispose }
    @sprite_puntuacion.dispose if @sprite_puntuacion
    @sprite_mensaje_valla.dispose if @sprite_mensaje_valla
    @viewport.dispose
  end
end

def pbMinijuegoSaltarVallas
  minijuego = MinijuegoSaltarVallas.new
  minijuego.main
end