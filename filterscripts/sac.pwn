#include <a_samp>
#include <foreach>
#include <zcmd>
#include <sscanf2>


#define ACNAME "SprunkGuard"
#define VERSION "0.3"
//#define DEFAULT_ARMOUR


#define COLOUR_LBLUE 0x0094FFFF
#define COLOUR_GREEN 0x00CC17FF
#define COLOUR_GREY 0x808080FF
#define COLOUR_RED 0xFF0000FF


new lagcompmode,
	money[MAX_PLAYERS],
	weapon[MAX_PLAYERS][47],
	bool:weapon_allowed[47] = true,
	Float:phealth[MAX_PLAYERS],
	Float:parmour[MAX_PLAYERS],
	Float:vhealth[MAX_VEHICLES];


stock CS_GetPlayerMoney(playerid) return money[playerid];
stock CS_SetPlayerMoney(playerid, amount) return GivePlayerMoney(playerid, amount - GetPlayerMoney(playerid));
stock CS_GivePlayerMoney(playerid, amount) return GivePlayerMoney(playerid, amount);
stock CS_TakePlayerMoney(playerid, amount) return GivePlayerMoney(playerid, -amount);

stock CS_GivePlayerWeapon(playerid, weaponid, ammo = 1)
{
	switch(weaponid)
	{
		case 1 .. 15, 40,  44 .. 46: ammo = 1;
	}

	switch(weaponid)
	{
		case 2 .. 9: for(new w = 2; w <= 9; w ++) weapon[playerid][w] = 0;
		case 10 .. 15: for(new w = 10; w <= 15; w ++) weapon[playerid][w] = 0;
		case 16 .. 18, 39: for(new w = 16; w <= 18; w ++) weapon[playerid][w] = 0;
		case 22 .. 24: for(new w = 22; w <= 24; w ++) weapon[playerid][w] = 0;
		case 25 .. 27: for(new w = 25; w <= 27; w ++) weapon[playerid][w] = 0;
		case 28, 29, 32: for(new w = 28; w <= 32; w ++)
		{
			if((w == 30) && (w == 31)) break;
			weapon[playerid][w] = 0;
		}
		case 30, 31: for(new w = 30; w <= 31; w ++) weapon[playerid][w] = 0;
		case 33, 34: for(new w = 33; w <= 34; w ++) weapon[playerid][w] = 0;
		case 35 .. 38: for(new w = 35; w <= 38; w ++) weapon[playerid][w] = 0;
		case 41 .. 43: for(new w = 41; w <= 43; w ++) weapon[playerid][w] = 0;
		case 44 .. 46: for(new w = 44; w <= 46; w ++) weapon[playerid][w] = 0;
	}

	weapon[playerid][weaponid] += ammo;
	ResetPlayerWeapons(playerid);
	for(new i = 0; i < 47; i ++)
	{
		if(weapon[playerid][i] > 0) GivePlayerWeapon(playerid, i, weapon[playerid][i]);
	}
	SetPlayerArmedWeapon(playerid, weaponid);
	return 1;
}

stock CS_TakePlayerWeapon(playerid, weaponid)
{
	weapon[playerid][weaponid] = 0;
	ResetPlayerWeapons(playerid);
	for(new i = 0; i < 47; i ++)
	{
		if(weapon[playerid][i] > 0) GivePlayerWeapon(playerid, i, weapon[playerid][i]);
	}
	SetPlayerArmedWeapon(playerid, 0);
	return 1;
}

stock CS_ResetPlayerWeapons(playerid)
{
	for(new i = 0; i < 47; i ++) weapon[playerid][i] = 0;
	ResetPlayerWeapons(playerid);
	return 1;
}

stock CS_GetPlayerHealth(playerid) return floatround(phealth[playerid]);

stock CS_SetPlayerHealth(playerid, Float:amount)
{
	phealth[playerid] = amount;
	SetPlayerHealth(playerid, amount);
	return 1;
}

stock CS_GetPlayerArmour(playerid) return floatround(parmour[playerid]);

stock CS_SetPlayerArmour(playerid, Float:amount)
{
	parmour[playerid] = amount;
	SetPlayerArmour(playerid, amount);
	return 1;
}

stock CS_GetVehicleHealth(vehicleid) return floatround(vhealth[vehicleid]);

stock CS_SetVehicleHealth(vehicleid, Float:amount)
{
	vhealth[vehicleid] = amount;
	SetVehicleHealth(vehicleid, amount);
	return 1;
}

stock CS_AddVehicle(modelid, Float:x, Float:y, Float:z, Float:rot, col1 = -1, col2 = -1, respawn_delay = -1)
{
	new vehicleid = AddStaticVehicleEx(modelid, x, y, z, rot, col1, col2, respawn_delay);
	CS_SetVehicleHealth(vehicleid, 1000);
	return vehicleid;
}

