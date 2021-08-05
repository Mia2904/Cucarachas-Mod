#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>

#define PLUGIN "Cucarachas Mod"
#define VERSION "1.01"

/*================================================================================
 [Constantes editables]
=================================================================================*/

const Float:NORMAL_SPEED = 80.0 // Velocidad normal
const Float:PURSUIT_SPEED = 220.0 // Velocidad de persecucion
const Float:VIDA = 10.0 // Demasiada vida = cucarachas mutantes (?
const Float:SALTO = 100.0 // Maxima altura que puede saltar una cucaracha.
const Float:RADIO = 500.0 // Radio de vision de la cucaracha
const CANTIDAD_BLOOD = 4 // Cantidad de 'sangre' (?
const Float:TRACE_DIST = 5.0 // Distancia maxima entre la cucaracha y una pared para cambiar de direccion

#define DAMAGE(%0) (float(%0)/4.0+6.0) // Da�o segun la cantidad de jugadores

new const CLASSNAME[] = "CUCARACHA";
new const MODEL[] = "models/roach.mdl";
new const SONIDO_SPLASH[] = "roach/rch_smash.wav";
new const SONIDO_DMG[] = "roach/rch_die.wav";
new const SONIDO_ATTACK[] = "roach/rch_walk.wav";

#pragma semicolon 1

/*================================================================================
 [Variables / Constantes / Macros]
=================================================================================*/

enum _:SPRS
{
	SPR_BLOOD = 0,
	SPR_BLOODSPRAY
};

new g_model, g_reg, g_sprindex[SPRS];
new Array:g_origins, g_origins_count;
new Array:g_extra_names, Array:g_extra_costs, g_extra_items;
new forward_extra_item_selected, forward_roach_killed;
new g_canattack;
new g_max_cucas, g_glow;
new g_menucallback;
new g_points[33], g_repel[33];
new cvar_reward, cvar_damage, cvar_killreward;

const TASKID = 9753;

#define is_user_valid(%0) (1 <= %0 <= 32)

/*================================================================================
 [Inicio del plugin]
=================================================================================*/

public plugin_precache()
{
	precache_sound(SONIDO_SPLASH);
	precache_sound(SONIDO_DMG);
	precache_sound(SONIDO_ATTACK);
	g_model = precache_model(MODEL);
	
	g_extra_names = ArrayCreate(32, 1);
	g_extra_costs = ArrayCreate(1, 1);
	
	g_sprindex[SPR_BLOOD] = precache_model("sprites/blood.spr");
	g_sprindex[SPR_BLOODSPRAY] = precache_model("sprites/bloodspray.spr");
}

