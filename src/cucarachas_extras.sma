#include <amxmodx>
#include <cstrike>
#include <fun>
#include <cucarachas_mod>

#define PLUGIN "CM Extras"
#define VERSION "0.1"

#pragma semicolon 1

new g_item[6];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, "Mario AR.");
	
	g_item[0] = cm_register_extra_item("+20 HP", 5);
	g_item[1] = cm_register_extra_item("+50 HP", 10);
	g_item[2] = cm_register_extra_item("Chaleco",8);
	g_item[3] = cm_register_extra_item("Repelente (10s)", 15);
	g_item[4] = cm_register_extra_item("Granada", 3);
	g_item[5] = cm_register_extra_item("MP5Navy", 5);
}

public cm_extra_item_selected(id, item)
{
	for (new i = 0; i < 6; i++)
	{
		if (item == g_item[i])
		{
			switch (i)
			{
				case 0:
				{
					if (!is_user_alive(id))
					{
						client_print(id, print_center, "Necesitas estar vivo para comprar esto!");
						return PLUGIN_HANDLED;
					}
					
					set_user_health(id, get_user_health(id) + 20);
				}
				case 1:
				{
					if (!is_user_alive(id))
					{
						client_print(id, print_center, "Necesitas estar vivo para comprar esto!");
						return PLUGIN_HANDLED;
					}
					
					set_user_health(id, get_user_health(id) + 50);
				}
				case 2:
				{
					if (!is_user_alive(id))
					{
						client_print(id, print_center, "Necesitas estar vivo para comprar esto!");
						return PLUGIN_HANDLED;
					}
					
					cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM);
				}
				case 3:
				{
					if (!is_user_alive(id))
					{
						client_print(id, print_center, "Necesitas estar vivo para comprar esto!");
						return PLUGIN_HANDLED;
					}
					
					cm_set_user_repel(id, 1);
					set_task(10.0, "remove_repel", id);
				}
				case 4:
				{
					if (!is_user_alive(id))
					{
						client_print(id, print_center, "Necesitas estar vivo para comprar esto!");
						return PLUGIN_HANDLED;
					}
					
					give_item(id, "weapon_hegrenade");
				}
				case 5:
				{
					if (!is_user_alive(id))
					{
						client_print(id, print_center, "Necesitas estar vivo para comprar esto!");
						return PLUGIN_HANDLED;
					}
					
					give_item(id, "weapon_mp5navy");
					cs_set_user_bpammo(id, CSW_MP5NAVY, 120);
				}
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public remove_repel(id)
{
	cm_set_user_repel(id);
}