stock CS_CreateVehicle(modelid, Float:x, Float:y, Float:z, Float:rot, col1 = -1, col2 = -1, respawn_delay = -1)
{
	new vehicleid = CreateVehicle(modelid, x, y, z, rot, col1, col2, respawn_delay);
	CS_SetVehicleHealth(vehicleid, 1000);
	return vehicleid;
}


main(){}

public OnFilterScriptInit()
{
	printf("%s v.%s loaded", ACNAME, VERSION);

	lagcompmode = GetServerVarAsInt("lagcompmode");
	switch(lagcompmode)
	{
		case 0: printf("[%s] WARNING: lagcompmode is 0 - PROTECTION IS LIMITED\n"   \
		"  Please set lagcompmode to 1 for maximum protection", ACNAME);
		case 1: printf("[%s] INFO: Server at maximum protection", ACNAME);
		case 2: printf("[%s] WARNING: lagcompmode is 2 - PROTECTION IS LIMITED\n"   \
		"  Please set lagcompmode to 1 for maximum protection", ACNAME);
	}

	EnableStuntBonusForAll(0);

	for(new i = 0; i < 47; i ++)
	{
		switch(i)
		{
			case 35 .. 40, 44, 45: continue;
		}
		weapon_allowed[i] = true;
	}
	return 1;
}

public OnFilterScriptExit()
{
	printf("%s unloaded", ACNAME);
	return 1;
}

public OnPlayerConnect(playerid)
{
	new string[30];

	format(string, sizeof(string), "%s {%06x}PROTECTED", ACNAME, COLOUR_GREEN>>>8);
	SendClientMessage(playerid, COLOUR_LBLUE, string);

	money[playerid] = 0;
	phealth[playerid] = 0;
	parmour[playerid] = 0;

	for(new i = 0; i < 47; i ++) weapon[playerid][i] = 0;
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	money[playerid] = 0;
	phealth[playerid] = 0;
	parmour[playerid] = 0;

	for(new i = 0; i < 47; i ++) weapon[playerid][i] = 0;
	return 1;
}

public OnPlayerSpawn(playerid)
{
	CS_SetPlayerHealth(playerid, 100);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	CS_ResetPlayerWeapons(playerid);
	return 1;
}

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
	weapon[playerid][weaponid] -= 1;
	if((GetPlayerAmmo(playerid) > weapon[playerid][weaponid] + 1) && ((weaponid != 28) && (weaponid != 29) &&
		(weaponid != 32) && (weaponid != 38)))
	{
		SendClientMessage(playerid, COLOUR_RED, "[SprunkGuard] {FFFFFF}Ammo cheats (no-reload) detected!");
		printf("[SprunkGuard] Ammo cheats (no-reload) detected! ( Player: %s(%d) )", PlayerName(playerid), playerid);
		SetPlayerAmmo(playerid, weaponid, weapon[playerid][weaponid]);
	}
	if((GetPlayerAmmo(playerid) > weapon[playerid][weaponid] + 2) && ((weaponid == 28) && (weaponid == 29) &&
		(weaponid == 32)))
	{
		SendClientMessage(playerid, COLOUR_RED, "[SprunkGuard] {FFFFFF}Ammo cheats (no-reload) detected!");
		printf("[SprunkGuard] Ammo cheats (no-reload) detected! ( Player: %s(%d) )", PlayerName(playerid), playerid);
		SetPlayerAmmo(playerid, weaponid, weapon[playerid][weaponid]);
	}

	if(GetPlayerAmmo(playerid) < weapon[playerid][weaponid]) SetPlayerAmmo(playerid, weaponid, weapon[playerid][weaponid]);

	new string[51];
	format(string, sizeof(string), "[DEBUG] weaponid = %d | ammo = %d | hittype = %d", weaponid, weapon[playerid][weaponid], hittype);
	SendClientMessage(playerid, COLOUR_GREY, string);


	new Float:amount,
		Float:health,
		Float:armour;
	switch(weaponid)
	{
		case 22: amount = 8; // 9mm pistol
		case 23: amount = 13; // Silencer
		case 24: amount = 31; // Desert eagle (default is 46)
		case 25: amount = 33; // Shotgun (default is 49)
		case 26: amount = 22; // Sawnoff shotgun (default is 33)
		case 27: amount = 39; // Combat shotgun
		case 28: amount = 6; // Uzi
		case 29: amount = 8; // Mp5
		case 30: amount = 9; // Ak47
		case 31: amount = 9; // M4
		case 32: amount = 6; // Tec9
		case 33: amount = 24; // Country rifle
		case 34: amount = 47; // Sniper (default is 41)
	}

	switch(hittype)
	{
		case 1:
		{
			armour = CS_GetPlayerArmour(hitid);
			health = CS_GetPlayerHealth(hitid);
			printf("%f %f", armour, health);

			if(armour == 0) CS_SetPlayerHealth(hitid, health - amount);

			#if defined DEFAULT_ARMOUR

			if(armour >= amount)
			{
				CS_SetPlayerArmour(hitid, armour - amount);
			}
			else if((armour < amount) && (armour != 0))
			{
				new Float:loss = amount - armour;
				CS_SetPlayerArmour(hitid, 0);
				CS_SetPlayerHealth(hitid, health - loss);
			}

			#else

			new Float:loss = floatround(amount / 1.1);

			if(armour >= loss)
			{
				CS_SetPlayerArmour(hitid, armour - loss);
				CS_SetPlayerHealth(hitid, health - floatround(amount - loss));
			}
			else if((armour < loss) && (armour != 0))
			{
				CS_SetPlayerArmour(hitid, 0);
				CS_SetPlayerHealth(hitid, health - (floatround(amount - loss) + (loss - armour)));
			}

			#endif
		}
		case 2:
		{
			health = CS_GetVehicleHealth(hitid);

			switch(hitid)
			{
				case 427, 428, 601, 520, 548:
				{
					amount = amount / 1.325;
					floatround(amount, floatround_ceil);
				}
				case 432:
				{
					amount = amount / 1.75;
					floatround(amount, floatround_ceil);
				}
			}
			CS_SetVehicleHealth(hitid, health - amount);
		}
	}

	/*if(Lrapid_oldticks[playerid] == 0) Lrapid_oldticks[playerid] = GetTickCount();
	else
	{
		new Lrapid_intervals,
			Lrapid_checkreturn = 1;
		if((Lrapid_intervals = GetTickCount() - Lrapid_oldticks[playerid]) <= 35 &&(GetPlayerWeapon(playerid) != 38
			&& GetPlayerWeapon(playerid) != 28 && GetPlayerWeapon(playerid) != 32)) { //Submachines such as 32, 28 and minigun got a higher fire rate.
	    	Lrapid_checkreturn = CallLocalFunction("OnPlayerRapidFire", "iii", playerid, weaponid, Lrapid_intervals);
		}
		else if((Lrapid_intervals = GetTickCount() - Lrapid_oldticks[playerid]) <= 370 && (GetPlayerWeapon(playerid) == 34 ||
		GetPlayerWeapon(playerid) == 33)) {
		    Lrapid_checkreturn = CallLocalFunction("OnPlayerRapidFire", "iii", playerid, weaponid, Lrapid_intervals);
		}
		Lrapid_oldticks[playerid] = GetTickCount();
		if(!Lrapid_checkreturn) return 0;
	}*/
	return 0;
}

