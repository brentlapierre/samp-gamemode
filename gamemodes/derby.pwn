#include	<a_samp>
#include	<foreach>
#include	<sscanf2>
#include	<zcmd>
#include	<streamer>


#define		SERVER_NAME					"NFG Derby"
#define		SERVER_VER					"0.1"
#define		SERVER_WEBSITE				"nofearzzgaming.com"
#define		SAMP_VER					"0.3.7 RC2"

#define		MIN_ADMIN_MUTE				1
#define		MIN_ADMIN_UNMUTE			1
#define		MIN_ADMIN_JAIL				1
#define		MIN_ADMIN_UNJAIL			1
#define		MIN_ADMIN_KICK				1
#define		MIN_ADMIN_V					1

// Colour definitions
#define		COLOUR_RED					0xFF0000FF
#define		COLOUR_ORANGE				0xFF6A00FF
#define		COLOUR_YELLOWORANGE			0xFFA100FF
#define		COLOUR_YELLOW				0xFFCC00FF
#define		COLOUR_GREEN				0x00CE18FF
#define		COLOUR_DARKGREEN			0x006B0AFF
#define		COLOUR_TURQUOISE			0x00D861FF
#define		COLOUR_SKYBLUE				0x199FFFFF
#define		COLOUR_BLUE					0x0000FFFF
#define		COLOUR_NAVYBLUE				0x09395BFF
#define		COLOUR_PURPLE				0xB200FFFF
#define		COLOUR_DARKPURPLE			0x57007FFF
#define		COLOUR_PINK					0xFF42C0FF
#define		COLOUR_GREY					0x9E9E9EFF
#define		COLOUR_DARKGREY				0x444444FF
#define		COLOUR_WHITE				0xFFFFFFFF
#define		COLOUR_SYNTAX				0xFFCA4FFF
#define		COLOUR_ADMIN				0x23597FFF

// Misc. definitions
#define		IsValidVehicleModel(%0) ((%0 < 400) || (%0 > 611))
#define		GetVehicleModelName(%0) VehicleNames[%0 - 400]


// Vehicle Model Names
new VehicleNames[][] =
{
	"Landstalker", "Bravura", "Buffalo", "Linerunner", "Perrenial", "Sentinel", "Dumper", "Firetruck",
	"Trashmaster", "Stretch", "Manana", "Infernus", "Voodoo", "Pony", "Mule", "Cheetah", "Ambulance", "Leviathan",
	"Moonbeam", "Esperanto", "Taxi", "Washington", "Bobcat", "Whoopee", "BF Injection", "Hunter", "Premier",
	"Enforcer", "Securicar", "Banshee", "Predator", "Bus", "Rhino", "Barracks", "Hotknife", "Trailer", "Previon",
	"Coach", "Cabbie", "Stallion", "Rumpo", "RC Bandit", "Romero", "Packer", "Monster", "Admiral", "Squalo",
	"Seasparrow", "Pizzaboy", "Tram", "Trailer", "Turismo", "Speeder", "Reefer", "Tropic", "Flatbed", "Yankee",
	"Caddy", "Solair", "Berkley's RC Van", "Skimmer", "PCJ-600", "Faggio", "Freeway", "RC Baron", "RC Raider",
	"Glendale", "Oceanic", "Sanchez", "Sparrow", "Patriot", "Quad", "Coastguard", "Dinghy", "Hermes", "Sabre",
	"Rustler", "ZR-350", "Walton", "Regina", "Comet", "BMX", "Burrito", "Camper", "Marquis", "Baggage", "Dozer",
	"Maverick", "News Chopper", "Rancher", "FBI Rancher", "Virgo", "Greenwood", "Jetmax", "Hotring", "Sandking",
	"Blista Compact", "Police Maverick", "Boxville", "Benson", "Mesa", "RC Goblin", "Hotring Racer A",
	"Hotring Racer B", "Bloodring Banger", "Rancher", "Super GT", "Elegant", "Journey", "Bike", "Mountain Bike",
	"Beagle", "Cropduster", "Stunt Plane", "Tanker", "Roadtrain", "Nebula", "Majestic", "Buccaneer", "Shamal", "Hydra",
	"FCR-900", "NRG-500", "HPV1000", "Cement Truck", "Tow Truck", "Fortune", "Cadrona", "FBI Truck", "Willard",
	"Forklift", "Tractor", "Combine", "Feltzer", "Remington", "Slamvan", "Blade", "Freight", "Streak", "Vortex",
	"Vincent", "Bullet", "Clover", "Sadler", "Firetruck", "Hustler", "Intruder", "Primo", "Cargobob", "Tampa",
	"Sunrise", "Merit", "Utility", "Nevada", "Yosemite", "Windsor", "Monster", "Monster", "Uranus", "Jester",
	"Sultan", "Stratium", "Elegy", "Raindance", "RC Tiger", "Flash", "Tahoma", "Savanna", "Bandito", "Freight Flat",
	"Streak Carriage", "Go-Kart", "Lawnmower", "Dune", "Sweeper", "Broadway", "Tornado", "AT-400", "DFT-30", "Huntley",
	"Stafford", "BF-400", "News Van", "Tug", "Trailer", "Emperor", "Wayfarer", "Euros", "Hotdog", "Club",
	"Freight Box", "Trailer", "Andromada", "Dodo", "RC Cam", "Launch", "Police Car (LS)", "Police Car (SF)",
	"Police Car (LV)", "Police Ranger", "Picador", "S.W.A.T. Tank", "Alpha", "Phoenix", "Glendale (damaged)",
	"Sadler (damaged)", "Luggage", "Luggage", "Stairs", "Boxville", "Tiller", "Utility Trailer"
};