public plugin_natives()
{
	register_native("cm_register_extra_item", "native_register_extra_item", 0);
	register_native("cm_get_user_points", "native_get_user_points", 1);
	register_native("cm_set_user_points", "native_set_user_points", 1);
	register_native("cm_spawn_roach", "native_spawn_roach", 0);
	register_native("cm_set_user_repel", "native_set_user_repel", 1);
	register_native("cm_get_user_repel", "native_get_user_repel", 1);
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, "Mario AR.");
	
	new szBuffer[196], File, szMap[32], szOrigins[3][10], Float:origins[3];
	
	get_mapname(szMap, charsmax(szMap));
	get_localinfo("amxx_configsdir", szBuffer, charsmax(szBuffer));
	
	format(szBuffer, charsmax(szBuffer), "%s/Cucarachas_Mod/%s.ini", szBuffer, szMap);
	
	if (!file_exists(szBuffer))
	{
		set_fail_state("Utiliza el Map Tool para adaptar este mapa a Cuca Mod.");
		return;
	}
	
	g_origins = ArrayCreate(3, 1);
	
	File = fopen(szBuffer, "rt");
	fgets(File, szBuffer, charsmax(szBuffer));
	parse(szBuffer, szOrigins[0], charsmax(szOrigins[]), szOrigins[1], charsmax(szOrigins[]));
	g_max_cucas = str_to_num(szOrigins[0]);
	g_glow = str_to_num(szOrigins[1]);
	
	while (!feof(File))
	{
		fgets(File, szBuffer, charsmax(szBuffer));
		trim(szBuffer);
		parse(szBuffer, szOrigins[0], charsmax(szOrigins[]), szOrigins[1], charsmax(szOrigins[]), szOrigins[2], charsmax(szOrigins[]));
		
		origins[0] = str_to_float(szOrigins[0]);
		origins[1] = str_to_float(szOrigins[1]);
		origins[2] = str_to_float(szOrigins[2]);
		
		ArrayPushArray(g_origins, origins);
		g_origins_count++;
	}
	
	fclose(File);
	
	register_clcmd("say /cuca", "clcmd_cuca");
	
	register_event("HLTV", "event_HLTV", "a", "1=0", "2=0");
	register_logevent("logevent_round_end", 2, "1=Round_End");
	
	register_touch("weaponbox", "*", "fw_WeaponBoxTouch");
	register_touch("armoury_entity", "*", "fw_WeaponBoxTouch");
	register_touch(CLASSNAME, "player", "fw_RoachTouch");
	register_think(CLASSNAME, "fw_RoachThink");
	
	RegisterHam(Ham_TakeDamage, "player", "fw_PlayerTakeDamage", false);
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn", true);
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled", true);
	
	register_forward(FM_GetGameDescription, "fw_GetGameDescription");
	
	cvar_killreward = register_cvar("cm_kill_reward", "2");
	cvar_reward = register_cvar("cm_points_reward", "1");
	cvar_damage = register_cvar("cm_block_damage", "1");
	
	g_menucallback = menu_makecallback("cb_item_block");
	
	forward_extra_item_selected = CreateMultiForward("cm_extra_item_selected", ET_STOP, FP_CELL, FP_CELL);
	forward_roach_killed = CreateMultiForward("cm_roach_killed", ET_STOP, FP_CELL, FP_CELL);
	
	set_task(1.0, "event_HLTV");
}

public plugin_end()
{
	ArrayDestroy(g_origins);
	ArrayDestroy(g_extra_names);
	ArrayDestroy(g_extra_costs);
}

/*================================================================================
 [API Extra Items]
=================================================================================*/

public clcmd_cuca(id)
{
	new item[50], cost;
	formatex(item, charsmax(item), "Tienda Cuca Mod^n\wTienes\r %d\w puntos.", g_points[id]);
	new menu = menu_create(item, "menu_cuca");
	
	for (new i = 0; i < g_extra_items; i++)
	{
		cost = ArrayGetCell(g_extra_costs, i);
		ArrayGetString(g_extra_names, i, item, charsmax(item));
		format(item, charsmax(item), "%s%s - %d puntos", item, g_points[id] >= cost ? "\y" : "\d", cost);
		menu_additem(menu, item, .callback = g_points[id] >= cost ? -1 : g_menucallback);
	}
	
	menu_setprop(menu, MPROP_EXITNAME, "Salir");
	
	menu_display(id, menu);
}

