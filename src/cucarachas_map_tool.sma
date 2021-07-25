#include <amxmodx>
#include <engine>

#define PLUGIN "CM Map Tool"
#define VERSION "0.3"

#pragma semicolon 1

new szBuffer[196], g_menu, g_glow, g_active, g_max = 30;

new const MODEL[] = "models/chick.mdl";

public plugin_precache()
{
	precache_model(MODEL);
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, "Mario AR.");
	
	register_clcmd("say /cmenu", "clcmd_menu");
	
	g_menu = menu_create("Menu Cuca Mod Map Tool", "menu_cuca");
	menu_additem(g_menu, "Crear origin aqui");
	menu_additem(g_menu, "Remover el origin mas cercano");
	menu_additem(g_menu, "Remover todos los origins");
	menu_additem(g_menu, "Aumentar cantidad de cucarachas");
	menu_additem(g_menu, "Reducir cantidad de cucarachas");
	menu_additem(g_menu, "Cambiar glow^n");
	menu_additem(g_menu, "\yGuardar^n");
	menu_additem(g_menu, "Reiniciar la ronda");
	menu_additem(g_menu, "Reiniciar el mapa^n");
	menu_additem(g_menu, "\rSalir");
	menu_setprop(g_menu, MPROP_PERPAGE, 0);
	menu_setprop(g_menu, MPROP_EXIT, MEXIT_NEVER);
}

public clcmd_menu(id)
{
	if (~get_user_flags(id) & ADMIN_IMMUNITY)
		return PLUGIN_CONTINUE;
	
	if (!g_active)
	{
		new szMap[32], szOrigins[3][10], Float:origins[3];
	
		get_mapname(szMap, charsmax(szMap));
		get_localinfo("amxx_configsdir", szBuffer, charsmax(szBuffer));
		
		format(szBuffer, charsmax(szBuffer), "%s/Cucarachas_Mod", szBuffer);
		
		if (!dir_exists(szBuffer))
			mkdir(szBuffer);
		
		format(szBuffer, charsmax(szBuffer), "%s/%s.ini", szBuffer, szMap);
		
		if (file_exists(szBuffer))
		{
			new File = fopen(szBuffer, "rt");
			fgets(File, szMap, charsmax(szMap));
			parse(szMap, szOrigins[0], charsmax(szOrigins[]), szOrigins[1], charsmax(szOrigins[]));
			g_max = str_to_num(szOrigins[0]);
			g_glow = str_to_num(szOrigins[1]);
			
			while (!feof(File))
			{
				fgets(File, szMap, charsmax(szMap));
				trim(szMap);
				parse(szMap, szOrigins[0], charsmax(szOrigins[]), szOrigins[1], charsmax(szOrigins[]), szOrigins[2], charsmax(szOrigins[]));
				
				origins[0] = str_to_float(szOrigins[0]);
				origins[1] = str_to_float(szOrigins[1]);
				origins[2] = str_to_float(szOrigins[2]);
				
				new ent = create_entity("info_target");
				entity_set_size(ent, Float:{ -2.0, -2.0, 0.0 }, Float:{ 2.0, 2.0, 1.0 });
				entity_set_model(ent, MODEL);
				set_rendering(ent, kRenderFxGlowShell, 255, 255, 255, kRenderNormal, 25);
				entity_set_string(ent, EV_SZ_classname, "roach_ent");
				entity_set_origin(ent, origins);
			}
			
			fclose(File);
		}
		
		g_active = 1;
	}
	
	menu_display(id, g_menu);
	return PLUGIN_HANDLED;
}

public menu_cuca(id, menu, item)
{
	switch (item)
	{
		case 0:
		{
			if (!is_user_alive(id))
			{
				client_print(id, print_chat, "Necesitas estar vivo!");
			}
			else
			{
				new Float:origin[3];
				entity_get_vector(id, EV_VEC_origin, origin);
				
				new ent = create_entity("info_target");
				entity_set_size(ent, Float:{ -2.0, -2.0, 0.0 }, Float:{ 2.0, 2.0, 1.0 });
				entity_set_model(ent, MODEL);
				set_rendering(ent, kRenderFxGlowShell, 255, 255, 255, kRenderNormal, 25);
				entity_set_string(ent, EV_SZ_classname, "roach_ent");
				entity_set_origin(ent, origin);
				client_print(id, print_chat, "Entidad creada.");
			}
		}
		case 1:
		{
			new ent = get_closest_entity(id, "roach_ent");
			
			if (ent)
			{
				remove_entity(ent);
				client_print(id, print_chat, "Entidad removida.");
			}
			else
				client_print(id, print_chat, "No hay entidades de cucarachas.");
		}
		case 2:
		{
			new ent = -1;
			while ((ent = find_ent_by_class(ent, "roach_ent")) > 0)
			{
				remove_entity(ent);
			}
			
			client_print(id, print_chat, "Se han removido todas las entidades de cucarachas.");
		}
		case 3:
		{
			client_print(id, print_chat, "Cantidad actual: %d", ++g_max);
		}
		case 4:
		{
			if (g_max > 1)
				g_max--;
			
			client_print(id, print_chat, "Cantidad actual: %d", g_max);
		}
		case 5:
		{
			static const COLORS[][] = { "blanco", "rojo", "verde", "azul", "amarillo", "celeste", "violeta", "morado", "naranja", "aleatorio"};
			g_glow++;
			
			if (g_glow > sizeof(COLORS))
			{
				client_print(id, print_chat, "Glow desactivado.");
				g_glow = 0;
			}
			else
			{
				client_print(id, print_chat, "Glow activado (color %s).", COLORS[g_glow-1]);
			}
		}
		case 6:
		{
			if (file_exists(szBuffer))
			{
				delete_file(szBuffer);
			}
			
			new ent, File = fopen(szBuffer, "wt");
			fprintf(File, "%d %d^n", g_max, g_glow);
			
			new Float:origin[3];
			while ((ent = find_ent_by_class(ent, "roach_ent")) > 0)
			{
				entity_get_vector(ent, EV_VEC_origin, origin);
				fprintf(File, "^"%.2f^" ^"%.2f^" ^"%.2f^"^n", origin[0], origin[1], origin[2]);
				//remove_entity(ent);
			}
			
			fclose(File);
			client_print(id, print_chat, "Datos guardados.");
		}
		case 7: set_cvar_num("sv_restart", 1);
		case 8: server_cmd("restart");
		case 9: return PLUGIN_HANDLED;
	}
	
	menu_display(id, g_menu);
	
	return PLUGIN_HANDLED;
}

get_closest_entity(ent_origin, const classname[])
{
	new ent = find_ent_by_class(-1, classname);
	new Float:range = entity_range(ent_origin, ent);
	new ret = ent;
	new Float:ret_range;
	
	while ((ent = find_ent_by_class(ent, classname)) > 0)
	{
		if ((ret_range = entity_range(ent_origin, ent)) < range)
		{
			range = ret_range;
			ret = ent;
		}
	}
	
	return ret;
}