// Global variables
new clock[3];


enum PlayerSettings
{
	bool:Spawned,
	bool:Banned,
	Clockmode,
	Vehicleid,
	Admin,
	Wanted,
	Money,
	bool:InCombat,
	bool:Cuffed,
	Jail,
	Mute,
	MuteTimer,
	AdminJail,
	AdminJailTimer
}
new Player[MAX_PLAYERS][PlayerSettings];

enum VehicleSettings
{
	bool:Engine,
	bool:Lights,
	bool:Alarm,
	bool:Hood,
	bool:Trunk,
	bool:Locked,
	Neon[2]
}
new Vehicle[MAX_VEHICLES][VehicleSettings];

new Text:TD_clock_default,
	Text:TD_clock_ampm,
	Text:TD_ampm;


main(){}


public OnGameModeInit()
{
	printf("%s has loaded", SERVER_NAME);

	new string[34];
	format(string, sizeof(string), "hostname %s %s [%s]", SERVER_NAME, SERVER_VER, SAMP_VER);
	SendRconCommand(string);

	SetGameModeText("Derby");

	SetWeather(1);
	SetWorldTime(12);
	clock[1] = 12;
	TextDrawSetString(Text:TD_ampm, "pm");

	DisableInteriorEnterExits();
	UsePlayerPedAnims();
	SetDeathDropAmount(0);
	EnableStuntBonusForAll(0);

	SetTimer("MainTimer", 1000, true);

	AddPlayerClass(0, 2105.4773, -1776.6875, 13.3911, 120.5673, 0, 0, 0, 0, 0, 0);


	TD_clock_default = TextDrawCreate(550.000000, 20.000000, "00:00");
	TextDrawBackgroundColor(TD_clock_default, 255);
	TextDrawFont(TD_clock_default, 3);
	TextDrawLetterSize(TD_clock_default, 0.539999, 2.299999);
	TextDrawColor(TD_clock_default, -1);
	TextDrawSetOutline(TD_clock_default, 1);
	TextDrawSetProportional(TD_clock_default, 1);
	TextDrawSetSelectable(TD_clock_default, 0);

	TD_clock_ampm = TextDrawCreate(550.000000, 20.000000, "00:00");
	TextDrawBackgroundColor(TD_clock_ampm, 255);
	TextDrawFont(TD_clock_ampm, 3);
	TextDrawLetterSize(TD_clock_ampm, 0.539999, 2.299999);
	TextDrawColor(TD_clock_ampm, -1);
	TextDrawSetOutline(TD_clock_ampm, 1);
	TextDrawSetProportional(TD_clock_ampm, 1);
	TextDrawSetSelectable(TD_clock_ampm, 0);

	TD_ampm = TextDrawCreate(607.000000, 21.000000, "pm");
	TextDrawBackgroundColor(TD_ampm, 255);
	TextDrawFont(TD_ampm, 2);
	TextDrawLetterSize(TD_ampm, 0.290000, 1.400000);
	TextDrawColor(TD_ampm, -1);
	TextDrawSetOutline(TD_ampm, 1);
	TextDrawSetProportional(TD_ampm, 1);
	TextDrawSetSelectable(TD_ampm, 0);
	return 1;
}

public OnGameModeExit()
{
	printf("%s has unloaded", SERVER_NAME);

	TextDrawHideForAll(Text:TD_clock_default);
	TextDrawDestroy(Text:TD_clock_default);
	TextDrawHideForAll(Text:TD_clock_ampm);
	TextDrawDestroy(Text:TD_clock_ampm);
	TextDrawHideForAll(Text:TD_ampm);
	TextDrawDestroy(Text:TD_ampm);
	return 1;
}