public menu_cuca(id, menu, item)
{
	if (!is_user_connected(id) || item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new ret;
	ExecuteForward(forward_extra_item_selected, ret, id, item+1);
	
	if (ret < PLUGIN_HANDLED)
		g_points[id] -= ArrayGetCell(g_extra_costs, item);
	
	menu_destroy(menu);
	clcmd_cuca(id);
	return PLUGIN_HANDLED;
}

public cb_item_block(id, menu, item)
	return ITEM_DISABLED;

/*================================================================================
 [Eventos / Forwards de AMXX]
=================================================================================*/

public client_putinserver(id)
{
	g_points[id] = 0;
	set_task(6.0, "task_show_message", id);
}

public event_HLTV()
{
	remove_task(TASKID);
	
	new ent = -1;
	
	while ((ent = find_ent_by_class(ent, CLASSNAME)) > 0)
		remove_entity(ent);
	
	arrayset(g_repel, 0, 33);
	
	set_task(2.0, "task_show_hud");
	g_canattack = 0;
	
	set_task(7.0, "task_create_roachs", TASKID);
}

public logevent_round_end()
{
	g_canattack = 0;
}

/*================================================================================
 [Huds / Prints / Tasks]
=================================================================================*/

public task_show_hud()
{
	set_hudmessage(255, 255, 255, -1.0, 0.2, 0, 5.0, 5.0, 0.1, 0.1, 4);
	show_hudmessage(0, "Invasion de cucarachas en 5 segundos!");
}

public task_create_roachs()
{
	new Float:origin[3];
	for (new i = 0; i < g_max_cucas; i++)
	{
		ArrayGetArray(g_origins, random(g_origins_count), origin);
	
		create_roach(origin);
	}
	
	g_canattack = 1;
}

public task_show_message(id)
{
	if (!is_user_connected(id))
		return;
		
	new name[32];
	get_user_name(id, name, 31);
	
	colored_print(id, "^x04[CM]^x01 Hola ^x03%s^x01 bienvenido a^x03 Cucarachas Mod!^x01 Escribe^x04 /cuca^x01 para abrir el menu de extras.", name);
}

/*================================================================================
 [Forwards de engine/fakemeta/hansandwich]
=================================================================================*/

public fw_RoachThink(ent)
{
	if (!is_valid_ent(ent))
		return PLUGIN_CONTINUE;
	
	static Float:velocity[3], Float:origin[3], Float:originT[3], Float:angles[3];
	static Float:spd, Float:fraction, trace;
	static victim, lastjump;
	entity_get_vector(ent, EV_VEC_origin, origin);
	lastjump = entity_get_int(ent, EV_INT_iuser1);
	
	// Recordando un poco de fisica
	// Vf^2 = Vo^2 + 2.a.d
	// En un salto, velocidad final = 0
	// Despejando: Vo = raiz(2.a.d)
	// La aceleracion del cs es 800, como el gravity de las cucas es 0.6
	// 800 * 2 * 0.6 = 960
	// Le puse 1000 para asegurarme que la cuca salte un poco mas de lo debido
	const Float:JUMP_CONST = 1000.0;
	
	if (lastjump > 0)
		entity_set_int(ent, EV_INT_iuser1, --lastjump);
	
	if (g_canattack)
	{
		if ((victim = entity_get_int(ent, EV_INT_iuser2)) == -1)
		{
			victim = get_closest_player(ent);
		}
		else
		{
			entity_set_int(ent, EV_INT_iuser2, --victim);
			victim = 0;
		}
	}
	else victim = 0;
	
	if (!(1 <= victim <= 32))
	{
		entity_get_vector(ent, EV_VEC_velocity, velocity);
		
		//angle_vector(velocity, ANGLEVECTOR_FORWARD, angles);
		xs_vec_normalize(velocity, angles);
		angles[2] = 0.0;
		xs_vec_mul_scalar(angles, TRACE_DIST, angles);
		
		xs_vec_add(origin, angles, originT);
		//origin[0] = origin[0] - (3.0 * origin[0] / lenght);
		//origin[1] = origin[1] - (3.0 * origin[1] / lenght);
		
		engfunc(EngFunc_TraceLine, origin, originT, DONT_IGNORE_MONSTERS, ent, trace);
		
		get_tr2(trace, TR_flFraction, fraction);
		
		if (fraction == 1.0)
		{
			spd = random_float(0.0, NORMAL_SPEED/4.0);
			velocity[0] = velocity[0] + random_float(-NORMAL_SPEED/4.0, NORMAL_SPEED/4.0);
			velocity[1] = velocity[1] > 0.0 ? floatsqroot(NORMAL_SPEED*NORMAL_SPEED - spd*spd) : 0.0 - floatsqroot(NORMAL_SPEED*NORMAL_SPEED - spd*spd);
			
			//velocity[2] = random(25) ? 0.0 : SALTO;
			
			entity_set_vector(ent, EV_VEC_velocity, velocity);
			
			vector_to_angle(velocity, velocity);
			entity_set_vector(ent, EV_VEC_angles, velocity);
		}
		else
		{
			roach_random_move(ent, velocity);
		}
	}
	else
	{
		entity_get_vector(victim, EV_VEC_origin, originT);
		entity_get_vector(ent, EV_VEC_velocity, velocity);
		
		//origin[0] = origin[0] - (2.0 * origin[0] / lenght);
		//origin[1] = origin[1] - (2.0 * origin[1] / lenght);
		//origin[2] = origin[2] - 1.0;
		
		engfunc(EngFunc_TraceLine, origin, originT, IGNORE_MONSTERS, ent, trace);
	
		get_tr2(trace, TR_flFraction, fraction);
		
		static Float:backup;
		
		if (fraction == 1.0)
		{
			backup = velocity[2];
			
			xs_vec_sub(originT, origin, velocity);
			vector_to_angle(velocity, velocity);
			
			entity_set_vector(ent, EV_VEC_angles, velocity);
			
			angle_vector(velocity, ANGLEVECTOR_FORWARD, velocity);
			xs_vec_normalize(velocity, velocity);
			xs_vec_mul_scalar(velocity, PURSUIT_SPEED, velocity);
			
			if (!lastjump && get_distance_f(origin, originT) < 50.0 && originT[2] > origin[2])
			{
				velocity[2] = floatsqroot(JUMP_CONST*floatmin(SALTO, (originT[2]-origin[2])));
				entity_set_int(ent, EV_INT_iuser1, 10);
			}
			else
				velocity[2] = backup;
			
			entity_set_vector(ent, EV_VEC_velocity, velocity);
		}
		else
		{
			if (originT[2] > origin[2])
			{
				backup = origin[2];
				origin[2] = originT[2];
				
				engfunc(EngFunc_TraceLine, origin, originT, IGNORE_MONSTERS, ent, trace);
				get_tr2(trace, TR_flFraction, fraction);
				
				if (fraction == 1.0)
				{
					origin[2] = backup;
					backup = velocity[2];
					
					xs_vec_sub(originT, origin, velocity);
					
					vector_to_angle(velocity, velocity);
					entity_set_vector(ent, EV_VEC_angles, velocity);
					
					angle_vector(velocity, ANGLEVECTOR_FORWARD, velocity);
					xs_vec_normalize(velocity, velocity);
					xs_vec_mul_scalar(velocity, PURSUIT_SPEED, velocity);
					
					if (!lastjump)
					{
						velocity[2] = floatsqroot(JUMP_CONST*floatmin(SALTO, (originT[2]-origin[2])));
						entity_set_int(ent, EV_INT_iuser1, 10);
					}
					else
						velocity[2] = backup;
					
					entity_set_vector(ent, EV_VEC_velocity, velocity);
				}
				else
				{
					origin[2] = backup + SALTO;
					backup = originT[2];
					originT[2] = origin[2];
					
					engfunc(EngFunc_TraceLine, origin, originT, IGNORE_MONSTERS, ent, trace);
					get_tr2(trace, TR_flFraction, fraction);
					
					if (fraction == 1.0)
					{
						originT[2] = backup;
						backup = velocity[2];
						
						xs_vec_sub(originT, origin, velocity);
						
						vector_to_angle(velocity, velocity);
						entity_set_vector(ent, EV_VEC_angles, velocity);
						
						angle_vector(velocity, ANGLEVECTOR_FORWARD, velocity);
						xs_vec_normalize(velocity, velocity);
						xs_vec_mul_scalar(velocity, PURSUIT_SPEED, velocity);
						
						if (!lastjump)
						{
							velocity[2] = floatsqroot(JUMP_CONST*SALTO);
							entity_set_int(ent, EV_INT_iuser1, 10);
						}
						else
							velocity[2] = backup;
						
						entity_set_vector(ent, EV_VEC_velocity, velocity);
					}
					else
					{
						roach_random_move(ent, velocity);
					}
				}
			}
			else
			{
				backup = originT[2];
				originT[2] = origin[2];
				
				engfunc(EngFunc_TraceLine, origin, originT, IGNORE_MONSTERS, ent, trace);
				get_tr2(trace, TR_flFraction, fraction);
				
				if (fraction == 1.0)
				{
					originT[2] = backup;
					backup = velocity[2];
					
					xs_vec_sub(originT, origin, velocity);
					
					vector_to_angle(velocity, velocity);
					entity_set_vector(ent, EV_VEC_angles, velocity);
					
					angle_vector(velocity, ANGLEVECTOR_FORWARD, velocity);
					xs_vec_normalize(velocity, velocity);
					xs_vec_mul_scalar(velocity, PURSUIT_SPEED, velocity);
					
					velocity[2] = backup;
					
					entity_set_vector(ent, EV_VEC_velocity, velocity);
				}
				else
				{
					roach_random_move(ent, velocity);
				}
			}
		}
	}
	
	entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.2);
	
	return PLUGIN_CONTINUE;
}