CMD:w(playerid, params[])
{
	new weaponid;
	if(sscanf(params, "d", weaponid)) return SendClientMessage(playerid, COLOUR_RED, "Syntax: {FFFFFF}/w [weaponid]");
	if((weaponid == 0) || ((weaponid >= 19) && (weaponid <= 21)) || (weaponid > 46)) return SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}Invalid 'weaponid'! Please try again.");

	new ammo;
	switch(weaponid)
	{
		case 1 .. 15, 40,  44 .. 46: ammo = 1;
		default: ammo = 250;
	}
	CS_GivePlayerWeapon(playerid, weaponid, ammo);
	return 1;
}

CMD:tw(playerid, params[])
{
	new weaponid;
	if(sscanf(params, "d", weaponid)) return SendClientMessage(playerid, COLOUR_RED, "Syntax: {FFFFFF}/w [weaponid]");
	if((weaponid == 0) || ((weaponid >= 19) && (weaponid <= 21)) || (weaponid > 46)) return SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}Invalid 'weaponid'! Please try again.");

	CS_TakePlayerWeapon(playerid, weaponid);
	return 1;
}

CMD:a(playerid, params[])
{
	CS_SetPlayerArmour(playerid, 100);
	return 1;
}

CMD:ta(playerid, params[])
{
	CS_SetPlayerArmour(playerid, 0);
	return 1;
}

public OnUnoccupiedVehicleUpdate(vehicleid, playerid, passenger_seat, Float:new_x, Float:new_y, Float:new_z)
{
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}

public OnPlayerUpdate(playerid)
{
	new weapons[13][2];

	for(new i = 0; i < 13; i ++)
	{
		GetPlayerWeaponData(playerid, i, weapons[i][0], weapons[i][1]);

		if(weapon_allowed[weapons[i][0]] == false) CS_TakePlayerWeapon(playerid, weapons[i][0]);
	}

	new Float:health;
	GetPlayerHealth(playerid, health);

	if(health > CS_GetPlayerHealth(playerid)) CS_SetPlayerHealth(playerid, CS_GetPlayerHealth(playerid));


	if(GetPlayerMoney(playerid) != money[playerid]) CS_SetPlayerMoney(playerid, money[playerid]);
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}

stock PlayerName(playerid)
{
	new name[MAX_PLAYER_NAME];
	GetPlayerName(playerid, name, MAX_PLAYER_NAME);
	return name;
}