forward MainTimer();
public MainTimer()
{
	clock[2] ++;

	if(clock[2] == 60)
	{
		clock[1] ++;
		clock[2] = 0;
		SetWorldTime(clock[1]);

		if(clock[1] == 12) TextDrawSetString(Text:TD_ampm, "pm");
	}
	if(clock[1] == 24)
	{
		clock[0] ++;
		clock[1] = 0;

		TextDrawSetString(Text:TD_ampm, "am");
	}
	if(clock[0] == 8)
	{
		clock[0] = 0;
	}

	new string[6],
		hour = clock[1];

	format(string, sizeof(string), "%02d:%02d", clock[1], clock[2]);
	TextDrawSetString(Text:TD_clock_default, string);

	if(hour > 12) hour = hour - 12;
	format(string, sizeof(string), "%02d:%02d", hour, clock[2]);
	TextDrawSetString(Text:TD_clock_ampm, string);
	return 1;
}

forward UnmuteTimer(playerid);
public UnmuteTimer(playerid) Player[playerid][Mute] = 0;

forward UnjailTimer_Admin(playerid);
public UnjailTimer_Admin(playerid)
{
	Player[playerid][AdminJail] = 0;
}

public OnIncomingConnection(playerid, ip_address[], port)
{
	printf("Incoming connection: %s:%d has taken playerid %d", ip_address, port, playerid);
	return 1;
}

public OnPlayerConnect(playerid)
{
	new string[79];
	format(string, sizeof(string), "Welcome to %s %s", SERVER_NAME, SERVER_VER);
	SendClientMessage(playerid, COLOUR_WHITE, string);

	format(string, sizeof(string), "%s(%d) has joined %s", PlayerName(playerid), playerid, SERVER_NAME);
	foreach(Player, i)
	{
		if(i != playerid) SendClientMessage(i, COLOUR_GREY, string);
	}

	if(!strcmp(PlayerName(playerid), "Brent")) Player[playerid][Admin] = 5;
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	new string[89];
	switch(reason)
	{
		case 0: format(string, sizeof(string), "%s(%d) has left %s (Timed out)", PlayerName(playerid), playerid, SERVER_NAME);
		case 1: format(string, sizeof(string), "%s(%d) has left %s (Quit)", PlayerName(playerid), playerid, SERVER_NAME);
		case 2: format(string, sizeof(string), "%s(%d) has left %s (Kicked)", PlayerName(playerid), playerid, SERVER_NAME);
	}
	SendClientMessageToAll(COLOUR_GREY, string);

	TextDrawHideForPlayer(playerid, Text:TD_clock_default);
	TextDrawHideForPlayer(playerid, Text:TD_clock_ampm);
	TextDrawHideForPlayer(playerid, Text:TD_ampm);
	return 1;
}

public OnPlayerSpawn(playerid)
{
	Player[playerid][Spawned] = true;

	SetPlayerColor(playerid, COLOUR_WHITE);

	switch(Player[playerid][Clockmode])
	{
		case 0: TextDrawShowForPlayer(playerid, Text:TD_clock_default);
		case 1:
		{
			TextDrawShowForPlayer(playerid, Text:TD_clock_ampm);
			TextDrawShowForPlayer(playerid, Text:TD_ampm);
		}
	}
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	Player[playerid][Spawned] = false;

	switch(killerid)
	{
		case INVALID_PLAYER_ID:
		{
			SendDeathMessage(killerid, playerid, reason);
		}
		default: SendDeathMessage(playerid, INVALID_PLAYER_ID, reason);
	}

	if(killerid != INVALID_PLAYER_ID) SendDeathMessage(killerid, playerid, reason);
	else SendDeathMessage(playerid, INVALID_PLAYER_ID, reason);

	SetPlayerColor(playerid, COLOUR_GREY);
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	if(newstate == PLAYER_STATE_DRIVER)
	{
		new vehicleid = GetPlayerVehicleID(playerid);
		Player[playerid][Vehicleid] = vehicleid;

		if(Vehicle[vehicleid][Engine] == true)
		{
			new vengine, vlights, valarm, vdoors, vhood, vtrunk, vobjective;
			GetVehicleParamsEx(vehicleid, vengine, vlights, valarm, vdoors, vhood, vtrunk, vobjective);
			SetVehicleParamsEx(vehicleid, true, vlights, valarm, vdoors, vhood, vtrunk, vobjective);
		}
	}
	if(oldstate == PLAYER_STATE_DRIVER)
	{
		if(Vehicle[Player[playerid][Vehicleid]][Engine] == true)
		{
			new vengine, vlights, valarm, vdoors, vhood, vtrunk, vobjective;
			GetVehicleParamsEx(Player[playerid][Vehicleid], vengine, vlights, valarm, vdoors, vhood, vtrunk, vobjective);
			SetVehicleParamsEx(Player[playerid][Vehicleid], false, vlights, valarm, vdoors, vhood, vtrunk, vobjective);
		}

		Player[playerid][Vehicleid] = -1;
	}
	return 1;
}