public fw_RoachTouch(touched, toucher)
{
	if (!is_valid_ent(touched))
		return PLUGIN_CONTINUE;
	
	if (g_canattack && entity_get_int(touched, EV_INT_iuser2) == -1 && is_user_alive(toucher))
	{
		ExecuteHam(Ham_TakeDamage, toucher, touched, touched, DAMAGE(get_playersnum()), DMG_SLASH);
		emit_sound(touched, CHAN_VOICE, SONIDO_ATTACK, 1.0, ATTN_NORM, 0, PITCH_NORM);
		entity_set_int(touched, EV_INT_iuser2, 10); // Delay para el proximo ataque
	}
	else if (entity_get_int(touched, EV_INT_flags) & FL_ONGROUND)
	{
		static Float:origin[3];
		entity_get_vector(touched, EV_VEC_origin, origin);
		
		UTIL_BloodDrips(origin);
		emit_sound(touched, CHAN_VOICE, SONIDO_SPLASH, 1.0, ATTN_NORM, 0, PITCH_NORM);
		ExecuteHamB(Ham_Killed, touched, toucher, 0);
	}
	
	return PLUGIN_CONTINUE;
}

public fw_RoachTakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	if (!is_valid_ent(victim))
		return HAM_IGNORED;
	
	//if (is_user_connected(attacker))
	//	set_user_frags(attacker, get_user_frags(attacker)+1);
	
	emit_sound(victim, CHAN_VOICE, SONIDO_DMG, 1.0, ATTN_NORM, 0, PITCH_NORM);
	static Float:origin[3];
	entity_get_vector(victim, EV_VEC_origin, origin);
	UTIL_BloodDrips(origin);
	
	const DMG_HEGRENADE = (1<<24);
	if (damagebits & DMG_HEGRENADE)
		entity_set_int(victim, EV_INT_iuser3, 1111);
	
	return HAM_IGNORED;
}

