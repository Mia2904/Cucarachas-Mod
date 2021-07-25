# Cucarachas Mod

### Información del Mod
* ¡Corre de las cucarachas y acuchilla a tus enemigos! El objetivo es sobrevivir al ataque de las cucarachas.
* Las cucarachas aparecen en lugares determinados del mapa.
* Persiguen a los jugadores cercanos, saltan, evaden obstáculos y atacan.
* Acumula puntos por matar a las cucarachas y enemigos, úsalos para comprar extra items.

### Información del Plugin
* El plugin principal (cucarachas_main) se encarga de hacer aparecer a las cucarachas y controlarlas, así como administrar el juego, la tienda de extra items y algunas opciones.
* El mod incluye una API para desarrollar nuevos extra items.
* Se incluye una herramienta para configurar los mapas para Cucarachas Mod.

### Configuración del Mod
* Se configura según el mapa: Orígenes de las cucarachas, cantidad y color de glow. (Véase: Map Tool)
* Se configura en la fuente del main plugin: Opciones de las cucarachas.

### CVARs
* cm_kill_reward <#> - Cuantos puntos se reciben por matar a un enemigo.
* cm_points_reward <#> - Cuantos puntos se reciben por matar a una cucaracha.
* cm_block_damage <0|1|2> - 0 : No bloquear el daño entre jugadores, 1 : Solo permitir daño con cuchillo, 2 : Bloquear toda forma de daño entre jugadores.

### Recursos adicionales
* Los models requeridos son incluídos con el Counter-Strike.
* Se incluye una colección de mapas configurados para Cucarachas Mod (incluídos mapas cc by Totopizza)
* Se incluyen extra ítems básicos para la tienda.

### Map Tool
* El Map Tool es una herramienta para configurar los mapas para Cucarachas Mod.
* Es sencillo usarla, sólo basta con leer las opciones del menú.
* Con el plugin activo en el servidor, un administrador con acceso a INMUNIDAD puede escribir en cualquier momento /cmenu para abrir el menú de Map Tool. Cuando lo haga, todas las posiciones donde aparecerán las cucarachas serán visibles con un model de una gallina con glow. Se ocultarán en cuanto se reinicie el mapa. ¡El Map Tool no guarda las configuraciones automáticamente, guárdarlas antes de reiniciar el mapa!

### API
* Véase cucarachas_mod.inc

### Créditos
* [Totopizza](https://github.com/oaus) - Mapas propios.
* [hud](https://amxmodx-es.com/member.php?action=profile&uid=374) - Idea.
* [Skylar](https://amxmodx-es.com/member.php?action=profile&uid=1276) - Servidor temporal donde se probó el mod.
* [jay-jay](https://amxmodx-es.com/member.php?action=profile&uid=308) - Model de insecticida Raid.