/*public OnVehicleDeath(vehicleid, killerid)
{
	new vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective;
	GetVehicleParamsEx(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective);
	SetVehicleParamsEx(vehicleid, true, true, -1, false, false, false, -1);
	return ;
}*/

public OnPlayerText(playerid, text[])
{
	if(Player[playerid][Mute]) return 0;

	new string[159];
	format(string, sizeof(string), "{%06x}%s(%d): {FFFFFF}%s", GetPlayerColor(playerid)>>>8, PlayerName(playerid),
		playerid, text);
	SendClientMessageToAll(COLOUR_WHITE, string);
	return 0;
}

public OnPlayerCommandPerformed(playerid, cmdtext[], success)
{
	if(!success)
	{
		new i = strfind(cmdtext, " "),
			cmd[31];
		if(i != -1) strmid(cmd, cmdtext, 0, i, sizeof(cmd));
		else strcat(cmd, cmdtext);

		new string[76];
		format(string, sizeof(string), "Error: {FFFFFF}The command '%s' does not exist.", cmd);
		SendClientMessage(playerid, COLOUR_RED, string);
	}
	return 1;
}


/*				GENERAL COMMANDS			*/

CMD:clockmode(playerid, params[])
{
	new mode;
	if(sscanf(params, "d", mode)) return
		SendClientMessage(playerid, COLOUR_SYNTAX, "Syntax: {FFFFFF}/mode [0/1]");
	if((mode < 0) || (mode > 1)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}'/mode' must have a value of 0 or 1.");
	if(Player[playerid][Clockmode] == mode)
	{
		new string[45];
		format(string, sizeof(string), "Error: {FFFFFF}Your clock mode is already %d.", mode);
		return SendClientMessage(playerid, COLOUR_RED, string);
	}

	UpdatePlayerClock(playerid, mode);

	new string[56];
	format(string, sizeof(string), "Success: {FFFFFF}Your clock mode has been changed to %d.", mode);
	SendClientMessage(playerid, COLOUR_GREEN, string);
	return 1;
}


/*				ADMIN COMMANDS				*/

CMD:mute(playerid, params[])
{
	if(Player[playerid][Admin] < MIN_ADMIN_MUTE) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You do not have permission to use '/mute'.");

	new targetid, time, reason[21];
	if(sscanf(params, "uds[21](no reason)", targetid, time, reason)) return
		SendClientMessage(playerid, COLOUR_SYNTAX, "Syntax: {FFFFFF}/mute [ Player ] [ Time ] [ Reason " \
			"(Optional) ]  -- {A5A5A5}'/mute help' for more info");
	if(targetid == INVALID_PLAYER_ID) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}The player you tried to '/mute' does not exist.");
	if(playerid == targetid) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You cannot '/mute' yourself.");
	if(Player[targetid][Admin] >= Player[playerid][Admin]) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You cannot '/mute' a staff member of equal or" \
			" higher administration level.");
	if(Player[targetid][Mute])
	{
		new string[63];
		format(string, sizeof(string), "Error: {FFFFFF}%s(%d) is already muted.", PlayerName(targetid), targetid);
		return SendClientMessage(playerid, COLOUR_RED, string);
	}
	if((time < 60) && (time != -1)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}The 'time' must be 60 seconds and above.");
	if(time > 3600) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}The 'time' must be 3600 seconds and below.");

	Player[targetid][Mute] = time;

	if(time != -1) Player[targetid][MuteTimer] = SetTimerEx("UnmutePlayer", time, false, "d", targetid);

	new string[86];
	format(string, sizeof(string), "ADMIN: {FFFFFF}%s(%d) has been muted for %s.", PlayerName(targetid), targetid,
		reason);
	SendClientMessageToAll(COLOUR_ADMIN, string);
	return 1;
}

CMD:unmute(playerid, params[])
{
	if(Player[playerid][Admin] < MIN_ADMIN_UNMUTE) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You do not have permission to use '/unmute'.");

	new targetid;
	if(sscanf(params, "u", targetid)) return
		SendClientMessage(playerid, COLOUR_SYNTAX, "Syntax: {FFFFFF}/unmute [ Player ]");
	if(targetid == INVALID_PLAYER_ID) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}The player you tried to '/unmute' does not exist.");
	if(playerid == targetid) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You cannot '/unmute' yourself.");
	if(Player[targetid][Admin] >= Player[playerid][Admin]) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You cannot '/unmute' a staff member of equal or" \
			" higher administration level.");
	if(!Player[targetid][Mute])
	{
		new string[59];
		format(string, sizeof(string), "Error: {FFFFFF}%s(%d) is not muted.", PlayerName(targetid), targetid);
		return SendClientMessage(playerid, COLOUR_RED, string);
	}

	Player[targetid][Mute] = 0;

	KillTimer(Player[targetid][MuteTimer]);

	new string[63];
	format(string, sizeof(string), "ADMIN: {FFFFFF}%s(%d) has been unmuted.", PlayerName(targetid), targetid);
	SendClientMessageToAll(COLOUR_ADMIN, string);
	return 1;
}