public fw_RoachKilled(victim, attacker)
{
	if (!is_valid_ent(victim))
		return HAM_IGNORED;
	
	new Float:origin[3], Float:direction[3];
	entity_get_vector(victim, EV_VEC_origin, origin);
	xs_vec_set(direction, random_float(-1.0, 1.0), random_float(-1.0, 1.0), random_float(0.0, 1.0));
		
	FX_StreakSplash(origin, direction, 5, 16, 50, 200);
	
	new ret;
	ExecuteForward(forward_roach_killed, ret, attacker, victim);
	
	ArrayGetArray(g_origins, random(g_origins_count), origin);
	
	create_roach(origin);
	
	if (g_canattack && is_user_valid(attacker) && entity_get_int(victim, EV_INT_iuser3) != 1111)
		g_points[attacker] += get_pcvar_num(cvar_reward);
	
	return HAM_IGNORED;
}

public fw_PlayerTakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	if (!is_user_connected(attacker))
		return HAM_IGNORED;
	
	if (!g_canattack)
		return HAM_SUPERCEDE;
	
	switch (get_pcvar_num(cvar_damage))
	{
		case 1:
		{
			const DMG_KNIFE = (DMG_BULLET|DMG_NEVERGIB);
			
			if (damagebits & DMG_KNIFE && get_user_weapon(attacker) == CSW_KNIFE)
				return HAM_IGNORED;
			
			return HAM_SUPERCEDE;
		}
		case 2: return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

public fw_PlayerSpawn(id)
{
	if (is_user_alive(id))
	{
		strip_user_weapons(id);
		give_item(id, "weapon_knife");
	}
	
	return HAM_IGNORED;
}

public fw_WeaponBoxTouch(ent)
{
	if (is_valid_ent(ent))
		remove_entity(ent);
}

public fw_GetGameDescription()
{
	forward_return(FMV_STRING, "Cucarachas Mod");
	
	return FMRES_SUPERCEDE;
}

public fw_PlayerKilled(victim, attacker)
{
	if (is_user_valid(attacker))
		g_points[attacker] += get_pcvar_num(cvar_killreward);
}

/*================================================================================
 [Funciones internas]
=================================================================================*/

create_roach(const Float:s_origin[3])
{
	new Float:origin[3];
	new ent;
	
	xs_vec_copy(s_origin, origin);
	
	do
	{
		ent = create_entity("info_target");
	}
	while (!is_valid_ent(ent));
	
	while (!is_hull_vacant(origin, HULL_POINT))
	{
		origin[0] = origin[0] + random_float(0.0, 3.0);
		origin[1] = origin[1] + random_float(0.0, 3.0);
	}
	
	entity_set_origin(ent, origin);
	
	entity_set_string(ent, EV_SZ_classname, CLASSNAME);
	
	entity_set_model(ent, MODEL);
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_BOUNCE);
	entity_set_int(ent, EV_INT_solid, SOLID_SLIDEBOX);
	
	// Un poco m�s grandes para que no sea tan jodido pisarlas...
	entity_set_size(ent, Float:{ -2.0, -2.0, 0.0 }, Float:{ 2.0, 2.0, 1.0 });
	entity_set_int(ent, EV_INT_modelindex, g_model);
	
	entity_set_int(ent, EV_INT_sequence, 0);
	entity_set_float(ent, EV_FL_animtime, get_gametime());
	entity_set_float(ent, EV_FL_framerate, 1.0);
	
	entity_set_float(ent, EV_FL_takedamage, 1.0);
	entity_set_float(ent, EV_FL_health, VIDA);
	entity_set_float(ent, EV_FL_gravity, 0.6);
	entity_set_float(ent, EV_FL_friction, 0.8);
	
	entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.1);
	
	if (g_glow)
	{
		static const RGB_COLORS[][3] =
		{
			{	150,	170,	200	},	// Blanco
			{	255,	0,	0	},	// Rojo
			{	0,	255,	0	},	// Verde
			{	0,	0,	255	},	// Azul
			{	255,	255,	0	},	// Amarillo
			{	0,	250,	250	},	// Celeste
			{	170,	50,	100	},	// Magenta
			{	100,	50,	200	},	// Morado
			{	255,	150,	100	}	// Naranja
		};
		
		new rdn = (g_glow == sizeof(RGB_COLORS)) ? random(sizeof(RGB_COLORS)) : g_glow-1;
		
		set_rendering(ent, kRenderFxGlowShell, RGB_COLORS[rdn][0], RGB_COLORS[rdn][1], RGB_COLORS[rdn][2], kRenderNormal, 25);
	}
	
	drop_to_floor(ent);
	
	if (!g_reg)
	{
		RegisterHamFromEntity(Ham_TakeDamage, ent, "fw_RoachTakeDamage", 0);
		RegisterHamFromEntity(Ham_Killed, ent, "fw_RoachKilled", 1);
		
		g_reg = 1;
	}
	
	return ent;
}

