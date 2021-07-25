#if defined _cucarachas_mod_included
	#endinput
#endif

#define _cucarachas_mod_included

/*
 Informacion de las cucarachas:
 Classname: "CUCARACHA"
 Model: "models/roach.mdl"
*/

// Registrar un extra item en la tienda de cuca mod
// Retorna el ID del item. Guardarlo para luego comprobar en la forward.
native cm_register_extra_item(const Name[], Cost);

// Retorna la cantidad de puntos de un jugador.
native cm_get_user_points(id);

// Establecer los puntos de un jugador.
native cm_set_user_points(id, points);

// Crear una cucaracha. Otra cucaracha será seleccionada aleatoriamente y morirá para crear esta.
// Retorna el id de la cuca si se creó con éxito, 0 si no se pudo crear.
native cm_spawn_roach(const Float:origin[3]);

// Se llama cuando un jugador selecciona un extra item. Si el itemid es igual al id que almacenaste al registrar, es tu item.
// Retornar PLUGIN_HANDLED cancelará la compra.
forward cm_extra_item_selected(id, itemid);

// Se llama cada vez que muere una cucaracha. killer es el id de quien la mató (puede no ser un jugador) y entid el id de la entidad de la cucaracha.
forward cm_roach_killed(killer, entid);

// Retorna 1 si el jugador tiene repelente, 0 si no tiene.
native cm_get_user_repel(id);

// Establecer el repelente de un jugador.
native cm_set_user_repel(id, repel = 0);
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang10250\\ f0\\ fs16 \n\\ par }
*/