CMD:jail(playerid, params[])
{
	if(Player[playerid][Admin] < MIN_ADMIN_JAIL) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You do not have permission to use '/jail'.");

	new targetid, time, reason[21];
	if(sscanf(params, "uds[21](no reason)", targetid, time, reason)) return
		SendClientMessage(playerid, COLOUR_SYNTAX, "Syntax: {FFFFFF}/jail [ Player ] [ Time ] [ Reason " \
			"(Optional) ]  -- {A5A5A5}'/mute help' for more info");
	if(targetid == INVALID_PLAYER_ID) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}The player you tried to '/jail' does not exist.");
	if(playerid == targetid) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You cannot '/jail' yourself.");
	if(Player[targetid][Admin] >= Player[playerid][Admin]) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You cannot '/jail' a staff member of equal or" \
			" higher administration level.");
	if(Player[targetid][AdminJail])
	{
		new string[65];
		format(string, sizeof(string), "Error: {FFFFFF}%s(%d) is already in jail.", PlayerName(targetid), targetid);
		return SendClientMessage(playerid, COLOUR_RED, string);
	}
	if(time < 60) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}The 'time' must be 60 seconds and above.");
	if(time > 600) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}The 'time' must be 600 seconds and below.");

	Player[targetid][AdminJail] = time;

	Player[targetid][AdminJailTimer] = SetTimerEx("UnjailPlayer_Admin", time, false, "d", targetid);

	new string[86];
	format(string, sizeof(string), "ADMIN: {FFFFFF}%s(%d) has been jailed for %s.", PlayerName(targetid), targetid,
		reason);
	SendClientMessageToAll(COLOUR_ADMIN, string);
	return 1;
}

CMD:unjail(playerid, params[])
{
	if(Player[playerid][Admin] < MIN_ADMIN_UNJAIL) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You do not have permission to use '/unjail'.");

	new targetid;
	if(sscanf(params, "u", targetid)) return
		SendClientMessage(playerid, COLOUR_SYNTAX, "Syntax: {FFFFFF}/unjail [ Player ]");
	if(targetid == INVALID_PLAYER_ID) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}The player you tried to '/unjail' does not exist.");
	if(playerid == targetid) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You cannot '/unjail' yourself.");
	if(Player[targetid][Admin] >= Player[playerid][Admin]) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You cannot '/unjail' a staff member of equal or" \
			" higher administration level.");
	if(!Player[targetid][AdminJail])
	{
		new string[61];
		format(string, sizeof(string), "Error: {FFFFFF}%s(%d) is not in jail.", PlayerName(targetid), targetid);
		return SendClientMessage(playerid, COLOUR_RED, string);
	}

	Player[targetid][AdminJail] = 0;

	KillTimer(Player[targetid][AdminJailTimer]);

	new string[64];
	format(string, sizeof(string), "ADMIN: {FFFFFF}%s(%d) has been unjailed.", PlayerName(targetid), targetid);
	SendClientMessageToAll(COLOUR_ADMIN, string);
	return 1;
}

CMD:kick(playerid, params[])
{
	if(Player[playerid][Admin] < MIN_ADMIN_KICK) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You do not have permission to use '/kick'.");

	new targetid, reason[21];
	if(sscanf(params, "us[21](no reason)", targetid, reason)) return
		SendClientMessage(playerid, COLOUR_SYNTAX, "Syntax: {FFFFFF}/kick [ Player ] [ Reason (Optional) ]" \
			"  -- {A5A5A5}'/mute help' for more info");
	if(targetid == INVALID_PLAYER_ID) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}The player you tried to '/kick' does not exist.");
	if(playerid == targetid) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You cannot '/kick' yourself.");
	if(Player[targetid][Admin] >= Player[playerid][Admin]) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You cannot '/kick' a staff member of equal or" \
			" higher administration level.");

	new string[87];
	format(string, sizeof(string), "ADMIN: {FFFFFF}%s(%d) has been kicked for %s.", PlayerName(targetid), targetid,
		reason);
	SendClientMessageToAll(COLOUR_ADMIN, string);

	Kick(targetid);
	return 1;
}


/*				MISC COMMANDS				*/