bool:is_hull_vacant(const Float:origin[3], hull)
{
	return !trace_hull(origin, hull, 0, 0);
}

roach_random_move(ent, Float:velocity[3])
{
	static Float:spd;
	spd = random_float(0.0, NORMAL_SPEED);
	velocity[0] = random_num(0, 1) ? spd : -spd; // Por alguna razon, random() sale casi siempre 0, es mejor random_num
	velocity[1] = random_num(0, 1) ? floatsqroot(NORMAL_SPEED*NORMAL_SPEED - spd*spd) : 0.0 - floatsqroot(NORMAL_SPEED*NORMAL_SPEED - spd*spd);
	//velocity[2] = random(25) ? 0.0 : SALTO;
				
	entity_set_vector(ent, EV_VEC_velocity, velocity);
		
	vector_to_angle(velocity, velocity);
	entity_set_vector(ent, EV_VEC_angles, velocity);
}

get_closest_player(ent)
{
	static players[32], num;
	get_players(players, num, "a");
	
	new player = 0;
	static id, Float:dist, Float:mindist;
	mindist = 5000.0;
	
	for (new i = 0; i < num; i++)
	{
		player = players[i];
		
		dist = entity_range(player, ent);
		
		if (dist <= mindist)
		{
			id = player;
			mindist = dist;
		}
	}
	
	return id;
}

/*================================================================================
 [Funciones no relacionadas a los NPC]
=================================================================================*/

colored_print(id, msg[], any:...)
{
	static send[191];
	vformat(send, 190, msg, 3);
	
	static msgSayText;
	if (!msgSayText)
		msgSayText = get_user_msgid("SayText");
	
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, msgSayText, _, id);
	write_byte(33);
	write_string(send);
	message_end();
}

/*================================================================================
 [Efectos visuales]
=================================================================================*/

// De HL Snarks
FX_StreakSplash( const Float:Origin[ 3 ], const Float:Direction[ 3 ], const Color, const Count, const Speed, const VelocityRange )
{
	#define message_begin_f(%1,%2,%3) ( engfunc ( EngFunc_MessageBegin, %1, %2, %3 ) )
	#define write_coord_f(%1)         ( engfunc ( EngFunc_WriteCoord, %1 ) )
	
	message_begin_f( MSG_PVS, SVC_TEMPENTITY, Origin, 0);
	write_byte( TE_STREAK_SPLASH );
	write_coord_f( Origin[ 0 ] );
	write_coord_f( Origin[ 1 ] );
	write_coord_f( Origin[ 2 ] );
	write_coord_f( Direction[ 0 ] );
	write_coord_f( Direction[ 1 ] );
	write_coord_f( Direction[ 2 ] );
	write_byte( min( Color, 255 ) );
	write_short( Count );
	write_short( Speed );
	write_short( VelocityRange );// random velocity modifier
	message_end();
}

UTIL_BloodDrips(Float:Origin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BLOODSPRITE);
	engfunc(EngFunc_WriteCoord, Origin[0]);
	engfunc(EngFunc_WriteCoord, Origin[1]);
	engfunc(EngFunc_WriteCoord, Origin[2]);
	write_short(g_sprindex[SPR_BLOOD]);
	write_short(g_sprindex[SPR_BLOODSPRAY]);
	write_byte(195);
	write_byte(CANTIDAD_BLOOD);
	message_end();
}

/*================================================================================
 [Natives]
=================================================================================*/
	
public native_register_extra_item(plugin, params)
{
	new name[32];
	get_string(1, name, charsmax(name));
	ArrayPushString(g_extra_names, name);
	ArrayPushCell(g_extra_costs, get_param(2));
	g_extra_items++;
	
	return g_extra_items;
}

public native_get_user_points(id)
{
	return g_points[id];
}

public native_set_user_points(id, points)
{
	g_points[id] = points;
}

public native_spawn_roach(plugin, params)
{
	if (!g_canattack)
		return 0;
	
	new ent = find_ent_by_class(-1, CLASSNAME);
	if (!ent)
		return 0;
	
	remove_entity(ent);
	
	new Float:origin[3];
	get_array_f(1, origin, 3);
	
	return create_roach(origin);
}

public native_get_user_repel(id)
{
	return g_repel[id];
}

public native_set_user_repel(id, repel)
{
	g_repel[id] = repel;
}