CMD:v(playerid, params[])
{
	if(Player[playerid][Admin] < MIN_ADMIN_V) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You do not have permission to use '/v'.");
	if(IsPlayerInAnyVehicle(playerid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You cannot use '/v' if you're already in a vehicle.");

	new modelid;
	if(sscanf(params, "d", modelid)) return
		SendClientMessage(playerid, COLOUR_SYNTAX, "Syntax: {FFFFFF}/v [ Model ]");
	if((modelid < 400) || (modelid > 611)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}Invalid vehicle model.");

	new Float:playerPos[4],
		vehicleid,
		string[40];
	GetPlayerPos(playerid, playerPos[0], playerPos[1], playerPos[2]);
	GetPlayerFacingAngle(playerid, playerPos[3]);

	vehicleid = CreateVehicleEx(modelid, playerPos[0], playerPos[1], playerPos[2], playerPos[3], -1, -1, -1);
	PutPlayerInVehicle(playerid, vehicleid, 0);

	switch(IsVehicleModelNameAn(modelid))
	{
		case 0: format(string, sizeof(string), "You have spawned a %s.", GetVehicleModelName(modelid));
		case 1: format(string, sizeof(string), "You have spawned an %s.", GetVehicleModelName(modelid));
	}
	SendClientMessage(playerid, COLOUR_GREY, string);
	return 1;
}

CMD:engine(playerid, params[])
{
	if(!IsPlayerInAnyVehicle(playerid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be in a vehicle to use '/engine'");
	if(GetPlayerVehicleSeat(playerid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be driving the vehicle to use '/engine'");

	new vehicleid = GetPlayerVehicleID(playerid),
		vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective;
	GetVehicleParamsEx(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective);

	switch(Vehicle[vehicleid][Engine])
	{
		case false:
			SetVehicleParamsEx_Fixed(vehicleid, true, vlights, valarm, vdoors, vbonnet, vboot, vobjective);
		case true:
			SetVehicleParamsEx_Fixed(vehicleid, false, vlights, valarm, vdoors, vbonnet, vboot, vobjective);
	}
	return 1;
}

CMD:lights(playerid, params[])
{
	if(!IsPlayerInAnyVehicle(playerid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be in a vehicle to use '/lights'");
	if(GetPlayerVehicleSeat(playerid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be driving the vehicle to use '/lights'");

	new vehicleid = GetPlayerVehicleID(playerid),
		vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective;
	GetVehicleParamsEx(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective);

	switch(Vehicle[vehicleid][Lights])
	{
		case false:
			SetVehicleParamsEx_Fixed(vehicleid, vengine, true, valarm, vdoors, vbonnet, vboot, vobjective);
		case true:
			SetVehicleParamsEx_Fixed(vehicleid, vengine, false, valarm, vdoors, vbonnet, vboot, vobjective);
	}
	return 1;
}

CMD:alarm(playerid, params[])
{
	if(!IsPlayerInAnyVehicle(playerid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be in a vehicle to use '/alarm'");
	if(GetPlayerVehicleSeat(playerid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be driving the vehicle to use '/alarm'");

	new vehicleid = GetPlayerVehicleID(playerid),
		vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective;
	GetVehicleParamsEx(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective);

	switch(Vehicle[vehicleid][Alarm])
	{
		case false:
			SetVehicleParamsEx_Fixed(vehicleid, vengine, vlights, true, vdoors, vbonnet, vboot, vobjective);
		case true:
			SetVehicleParamsEx_Fixed(vehicleid, vengine, vlights, false, vdoors, vbonnet, vboot, vobjective);
	}
	return 1;
}

CMD:hood(playerid, params[])
{
	if(!IsPlayerInAnyVehicle(playerid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be in a vehicle to use '/hood'");
	if(GetPlayerVehicleSeat(playerid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be driving the vehicle to use '/hood'");

	new vehicleid = GetPlayerVehicleID(playerid),
		vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective;
	GetVehicleParamsEx(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective);

	switch(Vehicle[vehicleid][Hood])
	{
		case false:
			SetVehicleParamsEx_Fixed(vehicleid, vengine, vlights, valarm, vdoors, true, vboot, vobjective);
		case true:
			SetVehicleParamsEx_Fixed(vehicleid, vengine, vlights, valarm, vdoors, false, vboot, vobjective);
	}
	return 1;
}

CMD:bonnet(playerid, params[])
{
	if(!IsPlayerInAnyVehicle(playerid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be in a vehicle to use '/bonnet'");
	if(GetPlayerVehicleSeat(playerid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be driving the vehicle to use '/bonnet'");

	new vehicleid = GetPlayerVehicleID(playerid),
		vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective;
	GetVehicleParamsEx(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective);

	switch(Vehicle[vehicleid][Hood])
	{
		case false:
			SetVehicleParamsEx_Fixed(vehicleid, vengine, vlights, valarm, vdoors, true, vboot, vobjective);
		case true:
			SetVehicleParamsEx_Fixed(vehicleid, vengine, vlights, valarm, vdoors, false, vboot, vobjective);
	}
	return 1;
}

CMD:trunk(playerid, params[])
{
	if(!IsPlayerInAnyVehicle(playerid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be in a vehicle to use '/trunk'");
	if(GetPlayerVehicleSeat(playerid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be driving the vehicle to use '/trunk'");

	new vehicleid = GetPlayerVehicleID(playerid),
		vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective;
	GetVehicleParamsEx(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective);

	switch(Vehicle[vehicleid][Trunk])
	{
		case false:
			SetVehicleParamsEx_Fixed(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, true, vobjective);
		case true:
			SetVehicleParamsEx_Fixed(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, false, vobjective);
	}
	return 1;
}

CMD:boot(playerid, params[])
{
	if(!IsPlayerInAnyVehicle(playerid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be in a vehicle to use '/boot'");
	if(GetPlayerVehicleSeat(playerid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be driving the vehicle to use '/boot'");

	new vehicleid = GetPlayerVehicleID(playerid),
		vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective;
	GetVehicleParamsEx(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective);

	switch(Vehicle[vehicleid][Trunk])
	{
		case false:
			SetVehicleParamsEx_Fixed(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, true, vobjective);
		case true:
			SetVehicleParamsEx_Fixed(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, false, vobjective);
	}
	return 1;
}

CMD:helmet(playerid, params[])
{
	SetPlayerAttachedObject(playerid, 3, 18645, 2, 0.045, 0.015, 0.0, 100.0, 90.0, 0.0, 1.0, 1.0, 1.0, 0, 0);
	return 1;
}

CMD:headphones(playerid, params[])
{
	new headphones;
	if(sscanf(params, "d", headphones)) return SendClientMessage(playerid, COLOUR_SYNTAX, "Syntax: {FFFFFF}/headphones [1-4]");
	if((headphones < 1) || (headphones > 4)) return SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}'/headphones' must be a value of 1-4");

	switch(headphones)
	{
		case 1:
			SetPlayerAttachedObject(playerid, 3, 19421, 2, 0.06, 0.0, 0.0, 270.0, 180.0, -270.0, 1.0, 1.0, 1.0, 0, 0);
		case 2:
			SetPlayerAttachedObject(playerid, 3, 19422, 2, 0.06, 0.0, 0.0, 270.0, 180.0, -270.0, 1.0, 1.0, 1.0, 0, 0);
		case 3:
			SetPlayerAttachedObject(playerid, 3, 19423, 2, 0.06, 0.0, 0.0, 270.0, 180.0, -270.0, 1.0, 1.0, 1.0, 0, 0);
		case 4:
			SetPlayerAttachedObject(playerid, 3, 19424, 2, 0.06, 0.0, 0.0, 270.0, 180.0, -270.0, 1.0, 1.0, 1.0, 0, 0);
	}
	return 1;
}


stock PlayerName(playerid)
{
	new name[MAX_PLAYER_NAME];
	GetPlayerName(playerid, name, MAX_PLAYER_NAME);
	return name;
}

stock UpdatePlayerClock(playerid, mode)
{
	Player[playerid][Clockmode] = mode;

	switch(mode)
	{
		case 0:
		{
			TextDrawHideForPlayer(playerid, Text:TD_clock_ampm);
			TextDrawHideForPlayer(playerid, Text:TD_ampm);

			TextDrawShowForPlayer(playerid, Text:TD_clock_default);
		}
		case 1:
		{
			TextDrawHideForPlayer(playerid, Text:TD_clock_default);

			TextDrawShowForPlayer(playerid, Text:TD_clock_ampm);
			TextDrawShowForPlayer(playerid, Text:TD_ampm);
		}
	}
	return 1;
}

stock SetPlayerPosEx(playerid, Float:x, Float:y, Float:z, Float:a, interior, vworld)
{
	SetPlayerPos(playerid, x, y, z);
	SetPlayerFacingAngle(playerid, a);
	SetPlayerInterior(playerid, interior);
	SetPlayerVirtualWorld(playerid, vworld);
	SetCameraBehindPlayer(playerid);
	return 1;
}

stock IsPlayerNearPlayer(playerid, targetid)
{
	new Float:pPos[3];
	GetPlayerPos(targetid, pPos[0], pPos[1], pPos[2]);

	if(IsPlayerInRangeOfPoint(playerid, 2.5, pPos[0], pPos[1], pPos[2])) return 1;
	return 0;
}

stock GetPlayerMoneyEx(playerid) return Player[playerid][Money];

stock GivePlayerMoneyEx(playerid, amount)
{
	Player[playerid][Money] += amount;
	GivePlayerMoney(playerid, amount);
	return 1;
}

stock SetPlayerMoney(playerid, amount)
{
	Player[playerid][Money] = amount;
	GivePlayerMoney(playerid, (-GetPlayerMoney(playerid)) + amount);
	return 1;
}

stock TakePlayerMoney(playerid, amount)
{
	Player[playerid][Money] -= amount;
	GivePlayerMoney(playerid, -amount);
	return 1;
}

stock IsVehicleModelNameAn(modelid)
{
	switch(modelid)
	{
		case 411, 416, 419, 427, 441, 445, 464, 465, 467, 490, 501, 507, 521, 522, 523, 528, 546, 562, 564, 577,
			585, 592, 594, 602: return 1;
	}
	return 0;
}

stock CreateStaticVehicleEx(modelid, Float:x, Float:y, Float:z, Float:rot, col1, col2, respawn_delay,
	bool:engine = true, bool:hood = false, bool:trunk = false)
{
	if((modelid < 400) || (modelid > 611)) return 0;

	new vehicleid = AddStaticVehicleEx(modelid, x, y, z, rot, col1, col2, respawn_delay);
	Vehicle[vehicleid][Engine] = engine;
	Vehicle[vehicleid][Hood] = hood;
	Vehicle[vehicleid][Trunk] = trunk;

	new vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective;
	GetVehicleParamsEx(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective);
	SetVehicleParamsEx_Fixed(vehicleid, vengine, vlights, valarm, vdoors, hood, trunk, vobjective);
	return vehicleid;
}

stock CreateVehicleEx(modelid, Float:x, Float:y, Float:z, Float:rot, col1, col2, respawn_delay,
	bool:engine = true, bool:hood = false, bool:trunk = false)
{
	if((modelid < 400) || (modelid > 611)) return 0;

	new vehicleid = CreateVehicle(modelid, x, y, z, rot, col1, col2, respawn_delay);
	Vehicle[vehicleid][Engine] = engine;
	Vehicle[vehicleid][Hood] = hood;
	Vehicle[vehicleid][Trunk] = trunk;

	new vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective;
	GetVehicleParamsEx(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective);
	SetVehicleParamsEx_Fixed(vehicleid, vengine, vlights, valarm, vdoors, hood, trunk, vobjective);
	return vehicleid;
}

new Timer_VehicleAlarm[MAX_VEHICLES];
stock SetVehicleParamsEx_Fixed(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective)
{
	switch(engine)
	{
		case false: Vehicle[vehicleid][Engine] = false;
		case true: Vehicle[vehicleid][Engine] = true;
	}
	switch(lights)
	{
		case false: Vehicle[vehicleid][Lights] = false;
		case true: Vehicle[vehicleid][Lights] = true;
	}
	switch(alarm)
	{
		case false: Vehicle[vehicleid][Alarm] = false;
		case true: Vehicle[vehicleid][Alarm] = true;
	}
	switch(bonnet)
	{
		case false: Vehicle[vehicleid][Hood] = false;
		case true: Vehicle[vehicleid][Hood] = true;
	}
	switch(boot)
	{
		case false: Vehicle[vehicleid][Trunk] = false;
		case true: Vehicle[vehicleid][Trunk] = true;
	}

	SetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
	if(alarm)
	{
		KillTimer(Timer_VehicleAlarm[vehicleid]);
		Timer_VehicleAlarm[vehicleid] = SetTimerEx("DisableVehicleAlarm", 20000, false, "d", vehicleid);
	}
	return 1;
}

forward DisableVehicleAlarm(vehicleid);
public DisableVehicleAlarm(vehicleid)
{
	new vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective;
	GetVehicleParamsEx(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective);
	SetVehicleParamsEx(vehicleid, vengine, vlights, false, vdoors, vbonnet, vboot, vobjective);
}

stock AddNeonToVehicle(vehicleid, neonid)
{
	if(Vehicle[vehicleid][Neon][0] == 0) RemoveNeonFromVehicle(vehicleid);

	new modelid;
	switch(neonid)
	{
		case 0: modelid = 18647;
		case 1: modelid = 18648;
		case 2: modelid = 18649;
		case 3: modelid = 18650;
		case 4: modelid = 18651;
		case 5: modelid = 18652;
	}

	Vehicle[vehicleid][Neon][0] = CreateDynamicObject(modelid, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
	AttachDynamicObjectToVehicle(Vehicle[vehicleid][Neon][0], vehicleid, -0.5, 0.0, -0.5, 0.0, 0.0, 0.0);
	Vehicle[vehicleid][Neon][1] = CreateDynamicObject(modelid, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
	AttachDynamicObjectToVehicle(Vehicle[vehicleid][Neon][1], vehicleid, 0.5, 0.0, -0.5, 0.0, 0.0, 0.0);
	return 1;
}

stock RemoveNeonFromVehicle(vehicleid)
{
	DestroyDynamicObject(Vehicle[vehicleid][Neon][0]);
	DestroyDynamicObject(Vehicle[vehicleid][Neon][1]);
	return 1;
}
