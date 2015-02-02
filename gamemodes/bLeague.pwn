/*

|*---------  bLeague T/CW v2.0  ---------*|
|*----------   Copyright (c)   ----------*|
|*----------  BJIADOKC, 2012   ----------*|



|* Начало разработки: 30.07.2011 *|
|* За основу взято: new.pwn + прямые руки *|
|* AAD Rumble тут никаким боком, так как написано все с нуля, если совпадают названия функций/переменных, извините уж, фантазии мало *|

*/





#file 									"bLeague.amx"





//#pragma amxram      					16777216
//#pragma compress    					1
#pragma dynamic     					32768
#pragma tabsize     					4
//#pragma pack        					0
//#pragma semicolon   					0
//#pragma ctrlchar    					'\\'






#include                                <a_http>
#include 								<a_samp>

#if defined MAX_PLAYERS
	#undef MAX_PLAYERS
	#define MAX_PLAYERS  				20
#else
	#define MAX_PLAYERS  				20
#endif

#if defined MAX_VEHICLES
	#undef MAX_VEHICLES
	#define MAX_VEHICLES 				20
#else
	#define MAX_VEHICLES 				20
#endif

#include                    			<audio>
#include                    			<cmd>
#include                    			<dns>
#include 								<gvar>
#include                    			<mail>
#include                    			<map>
#include                    			<multimap>
#include                    			<mysql>
#include                                <params>
#include 								<regex>
#include                    			<sha512>
#include                    			<socket>
#include                    			<streamer>
#include 								<timerfix>
#include                    			<vector>





#define Never 							999999

#define ModeVersion 					"v2.0 RC1"
#define samp_current_version 			"0.3x-R1-2"

#define Max_Spawns 						10
#define Max_Teams 						4

#define Team_None 						0
#define Team_Attack 					1
#define Team_Defend 					2
#define Team_Refferee 					3

#define Gametype_None 					0
#define Gametype_Base 					1
#define Gametype_Arena 					2
#define Gametype_CTF 					3

#define BalanceType_Random 				0
#define BalanceType_1 					1
#define BalanceType_2 					2

#define Red_Flag 						2993
#define Blue_Flag 						2914

#define Pickup_Type 					2

#define Lobby_VW 						1
#define Round_VW 						2
#define Dm_VW 							3
#define Duel_VW 						4
#define Intro_VW 						(random(50) + 5)

#define Register 						0
#define Login 							1
#define Changepass 						2
#define Resetstats 						3

#define Weapon 							4
#define Weapon_Change 					5

#define CarList_Main 					6
#define CarList_Auto 					7
#define CarList_Bikes 					8
#define CarList_Bicycle 				9
#define CarList_Boats 					10
#define CarList_Heli 					11
#define CarList_Planes 					12

#define HelpDialog 						13

#define Duel_Weapon 					14
#define Duel_Location 					15

#define SwitchDialog 					16
#define OnlyText 						17



#define mail_host           			"127.0.0.1"
#define mail_user           			"root"
#define mail_password       			"root1"
#define mail_from           			"bjiadokc@bleague.com"

#define mysql_host  					"127.0.0.1"
#define mysql_user  					"root"
#define mysql_password      			"root1"
#define mysql_db            			"server"
#define mysql_charset       			"utf8"



#define foreach_p(%0) \
	for(new %0, %0_m = cvector_size(playersVector), %0_i; %0_i < %0_m; %0 &= 0, %0 += cvector_get(playersVector, %0_i++))
	
#define isnull(%0) \
	!strlen(%0)
	
#define floatrandom(%0) \
	(float((random(%0 + 1) - random(%0 + 1))) + floatmul(random(1000), 0.001))
	
#define FixAngle(%0) \
	%0 += (%0 > 360.0) ? -360.0 : ((%0 < 0.0) ? 360.0 : 0.0)
	
#define ReverseAngle(%0) \
	%0 = (%0 >= 180.0) ? floatsub(%0, 180.0) : floatadd(%0, 180.0)

#define GivePVarInt(%0,%1,%2) \
	SetPVarInt(%0, %1, (GetPVarInt(%0, %1) + %2))
	
#define GivePVarFloat(%0,%1,%2) \
	SetPVarFloat(%0, %1, floatadd(GetPVarFloat(%0, %1), %2))

#define GiveGVarInt(%0,%1,%2) \
	SetGVarInt(%0,(GetGVarInt(%0, %2) + %1),%2)

#define GiveGVarFloat(%0,%1,%2) \
	SetGVarFloat(%0,floatadd(GetGVarFloat(%0, %2),%1),%2)

#define AngleCalculator(%0,%1,%2,%3,%4) \
	%0 = floatsub(180.0, atan2(floatsub(%1, %3), floatsub(%2, %4))); \
 		FixAngle(%0)

#define HideDialog(%0) \
	ShowPlayerDialog(%0, -1, 0, "", "", "", "")

#define PlayerStopSound(%0) \
	PlayerPlaySound(%0, 1069, 0.0, 0.0, 0.0)

#define JustDown(%0) \
 	((newkeys & %0) && !(oldkeys & %0))

#define Pressed(%0) \
	(((newkeys & %0) == %0) && ((oldkeys & %0) != %0))
	
#define SendClientMessageF(%0,%1,%2,%3) do{new scm[144];format(scm,sizeof scm,(%2),%3);SendClientMessage((%0),(%1),scm);}while(FALSE)
	
#define SendClientMessageToAllF(%0,%1,%2) do{new scmta[144];format(scmta,sizeof scmta,(%1),%2);SendClientMessageToAll((%0),scmta);}while(FALSE)
	
#define GameTextForPlayerF(%0,%1,%2,%3,%4) do{new gtfp[256];format(gtfp,sizeof gtfp,(%1),%4);GameTextForPlayer((%0),gtfp,(%2),(%3));}while(FALSE)
	
#define TextDrawSetStringF(%0,%1,%2) do{new tdss[1024];format(tdss,sizeof tdss,(%1),%2);TextDrawSetString((%0),tdss);}while(FALSE)

//#define PlayerTextDrawSetStringF(%0,%1,%2,%3) do{new ptdss[1024];format(ptdss,sizeof ptdss,(%2),%3);PlayerTextDrawSetString((%0),(%1),ptdss);}while(FALSE)

#define SendRconCommandF(%0,%1) do{new srcmd[256];format(srcmd,sizeof srcmd,(%0),%1);SendRconCommand(srcmd);}while(FALSE)





new const RandomWheels[17] =
{
	1098, 1097, 1096, 1085,
	1084, 1083, 1082, 1081,
	1080, 1079, 1078, 1077,
	1076, 1075, 1074, 1073,
	1025
};



new const MaxPassengers[27] =
{
	0x10331113, 0x11311131,
	0x11331313, 0x80133301,
	0x1381F110, 0x10311103,
	0x10001F10, 0x11113311,
	0x13113311, 0x31101100,
	0x30001301, 0x11031311,
	0x11111331, 0x10013111,
	0x01131100, 0x11111110,
	0x11100031, 0x11130221,
	0x33113311, 0x11111101,
	0x33101133, 0x101001F0,
	0x03133111, 0xFF11113F,
	0x13330111, 0xFF131111,
	0x0000FF3F
};



new const ForbiddenVehicles[33] =
{
	407, 416, 425, 427,
	432, 435, 441, 447,
	449, 450, 464, 465,
	470, 476, 501, 520,
	528, 537, 538, 544,
	564, 569, 570, 584,
	590, 591, 594, 601,
	606, 607, 608, 610,
	611
};



new const RandomSkin[100] =
{
	121, 123, 107, 105,
	102, 103, 104, 108,
	109, 175, 173, 118,
	247, 124, 127, 163,
	165, 274, 275, 276,
	277, 278, 279, 280,
	281, 283, 284, 286,
	287, 195, 190, 191,
	192, 193, 194, 138,
	139, 140, 154, 87,
	45,	128, 129, 132,
	133, 158, 159, 160,
   	197, 198, 161, 199,
	200, 34, 152, 178,
 	237, 244, 246, 85,
	256, 90, 80, 81,
	23, 167, 68, 155,
	205, 209, 260, 264,
	137, 241, 252, 255,
	29, 62, 83, 144,
	169, 263, 75, 185,
	188, 19, 216, 20,
	22, 214, 225, 226,
	76, 250, 28, 40,
	41, 185, 211, 219
};



new const WeaponNames[55][18] =
{
	"Unarmed", "Brass Knuckles", "Golf Club", "Night Stick",
	"Knife", "Baseball Bat", "Shovel", "Pool Cue",
	"Katana", "Chainsaw", "Dildo", "Vibrator1",
	"Vibrator2", "Vibrator3", "Flowers", "Cane",
	"Grenades", "Tear Gas", "Molotov", "N/A",
	"N/A", "N/A", "Pistol", "Silenced Pistol",
	"Desert Eagle", "Shotgun", "Sawnoff", "Spas12",
	"Mac-10", "MP5", "AK-47", "M4",
	"Tec-9", "Rifle", "Sniper Rifle", "RPG",
 	"HeatSeeker", "Flamethrower", "Minigun", "Satchel",
	"Detonator", "Spraycan", "Extinguisher", "Camera",
	"Nightvision", "Infrared", "Parachute", "N/A",
	"N/A", "Vehicle Collision", "HeliKill", "Explosion",
	"N/A", "N/A", "Long Fall"
};

new const CarList[212][18] =
{
    "Landstalker", "Bravura", "Buffalo", "Linerunner",
	"Perrenial", "Sentinel", "Dumper", "Fire Truck",
	"Trashmaster", "Stretch", "Manana", "Infernus",
	"Voodoo", "Pony", "Mule", "Cheetah", "Ambulance",
	"Leviathan", "Moonbeam", "Esperanto", "Taxi",
    "Washington", "Bobcat", "Mr Whoopee", "BF Injection",
	"Hunter", "Premier", "Enforcer", "Securicar",
	"Banshee", "Predator", "Bus", "Rhino",
	"Barracks", "Hotknife", "Trailer 1", "Previon",
    "Coach", "Cabbie", "Stallion", "Rumpo",
	"RC Bandit", "Romero", "Packer", "Monster",
	"Admiral", "Squalo", "Seaspar", "Pizzaboy",
    "Tram", "Trailer 2", "Turismo", "Speeder",
	"Reefer", "Tropic", "Flatbed", "Yankee",
	"Caddy", "Solair", "Berkley's RC Van", "Skimmer",
	"PCJ-600", "Faggio", "Freeway", "RC Baron",
    "RC Raider", "Glendale", "Oceanic", "Sanchez",
	"Sparroww", "Patriot", "Quad", "Coastguard",
	"Dinghy", "Hermes", "Sabre", "Rustler",
	"ZR-350", "Walton", "Regina", "Comet",
	"BMX", "Burrito", "Camper", "Marquis",
	"Baggage", "Dozer", "Maverick", "VCNMaverick",
	"Rancher", "FBI Rancher", "Virgo", "Greenwood",
    "Jetmax", "Hotring", "Sandking", "Blista Compact",
	"Police Maverick", "Boxville", "Benson", "Mesa",
	"RC Goblin", "Hotring A", "Hotring B", "Bloodring Banger",
	"Rancher", "Super GT", "Elegant", "Journey",
	"Bike", "Mountain Bike", "Beagle", "Cropdust",
 	"Stunt", "Tanker", "Roadtrain", "Nebula",
	"Majestic", "Buccaneer", "Shamal", "Hydra",
	"FCR-900", "NRG-500", "HPV1000", "Cement Truck",
    "Tow Truck", "Fortune", "Cadrona", "FBI Truck",
	"Willard", "Forklift", "Tractor", "Combine",
	"Feltzer", "Remington", "Slamvan", "Blade",
    "Freight", "Streak", "Vortex", "Vincent",
	"Bullet", "Clover", "Sadler", "Firetruck LA",
	"Hustler", "Intruder", "Primo", "Cargobob",
    "Tampa", "Sunrise", "Merit", "Utility",
	"Nevada", "Yosemite", "Windsor", "Monster A",
	"Monster B", "Uranus", "Jester", "Sultan",
	"Stratum", "Elegy", "Raindance", "RC Tiger",
	"Flash", "Tahoma", "Savanna", "Bandito",
	"Freight Flat", "Streak Carriage", "Kart", "Mower",
	"Duneride", "Sweeper", "Broadway", "Tornado",
	"AT-400", "DFT-30", "Huntley", "Stafford",
    "BF-400", "Newsvan", "Tug", "Trailer 3",
	"Emperor", "Wayfarer", "Euros", "Hotdog",
	"Club", "Freight Carriage", "Trailer 3", "Andromada",
	"Dodo", "RC Cam", "Launch",
	"LSPD", "SFPD", "LVPD", "Police Ranger",
	"Picador", "SWAT Van", "Alpha", "Phoenix",
	"Glendale", "Sadler", "Luggage Trailer A", "Luggage Trailer B",
	"Stair Trailer", "Boxville", "Farm Plow", "Utility Trailer"
};



enum A_INFO
{
	Interior,
	Votes,
	GangZone[4],
	bool:Exists,
	Float:CP[3],
	Float:Quad[4],
	Float:AttSpawn[30],
	Float:DefSpawn[30]
};



enum B_INFO
{
	Interior,
	Votes,
	bool:Exists,
	Float:CP[3],
	Float:AttSpawn[30],
	Float:DefSpawn[30]
};



enum C_INFO
{
	Interior,
	Votes,
	Flag[2],
	FlagOwner[2],
	GangZone[4],
	bool:Exists,
	Float:CP[3],
	Float:ACP[3],
	Float:DCP[3],
	Float:Quad[4],
	Float:AttSpawn[30],
	Float:DefSpawn[30]
};



enum D_INFO
{
	Interior,
	W[2],
	GangZone[4],
	bool:Exists,
	Float:Quad[4],
	Float:Spawns[15]
};



new Arena[100][A_INFO];
new Base[100][B_INFO];
new CTF[10][C_INFO];
new DM[10][D_INFO];



enum P_INFO
{
	IP[16],
	Name[24],
	bool:pConnect,
	PlayerText:Dot,
	PlayerText:IntroLetters,
	PlayerText:HealthBar,
	PlayerText:Speedometer,
	PlayerText:LoginText,
	PlayerText:HealthMinus,
	PlayerText:SpecText,
 	PlayerText:TeamText,
	PlayerText:Damage[2],
	Text3D:AtHead
};



enum S_INFO
{
	Current,
	Text:ArenaAndTime,
	Text:Main,
	Text:SLocked,
	Text:BlackFullScreen,
	Text:RedFullScreen,
	Text:Multi,
	Text:VoteText[2],
	Text:ModeStartText[3],
	Text:Barrier[9],
	Text:Gradient[75]
};



enum N_INFO
{
	Zone[5]
};



new Player[MAX_PLAYERS][P_INFO];
new PlayerWeapons[MAX_PLAYERS][2][13];
new Number[3][N_INFO];
new Server[S_INFO];



new FALSE = false;



new vote_string[1024 char];
new Text:TeamTextDraw[Max_Teams][5];
new Text:VoteKickText;
new Text:VoteBanText;
new Text3D:lobby_text;



new mysqlHandle;
new querySocketHandle;
new addonSocketHandle;



new textAdvertRegex;
new ipAdvertRegex;
new mailRegex;
new nameRegex;
new passwordRegex;



new playersVector;
new vehiclesVector;



new const Float:M4Location_1[2][3] =
{
	{-1622.8933, 654.9930, -5.2422},
	{-1626.3239, 739.8190, -5.2422}
};



new const Float:M4Location_2[2][3] =
{
	{-1539.3425, 1120.4105, 25.3125},
	{-1527.1514, 1211.7751, 25.3125}
};



new const Float:M4Location_3[2][3] =
{
	{-2720.7820, 679.3228, 66.0938},
	{-2636.0259, 602.2411, 66.0938}
};



new const Float:M4Location_4[2][3] =
{
	{-2235.2590, 12.2208, 59.0078},
	{-2221.7603, -58.1185, 59.0078}
};



new const Float:M4Location_5[2][3] =
{
	{-1981.0406, 632.9506, 145.3203},
	{-1924.7194, 687.0491, 145.3203}
};



new const Float:DeagleLocation_1[2][3] =
{
	{-1263.1597, -155.4978, 14.1484},
	{-1293.2792, -125.2019, 14.1484}
};


new const Float:DeagleLocation_2[2][3] =
{
	{1558.5586, -1353.8604, 329.4609},
	{1533.3788, -1361.3137, 329.4579}
};



new const Float:DeagleLocation_3[2][3] =
{
	{1544.4681, -1145.9684, 135.8281},
	{1499.5964, -1120.5315, 135.8281}
};



new const Float:DeagleLocation_4[2][3] =
{
	{1290.9338, -1187.1743, 94.2266},
	{1279.8617, -1198.4053, 94.2266}
};



new const Float:DeagleLocation_5[2][3] =
{
	{1020.1257, -1197.4657, 54.9063},
	{971.4015, -1193.8035, 54.9063}
};



new const Float:GrenadesLocation[2][3] =
{
	{836.1187, 449.0650, 103.5551},
	{852.7977, 506.5447, 103.5551}
};



new const Float:SniperLocation_1[2][3] =
{
	{2182.7371, 2195.3782, 103.8786},
	{2305.3457, 2173.6763, 103.8786}
};



new const Float:SniperLocation_2[2][3] =
{
	{1792.7318, 2132.4729, 3.9063},
	{1812.2236, 2066.2903, 3.9139}
};



new const Float:SniperLocation_3[2][3] =
{
	{-2160.5408, 2636.5759, 55.6848},
	{-2087.3616, 2611.5598, 55.5044}
};



new const Float:SniperLocation_4[2][3] =
{
	{1412.6573, -5575.1660, 7.3840},
	{1494.7050, -5570.8008, 14.1262}
};



new const Float:SniperLocation_5[2][3] =
{
	{2219.4087, -1150.5950, 1025.7969},
	{2198.4912, -1143.2332, 1029.7969}
};



new const Float:ShotLocation_1[2][3] =
{
	{934.7620, 2107.1057, 1011.0234},
	{959.2305, 2171.4241, 1011.0234}
};



new const Float:ShotLocation_2[2][3] =
{
	{274.8822, 1871.4543, 8.7649},
	{256.3244, 1816.5706, 4.7109}
};



new const Float:ShotLocation_3[2][3] =
{
	{-1470.5514, 1488.9510, 8.2501},
	{-1435.7531, 1497.4534, 1.8672}
};



new const Float:ShotLocation_4[2][3] =
{
	{-2333.8921, 1538.0016, 17.3281},
	{-2466.8987, 1546.8735, 23.6641}
};
	
	
	
new const Float:ShotLocation_5[2][3] =
{
	{2838.3909, -2531.5842, 17.9784},
	{2837.9565, -2345.9109, 19.2058}
};





main()
{
	print("\n.______________________________.");
	print("|*----------------------------*|");
	print("|*------- bLeague T/CW -------*|");
	print("|*--------- " #ModeVersion " ----------*|");
	print("|*------- by BJIADOKC --------*|");
	print("|*---- Copyright (c) 2012 ----*|");
	print("|*--------- Loaded! ----------*|");
	print("|*----------------------------*|");
	print("'------------------------------'\n");
	
	SetGVarInt("UpTime", GetTickCount());
	printf("Total gamemode loading time: %i msec", (GetGVarInt("UpTime") - GetGVarInt("LoadTick")));
	DeleteGVar("LoadTick");
	
	printf("Start GetTickCount: %i", GetGVarInt("UpTime"));
	
	print("bLeague T/CW " #ModeVersion " | All rights reserved");
	print("Have a nice game!");
}



strcpy(dest[], src[])
{
	new i;
	
	while((dest[i] = src[i]))
	{
		i++;
	}
}



DestroyVehicleEx(vehicleid, playerid = INVALID_PLAYER_ID)
{
	if(!GetPVarInt(playerid, "Connected"))
	{
		for(playerid = MAX_PLAYERS; playerid != -1; --playerid)
		{
			if(vehicleid == GetPVarInt(playerid, "CarID"))
			{
				SetPVarInt(playerid, "CarID", INVALID_VEHICLE_ID);
			}
		}
	}
	else
	{
		SetPVarInt(playerid, "CarID", INVALID_VEHICLE_ID);
	}

	return DestroyVehicle(vehicleid);
}



mysql_ban(playerid, adminid, bantime, reason[], adminname[] = "")
{
	new ip[16];
	new serial[129];
	new query[256];
	
	strcpy(ip, Player[playerid][IP]);
	strdel(ip, strfind(ip, ".", false, 4), strlen(ip));

	gpci(playerid, serial, sizeof serial);
	strcat(serial, ip);

	if(GetPVarInt(adminid, "Connected"))
	{
		mysql_format(mysqlHandle, query, sizeof query, "INSERT INTO `banlist` VALUES (SHA2('%s', 512), '%s', '%s', '%e', %i, %i)", serial, Player[playerid][Name], Player[adminid][Name], reason, gettime(), bantime);
	}
	else
	{
		mysql_format(mysqlHandle, query, sizeof query, "INSERT INTO `banlist` VALUES (SHA2('%s', 512), '%s', '%s', '%s', %i, %i)", serial, Player[playerid][Name], adminname, reason, gettime(), bantime);
	}
	
	mysql_function_query(mysqlHandle, query, false, "OnPlayerBanned", "i", playerid);

	return 1;
}



bool:IsBike(modelid)
{
	switch(modelid)
	{
		case 448, 461..463, 468, 521..523, 581, 586: return true;
		default: return false;
	}

	return false;
}



bool:IsBicycle(modelid)
{
	switch(modelid)
	{
		case 481, 509, 510: return true;
		default: return false;
	}

	return false;
}



bool:IsBoat(modelid)
{
	switch(modelid)
	{
		case 430, 446, 452..454, 472, 473, 484, 493, 539, 595: return true;
		default: return false;
	}

	return false;
}



bool:IsHelicopter(modelid)
{
	switch(modelid)
	{
		case 417, 425, 447, 465, 469, 487, 488, 497, 501, 548, 563: return true;
		default: return false;
  	}

	return false;
}



bool:IsMonsterTruck(modelid)
{
  	switch(modelid)
  	{
   		case 406, 444, 556, 557, 573: return true;
		default: return false;
  	}

	return false;
}



bool:IsPlane(modelid)
{
  	switch(modelid)
  	{
		case 460, 464, 476, 511..513, 519, 520, 553, 577, 592, 593: return true;
        default: return false;
  	}

	return false;
}



bool:IsQuad(modelid)
{
 	if(modelid == 471) return true;

	return false;
}



bool:IsCar(modelid)
{
  	switch(modelid)
  	{
   		case 406, 417, 425, 430, 444, 446..448, 452..454, 460..464, 465, 468, 469, 471..473, 476, 481, 484, 487, 488, 493, 497, 501, 509..513, 519, 520, 521..523, 539, 548, 553, 556, 557, 563, 573, 577, 581, 586, 592, 593, 595: return false;
   		default: return true;
  	}

	return true;
}



Float:ReturnPlayerHealth(playerid)
{
	new Float:health;
	
	GetPlayerHealth(playerid, health);
	
	return health;
}



Float:ReturnPlayerArmour(playerid)
{
	new Float:armour;
	
	GetPlayerArmour(playerid, armour);
	
	return armour;
}



Float:ReturnPlayerZAngle(playerid)
{
	new Float:angle;
	
	GetPlayerFacingAngle(playerid, angle);
	
	return angle;
}



Float:ReturnVehicleHealth(vehicleid)
{
	new Float:health;
	
	GetVehicleHealth(vehicleid, health);
	
	return health;
}



/*Float:ReturnVehicleZAngle(vehicleid)
{
	new Float:angle;
	
	GetVehicleZAngle(vehicleid, angle);
	
	return angle;
}*/



ReplaceStyleChars(dest[])
{
	new i;
	
	for( ; dest[i]; )
	{
	    switch(dest[i])
	    {
	        case '[', ']':
			{
				strdel(dest, (i - 1), ++i);
			}
			
			default:
			{
				i++;
			}
		}
	}
	
	dest[i] = 0;
}



SpawnVehicle(playerid, modelid)
{
	new CarID;
 	new Float:data[3];
	
	if(GetPVarInt(playerid, "Playing") && (GetGVarInt("GameType") == Gametype_Base))
	{
	    GetPlayerPos(playerid, data[0], data[1], data[2]);
		
		CarID = GetPVarInt(playerid, "CarID");
		
		if(CarID != INVALID_VEHICLE_ID)
		{
			DestroyVehicleEx(CarID, playerid);
		}
		
		CarID = CreateVehicle(modelid, data[0], data[1], floatadd(data[2], 0.3), ReturnPlayerZAngle(playerid), 3, 3, Never);
		SetPVarInt(playerid, "CarID", CarID);
		
        SetVehicleNumberPlate(CarID, "{FF0000}b{FFFF00}League");
		ChangeVehiclePaintjob(CarID, random(3));
		ChangeVehicleColor(CarID, 3, 3);
		SetVehicleVirtualWorld(CarID, GetPlayerVirtualWorld(playerid));
		LinkVehicleToInterior(CarID, GetPlayerInterior(playerid));
		
		if(IsCar(GetVehicleModel(CarID)))
		{
			AddVehicleComponent(CarID, RandomWheels[random(17)]);
		}
		
		GetPlayerVelocity(playerid, data[0], data[1], data[2]);
		PutPlayerInVehicle(playerid, CarID, 0);
		SetVehicleVelocity(CarID, data[0], data[1], data[2]);
		
		GivePVarInt(playerid, "Cars_Spawned", 1);
	}
	else if(!GetPVarInt(playerid, "Playing"))
	{
	    GetPlayerPos(playerid, data[0], data[1], data[2]);
		
		CarID = GetPVarInt(playerid, "CarID");
		
		if(CarID != INVALID_VEHICLE_ID)
		{
			DestroyVehicleEx(CarID, playerid);
		}
		
		CarID = CreateVehicle(modelid, data[0], data[1], floatadd(data[2], 0.3), ReturnPlayerZAngle(playerid), 3, 3, Never);
		SetPVarInt(playerid, "CarID", CarID);
		
        SetVehicleNumberPlate(CarID, "{FF0000}b{FFFF00}League");
		ChangeVehiclePaintjob(CarID, random(3));
		ChangeVehicleColor(CarID, random(255), random(255));
		SetVehicleVirtualWorld(CarID, GetPlayerVirtualWorld(playerid));
		LinkVehicleToInterior(CarID, GetPlayerInterior(playerid));
		
		if(IsCar(GetVehicleModel(CarID)))
		{
			AddVehicleComponent(CarID, RandomWheels[random(17)]);
		}
		
		GetPlayerVelocity(playerid, data[0], data[1], data[2]);
		PutPlayerInVehicle(playerid, CarID, 0);
		SetVehicleVelocity(CarID, data[0], data[1], data[2]);
	}
}



/*RandomString(length, dest[])
{
	dest[0] = 0;
	
	for( ; length != -1; --length)
	{
		switch(random(3))
		{
		    case 0: dest[length] = ('a' + random(24));
		    case 1: dest[length] = ('A' + random(24));
		    case 2: dest[length] = ('0' + random(10));
		}
	}
}*/



StringToHex(string[])
{
	if(isnull(string))
	{
		return 0;
	}
	
	new buffer;
	new current = 1;
	
	for(new i = strlen(string); i; --i)
	{
		if(string[i - 1] < ':')
		{
			buffer += current * (string[i - 1] - '0');
		}
		else
		{
			buffer += current * (string[i - 1] - '7');
		}
		
		current <<= 4;
	}
	
	return buffer;
}



GivePlayerWeaponEx(playerid, ...)
{
	for(new arg_pos = 1, num = numargs(); arg_pos != num; arg_pos += 2)
	{
		GivePlayerWeapon(playerid,getarg(arg_pos),getarg(arg_pos + 1));
	}
	
	return 1;
}



bool:IsBugWeapon(weaponid)
{
	switch(weaponid)
	{
	    case 23..25, 33, 34: return true;
	    default: return false;
	}
	
	return false;
}



bool:IsNumeric(string[])
{
	if(isnull(string))
	{
		return false;
	}
	
	for(new i; string[i]; i++)
	{
	    if((string[i] == '+' || string[i] == '-') && !i)
		{
			continue;
		}
	    
		if(!('0' <= string[i] <= '9'))
		{
			return false;
		}
	}
	
	return true;
}



bool:PlayerToPoint(Float:Distance, playerid, Float:x, Float:y, Float:z)
{
	new Float:pos[3];
	
    if(GetPlayerPos(playerid, pos[0], pos[1], pos[2]) && (Distance > (pos[0] - x) > -Distance) && (Distance > (pos[1] - y) > -Distance) && (Distance > (pos[2] - z) > -Distance))
	{
		return true;
	}
    
    return false;
}



ClearChat()
{
	for(new i; i != 100; i++)
	{
		SendClientMessageToAll(-1, "\0");
	}
}



ClearKillChat()
{
	for(new i; i != 6; i++)
	{
		SendDeathMessage(255, 255, 255);
	}
}



ClearConsole()
{
	for(new i; i != 1000; i++)
	{
		print(" ");
	}
}



/*HideDialogForAll()
{
	foreach_p(i)
	{
		HideDialog(i);
	}
}*/



StopSoundForAll()
{
	foreach_p(i)
	{
		PlayerStopSound(i);
	}
}



GetWeaponSlot(weaponid)
{
	switch(weaponid)
	{
		case 0, 1: return 0;
		case 2..9: return 1;
		case 10..15: return 10;
		case 16..18: return 8;
		case 22..24: return 2;
		case 25..27: return 3;
		case 28, 29, 32: return 4;
		case 30, 31: return 5;
		case 33, 34: return 6;
		case 35..38: return 7;
		case 39: return 8;
		case 40: return 12;
		case 41..43: return 9;
		case 44..46: return 11;
	}
	
	return 0;
}



AdvanceSpectate(playerid)
{
	if((GetOnlinePlayers() < 3) || (GetPVarInt(playerid,"SpecID") == -1) || (Server[Current] == -1) || GetGVarInt("Starting") || !AttsAlive() || !DefsAlive())
	{
		StopSpectate(playerid);
		
		return 1;
	}

	new string[12];
	
	for(new i = (GetPVarInt(playerid,"SpecID") + 1); i <= MAX_PLAYERS; i++)
	{
	    if(i == MAX_PLAYERS)
		{
			i = 0;
		}
		
	    if(!GetPVarInt(i, "Connected") || !GetPVarInt(i, "Playing") || (i == playerid) || GetPVarInt(i, "AFK_In"))
		{
			continue;
		}
	    
	    switch(GetPVarInt(playerid, "Team"))
	    {
	        case Team_Refferee:
			{
			    valstr(string, i);
			    
			    SetPVarInt(playerid, "CMD_Time", (GetTickCount() - 2501));
			    CallLocalFunction("_spec", "isi", playerid, string, strlen(string));
			    
				break;
			}
			
	        default:
	        {
	            if(GetPVarInt(i,"Team") != GetPVarInt(playerid,"Team"))
				{
					continue;
				}
				
				valstr(string, i);
				
				SetPVarInt(playerid, "CMD_Time", (GetTickCount() - 2501));
			    CallLocalFunction("_spec", "isi", playerid, string, strlen(string));
			    
	            break;
			}
		}
	}
	
	return 1;
}



ReverseSpectate(playerid)
{
	if((GetOnlinePlayers() < 3) || (GetPVarInt(playerid,"SpecID") == -1) || (Server[Current] == -1) || GetGVarInt("Starting") || !AttsAlive() || !DefsAlive())
	{
		StopSpectate(playerid);
		
		return 1;
	}

	new string[12];
	
	for(new i = (GetPVarInt(playerid,"SpecID") - 1); i >= -1; i--)
	{
	    if(i == -1)
		{
			i = MAX_PLAYERS;
		}
		
	    if(!GetPVarInt(i,"Connected") || !GetPVarInt(i,"Playing") || (i == playerid) || GetPVarInt(i,"AFK_In"))
		{
			continue;
		}

	    switch(GetPVarInt(playerid,"Team"))
	    {
	        case Team_Refferee:
			{
			    valstr(string, i);
			    
			    SetPVarInt(playerid, "CMD_Time", (GetTickCount() - 2501));
			    CallLocalFunction("_spec", "isi", playerid, string, strlen(string));
			    
				break;
			}
			
	        default:
	        {
	            if(GetPVarInt(i,"Team") != GetPVarInt(playerid,"Team"))
				{
					continue;
				}
				
				valstr(string, i);
				
				SetPVarInt(playerid, "CMD_Time", (GetTickCount() - 2501));
			    CallLocalFunction("_spec", "isi", playerid, string, strlen(string));
			    
	            break;
			}
		}
	}
	
	return 1;
}



DestroyGangZones()
{
	for(new i = GetGVarInt("A_Count"); i != -1; --i)
	{
	    for(new x; x != 4; x++)
	    {
	        GangZoneDestroy(Arena[i][GangZone][x]);
		}
	}
	
	for(new i = GetGVarInt("C_Count"); i != -1; --i)
	{
	    for(new x; x != 4; x++)
	    {
	        GangZoneDestroy(CTF[i][GangZone][x]);
		}
	}
	
	for(new i = GetGVarInt("D_Count"); i != -1; --i)
	{
		for(new x; x != 4; x++)
	    {
	        GangZoneDestroy(DM[i][GangZone][x]);
		}
	}
}



PlayRandomSound(playerid)
{
	PlayerStopSound(playerid);
	
	switch(random(7))
	{
	    case 0: return PlayerPlaySound(playerid,1062,0.0,0.0,0.0);
	    case 1: return PlayerPlaySound(playerid,1068,0.0,0.0,0.0);
	    case 2: return PlayerPlaySound(playerid,1076,0.0,0.0,0.0);
	    case 3: return PlayerPlaySound(playerid,1097,0.0,0.0,0.0);
	    case 4: return PlayerPlaySound(playerid,1183,0.0,0.0,0.0);
	    case 5: return PlayerPlaySound(playerid,1185,0.0,0.0,0.0);
		case 6: return PlayerPlaySound(playerid,1187,0.0,0.0,0.0);
	}
	
	return 1;
}



Float:GetDistanceBetweenPlayers(playerid, playerid2)
{
	new Float:data[6];
	
	if(!GetPlayerPos(playerid, data[0], data[1], data[2]) || !GetPlayerPos(playerid2, data[3], data[4], data[5]))
	{
		return (Float:0x7FFFFFFF);
	}
	
	return floatsqroot(floatpower(data[0] - data[3], 2.0) + floatpower(data[1] - data[4], 2.0) + floatpower(data[2] - data[5], 2.0));
}



StopVoteKick()
{
	if(!GetGVarInt("VoteKick_Active"))
	{
		return 0;
	}
	
	TextDrawHideForAll(VoteKickText);
	
	SetGVarInt("VoteKick_Active", false);
	SetGVarInt("VoteKick_ID", -1);
	SetGVarString("VoteKick_Reason", "");
	SetGVarInt("VoteKick_Votes", 0);
	
	for(new i = MAX_PLAYERS; i != -1; --i)
	{
		SetGVarInt("VoteKick_Voted", false, i);
	}
	
	return SendClientMessageToAll(-1, "[Инфо]: {AFAFAF}VoteKick - голосование окончено");
}



StopVoteBan()
{
	if(!GetGVarInt("VoteBan_Active"))
	{
		return 0;
	}
	
	TextDrawHideForAll(VoteBanText);
	
	SetGVarInt("VoteBan_Active", false);
	SetGVarInt("VoteBan_ID", -1);
	SetGVarString("VoteBan_Reason", "");
	SetGVarInt("VoteBan_Votes", 0);
	
	for(new i = MAX_PLAYERS; i != -1; --i)
	{
		SetGVarInt("VoteBan_Voted", false, i);
	}
	
	return SendClientMessageToAll(-1, "[Инфо]: {AFAFAF}VoteBan - голосование окончено");
}



SyncPlayer(playerid)
{
	new Float:data[3];
	
	GetPlayerPos(playerid, data[0], data[1], data[2]);
	SetPVarFloat(playerid, "SyncPos_X", data[0]);
	SetPVarFloat(playerid, "SyncPos_Y", data[1]);
	SetPVarFloat(playerid, "SyncPos_Z", data[2]);
	
	GetPlayerVelocity(playerid, data[0], data[1], data[2]);
	SetPVarFloat(playerid, "SyncVelo_X", data[0]);
	SetPVarFloat(playerid, "SyncVelo_Y", data[1]);
	SetPVarFloat(playerid, "SyncVelo_Z", data[2]);
	
	SetPVarFloat(playerid, "SyncAng", ReturnPlayerZAngle(playerid));
	SetPVarFloat(playerid, "SyncHealth", ReturnPlayerHealth(playerid));
	
	SetPVarInt(playerid, "SyncInt", GetPlayerInterior(playerid));
	SetPVarInt(playerid, "SyncVW", GetPlayerVirtualWorld(playerid));
	SetPVarInt(playerid, "SyncSkin", GetPlayerSkin(playerid));
	SetPVarInt(playerid, "SyncSpecAct", GetPlayerSpecialAction(playerid));
	SetPVarInt(playerid, "SyncColor", GetPlayerColor(playerid));
	SetPVarInt(playerid, "SyncTeam", GetPlayerTeam(playerid));
	SetPVarInt(playerid, "SyncScore", GetPlayerScore(playerid));
	SetPVarInt(playerid, "SyncDLevel", GetPlayerDrunkLevel(playerid));
	SetPVarInt(playerid, "SyncFStyle", GetPlayerFightingStyle(playerid));
	
	for(new i; i != 13; i++)
	{
		GetPlayerWeaponData(playerid, i, PlayerWeapons[playerid][0][i], PlayerWeapons[playerid][1][i]);
	}
	
	SetPVarInt(playerid, "SyncSpawn", true);
	SpawnPlayer(playerid);
}



trimSideSpaces(string[]) //by MX_Master
{
    new i;
	new len = strlen(string);
	
    for( ; string[i]; i++)
    {
        switch(string[i])
        {
            case ' ', 0x09, 0x0D, 0x0A:
			{
				continue;
			}
			
            default:
            {
                if(i)
				{
					strmid(string, string, i, len, len);
				}
				
                break;
            }
        }
    }
    
    for(i = len - i - 1; i >= 0; i--)
    {
        switch(string[i])
        {
            case ' ', 0x09, 0x0D, 0x0A:
			{
				continue;
			}
			
            default:
            {
                string[++i] = 0;
                
                break;
            }
        }
    }
}



spaceGroupsToSpaces(string[]) //by MX_Master
{
    new len = strlen(string);
	new i = (len - 1);
	new spaces;
	
    for( ; i >= 0; i--)
    {
        switch(string[i])
        {
            case ' ', 0x09, 0x0D, 0x0A:
			{
				spaces++;
			}
			
            default:
            {
                if(spaces > 1)
                {
                    memcpy(string, string[i + spaces + 1], ((i + 2) << 2), ((len - i - spaces - 1) << 2), len);

					len -= (spaces - 1);
                }

                if(spaces > 0)
                {
                    string[i + 1] = ' ';
                    spaces = 0;
                }
            }
        }
    }

    if(spaces > 1)
    {
        memcpy(string, string[i + spaces + 1], ((i + 2) << 2), ((len - i - spaces - 1) << 2), len);
        
        len -= (spaces - 1);
    }
    
    if(spaces > 0)
	{
		string[i + 1] = ' ';
	}
	
    string[len] = 0;
}



bool:tooManyUpperChars(string[])
{
    new upperChars;
	
    for(new i; string[i]; i++)
    {
        switch(string[i])
        {
            case 'A'..'Z', 'А'..'Я':
			{
				upperChars++;
			}
			
            default:
			{
				continue;
			}
        }
    }
    
    if(((upperChars / strlen(string)) * 100) > 75)
	{
		return true;
	}
    
    return false;
}



bool:emptyMessage(string[])
{
 	for(new i; string[i]; i++)
	{
	    switch(string[i])
	    {
	        case ' ': continue;
	        default: return false;
		}
	}
	
	return true;
}



CreateNumb(Float:minx, Float:miny, Float:maxx, Float:maxy, number[], Float:zoom = 1.5)
{
	#define CCZOOM (mincx + 100 * zoom * i)
	
	if(strlen(number) > 3)
	{
		return 1;
	}
	
	new i;
	new Float:cy = ((miny + maxy) / 2 + 50 * zoom);
	new Float:mincx = ((minx + maxx) / 2) - 50 * zoom - ((strlen(number) - 1) * 100 * zoom / 2);
		
	for( ; i != 3; i++)
 	{
 	    for(new x; x != 4; x++)
 	    {
  			GangZoneHideForAll(Number[i][Zone][x]);
   			GangZoneDestroy(Number[i][Zone][x]);
		}
	}

	i = -1;
	
	while(number[++i])
	{
	    switch((number[i] - '0'))
	    {
		    case 0:
			{
		        Number[i][Zone][0] = GangZoneCreate(CCZOOM + 10 * zoom, cy - 80 * zoom, CCZOOM + 30 * zoom, cy - 20 * zoom);
				Number[i][Zone][1] = GangZoneCreate(CCZOOM + 10 * zoom, cy - 20 * zoom, CCZOOM + 90 * zoom, cy);
	            Number[i][Zone][2] = GangZoneCreate(CCZOOM + 70 * zoom, cy - 80 * zoom, CCZOOM + 90 * zoom, cy - 20 * zoom);
				Number[i][Zone][3] = GangZoneCreate(CCZOOM + 10 * zoom, cy - 100 * zoom, CCZOOM + 90 * zoom, cy - 80 * zoom);
	            Number[i][Zone][4] = GangZoneCreate(0.0, 0.0, 0.0, 0.0);
		    }
		    
		    case 1:
			{
		        Number[i][Zone][0] = GangZoneCreate(CCZOOM + 40 * zoom, cy - 100 * zoom, CCZOOM + 60 * zoom, cy);
	            Number[i][Zone][1] = GangZoneCreate(0.0, 0.0, 0.0, 0.0);
	            Number[i][Zone][2] = GangZoneCreate(0.0, 0.0, 0.0, 0.0);
	            Number[i][Zone][3] = GangZoneCreate(0.0, 0.0, 0.0, 0.0);
	            Number[i][Zone][4] = GangZoneCreate(0.0, 0.0, 0.0, 0.0);
		    }
		    
		    case 2:
			{
		        Number[i][Zone][0] = GangZoneCreate(CCZOOM + 10 * zoom, cy - 20 * zoom, CCZOOM + 70 * zoom, cy);
				Number[i][Zone][1] = GangZoneCreate(CCZOOM + 70 * zoom, cy - 40 * zoom, CCZOOM + 90 * zoom, cy);
	            Number[i][Zone][2] = GangZoneCreate(CCZOOM + 30 * zoom, cy - 60 * zoom, CCZOOM + 90 * zoom, cy - 40 * zoom);
				Number[i][Zone][3] = GangZoneCreate(CCZOOM + 10 * zoom, cy - 100 * zoom, CCZOOM + 30 * zoom, cy - 40 * zoom);
	            Number[i][Zone][4] = GangZoneCreate(CCZOOM + 30 * zoom, cy - 100 * zoom, CCZOOM + 90 * zoom, cy - 80 * zoom);
		    }
		    
		    case 3:
			{
		        Number[i][Zone][0] = GangZoneCreate(CCZOOM + 10 * zoom, cy - 20 * zoom, CCZOOM + 70 * zoom, cy);
				Number[i][Zone][1] = GangZoneCreate(CCZOOM + 10 * zoom, cy - 60 * zoom, CCZOOM + 70 * zoom, cy - 40 * zoom);
	            Number[i][Zone][2] = GangZoneCreate(CCZOOM + 10 * zoom, cy - 80 * zoom, CCZOOM + 70 * zoom, cy - 100 * zoom);
				Number[i][Zone][3] = GangZoneCreate(CCZOOM + 70 * zoom, cy - 100 * zoom, CCZOOM + 90 * zoom, cy);
	            Number[i][Zone][4] = GangZoneCreate(0.0, 0.0, 0.0, 0.0);
		    }
		    
		    case 4:
			{
		        Number[i][Zone][0] = GangZoneCreate(CCZOOM + 10 * zoom, cy - 40 * zoom, CCZOOM + 30 * zoom, cy);
				Number[i][Zone][1] = GangZoneCreate(CCZOOM + 10 * zoom, cy - 60 * zoom, CCZOOM + 70 * zoom, cy - 40 * zoom);
	            Number[i][Zone][2] = GangZoneCreate(CCZOOM + 70 * zoom, cy - 100 * zoom, CCZOOM + 90 * zoom, cy);
	            Number[i][Zone][3] = GangZoneCreate(0.0, 0.0, 0.0, 0.0);
	            Number[i][Zone][4] = GangZoneCreate(0.0, 0.0, 0.0, 0.0);
		    }
		    
		    case 5:
			{
		        Number[i][Zone][0] = GangZoneCreate(CCZOOM + 30 * zoom, cy - 20 * zoom, CCZOOM + 90 * zoom, cy);
				Number[i][Zone][1] = GangZoneCreate(CCZOOM + 10 * zoom, cy - 60 * zoom,  CCZOOM + 30 * zoom, cy);
	            Number[i][Zone][2] = GangZoneCreate(CCZOOM + 30 * zoom, cy - 60 * zoom, CCZOOM + 90 * zoom, cy - 40 * zoom);
				Number[i][Zone][3] = GangZoneCreate(CCZOOM + 70 * zoom, cy - 100 * zoom, CCZOOM + 90 * zoom, cy - 60 * zoom);
	            Number[i][Zone][4] = GangZoneCreate(CCZOOM + 10 * zoom, cy - 100 * zoom, CCZOOM + 70 * zoom, cy - 80 * zoom);
		    }
		    
		    case 6:
			{
		        Number[i][Zone][0] = GangZoneCreate(CCZOOM + 30 * zoom, cy - 20 * zoom, CCZOOM + 90 * zoom, cy);
				Number[i][Zone][1] = GangZoneCreate(CCZOOM + 10 * zoom, cy - 100 * zoom,  CCZOOM + 30 * zoom, cy);
	            Number[i][Zone][2] = GangZoneCreate(CCZOOM + 30 * zoom, cy - 60 * zoom, CCZOOM + 90 * zoom, cy - 40 * zoom);
				Number[i][Zone][3] = GangZoneCreate(CCZOOM + 70 * zoom, cy - 80 * zoom, CCZOOM + 90 * zoom, cy - 60 * zoom);
	            Number[i][Zone][4] = GangZoneCreate(CCZOOM + 30 * zoom, cy - 100 * zoom, CCZOOM + 90 * zoom, cy - 80 * zoom);
		    }
		    
		    case 7:
			{
		        Number[i][Zone][0] = GangZoneCreate(CCZOOM + 10 * zoom, cy - 20 * zoom, CCZOOM + 70 * zoom, cy);
	            Number[i][Zone][1] = GangZoneCreate(CCZOOM + 70 * zoom, cy - 100 * zoom, CCZOOM + 90 * zoom, cy);
	            Number[i][Zone][2] = GangZoneCreate(0.0, 0.0, 0.0, 0.0);
	            Number[i][Zone][3] = GangZoneCreate(0.0, 0.0, 0.0, 0.0);
	            Number[i][Zone][4] = GangZoneCreate(0.0, 0.0, 0.0, 0.0);
		    }
		    
		    case 8:
			{
		        Number[i][Zone][0] = GangZoneCreate(CCZOOM + 30 * zoom, cy - 20 * zoom, CCZOOM + 70 * zoom, cy);
				Number[i][Zone][1] = GangZoneCreate(CCZOOM + 30 * zoom, cy - 60 * zoom, CCZOOM + 70 * zoom, cy - 40 * zoom);
	            Number[i][Zone][2] = GangZoneCreate(CCZOOM + 30 * zoom, cy - 100 * zoom, CCZOOM + 70 * zoom, cy - 80 * zoom);
				Number[i][Zone][3] = GangZoneCreate(CCZOOM + 10 * zoom, cy - 100 * zoom, CCZOOM + 30 * zoom, cy);
	            Number[i][Zone][4] = GangZoneCreate(CCZOOM + 70 * zoom, cy - 100 * zoom, CCZOOM + 90 * zoom, cy);
		    }
		    
		    case 9:
			{
		        Number[i][Zone][0] = GangZoneCreate(CCZOOM + 30 * zoom, cy - 20 * zoom, CCZOOM + 70 * zoom, cy);
				Number[i][Zone][1] = GangZoneCreate(CCZOOM + 30 * zoom, cy - 60 * zoom, CCZOOM + 70 * zoom, cy - 40 * zoom);
	            Number[i][Zone][2] = GangZoneCreate(CCZOOM + 10 * zoom, cy - 60 * zoom, CCZOOM + 30 * zoom, cy);
				Number[i][Zone][3] = GangZoneCreate(CCZOOM + 10 * zoom, cy - 100 * zoom, CCZOOM + 70 * zoom, cy - 80 * zoom);
	            Number[i][Zone][4] = GangZoneCreate(CCZOOM + 70 * zoom, cy - 100 * zoom, CCZOOM + 90 * zoom, cy);
		    }
	    }
	}
	
	#undef CCZOOM
	
	foreach_p(x)
	{
	    if(!GetPVarInt(x, "Playing"))
		{
			continue;
		}
		
	    for( ; i != -1; --i)
	    {
	        for(new z = 0; z != 4; z++)
	        {
	        	GangZoneShowForPlayer(x, Number[i][Zone][z], GetGVarInt("Zone_NumbColor"));
	        }
		}
	}
	
	return 1;
}



Convert(seconds, dest[], size = sizeof dest)
{
    new data[4] = {-1, ...};
	
    data[0] = floatround(seconds / 86400);
    data[1] = floatround(seconds / 3600);
    data[2] = floatround((seconds / 60) - (data[1] * 60));
    data[3] = floatround(seconds - ((data[1] * 3600) + (data[2] * 60)));
    
    switch(data[0])
    {
        case 0:
        {
            switch(data[1])
            {
                case 0:
				{
					format(dest, size, "%02i:%02i", data[2], data[3]);
				}
                default:
				{
					format(dest, size, "%i:%02i:%02i", data[1], data[2], data[3]);
				}
			}
		}
		default:
		{
		    switch(data[1])
		    {
		        case 0:
				{
					format(dest, size, "%i дней, %02i:%02i", data[0], data[2], data[3]);
				}
		        default:
				{
					format(dest, size, "%i дней, %i:%02i:%02i", data[0], data[1], data[2], data[3]);
				}
			}
		}
	}
}



Float:GetPlayerSpeedXY(playerid)
{
	new Float:data[3];
	
    if(IsPlayerInAnyVehicle(playerid))
	{
		GetVehicleVelocity(GetPlayerVehicleID(playerid), data[0], data[1], data[2]);
	}
	else
	{
		GetPlayerVelocity(playerid, data[0], data[1], data[2]);
	}
	
    return floatmul(floatsqroot(floatpower(data[0], 2.0) + floatpower(data[1], 2.0)), 200.0);
}



/*
bool:IsAngularVelocity(playerid)
{
	new
		Float:V[3],
	;
	if(!GetPlayerVelocity(playerid,V[0],V[1],V[2])) return false;
	
	switch(floatround(ReturnPlayerZAngle(playerid)))
	{
	    case 0, 360:
	    {
	        if(!V[0] && V[1] > 0.0) return true;
	        return false;
		}
	    case 1..89:
	    {
	        if(V[0] > 0.0 && V[1] > 0.0) return true;
	        return false;
		}
		case 90:
		{
		    if(V[0] > 0.0 && !V[1]) return true;
		    return false;
		}
		case 91..179:
		{
		    if(V[0] > 0.0 && V[1] < 0.0) return true;
		    return false;
		}
		case 180:
		{
		    if(!V[0] && V[1] < 0.0) return true;
		    return false;
		}
		case 181..269:
		{
		    if(V[0] < 0.0 && V[1] < 0.0) return true;
		    return false;
		}
		case 270:
		{
		    if(V[0] < 0.0 && !V[1]) return true;
		    return false;
		}
		case 271..359:
		{
		    if(V[0] < 0.0 && V[1] > 0.0) return true;
		    return false;
		}
	}
	
	return false;
}
*/



CheckPack(playerid)
{
	if(!GetPVarInt(playerid, "Weapon_1") || !GetPVarInt(playerid, "Weapon_2"))
	{
	    SetPVarInt(playerid, "Weapon_1", 0);
	    SetPVarInt(playerid, "Weapon_2", 0);
	    SetPVarInt(playerid, "Weapon_3", 0);
	    
	    ShowPlayerFirstWeapDialog(playerid);
	    
	    return 1;
	}
	
	new string[128];
	
	GetPlayerPack_3(playerid, string);
	
	return ShowPlayerDialog(playerid, Weapon_Change, DIALOG_STYLE_MSGBOX, "{FFFFFF}bLeague | Подтверждение выбора пака", string, "Выбор", "Сброс");
}



GetPlayerPack(playerid, dest[], size = sizeof dest)
{
	if(GetPVarInt(playerid, "Weapon_1") != GetPVarInt(playerid, "Weapon_2"))
	{
	    new W1 = GetPVarInt(playerid, "Weapon_1");
		new W2 = GetPVarInt(playerid, "Weapon_2");
		new W3 = GetPVarInt(playerid, "Weapon_3");

		switch(W3)
		{
			case 0:
			{
				format(dest, size, "%s (%i) + %s (%i)", WeaponNames[W1], ReturnAmmo(W1), WeaponNames[W2], ReturnAmmo(W2));
			}
			case 16, 17:
			{
				format(dest, size, "%s (%i) + %s (%i) + %s (%i)", WeaponNames[W1], ReturnAmmo(W1), WeaponNames[W2], ReturnAmmo(W2), WeaponNames[W3], ReturnAmmo(W3));
			}
			default:
			{
				format(dest, size, "%s (%i) + %s (%i) + %s", WeaponNames[W1], ReturnAmmo(W1), WeaponNames[W2], ReturnAmmo(W2), WeaponNames[W3]);
			}
		}
	}
	else
	{
	    new W1 = GetPVarInt(playerid, "Weapon_1");
		new W3 = GetPVarInt(playerid, "Weapon_3");

		switch(W3)
		{
			case 0:
			{
				format(dest, size, "2x %s (%i)", WeaponNames[W1], (ReturnAmmo(W1) << 1));
			}

			case 16, 17:
			{
				format(dest, size, "2x %s (%i) + %s (%i)", WeaponNames[W1], (ReturnAmmo(W1) << 1), WeaponNames[W3], ReturnAmmo(W3));
			}

			default:
			{
				format(dest, size, "2x %s (%i) + %s", WeaponNames[W1], (ReturnAmmo(W1) << 1), WeaponNames[W3]);
			}
		}
	}
}



GetPlayerPack_2(playerid, dest[], size = sizeof dest)
{
	if(GetPlayerInterior(playerid) && (GetPVarInt(playerid, "Weapon_3") == 16))
	{
		SetPVarInt(playerid, "Weapon_3", 17);
		SendClientMessage(playerid, -1, "[Инфо]: {AFAFAF}Гранаты автоматически сменены на дымовые {FFFF00}(В интерьерах разрешены только дымовые гранаты)");
	}
	
	new string[128];
	
	GetPlayerPack(playerid, string);
	format(dest, size, "{FFFFFF}Предыдущий пак: {FF0000}%s\n{FFFFFF}Сменить пак?", string);
}



GetPlayerPack_3(playerid, dest[], size = sizeof dest)
{
	new string[128];

	GetPlayerPack(playerid, string);
	format(dest, size, "{FFFFFF}Выбранный пак: {FF0000}%s\n{FFFFFF}Продолжить?", string);
}



ReturnAmmo(weaponid)
{
	switch(weaponid)
	{
	    case 16: return GetGVarInt("Ammo_Grenades");
	    case 17: return GetGVarInt("Ammo_SGrenades");
	    case 23: return GetGVarInt("Ammo_Silenced");
	    case 24: return GetGVarInt("Ammo_Deagle");
	    case 25: return GetGVarInt("Ammo_Shotgun");
	    case 29: return GetGVarInt("Ammo_MP5");
	    case 30: return GetGVarInt("Ammo_AK");
	    case 31: return GetGVarInt("Ammo_M4");
	    case 33: return GetGVarInt("Ammo_Rifle");
	    case 34: return GetGVarInt("Ammo_Sniper");
	}
	
	return 0;
}



GivePlayerWeapons(playerid)
{
	ResetPlayerWeapons(playerid);
	
	if(GetPVarInt(playerid, "Weapon_1") != GetPVarInt(playerid, "Weapon_2"))
	{
		switch(GetPVarInt(playerid, "Weapon_3"))
		{
		    case 0:
			{
				GivePlayerWeaponEx(playerid, GetPVarInt(playerid, "Weapon_1"), ReturnAmmo(GetPVarInt(playerid, "Weapon_1")), GetPVarInt(playerid, "Weapon_2"), ReturnAmmo(GetPVarInt(playerid, "Weapon_2")));
			}
			
			case 16, 17:
			{
				GivePlayerWeaponEx(playerid, GetPVarInt(playerid, "Weapon_1"), ReturnAmmo(GetPVarInt(playerid, "Weapon_1")), GetPVarInt(playerid, "Weapon_2"), ReturnAmmo(GetPVarInt(playerid, "Weapon_2")), GetPVarInt(playerid, "Weapon_3"), ReturnAmmo(GetPVarInt(playerid, "Weapon_3")));
			}
			
			default:
			{
			    GivePlayerWeaponEx(playerid, GetPVarInt(playerid, "Weapon_1"), ReturnAmmo(GetPVarInt(playerid, "Weapon_1")), GetPVarInt(playerid, "Weapon_2"), ReturnAmmo(GetPVarInt(playerid, "Weapon_2")));
			    GivePlayerWeapon(playerid, GetPVarInt(playerid, "Weapon_3"), 1);
			}
		}
	}
	else
	{
	    switch(GetPVarInt(playerid, "Weapon_3"))
		{
		    case 0:
			{
				GivePlayerWeapon(playerid, GetPVarInt(playerid,"Weapon_1"), (ReturnAmmo(GetPVarInt(playerid, "Weapon_1")) << 1));
			}
			case 16, 17:
			{
			    GivePlayerWeapon(playerid, GetPVarInt(playerid, "Weapon_1"), (ReturnAmmo(GetPVarInt(playerid, "Weapon_1")) << 1));
			    GivePlayerWeapon(playerid, GetPVarInt(playerid, "Weapon_3"), ReturnAmmo(GetPVarInt(playerid, "Weapon_3")));
			}
			default:
			{
			    GivePlayerWeapon(playerid, GetPVarInt(playerid, "Weapon_1"), (ReturnAmmo(GetPVarInt(playerid, "Weapon_1")) << 1));
			    GivePlayerWeapon(playerid, GetPVarInt(playerid, "Weapon_3"), 1);
			}
		}
	}
	
	new string[128];
	
	GetPlayerPack(playerid, string);
	
	foreach_p(i)
	{
 		if(GetPVarInt(i, "Team") != GetPVarInt(playerid, "Team"))
		 {
		 	continue;
		}
		
 		SendClientMessageF(i, GetPlayerColor(playerid), "[Команда] {FF0000}%s: {FFFFFF}Мой пак - {FFFF00}%s", Player[playerid][Name], string);
	}
	
	strins(string, "Мой пак: ", 0);
	SetPlayerChatBubble(playerid, string, GetPlayerColor(playerid), 20.0, 4000);
	
	SendClientMessageF(playerid, -1, "[Инфо]: {AFAFAF}Для перевыбора пака в течении {FF0000}%i {AFAFAF}секунд после старта раунда вы можете ввести {FFFF00}/w", GetGVarInt("Weap_ChangeTime"));
	
	return 1;
}



ShowPlayerChangeWeapDialog(playerid)
{
	new string[128];
	
	GetPlayerPack_2(playerid, string);
	
	return ShowPlayerDialog(playerid, Weapon_Change, DIALOG_STYLE_MSGBOX, "{FFFFFF}bLeague | Смена пака оружий", string, "Оставить", "Сменить");
}



CreateVehicles()
{
	new string[2048] = "{FFFFFF}";
	new index;
	new x;
	new i;
	
	for(i = 400, index = 0; i != 612; i++)
	{
	    for(x = (sizeof(ForbiddenVehicles) - 1); x != -1; --x)
		{
			if(i == ForbiddenVehicles[x])
			{
				i++;
				
				break;
			}
		}
		
		if(IsCar(i) || IsMonsterTruck(i))
		{
		    format(string, sizeof string, "%s%s\n", string, CarList[i - 400]);
		    SetGVarInt("iVehicles", i, index++);
		}
	}
	
	SetGVarString("Vehicles", string);
	
	string = "{FFFFFF}";
	
	for(i = 400, index = 0; i != 612; i++)
	{
        for(x = (sizeof(ForbiddenVehicles) - 1); x != -1; --x)
		{
			if(i == ForbiddenVehicles[x])
			{
				i++;
				
				break;
			}
		}
		
        if(IsBike(i) || IsQuad(i))
        {
            format(string, sizeof string, "%s%s\n", string, CarList[i - 400]);
            SetGVarInt("iBikes", i, index++);
		}
	}
	
	SetGVarString("Bikes", string);
	
	string = "{FFFFFF}";
	
	for(i = 400, index = 0; i != 612; i++)
	{
        for(x = (sizeof(ForbiddenVehicles) - 1); x != -1; --x)
		{
			if(i == ForbiddenVehicles[x])
			{
				i++;
				
				break;
			}
		}
		
        if(IsBicycle(i))
        {
            format(string, sizeof string, "%s%s\n", string, CarList[i - 400]);
            SetGVarInt("iBicycles", i, index++);
		}
	}
	
	SetGVarString("Bicycles", string);
	
	string = "{FFFFFF}";
	
	for(i = 400, index = 0; i != 612; i++)
	{
        for(x = (sizeof(ForbiddenVehicles) - 1); x != -1; --x)
		{
			if(i == ForbiddenVehicles[x])
			{
				i++;
				
				break;
			}
		}
		
        if(IsBoat(i))
        {
            format(string, sizeof string, "%s%s\n", string, CarList[i - 400]);
            SetGVarInt("iBoats", i, index++);
		}
	}
	
	SetGVarString("Boats", string);
	
	string = "{FFFFFF}";
	
	for(i = 400, index = 0; i != 612; i++)
	{
        for(x = (sizeof(ForbiddenVehicles) - 1); x != -1; --x)
		{
			if(i == ForbiddenVehicles[x])
			{
				i++;
				
				break;
			}
		}
		
        if(IsHelicopter(i))
        {
            format(string, sizeof string, "%s%s\n", string, CarList[i - 400]);
            SetGVarInt("iHeli", i, x++);
		}
	}
	
	SetGVarString("Heli", string);
	
	string = "{FFFFFF}";
	
	for(i = 400, index = 0; i != 612; i++)
	{
        for(x = (sizeof(ForbiddenVehicles) - 1); x != -1; --x)
		{
			if(i == ForbiddenVehicles[x]) 
			{
			    i++;
			    
			    break;
			}
		}
		
        if(IsPlane(i))
        {
            format(string, sizeof string, "%s%s\n", string, CarList[i - 400]);
            SetGVarInt("iPlanes", i, index++);
		}
	}
	
	SetGVarString("Planes", string);
}



ResetServerVars()
{
	new string[2048];
	
	playersVector = cvector();
	cvector_clear(playersVector);
	
	vehiclesVector = cvector();
	cvector_clear(vehiclesVector);
	
    SetGVarInt("LoadTick", GetTickCount());
	SetGameModeText("bLeague T/CW " #ModeVersion);
	SendRconCommand("mapname Lobby");
	
	Server[Current] = -1;
	SetGVarInt("Main3D_Color", 0x00FF40FF);
	SetGVarInt("ModeSec", 1);
	SetGVarInt("VoteKick_ID", -1);
	SetGVarInt("VoteBan_ID", -1);
	SetGVarFloat("Gravity", 0.008);
	
	strcat(string, "{FFFFFF}/help - краткая помощь по моду\n/cmd - комманды мода (это окно)\n/info (/credits) - информация о создателях мода\n/kill (/k) - самоубийство\n/a (/arena) - проголосовать за арену | /b (/base) - проголосовать за базу\n/c (/ctf) - проголосовать за CTF\n/dm - зайти на DM");
	strcat(string, "\n/changepass - сменить пароль от аккаунта");
	strcat(string, "\n/resetstats - сброс статистики\n/mystats - узнать свою статистику | /stats - узнать статистику другого игрока\n/noplay - игра вне раундов | /play - игра на раундах\n/sync (/s) - синхронизация\n/car (/veh) - меню транспорта\n/admins - администрация онлайн\n/report - жалоба на игрока\n/votekick - голосование за кик игрока | /voteban - голосование за бан игрока");
	strcat(string, "\n/w (/weap) - перевыбор оружия (в раунде)\n/spec - следить за игроком\n/switch - сменить комманду\n/pm - отправить PM\n/leave - выйти из DM");
	SetGVarString("UsualCommands", string);
	
	string[0] = 0;
	strcat(string, "{FFFFFF}/mcmd - список модер комманд (этот диалог)\n/gmenu - дать меню перевыбора оружий\n/pause [on/off] - поставить/убрать паузу\n/end - завершить раунд\n/stopvote - остановить голосование за раунд\n/lock [on/off] - открыть/закрыть сервер");
	strcat(string, "\n/sarena - запустить арену | /sbase - запустить базу | /sctf - запустить CTF\n/aswap - сменить комманду игроку\n/swapall - сменить комманды местами\n/balance - сбалансировать комманды\n/diss - удалить игрока из раунда | /add - добавить игрока в раунд");
	strcat(string, "\n/gm - проверить игрока на GM\n/akill - убить игрока\n/slap - пнуть игрока\n/burn - поджечь игрока\n/mute - заткнуть игрока | /unmute - разоткнуть игрока\n/cc - очистить чат | /ccd - очистить килл чат\n/goto - телепортироваться к игроку | /get - телепортировать игрока к себе");
	strcat(string, "\n/kick - кикнуть игрока | /ban - забанить игрока\n/leave - выкинуть игрока из DM | /leaveall - выкинуть всех из DM");
	SetGVarString("ModerCommands", string);

	string[0] = 0;
	strcat(string, "{FFFFFF}/acmd - список админ комманд (этот диалог)\n/gmenu - дать меню перевыбора оружий\n/sync [on/off] - разрешить/запретить синхронизацию\n/pause [on/off] - поставить/убрать паузу\n/end - завершить раунд\n/stopvote - остановить голосование за раунд\n/lock [on/off] - открыть/закрыть сервер\n/reloadgame - перезагрузить раунды");
	strcat(string, "\n/gmx - перезагрузить сервер\n/resetscores - обнулить очки комманд\n/vote [on/off] - разрешить/запретить голосование за раунды\n/sarena - запустить арену | /sbase - запустить базу | /sctf - запустить CTF\n/aswap - сменить комманду игроку\n/swapall - сменить комманды местами\n/autoswap [on/off] - включить/выключить автосмену комманд");
	strcat(string, "\n/balance - сбалансировать комманды\n/abalance [on/off] - включить/выключить автобаланс\n/balancetype - сменить тип автобаланса\n/tname - сменить имя комманде\n/setname - сменить имя игроку\n/setmoder - дать игроку полномочия модератора | /delmoder - отобрать полномочия модератора у игрока\n/diss - удалить игрока из раунда | /add - добавить игрока в раунд");
	strcat(string, "\n/gm - проверить игрока на GM\n/akill - убить игрока/slap - пнуть игрока\n/burn - поджечь игрока\n/mute - заткнуть игрока | /unmute - разоткнуть игрока\n/cc - очистить чат | /ccd - очистить килл чат\n/goto - телепортироваться к игроку | /get - телепортировать игрока к себе\n/maxping - установить максимальный пинг");
	strcat(string, "\n/maxpingwarn - установить максимальное количество предупреждений за высокий пинг\n/kick - кикнуть игрока | /ban - забанить игрока\n/leave - выкинуть игрока из DM | /leaveall - выкинуть всех из DM");
	SetGVarString("AdminCommands", string);
	
	string[0] = 0;
	strcat(string, "{FFFFFF}Начало разработки мода: {AFAFAF}27.07.2011\n{FFFFFF}Длительность разработки: {AFAFAF}4 месяца\n\n{FFFFFF}Комманда разработчиков:\n\nАвтор, скриптер, отладчик: {FF0000}BJIADOKC\n{FFFFFF}Бета-тестеры: {FF0000}Demetr1us {FFFFFF}| {FF0000}VIRuS {FFFFFF}| {FF0000}Vandersexxx");
	strcat(string, "\n{FFFFFF}В моде используются:\n- RegEx (Автор: Fro)\n- Whirlpool (Автор: Y_Less)\n- zcmd (Автор: Zeex)\n- sscanf (Автор: Y_Less)\n- MySQL R7 (Автор: BlueG)\n- GVar (Автор: Incognito)\n\nВсе предложения и пожелания по моду можно отправлять:\n{00FF40}ICQ 3300626 {FFFFFF}или {0040FF}Skype: bjiadokc");
	strcat(string, "\n\n{FF0000}b{AFAFAF}League " #ModeVersion " {FFFFFF}(c) BJIADOKC, 2012, Все права защищены грубой физической силой\nДанный мод и все его части являются собственностью Владокса. Мод не в паблике, и не для продажи");
	SetGVarString("Info", string);
	
	SetGVarString("Mayak", "Атакуют... Требуется поддержка!");
 	SetGVarString("Mayak", "Противник замечен!", 1);
  	SetGVarString("Mayak", "Прикройте меня!", 2);
   	SetGVarString("Mayak", "Нужно подкрепление!", 3);
    SetGVarString("Mayak", "Помогите!", 4);
    SetGVarString("Mayak", "Убивааают!", 5);
    
	SetGVarInt("Paused", 0);
    SetGVarInt("Vote_Avalible", 1);
	SetGVarInt("VoteKick_Active", 0);
	SetGVarInt("VoteKick_ID", -1);
	SetGVarInt("VoteBan_Active", 0);
	SetGVarInt("VoteBan_ID", -1);
	SetGVarInt("VoteKick_Votes", 0);
	SetGVarInt("VoteBan_Votes", 0);
	SetGVarInt("Voting", 0);
	SetGVarInt("Skin_Att", 28);
	SetGVarInt("Skin_Def", 144);
	SetGVarInt("Skin_Ref", 101);
	SetGVarString("Team_Name", "None", Team_None);
	SetGVarString("Team_Name", "Attack", Team_Attack);
	SetGVarString("Team_Name", "Defend", Team_Defend);
	SetGVarString("Team_Name", "Judges", Team_Refferee);
	SetGVarInt("Score", 0, Team_None);
	SetGVarInt("Score", 0, Team_Attack);
	SetGVarInt("Score", 0, Team_Defend);
	SetGVarInt("Score", 0, Team_Refferee);
	SetGVarInt("Team_Color_R", 0x00000000, Team_None);
	SetGVarInt("Team_Color_L", 0x00000000, Team_None);
	SetGVarInt("Team_Color_R", 0x9F0000FF, Team_Attack);
	SetGVarInt("Team_Color_L", 0xFF2F2FFF, Team_Attack);
	SetGVarInt("Team_Color_R", 0x0000B3FF, Team_Defend);
	SetGVarInt("Team_Color_L", 0x4242FFFF, Team_Defend);
	SetGVarInt("Team_Color_R", 0x008000FF, Team_Refferee);
	SetGVarInt("Team_Color_L", 0x00FF00FF, Team_Refferee);
	SetGVarInt("Connect_Color", 0xAFAFAFFF);
	SetGVarInt("Zone_Color", 0x00000075);
	SetGVarInt("Default_VotingTime", 20);
	SetGVarInt("MaxLoginTime", 60);
	SetGVarInt("AFK_System", 1);
	SetGVarInt("AFK_Show", 1);
	SetGVarInt("AFK_Kick", 0);
	SetGVarInt("AFK_Remove", 1);
	SetGVarInt("DissTime", 20);
	SetGVarInt("AFK_RemoveTime", 30);
	SetGVarInt("AFK_KickTime", 600);
	SetGVarInt("Weather", 17);
	SetGVarInt("TimeSync", 0);
	SetGVarInt("ConstTime", 12);
	SetGVarFloat("Gravity", 0.008000);
	SetGVarInt("MainInterior", 0);
	SetGVarFloat("Lobby_Pos", 332.612, 0);
	SetGVarFloat("Lobby_Pos", -1799.924, 1);
	SetGVarFloat("Lobby_Pos", 5.045, 2);
	SetGVarString("Lobby_3DText", "bLeague " #ModeVersion);
	SetGVarInt("Main3D_Color", 0x00FF40FF);
	SetGVarInt("Zone_NumbColor", 0x00000099);
	SetGVarFloat("Number_Size", 1.500000);
	SetGVarInt("AntiBug_C", 1);
	SetGVarInt("AntiBug_S", 1);
	SetGVarInt("AntiBug_G", 1);
	SetGVarInt("AntiBug_K", 1);
	SetGVarInt("AntiCheat_Load", 1);
	SetGVarInt("AntiCheat_Weapon", 0);
	SetGVarInt("AntiCheat_FastWalk", 0);
	SetGVarInt("CW", 0);
	SetGVarInt("AutoSwap", 1);
	SetGVarInt("AutoBalance", 1);
	SetGVarInt("AutoBalance_Type", 2);
	SetGVarInt("Default_Counting", 10);
	SetGVarInt("Default_ModeMin", 5);
	SetGVarInt("Weap_ChangeTime", 30);
	SetGVarFloat("Base_Distance", 250.000000);
	SetGVarInt("SyncEnabled", 1);
	SetGVarInt("MaxPing", 500);
	SetGVarInt("MaxPingExceeds", 5);

 	SetGVarInt("Ammo_Deagle", 107);
  	SetGVarInt("Ammo_Shotgun", 100);
   	SetGVarInt("Ammo_Silenced", 200);
    SetGVarInt("Ammo_MP5", 500);
    SetGVarInt("Ammo_AK", 400);
    SetGVarInt("Ammo_M4", 300);
    SetGVarInt("Ammo_Rifle", 150);
    SetGVarInt("Ammo_Sniper", 100);
    SetGVarInt("Ammo_Grenades", 3);
    SetGVarInt("Ammo_SGrenades", 5);

	FormatWeapons();
}



ResetPlayerVars(playerid)
{
	if(GetPVarInt(playerid, "CarID") != 0xFFFF)
	{
		DestroyVehicleEx(GetPVarInt(playerid, "CarID"), playerid);
	}
	
	SetPVarInt(playerid, "ClearTimer", -1);
	SetPVarInt(playerid, "DamageTimer", -1);
	SetPVarInt(playerid, "ComboTimer", -1);
	SetPVarInt(playerid, "DM_Zone", -1);
	SetPVarInt(playerid, "DuelID", -1);
	SetPVarInt(playerid, "Disqual_Time", GetGVarInt("DissTime"));
	SetPVarInt(playerid, "SpecID", -1);
	SetPVarInt(playerid, "DialogID", -1);
	
	for(new i, x; i != 2; i++)
	{
 		for( ; x != 12; x++)
 		{
			PlayerWeapons[playerid][i][x] = 0;
		}
	}
}



ShowPlayerRegisterDialog(playerid)
{
	new string[64];
 	new text[256];
	
	format(string, sizeof string, "{FFFFFF}Регистрация аккаунта {FF0000}%s", Player[playerid][Name]);
	format(text, sizeof text, "{FFFFFF}Здраствуйте, {FF0000}%s\n{FFFFFF}Вы должны установить на свой аккаунт пароль\nПароль нужен для сохранности аккаунта\nДля продолжения введите пароль в поле снизу\nДлина пароля должна быть {FF0000}не меньше 4 и не больше 20 {FFFFFF}символов\nПароль не может состоять из одних чисел", Player[playerid][Name]);
	
	return ShowPlayerDialog(playerid, Register, DIALOG_STYLE_INPUT, string, text, "Ок", "");
}



ShowPlayerLoginDialog(playerid)
{
	new string[64];
 	new text[256];
	
	format(string, sizeof string, "{FFFFFF}Вход в аккаунт {FF0000}%s", Player[playerid][Name]);
	format(text, sizeof text, "{FFFFFF}Здраствуйте, {FF0000}%s\n{FFFFFF}Ваш аккаунт на этом сервере {FF0000}защищен паролем\n{FFFFFF}Для продолжения введите Ваш пароль в поле снизу\nУ Вас есть {FF0000}3 попытки и 60 секунд", Player[playerid][Name]);
	
	return ShowPlayerDialog(playerid, Login, DIALOG_STYLE_PASSWORD, string, text, "Ок", "Выйти");
}



ShowPlayerChangepassDialog(playerid)
{
	new string[64];
 	new text[256];
	
	format(string, sizeof string, "{FFFFFF}Смена пароля от аккаунта {FF0000}%s", Player[playerid][Name]);
	format(text, sizeof text, "{FFFFFF}Здраствуйте, {FF0000}%s\n{FFFFFF}Вы хотите сменить старый пароль от вашего аккаунта на новый\nДля продолжения введите новый пароль в поле снизу\nДлина пароля должна быть {FF0000}не меньше 4 и не больше 20 {FFFFFF}символов\nПароль не может состоять из одних чисел", Player[playerid][Name]);
	
	return ShowPlayerDialog(playerid, Changepass, DIALOG_STYLE_INPUT, string, text, "Ок", "Отмена");
}



ShowPlayerResetstatsDialog(playerid)
{
	new string[64];
 	new text[256];
	
	format(string, sizeof string, "{FFFFFF}Сброс статистики аккаунта {FF0000}%s", Player[playerid][Name]);
	format(text, sizeof text, "{FFFFFF}Здраствуйте, {FF0000}%s\n{FFFFFF}Вы хотите обнулить всю статистику своего аккаунта без возможности восстановления\nДля продолжения введите текущий пароль от аккаунта в поле снизу\nУ Вас есть {FF0000}3 попытки", Player[playerid][Name]);
	
	return ShowPlayerDialog(playerid, Resetstats, DIALOG_STYLE_PASSWORD, string, text, "Ок", "Отмена");
}



FormatWeapons()
{
	new string[150];
	
	format(string, sizeof string, "{FFFFFF}Desert Eagle (%i)\nSilenced Pistol (%i)\nShotgun (%i)\nMP5 (%i)\nAK-47 (%i)\nM4 (%i)\nCountry Rifle (%i)\nSniper Rifle (%i)", GetGVarInt("Ammo_Deagle"), GetGVarInt("Ammo_Silenced"), GetGVarInt("Ammo_Shotgun"), GetGVarInt("Ammo_MP5"), GetGVarInt("Ammo_AK"), GetGVarInt("Ammo_M4"), GetGVarInt("Ammo_Rifle"), GetGVarInt("Ammo_Sniper"));
	SetGVarString("Weapons", string);
	format(string, sizeof string, "{FFFFFF}Knife\nBaseball Bat\nShovel\nNitestick\n__________\nGrenades (%i)\nTear Gas (%i)", GetGVarInt("Ammo_Grenades"), GetGVarInt("Ammo_SGrenades"));
	SetGVarString("Weapons", string, 1);
}



ShowPlayerFirstWeapDialog(playerid)
{
	new string[150];
	
	GetGVarString("Weapons", string);
	
	return ShowPlayerDialog(playerid, Weapon, DIALOG_STYLE_LIST, "{FFFFFF}bLeague | Выбор пака оружий", string, "Выбор", "Отмена");
}



ShowPlayerSecWeapDialog(playerid)
{
	new string[2][150];
	
	format(string[0], 150, "{FFFFFF}Выбранное оружие №1: %s | Выберите 2е оружие", WeaponNames[GetPVarInt(playerid, "Weapon_1")]);
	GetGVarString("Weapons", string[1], 150);
	
	return ShowPlayerDialog(playerid, Weapon, DIALOG_STYLE_LIST, string[0], string[1], "Выбор", "Назад");
}



ShowPlayerThirdWeapDialog(playerid)
{
	new string[150];
	
	GetGVarString("Weapons", string, sizeof string, 1);
	
	return ShowPlayerDialog(playerid, Weapon, DIALOG_STYLE_LIST, "{FFFFFF}Выберите дополнительное оружие", string, "Выбор", "Не надо");
}



GetOnlinePlayers()
{
	return cvector_size(playersVector);
}



GetActivePlayers()
{
	new active;
 	
	foreach_p(i)
	{
		if(GetPVarInt(i, "No_Play") || !GetPVarInt(i, "Spawned") || GetPVarInt(i, "AFK_In"))
		{
			continue;
		}
		
		active++;
	}
	
	return active;
}



GetAdmins()
{
	new admins;
	
	foreach_p(i)
	{
		if(!GetPVarInt(i, "Admin"))
		{
			continue;
		}
		
		admins++;
	}
	
	return admins;
}



AttsOnline()
{
	new att_online;

	foreach_p(i)
	{
	    if(GetPVarInt(i, "Team") != Team_Attack)
		{
			continue;
		}
		
	    att_online++;
	}
	
	return att_online;
}



DefsOnline()
{
	new def_online;
	
	foreach_p(i)
	{
	    if(GetPVarInt(i, "Team") != Team_Defend)
		{
			continue;
		}
		
	    def_online++;
	}
	
	return def_online;
}



AttsActive()
{
	new att_active;
	
	foreach_p(i)
	{
	    if((GetPVarInt(i, "Team") != Team_Attack) || GetPVarInt(i, "No_Play") || GetPVarInt(i, "AFK_In") || !GetPVarInt(i, "Playing"))
		{
			continue;
		}
		
	    att_active++;
	}
	
	return att_active;
}



DefsActive()
{
	new def_active;
	
	foreach_p(i)
	{
	    if((GetPVarInt(i, "Team") != Team_Defend) || GetPVarInt(i, "No_Play") || GetPVarInt(i, "AFK_In") || !GetPVarInt(i, "Playing"))
		{
			continue;
		}
		
	    def_active++;
	}
	
	return def_active;
}



AttsAlive()
{
	new att_alive;
	
	foreach_p(i)
	{
	    if((GetPVarInt(i, "Team") != Team_Attack) || !GetPVarInt(i, "Playing") || (GetPlayerState(i) == 7) || GetPVarInt(i, "No_Play"))
		{
			continue;
		}
		
	    att_alive++;
	}
	
	return att_alive;
}



DefsAlive()
{
	new def_alive;
	
	foreach_p(i)
	{
	    if((GetPVarInt(i, "Team") != Team_Defend) || !GetPVarInt(i, "Playing") || (GetPlayerState(i) == 7) || GetPVarInt(i, "No_Play"))
		{
			continue;
		}
		
	    def_alive++;
	}
	
	return def_alive;
}



Float:AttHp()
{
	new Float:att_return_hp;
	
	foreach_p(i)
	{
	    if((GetPVarInt(i, "Team") != Team_Attack) || !GetPVarInt(i, "Playing"))
		{
			continue;
		}
		
	    att_return_hp += ReturnPlayerHealth(i);
	}
	
	return att_return_hp;
}



Float:DefHp()
{
	new Float:def_return_hp;
	
	foreach_p(i)
	{
	    if((GetPVarInt(i, "Team") != Team_Defend) || !GetPVarInt(i, "Playing"))
		{
			continue;
		}
		
	    def_return_hp += ReturnPlayerHealth(i);
	}
	
	return def_return_hp;
}



SetWin(team)
{
	new string[64];
	
    switch(GetGVarInt("GameType"))
	{
	    case Gametype_Base:
		{
			foreach_p(i)
			{
				if(!GetPVarInt(i, "Playing"))
				{
					continue;
				}
				
				GivePVarInt(i, "B_Played", 1);
			}
		}
		
	    case Gametype_Arena:
		{
			foreach_p(i)
			{
				if(!GetPVarInt(i, "Playing"))
				{
					continue;
				}
				
				GivePVarInt(i, "A_Played", 1);
			}
		}
		
	    case Gametype_CTF:
		{
			foreach_p(i)
			{
				if(!GetPVarInt(i, "Playing"))
				{
					continue;
				}
				
				GivePVarInt(i, "C_Played", 1);
			}
		}
	}

	switch(team)
	{
	    case Team_Attack:
	    {
     		GiveGVarInt("Score", 1, Team_Attack);
     		GetGVarString("Team_Name", string, sizeof string, Team_Attack);
     		
		    SendClientMessageToAllF(-1, "[Инфо]: {00FF40}Атакеры (%s) выиграли раунд!", string);
		    SendRconCommandF("mapname Attack (%s) win!", string);
		    
	        TextDrawSetStringF(TeamTextDraw[Team_Attack][4], "Congratulations, %s!", string);
	        TextDrawSetStringF(TeamTextDraw[Team_Attack][1], "HP: %.1f     Alive: %i", AttHp(), AttsAlive());
	        
			foreach_p(i)
			{
			    if(!GetPVarInt(i, "Spawned") || (GetPVarInt(i, "DM_Zone") != -1) || (GetPVarInt(i, "DuelID") != -1) || GetPVarInt(i, "No_Play"))
				{
					continue;
				}
				
			    switch(GetPVarInt(i, "Team"))
			    {
			        case Team_Attack:
					{
						GivePVarInt(i, "Team_Wins", 1);
					}
					
					case Team_Defend:
					{
						GivePVarInt(i, "Team_Loses", 1);
					}
				}
				
				PlayRandomSound(i);
				
				for(new x; x != 5; x++)
				{
					TextDrawShowForPlayer(i, TeamTextDraw[Team_Attack][x]);
				}
				
				TogglePlayerControllable(i, true);
			}
			
			StopRound();
		}
		
		case Team_Defend:
		{
		    GiveGVarInt("Score", 1, Team_Defend);
		    GetGVarString("Team_Name", string, sizeof string, Team_Defend);
		    
		    SendClientMessageToAllF(-1, "[Инфо]: {00FF40}Дефендеры (%s) выиграли раунд!", string);
		    SendRconCommandF("mapname Defend (%s) win!", string);
		    
	        TextDrawSetStringF(TeamTextDraw[Team_Defend][4], "Congratulations, %s!", string);
	        TextDrawSetStringF(TeamTextDraw[Team_Defend][1], "HP: %.1f     Alive: %i", DefHp(), DefsAlive());
	        
			foreach_p(i)
			{
			    if(!GetPVarInt(i, "Spawned") || (GetPVarInt(i, "DM_Zone") != -1) || (GetPVarInt(i, "DuelID") != -1) || GetPVarInt(i, "No_Play"))
				{
					continue;
				}
				
			    switch(GetPVarInt(i, "Team"))
			    {
			        case Team_Attack:
					{
						GivePVarInt(i, "Team_Wins", 1);
					}
					
					case Team_Defend:
					{
						GivePVarInt(i, "Team_Loses", 1);
					}
				}
				
				PlayRandomSound(i);
				
				for(new x; x != 5; x++)
				{
					TextDrawShowForPlayer(i, TeamTextDraw[Team_Defend][x]);
				}
				
				TogglePlayerControllable(i, true);
			}
			
			StopRound();
		}
		
		default:
		{
		    SendClientMessageToAll(-1, "[Инфо]: {AFAFAF}Ничья!");
		    SendRconCommand("mapname Draw!");
		    
	        TextDrawSetStringF(TeamTextDraw[Team_None][1], "Attack:~n~HP: %.1f     Alive: %i", AttHp(), AttsAlive());
	        TextDrawSetStringF(TeamTextDraw[Team_None][4], "Defend:~n~HP: %.1f     Alive: %i", DefHp(), DefsAlive());
	        
			foreach_p(i)
			{
			    if(!GetPVarInt(i, "Spawned") || (GetPVarInt(i, "DM_Zone") != -1) || (GetPVarInt(i, "DuelID") != -1) || GetPVarInt(i, "No_Play"))
				{
					continue;
				}
				
				PlayRandomSound(i);
				
				for(new x; x != 5; x++)
				{
					TextDrawShowForPlayer(i, TeamTextDraw[Team_None][x]);
				}
				
				TogglePlayerControllable(i, true);
			}
			
			StopRound();
		}
	}

	if(GetGVarInt("AutoSwap"))
	{
		SetTimer("SwapAll", 3500, false);
	}
	
	if(GetGVarInt("AutoBalance") && ((AttsOnline() > (DefsOnline() + 1)) || (DefsOnline() > (AttsOnline() + 1))))
	{
		SetTimerEx("Balance", 5000, false, "i", GetGVarInt("AutoBalance_Type"));
	}
	
	SetTimer("HideWin", 5000, false);
	
	return 1;
}



StopRound()
{
	switch(GetGVarInt("GameType"))
	{
		case Gametype_Arena:
		{
		    for(new i; i != 4; i++)
		    {
		    	GangZoneHideForAll(Arena[Server[Current]][GangZone][i]);
		    }
		    
		    for(new i; i != 3; i++)
		    {
		        for(new x; x != 5; x++)
		        {
		        	GangZoneHideForAll(Number[i][Zone][x]);
		        }
		    }
		}
		
		case Gametype_CTF:
		{
		    for(new i; i != 4; i++)
		    {
		    	GangZoneHideForAll(CTF[Server[Current]][GangZone][i]);
		    }
		    
		    for(new i; i != 3; i++)
		    {
		        for(new x; x != 5; x++)
		        {
		        	GangZoneHideForAll(Number[i][Zone][x]);
		        }
		    }
		    
			CTF[Server[Current]][FlagOwner][0] = INVALID_PLAYER_ID;
			CTF[Server[Current]][FlagOwner][1] = INVALID_PLAYER_ID;
			
			for(new i; i != 2; i++)
			{
				if(IsValidObject(CTF[Server[Current]][Flag][i]))
				{
					DestroyObject(CTF[Server[Current]][Flag][i]);
				}
				else
				{
					DestroyPickup(CTF[Server[Current]][Flag][i]);
				}
			}
		}
	}
	
	foreach_p(i)
	{
	    if(GetPVarInt(i, "SpecID") != -1)
		{
			StopSpectate(i);
		}
		
	    SetPlayerScore(i, GetPVarInt(i, "Kills"));
	    
	    if(!GetPVarInt(i, "Playing"))
		{
			continue;
		}
	    
	    PlayerTextDrawSetString(i, Player[i][HealthBar], "HP: 100");
    	PlayerTextDrawShow(i, Player[i][HealthBar]);
	    SetPlayerHealth(i, 100.0);
	    
	    if(GetPVarInt(i, "CarID") != INVALID_VEHICLE_ID)
		{
			DestroyVehicleEx(GetPVarInt(i, "CarID"), i);
		}
		
     	SetPVarInt(i, "Playing", 0);
     	SetPVarInt(i, "Change_Weapon", 0);
     	
      	SetPlayerColor(i, GetGVarInt("Team_Color_L", GetPVarInt(i, "Team")));
       	SetPlayerVirtualWorld(i, Lobby_VW);
       	SetPlayerInterior(i, GetGVarInt("MainInterior"));
        ResetPlayerWeapons(i);
        HideDialog(i);
        PlayerStopSound(i);
        SetPVarInt(i, "ComboKills", 0);
        TogglePlayerControllable(i, true);
        
        if(GetGVarInt("GameType") == Gametype_Base)
		{
			DisablePlayerCheckpoint(i);
		}
		
        SetPlayerPos(i, floatadd(GetGVarFloat("Lobby_Pos", 0), floatrandom(10)), floatadd(GetGVarFloat("Lobby_Pos", 1), floatrandom(10)), GetGVarFloat("Lobby_Pos", 2));
        SetCameraBehindPlayer(i);
	}
	
	SetGVarInt("GameType", Gametype_None);
	Server[Current] = -1;
}



TeamFix(playerid)
{
 	if(GetPlayerSkin(playerid) == GetGVarInt("Skin_Att"))
	{
	    SetPVarInt(playerid, "Team", Team_Attack);
	    SetPlayerColor(playerid, GetGVarInt("Team_Color_L", Team_Attack));
	}
	else if(GetPlayerSkin(playerid) == GetGVarInt("Skin_Def"))
	{
	    SetPVarInt(playerid, "Team", Team_Defend);
        SetPlayerColor(playerid, GetGVarInt("Team_Color_L", Team_Defend));
	}
	else if(GetPlayerSkin(playerid) == GetGVarInt("Skin_Ref"))
	{
	    SetPVarInt(playerid, "Team", Team_Refferee);
	    SetPlayerColor(playerid, GetGVarInt("Team_Color_L", Team_Refferee));
	}
}



CreateTextDraws()
{
	new string_data[128];
	
	for(new i, int_data; i != 75; i++, int_data += 3)
	{
	    
	    if(int_data > 99)
		{
			format(string_data,32,"0x00000%02d",int_data);
		}
		else
		{
			format(string_data,32,"0x000000%02d",int_data);
		}
		Server[Gradient][i] = TextDrawCreate(1.000000,floatadd(431.000000,float(i)),"_");
		TextDrawUseBox(Server[Gradient][i],1);
		TextDrawBoxColor(Server[Gradient][i],StringToHex(string_data));
		TextDrawTextSize(Server[Gradient][i],640.000000,0.000000);
		TextDrawAlignment(Server[Gradient][i],0);
		TextDrawBackgroundColor(Server[Gradient][i],0x00000000);
		TextDrawFont(Server[Gradient][i],3);
		TextDrawLetterSize(Server[Gradient][i],4.599999,1.800000);
		TextDrawColor(Server[Gradient][i],0x00000000);
		TextDrawSetOutline(Server[Gradient][i],1);
		TextDrawSetProportional(Server[Gradient][i],1);
		TextDrawSetShadow(Server[Gradient][i],1);
	}
	
	Server[BlackFullScreen] = TextDrawCreate(1.000000,1.000000,"_");
	TextDrawUseBox(Server[BlackFullScreen],1);
	TextDrawBoxColor(Server[BlackFullScreen],0x000000FF);
	TextDrawTextSize(Server[BlackFullScreen],650.000000,0.000000);
	TextDrawAlignment(Server[BlackFullScreen],0);
	TextDrawBackgroundColor(Server[BlackFullScreen],0x00000000);
	TextDrawFont(Server[BlackFullScreen],3);
	TextDrawLetterSize(Server[BlackFullScreen],4.000000,54.000000);
	TextDrawColor(Server[BlackFullScreen],0x00000000);
	TextDrawSetOutline(Server[BlackFullScreen],1);
	TextDrawSetProportional(Server[BlackFullScreen],1);
	TextDrawSetShadow(Server[BlackFullScreen],1);
	
	Server[RedFullScreen] = TextDrawCreate(1.000000,1.000000,"_");
	TextDrawUseBox(Server[RedFullScreen],1);
	TextDrawBoxColor(Server[RedFullScreen],0xFF000066);
	TextDrawTextSize(Server[RedFullScreen],650.000000,0.000000);
	TextDrawAlignment(Server[RedFullScreen],0);
	TextDrawBackgroundColor(Server[RedFullScreen],0x00000000);
	TextDrawFont(Server[RedFullScreen],3);
	TextDrawLetterSize(Server[RedFullScreen],4.000000,54.000000);
	TextDrawColor(Server[RedFullScreen],0x00000000);
	TextDrawSetOutline(Server[RedFullScreen],1);
	TextDrawSetProportional(Server[RedFullScreen],1);
	TextDrawSetShadow(Server[RedFullScreen],1);
	
	VoteKickText = TextDrawCreate(556.000000,105.000000,"_");
	VoteBanText = TextDrawCreate(556.000000,151.000000,"_");
	TextDrawUseBox(VoteKickText,1);
	TextDrawBoxColor(VoteKickText,0x00000033);
	TextDrawTextSize(VoteKickText,0.000000,160.000000);
	TextDrawUseBox(VoteBanText,1);
	TextDrawBoxColor(VoteBanText,0x00000033);
	TextDrawTextSize(VoteBanText,0.000000,160.000000);
	TextDrawAlignment(VoteKickText,2);
	TextDrawAlignment(VoteBanText,2);
	TextDrawBackgroundColor(VoteKickText,0xffffff33);
	TextDrawBackgroundColor(VoteBanText,0xffffff33);
	TextDrawFont(VoteKickText,2);
	TextDrawLetterSize(VoteKickText,0.299999,1.500000);
	TextDrawFont(VoteBanText,2);
	TextDrawLetterSize(VoteBanText,0.299999,1.300000);
	TextDrawColor(VoteKickText,0x000000ff);
	TextDrawColor(VoteBanText,0x000000ff);
	TextDrawSetOutline(VoteKickText,1);
	TextDrawSetOutline(VoteBanText,1);
	TextDrawSetProportional(VoteKickText,1);
	TextDrawSetProportional(VoteBanText,1);
	TextDrawSetShadow(VoteKickText,1);
	TextDrawSetShadow(VoteBanText,1);

	Server[Barrier][0] = TextDrawCreate(1.000000,425.000000,"-");
	TextDrawAlignment(Server[Barrier][0],0);
	TextDrawBackgroundColor(Server[Barrier][0],0x000000ff);
	TextDrawFont(Server[Barrier][0],3);
	TextDrawLetterSize(Server[Barrier][0],45.000000,1.000000);
	TextDrawColor(Server[Barrier][0],-1);
	TextDrawSetOutline(Server[Barrier][0],1);
	TextDrawSetProportional(Server[Barrier][0],1);
	TextDrawSetShadow(Server[Barrier][0],1);
	
	Server[Barrier][1] = TextDrawCreate(359.000000,344.000000,".");
	Server[Barrier][2] = TextDrawCreate(276.000000,350.000000,".");
	TextDrawAlignment(Server[Barrier][1],0);
	TextDrawAlignment(Server[Barrier][2],0);
	TextDrawBackgroundColor(Server[Barrier][1],0x000000ff);
	TextDrawBackgroundColor(Server[Barrier][2],0x000000ff);
	TextDrawFont(Server[Barrier][1],3);
	TextDrawLetterSize(Server[Barrier][1],0.199999,14.000000);
	TextDrawFont(Server[Barrier][2],3);
	TextDrawLetterSize(Server[Barrier][2],0.199999,13.000000);
	TextDrawColor(Server[Barrier][1],-1);
	TextDrawColor(Server[Barrier][2],-1);
	TextDrawSetOutline(Server[Barrier][1],1);
	TextDrawSetOutline(Server[Barrier][2],1);
	TextDrawSetProportional(Server[Barrier][1],1);
	TextDrawSetProportional(Server[Barrier][2],1);
	TextDrawSetShadow(Server[Barrier][1],1);
	TextDrawSetShadow(Server[Barrier][2],1);
	
	Server[Barrier][3] = TextDrawCreate(475.000000,254.000000,".");
	Server[Barrier][4] = TextDrawCreate(475.000000,385.000000,".");
	TextDrawAlignment(Server[Barrier][3],0);
	TextDrawAlignment(Server[Barrier][4],0);
	TextDrawBackgroundColor(Server[Barrier][3],0x000000ff);
	TextDrawBackgroundColor(Server[Barrier][4],0x000000ff);
	TextDrawFont(Server[Barrier][3],3);
	TextDrawLetterSize(Server[Barrier][3],0.199999,22.000000);
	TextDrawFont(Server[Barrier][4],3);
	TextDrawLetterSize(Server[Barrier][4],20.000000,1.000000);
	TextDrawColor(Server[Barrier][3],-1);
	TextDrawColor(Server[Barrier][4],-1);
	TextDrawSetOutline(Server[Barrier][3],1);
	TextDrawSetOutline(Server[Barrier][4],1);
	TextDrawSetProportional(Server[Barrier][3],1);
	TextDrawSetProportional(Server[Barrier][4],1);
	TextDrawSetShadow(Server[Barrier][3],1);
	TextDrawSetShadow(Server[Barrier][4],1);
	
	Server[Barrier][5] = TextDrawCreate(25.000000,292.000000,".");
	Server[Barrier][6] = TextDrawCreate(25.000000,323.000000,".");
	TextDrawAlignment(Server[Barrier][5],0);
	TextDrawAlignment(Server[Barrier][6],0);
	TextDrawBackgroundColor(Server[Barrier][5],0x000000ff);
	TextDrawBackgroundColor(Server[Barrier][6],0x000000ff);
	TextDrawFont(Server[Barrier][5],3);
	TextDrawLetterSize(Server[Barrier][5],13.799999,1.000000);
	TextDrawFont(Server[Barrier][6],3);
	TextDrawLetterSize(Server[Barrier][6],13.699998,1.000000);
	TextDrawColor(Server[Barrier][5],-1);
	TextDrawColor(Server[Barrier][6],-1);
	TextDrawSetOutline(Server[Barrier][5],1);
	TextDrawSetOutline(Server[Barrier][6],1);
	TextDrawSetProportional(Server[Barrier][5],1);
	TextDrawSetProportional(Server[Barrier][6],1);
	TextDrawSetShadow(Server[Barrier][5],1);
	TextDrawSetShadow(Server[Barrier][6],1);
	
	Server[Barrier][7] = TextDrawCreate(29.000000,121.000000,".");
	Server[Barrier][8] = TextDrawCreate(28.000000,171.000000,".");
    TextDrawAlignment(Server[Barrier][7],0);
	TextDrawAlignment(Server[Barrier][8],0);
	TextDrawBackgroundColor(Server[Barrier][7],0x000000ff);
	TextDrawBackgroundColor(Server[Barrier][8],0x000000ff);
	TextDrawFont(Server[Barrier][7],3);
	TextDrawLetterSize(Server[Barrier][7],14.000000,1.000000);
	TextDrawFont(Server[Barrier][8],3);
	TextDrawLetterSize(Server[Barrier][8],14.000000,1.000000);
	TextDrawColor(Server[Barrier][7],-1);
	TextDrawColor(Server[Barrier][8],-1);
	TextDrawSetOutline(Server[Barrier][7],1);
	TextDrawSetOutline(Server[Barrier][8],1);
	TextDrawSetProportional(Server[Barrier][7],1);
	TextDrawSetProportional(Server[Barrier][8],1);
	TextDrawSetShadow(Server[Barrier][7],1);
	TextDrawSetShadow(Server[Barrier][8],1);

	Server[SLocked] = TextDrawCreate(568.000000,4.000000,"Server Locked");
	TextDrawUseBox(Server[SLocked],1);
	TextDrawBoxColor(Server[SLocked],0x00000033);
	TextDrawTextSize(Server[SLocked],628.000000,136.000000);
	TextDrawAlignment(Server[SLocked],2);
	TextDrawBackgroundColor(Server[SLocked],0xffffff33);
	TextDrawFont(Server[SLocked],2);
	TextDrawLetterSize(Server[SLocked],0.399999,1.200000);
	TextDrawColor(Server[SLocked],0x000000ff);
	TextDrawSetOutline(Server[SLocked],1);
	TextDrawSetProportional(Server[SLocked],1);
	TextDrawSetShadow(Server[SLocked],1);

	Server[Main] = TextDrawCreate(321.000000,434.000000,"_");
	Server[ArenaAndTime] = TextDrawCreate(319.000000,431.000000,"_");
	TextDrawAlignment(Server[Main],2);
	TextDrawAlignment(Server[ArenaAndTime],2);
	TextDrawBackgroundColor(Server[Main],0x000000ff);
	TextDrawBackgroundColor(Server[ArenaAndTime],0x000000ff);
	TextDrawFont(Server[Main],2);
	TextDrawLetterSize(Server[Main],0.299999,1.000000);
	TextDrawFont(Server[ArenaAndTime],2);
	TextDrawLetterSize(Server[ArenaAndTime],0.299999,0.899999);
	TextDrawColor(Server[Main],-1);
	TextDrawColor(Server[ArenaAndTime],-1);
	TextDrawSetProportional(Server[Main],1);
	TextDrawSetProportional(Server[ArenaAndTime],1);
	TextDrawSetShadow(Server[Main],1);
	TextDrawSetShadow(Server[ArenaAndTime],1);

	Server[Multi] = TextDrawCreate(121.000000,161.000000,"_");
	TextDrawAlignment(Server[Multi],0);
	TextDrawBackgroundColor(Server[Multi],0xff0000ff);
	TextDrawFont(Server[Multi],0);
	TextDrawLetterSize(Server[Multi],3.000000,8.000000);
	TextDrawColor(Server[Multi],0x00ff00ff);
	TextDrawSetProportional(Server[Multi],1);
	TextDrawSetShadow(Server[Multi],1);
	
	TeamTextDraw[Team_Attack][0] = TextDrawCreate(331.000000,142.000000,"_");
	TeamTextDraw[Team_Attack][1] = TextDrawCreate(331.000000,274.000000,"_");
	TeamTextDraw[Team_Attack][2] = TextDrawCreate(1.000000,0.000000,"_");
	TeamTextDraw[Team_Attack][3] = TextDrawCreate(1.000000,371.000000,"_");
	TeamTextDraw[Team_Attack][4] = TextDrawCreate(341.000000,371.000000,"_");
	TextDrawUseBox(TeamTextDraw[Team_Attack][0],1);
	TextDrawBoxColor(TeamTextDraw[Team_Attack][0],0xffffff33);
	TextDrawTextSize(TeamTextDraw[Team_Attack][0],0.000000,340.000000);
	TextDrawUseBox(TeamTextDraw[Team_Attack][1],1);
	TextDrawBoxColor(TeamTextDraw[Team_Attack][1],0xffffff33);
	TextDrawTextSize(TeamTextDraw[Team_Attack][1],0.000000,340.000000);
	TextDrawUseBox(TeamTextDraw[Team_Attack][2],1);
	TextDrawBoxColor(TeamTextDraw[Team_Attack][2],0xffffff33);
	TextDrawTextSize(TeamTextDraw[Team_Attack][2],650.000000,0.000000);
	TextDrawUseBox(TeamTextDraw[Team_Attack][3],1);
	TextDrawBoxColor(TeamTextDraw[Team_Attack][3],0xffffff33);
	TextDrawTextSize(TeamTextDraw[Team_Attack][3],670.000000,-138.000000);
	TextDrawUseBox(TeamTextDraw[Team_Attack][4],1);
	TextDrawBoxColor(TeamTextDraw[Team_Attack][4],0xff000033);
	TextDrawTextSize(TeamTextDraw[Team_Attack][4],30.000000,400.000000);
	TextDrawAlignment(TeamTextDraw[Team_Attack][0],2);
	TextDrawAlignment(TeamTextDraw[Team_Attack][1],2);
	TextDrawAlignment(TeamTextDraw[Team_Attack][2],0);
	TextDrawAlignment(TeamTextDraw[Team_Attack][3],0);
	TextDrawAlignment(TeamTextDraw[Team_Attack][4],2);
	TextDrawBackgroundColor(TeamTextDraw[Team_Attack][0],-1);
	TextDrawBackgroundColor(TeamTextDraw[Team_Attack][1],0xff0000ff);
	TextDrawBackgroundColor(TeamTextDraw[Team_Attack][2],0x00000000);
	TextDrawBackgroundColor(TeamTextDraw[Team_Attack][3],0x00000000);
	TextDrawBackgroundColor(TeamTextDraw[Team_Attack][4],0xff0000ff);
	TextDrawFont(TeamTextDraw[Team_Attack][0],0);
	TextDrawLetterSize(TeamTextDraw[Team_Attack][0],4.000000,7.000000);
	TextDrawFont(TeamTextDraw[Team_Attack][1],2);
	TextDrawLetterSize(TeamTextDraw[Team_Attack][1],0.699999,1.900000);
	TextDrawFont(TeamTextDraw[Team_Attack][2],3);
	TextDrawLetterSize(TeamTextDraw[Team_Attack][2],5.000000,10.000000);
	TextDrawFont(TeamTextDraw[Team_Attack][3],3);
	TextDrawLetterSize(TeamTextDraw[Team_Attack][3],5.000000,13.200000);
	TextDrawFont(TeamTextDraw[Team_Attack][4],1);
	TextDrawLetterSize(TeamTextDraw[Team_Attack][4],1.000000,4.000000);
	TextDrawColor(TeamTextDraw[Team_Attack][0],0xff0000ff);
	TextDrawColor(TeamTextDraw[Team_Attack][1],0xffff00ff);
	TextDrawColor(TeamTextDraw[Team_Attack][2],0x00000000);
	TextDrawColor(TeamTextDraw[Team_Attack][3],0x00000000);
	TextDrawColor(TeamTextDraw[Team_Attack][4],0xffff00ff);
	TextDrawSetOutline(TeamTextDraw[Team_Attack][0],1);
	TextDrawSetOutline(TeamTextDraw[Team_Attack][1],1);
	TextDrawSetOutline(TeamTextDraw[Team_Attack][2],1);
	TextDrawSetOutline(TeamTextDraw[Team_Attack][3],1);
	TextDrawSetOutline(TeamTextDraw[Team_Attack][4],1);
	TextDrawSetProportional(TeamTextDraw[Team_Attack][0],1);
	TextDrawSetProportional(TeamTextDraw[Team_Attack][1],1);
	TextDrawSetProportional(TeamTextDraw[Team_Attack][2],1);
	TextDrawSetProportional(TeamTextDraw[Team_Attack][3],1);
	TextDrawSetProportional(TeamTextDraw[Team_Attack][4],1);
	TextDrawSetShadow(TeamTextDraw[Team_Attack][0],1);
	TextDrawSetShadow(TeamTextDraw[Team_Attack][1],1);
	TextDrawSetShadow(TeamTextDraw[Team_Attack][2],1);
	TextDrawSetShadow(TeamTextDraw[Team_Attack][3],1);
	TextDrawSetShadow(TeamTextDraw[Team_Attack][4],1);
	
	TeamTextDraw[Team_Defend][0] = TextDrawCreate(331.000000,142.000000,"_");
	TeamTextDraw[Team_Defend][1] = TextDrawCreate(331.000000,274.000000,"_");
	TeamTextDraw[Team_Defend][2] = TextDrawCreate(1.000000,0.000000,"_");
	TeamTextDraw[Team_Defend][3] = TextDrawCreate(1.000000,371.000000,"_");
	TeamTextDraw[Team_Defend][4] = TextDrawCreate(341.000000,371.000000,"_");
	TextDrawUseBox(TeamTextDraw[Team_Defend][0],1);
	TextDrawBoxColor(TeamTextDraw[Team_Defend][0],0xffffff33);
	TextDrawTextSize(TeamTextDraw[Team_Defend][0],0.000000,340.000000);
	TextDrawUseBox(TeamTextDraw[Team_Defend][1],1);
	TextDrawBoxColor(TeamTextDraw[Team_Defend][1],0xffffff33);
	TextDrawTextSize(TeamTextDraw[Team_Defend][1],0.000000,340.000000);
	TextDrawUseBox(TeamTextDraw[Team_Defend][2],1);
	TextDrawBoxColor(TeamTextDraw[Team_Defend][2],0xffffff33);
	TextDrawTextSize(TeamTextDraw[Team_Defend][2],650.000000,0.000000);
	TextDrawUseBox(TeamTextDraw[Team_Defend][3],1);
	TextDrawBoxColor(TeamTextDraw[Team_Defend][3],0xffffff33);
	TextDrawTextSize(TeamTextDraw[Team_Defend][3],670.000000,-138.000000);
	TextDrawUseBox(TeamTextDraw[Team_Defend][4],1);
	TextDrawBoxColor(TeamTextDraw[Team_Defend][4],0x0000ff33);
	TextDrawTextSize(TeamTextDraw[Team_Defend][4],30.000000,400.000000);
	TextDrawAlignment(TeamTextDraw[Team_Defend][0],2);
	TextDrawAlignment(TeamTextDraw[Team_Defend][1],2);
	TextDrawAlignment(TeamTextDraw[Team_Defend][2],0);
	TextDrawAlignment(TeamTextDraw[Team_Defend][3],0);
	TextDrawAlignment(TeamTextDraw[Team_Defend][4],2);
	TextDrawBackgroundColor(TeamTextDraw[Team_Defend][0],-1);
	TextDrawBackgroundColor(TeamTextDraw[Team_Defend][1],0x0000ffff);
	TextDrawBackgroundColor(TeamTextDraw[Team_Defend][2],0x00000000);
	TextDrawBackgroundColor(TeamTextDraw[Team_Defend][3],0x00000000);
	TextDrawBackgroundColor(TeamTextDraw[Team_Defend][4],0x0000ffff);
	TextDrawFont(TeamTextDraw[Team_Defend][0],0);
	TextDrawLetterSize(TeamTextDraw[Team_Defend][0],4.000000,7.000000);
	TextDrawFont(TeamTextDraw[Team_Defend][1],2);
	TextDrawLetterSize(TeamTextDraw[Team_Defend][1],0.699999,1.900000);
	TextDrawFont(TeamTextDraw[Team_Defend][2],3);
	TextDrawLetterSize(TeamTextDraw[Team_Defend][2],5.000000,10.000000);
	TextDrawFont(TeamTextDraw[Team_Defend][3],3);
	TextDrawLetterSize(TeamTextDraw[Team_Defend][3],5.000000,13.200000);
	TextDrawFont(TeamTextDraw[Team_Defend][4],1);
	TextDrawLetterSize(TeamTextDraw[Team_Defend][4],1.000000,4.000000);
	TextDrawColor(TeamTextDraw[Team_Defend][0],0x0000ffff);
	TextDrawColor(TeamTextDraw[Team_Defend][1],0xffff00ff);
	TextDrawColor(TeamTextDraw[Team_Defend][2],0x00000000);
	TextDrawColor(TeamTextDraw[Team_Defend][3],0x00000000);
	TextDrawColor(TeamTextDraw[Team_Defend][4],0xffff00ff);
	TextDrawSetOutline(TeamTextDraw[Team_Defend][0],1);
	TextDrawSetOutline(TeamTextDraw[Team_Defend][1],1);
	TextDrawSetOutline(TeamTextDraw[Team_Defend][2],1);
	TextDrawSetOutline(TeamTextDraw[Team_Defend][3],1);
	TextDrawSetOutline(TeamTextDraw[Team_Defend][4],1);
	TextDrawSetProportional(TeamTextDraw[Team_Defend][0],1);
	TextDrawSetProportional(TeamTextDraw[Team_Defend][1],1);
	TextDrawSetProportional(TeamTextDraw[Team_Defend][2],1);
	TextDrawSetProportional(TeamTextDraw[Team_Defend][3],1);
	TextDrawSetProportional(TeamTextDraw[Team_Defend][4],1);
	TextDrawSetShadow(TeamTextDraw[Team_Defend][0],1);
	TextDrawSetShadow(TeamTextDraw[Team_Defend][1],1);
	TextDrawSetShadow(TeamTextDraw[Team_Defend][2],1);
	TextDrawSetShadow(TeamTextDraw[Team_Defend][3],1);
	TextDrawSetShadow(TeamTextDraw[Team_Defend][4],1);
	
	TeamTextDraw[Team_None][0] = TextDrawCreate(331.000000,121.000000,"_");
	TeamTextDraw[Team_None][1] = TextDrawCreate(331.000000,253.000000,"_");
	TeamTextDraw[Team_None][2] = TextDrawCreate(1.000000,0.000000,"_");
	TeamTextDraw[Team_None][3] = TextDrawCreate(1.000000,371.000000,"_");
	TeamTextDraw[Team_None][4] = TextDrawCreate(331.000000,293.000000,"_");
	TextDrawUseBox(TeamTextDraw[Team_None][0],1);
	TextDrawBoxColor(TeamTextDraw[Team_None][0],0xffffff33);
	TextDrawTextSize(TeamTextDraw[Team_None][0],-5.000000,359.000000);
	TextDrawUseBox(TeamTextDraw[Team_None][1],1);
	TextDrawBoxColor(TeamTextDraw[Team_None][1],0xffffff33);
	TextDrawTextSize(TeamTextDraw[Team_None][1],-23.000000,359.000000);
	TextDrawUseBox(TeamTextDraw[Team_None][2],1);
	TextDrawBoxColor(TeamTextDraw[Team_None][2],0xffffff33);
	TextDrawTextSize(TeamTextDraw[Team_None][2],650.000000,0.000000);
	TextDrawUseBox(TeamTextDraw[Team_None][3],1);
	TextDrawBoxColor(TeamTextDraw[Team_None][3],0xffffff33);
	TextDrawTextSize(TeamTextDraw[Team_None][3],670.000000,-138.000000);
	TextDrawUseBox(TeamTextDraw[Team_None][4],1);
	TextDrawBoxColor(TeamTextDraw[Team_None][4],0xffffff33);
	TextDrawTextSize(TeamTextDraw[Team_None][4],-2.000000,359.000000);
	TextDrawAlignment(TeamTextDraw[Team_None][0],2);
	TextDrawAlignment(TeamTextDraw[Team_None][1],2);
	TextDrawAlignment(TeamTextDraw[Team_None][2],0);
	TextDrawAlignment(TeamTextDraw[Team_None][3],0);
	TextDrawAlignment(TeamTextDraw[Team_None][4],2);
	TextDrawBackgroundColor(TeamTextDraw[Team_None][0],-1);
	TextDrawBackgroundColor(TeamTextDraw[Team_None][1],-1);
	TextDrawBackgroundColor(TeamTextDraw[Team_None][2],0x00000000);
	TextDrawBackgroundColor(TeamTextDraw[Team_None][3],0x00000000);
	TextDrawBackgroundColor(TeamTextDraw[Team_None][4],-1);
	TextDrawFont(TeamTextDraw[Team_None][0],0);
	TextDrawLetterSize(TeamTextDraw[Team_None][0],4.000000,7.000000);
	TextDrawFont(TeamTextDraw[Team_None][1],2);
	TextDrawLetterSize(TeamTextDraw[Team_None][1],0.699999,1.900000);
	TextDrawFont(TeamTextDraw[Team_None][2],3);
	TextDrawLetterSize(TeamTextDraw[Team_None][2],5.000000,10.000000);
	TextDrawFont(TeamTextDraw[Team_None][3],3);
	TextDrawLetterSize(TeamTextDraw[Team_None][3],5.000000,13.200000);
	TextDrawFont(TeamTextDraw[Team_None][4],2);
	TextDrawLetterSize(TeamTextDraw[Team_None][4],0.699999,1.700000);
	TextDrawColor(TeamTextDraw[Team_None][0],0x000000ff);
	TextDrawColor(TeamTextDraw[Team_None][1],0x000000ff);
	TextDrawColor(TeamTextDraw[Team_None][2],0x00000000);
	TextDrawColor(TeamTextDraw[Team_None][3],0x00000000);
	TextDrawColor(TeamTextDraw[Team_None][4],0x000000ff);
	TextDrawSetOutline(TeamTextDraw[Team_None][0],1);
	TextDrawSetOutline(TeamTextDraw[Team_None][1],1);
	TextDrawSetOutline(TeamTextDraw[Team_None][2],1);
	TextDrawSetOutline(TeamTextDraw[Team_None][3],1);
	TextDrawSetOutline(TeamTextDraw[Team_None][4],1);
	TextDrawSetProportional(TeamTextDraw[Team_None][0],1);
	TextDrawSetProportional(TeamTextDraw[Team_None][1],1);
	TextDrawSetProportional(TeamTextDraw[Team_None][2],1);
	TextDrawSetProportional(TeamTextDraw[Team_None][3],1);
	TextDrawSetProportional(TeamTextDraw[Team_None][4],1);
	TextDrawSetShadow(TeamTextDraw[Team_None][0],1);
	TextDrawSetShadow(TeamTextDraw[Team_None][1],1);
	TextDrawSetShadow(TeamTextDraw[Team_None][2],1);
	TextDrawSetShadow(TeamTextDraw[Team_None][3],1);
	TextDrawSetShadow(TeamTextDraw[Team_None][4],1);
	
    Server[VoteText][0] = TextDrawCreate(36.000000,132.000000,"_");
    Server[VoteText][1] = TextDrawCreate(94.000000,181.000000,"_");
	TextDrawUseBox(Server[VoteText][0],1);
	TextDrawBoxColor(Server[VoteText][0],0x00000033);
	TextDrawTextSize(Server[VoteText][0],150.000000,0.000000);
	TextDrawAlignment(Server[VoteText][0],1);
	TextDrawAlignment(Server[VoteText][1],2);
	TextDrawBackgroundColor(Server[VoteText][0],0xffffff33);
	TextDrawBackgroundColor(Server[VoteText][1],0x000000ff);
	TextDrawFont(Server[VoteText][0],2);
	TextDrawLetterSize(Server[VoteText][0],0.299999,1.200000);
	TextDrawFont(Server[VoteText][1],1);
	TextDrawLetterSize(Server[VoteText][1],0.299999,1.000000);
	TextDrawColor(Server[VoteText][0],0x000000ff);
	TextDrawColor(Server[VoteText][1],-1);
	TextDrawSetOutline(Server[VoteText][0],1);
	TextDrawSetOutline(Server[VoteText][1],1);
	TextDrawSetProportional(Server[VoteText][0],1);
	TextDrawSetProportional(Server[VoteText][1],1);
	TextDrawSetShadow(Server[VoteText][0],1);
	TextDrawSetShadow(Server[VoteText][1],1);

	Server[ModeStartText][0] = TextDrawCreate(1.000000,2.000000,"_");
	Server[ModeStartText][1] = TextDrawCreate(1.000000,388.000000,"_");
	Server[ModeStartText][2] = TextDrawCreate(321.000000,391.000000,"_");
	TextDrawUseBox(Server[ModeStartText][0],1);
	TextDrawBoxColor(Server[ModeStartText][0],0xffffff33);
	TextDrawTextSize(Server[ModeStartText][0],650.000000,0.000000);
	TextDrawUseBox(Server[ModeStartText][1],1);
	TextDrawBoxColor(Server[ModeStartText][1],0xffffff33);
	TextDrawTextSize(Server[ModeStartText][1],650.000000,0.000000);
	TextDrawUseBox(Server[ModeStartText][2],1);
	TextDrawBoxColor(Server[ModeStartText][2],0x00ffff33);
	TextDrawTextSize(Server[ModeStartText][2],0.000000,381.000000);
	TextDrawAlignment(Server[ModeStartText][0],0);
	TextDrawAlignment(Server[ModeStartText][1],0);
	TextDrawAlignment(Server[ModeStartText][2],2);
	TextDrawBackgroundColor(Server[ModeStartText][0],0x00000000);
	TextDrawBackgroundColor(Server[ModeStartText][1],0x00000000);
	TextDrawBackgroundColor(Server[ModeStartText][2],0xff0000ff);
	TextDrawFont(Server[ModeStartText][0],3);
	TextDrawLetterSize(Server[ModeStartText][0],5.000000,7.000000);
	TextDrawFont(Server[ModeStartText][1],3);
	TextDrawLetterSize(Server[ModeStartText][1],5.000000,8.000000);
	TextDrawFont(Server[ModeStartText][2],3);
	TextDrawLetterSize(Server[ModeStartText][2],0.899999,1.900000);
	TextDrawColor(Server[ModeStartText][0],0x00000000);
	TextDrawColor(Server[ModeStartText][1],0x00000000);
	TextDrawColor(Server[ModeStartText][2],0x00ff00ff);
	TextDrawSetOutline(Server[ModeStartText][0],1);
	TextDrawSetOutline(Server[ModeStartText][1],1);
	TextDrawSetOutline(Server[ModeStartText][2],1);
	TextDrawSetProportional(Server[ModeStartText][0],1);
	TextDrawSetProportional(Server[ModeStartText][1],1);
	TextDrawSetProportional(Server[ModeStartText][2],1);
	TextDrawSetShadow(Server[ModeStartText][0],1);
	TextDrawSetShadow(Server[ModeStartText][1],1);
	TextDrawSetShadow(Server[ModeStartText][2],1);
	
	GetGVarString("Lobby_3DText",string_data);
	lobby_text = Create3DTextLabel(string_data,GetGVarInt("Main3D_Color"),GetGVarFloat("Lobby_Pos",0),GetGVarFloat("Lobby_Pos",1),floatadd(GetGVarFloat("Lobby_Pos",2),0.2),250.0,Lobby_VW,true);
}



DestroyTextDraws()
{
	TextDrawDestroy(Server[ArenaAndTime]);
	TextDrawDestroy(Server[Main]);
	TextDrawDestroy(Server[SLocked]);
	TextDrawDestroy(Server[BlackFullScreen]);
	TextDrawDestroy(VoteKickText);
	TextDrawDestroy(VoteBanText);
	TextDrawDestroy(Server[Multi]);
	
	for(new i; i != 2; i++)
	{
		TextDrawDestroy(Server[VoteText][i]);
	}
	
	for(new i; i != 3; i++)
	{
		TextDrawDestroy(Server[ModeStartText][i]);
	}
	
	for(new i; i != Max_Teams; i++)
	{
		for(new x; x != 5; x++)
		{
			TextDrawDestroy(TeamTextDraw[i][x]);
		}
	}
	
	for(new i; i != 9; i++)
	{
		TextDrawDestroy(Server[Barrier][i]);
	}
	
	for(new i; i != 75; i++)
	{
		TextDrawDestroy(Server[Gradient][i]);
	}
}



CreatePlayerTextDraws(playerid)
{
	Player[playerid][IntroLetters] = CreatePlayerTextDraw(playerid, 320.000000, 121.000000, "BJIADOKC's Training~n~bLeague v2.0"); // 421
	PlayerTextDrawAlignment(playerid,Player[playerid][IntroLetters],2); // 3
	PlayerTextDrawBackgroundColor(playerid,Player[playerid][IntroLetters],0xffffff33);
    PlayerTextDrawFont(playerid,Player[playerid][IntroLetters],2);
	PlayerTextDrawLetterSize(playerid,Player[playerid][IntroLetters],0.799999,3.099999);
	PlayerTextDrawColor(playerid,Player[playerid][IntroLetters],0x000000ff);
	PlayerTextDrawSetOutline(playerid,Player[playerid][IntroLetters],1);
	PlayerTextDrawSetProportional(playerid,Player[playerid][IntroLetters],1);
	PlayerTextDrawSetShadow(playerid,Player[playerid][IntroLetters],1);
	PlayerTextDrawSetSelectable(playerid,Player[playerid][IntroLetters], false);
	
	Player[playerid][TeamText] = CreatePlayerTextDraw(playerid,299.000000,186.000000,"."); 
	PlayerTextDrawAlignment(playerid,Player[playerid][TeamText],2);
	PlayerTextDrawBackgroundColor(playerid,Player[playerid][TeamText],0xffffff33);
	PlayerTextDrawFont(playerid,Player[playerid][TeamText],2);
	PlayerTextDrawLetterSize(playerid,Player[playerid][TeamText],0.599999,3.000000);
	PlayerTextDrawColor(playerid,Player[playerid][TeamText],-1);
	PlayerTextDrawSetOutline(playerid,Player[playerid][TeamText],1);
	PlayerTextDrawSetProportional(playerid,Player[playerid][TeamText],1);
	PlayerTextDrawSetShadow(playerid,Player[playerid][TeamText],1);
	PlayerTextDrawSetSelectable(playerid,Player[playerid][TeamText],false);
	
	Player[playerid][Dot] = CreatePlayerTextDraw(playerid,50.000000,173.000000,".");// 31
	PlayerTextDrawAlignment(playerid,Player[playerid][Dot],0);
	PlayerTextDrawBackgroundColor(playerid,Player[playerid][Dot],0x000000ff);
	PlayerTextDrawFont(playerid,Player[playerid][Dot],3);
	PlayerTextDrawLetterSize(playerid,Player[playerid][Dot],1.000000,1.000000);
	PlayerTextDrawColor(playerid,Player[playerid][Dot],-1);
	PlayerTextDrawSetOutline(playerid,Player[playerid][Dot],1);
	PlayerTextDrawSetProportional(playerid,Player[playerid][Dot],1);
	PlayerTextDrawSetShadow(playerid,Player[playerid][Dot],1);
	PlayerTextDrawSetSelectable(playerid,Player[playerid][Dot],false);
	
	Player[playerid][Speedometer] = CreatePlayerTextDraw(playerid,557.000000,394.000000,"~r~~h~~h~Infernus~n~~r~~h~Speed: 100.0 KM/H~n~~r~Health: 100");
	PlayerTextDrawUseBox(playerid,Player[playerid][Speedometer],1);
	PlayerTextDrawBoxColor(playerid,Player[playerid][Speedometer],0x00000033);
	PlayerTextDrawTextSize(playerid,Player[playerid][Speedometer],-30.000000,160.000000);
	PlayerTextDrawAlignment(playerid,Player[playerid][Speedometer],2);
	PlayerTextDrawBackgroundColor(playerid,Player[playerid][Speedometer],0x00000099);
	PlayerTextDrawFont(playerid,Player[playerid][Speedometer],2);
	PlayerTextDrawLetterSize(playerid,Player[playerid][Speedometer],0.399999,1.200000);
	PlayerTextDrawColor(playerid,Player[playerid][Speedometer],-1);
	PlayerTextDrawSetOutline(playerid,Player[playerid][Speedometer],1);
	PlayerTextDrawSetProportional(playerid,Player[playerid][Speedometer],1);
	PlayerTextDrawSetShadow(playerid,Player[playerid][Speedometer],1);
	PlayerTextDrawSetSelectable(playerid,Player[playerid][Speedometer],false);

	Player[playerid][HealthBar] = CreatePlayerTextDraw(playerid,578.000000,66.000000,"HP: 100");
	PlayerTextDrawAlignment(playerid,Player[playerid][HealthBar],2);
	PlayerTextDrawBackgroundColor(playerid,Player[playerid][HealthBar],0xffffff33);
	PlayerTextDrawFont(playerid,Player[playerid][HealthBar],2);
	PlayerTextDrawLetterSize(playerid,Player[playerid][HealthBar],0.299999,1.000000);
    PlayerTextDrawColor(playerid,Player[playerid][HealthBar],0x000000ff);
    PlayerTextDrawSetOutline(playerid,Player[playerid][HealthBar],1);
    PlayerTextDrawSetProportional(playerid,Player[playerid][HealthBar],1);
    PlayerTextDrawSetShadow(playerid,Player[playerid][HealthBar],1);
    PlayerTextDrawSetSelectable(playerid,Player[playerid][HealthBar],false);
    
	Player[playerid][HealthMinus] = CreatePlayerTextDraw(playerid,88.000000,303.000000,"-100~n~Health: 100");
	PlayerTextDrawUseBox(playerid,Player[playerid][HealthMinus],1);
	PlayerTextDrawBoxColor(playerid,Player[playerid][HealthMinus],0x00000033);
	PlayerTextDrawTextSize(playerid,Player[playerid][HealthMinus],0.000000,110.000000);
	PlayerTextDrawAlignment(playerid,Player[playerid][HealthMinus],2);
	PlayerTextDrawBackgroundColor(playerid,Player[playerid][HealthMinus],0x000000ff);
	PlayerTextDrawFont(playerid,Player[playerid][HealthMinus],2);
	PlayerTextDrawLetterSize(playerid,Player[playerid][HealthMinus],0.399999,1.300000);
	PlayerTextDrawColor(playerid,Player[playerid][HealthMinus],-1);
	PlayerTextDrawSetOutline(playerid,Player[playerid][HealthMinus],1);
	PlayerTextDrawSetProportional(playerid,Player[playerid][HealthMinus],1);
	PlayerTextDrawSetShadow(playerid,Player[playerid][HealthMinus],1);
	PlayerTextDrawSetSelectable(playerid,Player[playerid][HealthMinus],false);

	Player[playerid][LoginText] = CreatePlayerTextDraw(playerid,317.000000,371.000000,"Login in 60 Seconds~n~Or you will be kicked");
	PlayerTextDrawUseBox(playerid,Player[playerid][LoginText],1);
	PlayerTextDrawBoxColor(playerid,Player[playerid][LoginText],0x00000033);
	PlayerTextDrawTextSize(playerid,Player[playerid][LoginText],0.000000,250.000000);
	PlayerTextDrawAlignment(playerid,Player[playerid][LoginText],2);
	PlayerTextDrawBackgroundColor(playerid,Player[playerid][LoginText],0xffffff33);
	PlayerTextDrawFont(playerid,Player[playerid][LoginText],2);
	PlayerTextDrawLetterSize(playerid,Player[playerid][LoginText],0.499999,1.900000);
	PlayerTextDrawColor(playerid,Player[playerid][LoginText],0x000000ff);
	PlayerTextDrawSetOutline(playerid,Player[playerid][LoginText],1);
	PlayerTextDrawSetProportional(playerid,Player[playerid][LoginText],1);
	PlayerTextDrawSetShadow(playerid,Player[playerid][LoginText],1);
	PlayerTextDrawSetSelectable(playerid,Player[playerid][LoginText],false);
	
	Player[playerid][SpecText] = CreatePlayerTextDraw(playerid,315.000000,351.000000,"(ALFA) BJIADOKC (ID: 10)~n~Sniper Rifle (100)~n~Sniper Rifle (100)~n~Knife~n~Ping: 1000 ] FPS: 100");
	PlayerTextDrawUseBox(playerid,Player[playerid][SpecText],1);
	PlayerTextDrawBoxColor(playerid,Player[playerid][SpecText],0x00000033);
	PlayerTextDrawTextSize(playerid,Player[playerid][SpecText],0.000000,160.000000);
	PlayerTextDrawAlignment(playerid,Player[playerid][SpecText],2);
	PlayerTextDrawBackgroundColor(playerid,Player[playerid][SpecText],0x000000ff);
	PlayerTextDrawFont(playerid,Player[playerid][SpecText],2);
	PlayerTextDrawLetterSize(playerid,Player[playerid][SpecText],0.299999,1.400000);
	PlayerTextDrawColor(playerid,Player[playerid][SpecText],-1);
	PlayerTextDrawSetOutline(playerid,Player[playerid][SpecText],1);
	PlayerTextDrawSetProportional(playerid,Player[playerid][SpecText],1);
	PlayerTextDrawSetShadow(playerid,Player[playerid][SpecText],1);
	PlayerTextDrawSetSelectable(playerid,Player[playerid][SpecText],false);
	
	Player[playerid][Damage][0] = CreatePlayerTextDraw(playerid,564.000000,354.000000,"BJIADOKC~n~Desert Eagle (-90HP, 10x Combo)~n~Ping: 1000 / FPS: 100~n~Distance: 500.0M");
	PlayerTextDrawSetShadow(playerid,Player[playerid][Damage][0],1);
	PlayerTextDrawSetProportional(playerid,Player[playerid][Damage][0],1);
	PlayerTextDrawSetOutline(playerid,Player[playerid][Damage][0],1);
	PlayerTextDrawColor(playerid,Player[playerid][Damage][0],0x00ff00ff);
	PlayerTextDrawFont(playerid,Player[playerid][Damage][0],2);
	PlayerTextDrawLetterSize(playerid,Player[playerid][Damage][0],0.200000,1.000000);
	PlayerTextDrawBackgroundColor(playerid,Player[playerid][Damage][0],0x000000ff);
	PlayerTextDrawAlignment(playerid,Player[playerid][Damage][0],2);
	PlayerTextDrawSetSelectable(playerid,Player[playerid][Damage][0],false);
	
	Player[playerid][Damage][1] = CreatePlayerTextDraw(playerid,564.000000,308.000000,"BJIADOKC~n~Desert Eagle (-90HP, 10x Combo)~n~Ping: 1000 / FPS: 100~n~Distance: 500.0M");
	PlayerTextDrawSetShadow(playerid,Player[playerid][Damage][1],1);
	PlayerTextDrawSetProportional(playerid,Player[playerid][Damage][1],1);
	PlayerTextDrawSetOutline(playerid,Player[playerid][Damage][1],1);
	PlayerTextDrawColor(playerid,Player[playerid][Damage][1],0xff0000ff);
	PlayerTextDrawFont(playerid,Player[playerid][Damage][1],2);
	PlayerTextDrawLetterSize(playerid,Player[playerid][Damage][1],0.200000,1.000000);
	PlayerTextDrawBackgroundColor(playerid,Player[playerid][Damage][1],0x000000ff);
	PlayerTextDrawAlignment(playerid,Player[playerid][Damage][1],2);
	PlayerTextDrawSetSelectable(playerid,Player[playerid][Damage][1],false);
	
	Player[playerid][AtHead] = Create3DTextLabel(" ",0x00FF40FF,0.0,0.0,0.0,250.0,-1,false);
}



DestroyPlayerTextDraws(playerid)
{
	PlayerTextDrawDestroy(playerid,Player[playerid][IntroLetters]);
	PlayerTextDrawDestroy(playerid,Player[playerid][HealthBar]);
	PlayerTextDrawDestroy(playerid,Player[playerid][Speedometer]);
	PlayerTextDrawDestroy(playerid,Player[playerid][LoginText]);
	PlayerTextDrawDestroy(playerid,Player[playerid][SpecText]);
	PlayerTextDrawDestroy(playerid,Player[playerid][HealthMinus]);
	PlayerTextDrawDestroy(playerid,Player[playerid][TeamText]);
	
	for(new i = 1; i != -1; --i)
	{
		PlayerTextDrawDestroy(playerid,Player[playerid][Damage][i]);
	}
	
	Delete3DTextLabel(Player[playerid][AtHead]);
}



Float:GetRatio(int_1, int_2)
{
	new
		Float:float_data
	;
	
	if(!int_1 && int_2 > 0)
	{
		float_data = -(floatabs(float(int_2)));
	}
	if(int_1 > 0 && !int_2)
	{
		float_data = floatabs(float(int_1));
	}
	if(!int_1 && !int_2)
	{
		float_data = 0.00;
	}
	if((0 < int_1 < int_2))
	{
		float_data = -(floatabs(floatdiv(float(int_2),float(int_1))));
	}
	if((0 < int_2 <= int_1))
	{
		float_data = floatabs(floatdiv(float(int_1),float(int_2)));
	}
	
	return float_data;
}



SetTeam(playerid, Teamid)
{
	if(Server[Current] != -1) return 1;
	
	switch(Teamid)
	{
	    case Team_Attack:
	    {
			switch(GetPVarInt(playerid,"Team"))
			{
			    case Team_Attack: return 1;
				case Team_Defend, Team_Refferee:
				{
				    SetPVarInt(playerid,"Team",Team_Attack);
				    SetPlayerColor(playerid,GetGVarInt("Team_Color_L",Team_Attack));
            		SetSpawnInfo(playerid,Team_Attack,GetGVarInt("Skin_Att"),0.0,0.0,0.0,0.0,0,0,0,0,0,0);
            		return SpawnPlayer(playerid);
				}
			}
		}
		case Team_Defend:
		{
		    switch(GetPVarInt(playerid,"Team"))
		    {
		        case Team_Defend: return 1;
		        case Team_Attack, Team_Refferee:
		        {
		            SetPVarInt(playerid,"Team",Team_Defend);
		            SetPlayerColor(playerid,GetGVarInt("Team_Color_L",Team_Defend));
            		SetSpawnInfo(playerid,Team_Defend,GetGVarInt("Skin_Def"),0.0,0.0,0.0,0.0,0,0,0,0,0,0);
            		return SpawnPlayer(playerid);
				}
			}
		}
		case Team_Refferee:
		{
		    switch(GetPVarInt(playerid,"Team"))
		    {
		        case Team_Refferee: return 1;
		        case Team_Attack, Team_Defend:
		        {
		            SetPVarInt(playerid,"Team",Team_Refferee);
		            SetPlayerColor(playerid,GetGVarInt("Team_Color_L",Team_Refferee));
              		SetSpawnInfo(playerid,Team_Refferee,GetGVarInt("Skin_Ref"),0.0,0.0,0.0,0.0,0,0,0,0,0,0);
           			return SpawnPlayer(playerid);
				}
			}
		}
	}
	return 1;
}



AddToRound(playerid)
{
    new
		i
	;
	
	SetPVarInt(playerid,"Playing",1);
 	SetPlayerHealth(playerid,200.0);
 	SetPlayerScore(playerid,200);
 	
	PlayerTextDrawSetString(playerid, Player[playerid][HealthBar], "Protected");
	PlayerTextDrawShow(playerid, Player[playerid][HealthBar]);
	
	SetPlayerVirtualWorld(playerid,Round_VW);
	PlayerPlaySound(playerid,1057,0.0,0.0,0.0);
	
	switch(GetGVarInt("GameType"))
	{
	    case Gametype_Arena:
	    {
	        SetPlayerInterior(playerid,Arena[Server[Current]][Interior]);
	        SetPlayerVirtualWorld(playerid,Round_VW);
	        
	        for(i = 3; i != -1; --i)
	        {
	        	GangZoneShowForPlayer(playerid,Arena[Server[Current]][GangZone][i],GetGVarInt("Zone_Color"));
	        }
	        
	        switch(GetPVarInt(playerid,"Team"))
	        {
	            case Team_Attack:
	            {
	                SetPlayerPos(playerid,floatadd(Arena[Server[Current]][AttSpawn][0],floatrandom(2)),floatadd(Arena[Server[Current]][AttSpawn][1],floatrandom(2)),Arena[Server[Current]][AttSpawn][2]);
	                SetCameraBehindPlayer(playerid);
	                SetPlayerColor(playerid,GetGVarInt("Team_Color_R",Team_Attack));
				}
				case Team_Defend:
				{
				    SetPlayerPos(playerid,floatadd(Arena[Server[Current]][DefSpawn][0],floatrandom(2)),floatadd(Arena[Server[Current]][DefSpawn][1],floatrandom(2)),Arena[Server[Current]][DefSpawn][2]);
				    SetCameraBehindPlayer(playerid);
	                SetPlayerColor(playerid,GetGVarInt("Team_Color_R",Team_Defend));
				}
				case Team_Refferee:
				{
				    SetPlayerPos(playerid,floatadd(Arena[Server[Current]][CP][0],floatrandom(5)),floatadd(Arena[Server[Current]][CP][1],floatrandom(5)),Arena[Server[Current]][CP][2]);
				    SetCameraBehindPlayer(playerid);
				    SetPlayerColor(playerid,GetGVarInt("Team_Color_R",Team_Refferee));
				}
			}
		}
		case Gametype_Base:
		{
		    SetPlayerInterior(playerid,Base[Server[Current]][Interior]);
		    SetPlayerVirtualWorld(playerid,Round_VW);
		    
		    switch(GetPVarInt(playerid,"Team"))
			{
			    case Team_Attack:
			    {
			        SetPlayerPos(playerid,floatadd(Base[Server[Current]][AttSpawn][0],floatrandom(2)),floatadd(Base[Server[Current]][AttSpawn][1],floatrandom(2)),Base[Server[Current]][AttSpawn][2]);
			        SetPlayerColor(playerid,GetGVarInt("Team_Color_R",Team_Attack));
				}
				case Team_Defend:
				{
				    SetPlayerPos(playerid,floatadd(Base[Server[Current]][DefSpawn][0],floatrandom(2)),floatadd(Base[Server[Current]][DefSpawn][1],floatrandom(2)),Base[Server[Current]][DefSpawn][2]);
			        SetPlayerColor(playerid,GetGVarInt("Team_Color_R",Team_Defend));
				}
				case Team_Refferee:
				{
				    SetPlayerPos(playerid,floatadd(Base[Server[Current]][CP][0],floatrandom(5)),floatadd(Base[Server[Current]][CP][1],floatrandom(5)),Base[Server[Current]][CP][2]);
			        SetPlayerColor(playerid,GetGVarInt("Team_Color_R",Team_Refferee));
				}
			}
			
			SetCameraBehindPlayer(playerid);
			SetPlayerCheckpoint(playerid,Base[Server[Current]][CP][0],Base[Server[Current]][CP][1],Base[Server[Current]][CP][2],10.0);
		}
		case Gametype_CTF:
	    {
	        SetPlayerInterior(playerid,CTF[Server[Current]][Interior]);
			SetPlayerVirtualWorld(playerid,Round_VW);
			
			for(i = 3; i != -1; --i)
			{
	        	GangZoneShowForPlayer(playerid,CTF[Server[Current]][GangZone][i],GetGVarInt("Zone_Color"));
	        }
	        
	        switch(GetPVarInt(playerid,"Team"))
	        {
	            case Team_Attack:
	            {
	                SetPlayerPos(playerid,floatadd(CTF[Server[Current]][AttSpawn][0],floatrandom(2)),floatadd(CTF[Server[Current]][AttSpawn][1],floatrandom(2)),CTF[Server[Current]][AttSpawn][2]);
	                SetCameraBehindPlayer(playerid);
	                SetPlayerColor(playerid,GetGVarInt("Team_Color_R",Team_Attack));
				}
				case Team_Defend:
				{
				    SetPlayerPos(playerid,floatadd(CTF[Server[Current]][DefSpawn][0],floatrandom(2)),floatadd(CTF[Server[Current]][DefSpawn][1],floatrandom(2)),CTF[Server[Current]][DefSpawn][2]);
				    SetCameraBehindPlayer(playerid);
	                SetPlayerColor(playerid,GetGVarInt("Team_Color_R",Team_Defend));
				}
				case Team_Refferee:
				{
				    SetPlayerPos(playerid,floatadd(CTF[Server[Current]][CP][0],floatrandom(5)),floatadd(CTF[Server[Current]][CP][1],floatrandom(5)),CTF[Server[Current]][CP][2]);
				    SetCameraBehindPlayer(playerid);
				    SetPlayerColor(playerid,GetGVarInt("Team_Color_R",Team_Refferee));
				}
			}
		}
	}
	
	Update3DTextLabelText(Player[playerid][AtHead],GetPlayerColor(playerid)," ");
	SetTimerEx("NoProtectAdd",5000,false,"d",playerid);
	
	if(!GetPVarInt(playerid,"Weapon_1") || !GetPVarInt(playerid,"Weapon_2")) return ShowPlayerFirstWeapDialog(playerid);
	return ShowPlayerChangeWeapDialog(playerid);
}



RemoveFromRound(playerid)
{
	new Float:data[3];
	
	SetPVarInt(playerid,"Playing",0);
	SetPlayerScore(playerid,0);
	SetPlayerColor(playerid,GetGVarInt("Team_Color_L",GetPVarInt(playerid,"Team")));
	
	foreach_p(i)
	{
		if(GetPVarInt(i, "SpecID") != playerid)
		{
			continue;
		}
		
		AdvanceSpectate(i);
	}
	
	switch(GetGVarInt("GameType"))
	{
		case Gametype_Arena:
		{
		    for(new i; i != 4; i++)
		    {
				GangZoneHideForPlayer(playerid, Arena[Server[Current]][GangZone][i]);
			}
			
			SetPVarInt(playerid, "Disqual_Time", GetGVarInt("DissTime"));
		}
		
		case Gametype_Base:
		{
		    DisablePlayerCheckpoint(playerid);
		    SetPVarInt(playerid, "Disqual_Time", GetGVarInt("DissTime"));
		}
		
		case Gametype_CTF:
		{
		    for(new i; i != 4; i++)
		    {
		    	GangZoneHideForPlayer(playerid, CTF[Server[Current]][GangZone][i]);
		    }
		    
		    SetPVarInt(playerid, "Disqual_Time", GetGVarInt("DissTime"));
		    GetPlayerPos(playerid, data[0], data[1], data[2]);
		    
		    switch(GetPVarInt(playerid, "Team"))
		    {
		        case Team_Attack:
		        {
		            if(playerid == CTF[Server[Current]][FlagOwner][1])
		            {
		                CTF[Server[Current]][FlagOwner][1] = INVALID_PLAYER_ID;
		                
						if(IsValidObject(CTF[Server[Current]][Flag][1]))
						{
							DestroyObject(CTF[Server[Current]][Flag][1]);
						}
						else
						{
							DestroyPickup(CTF[Server[Current]][Flag][1]);
						}
						
						CTF[Server[Current]][Flag][1] = CreatePickup(Blue_Flag, Pickup_Type, data[0], data[1], (data[2] + 0.5), Round_VW);
						SendClientMessageToAll(-1, "[Инфо]: {00FF40}Комманда атакеров потеряла флаг противника!");
					}
				}
				
				case Team_Defend:
		        {
		            if(playerid == CTF[Server[Current]][FlagOwner][0])
		            {
		                CTF[Server[Current]][FlagOwner][0] = INVALID_PLAYER_ID;
		                
						if(IsValidObject(CTF[Server[Current]][Flag][0]))
						{
							DestroyObject(CTF[Server[Current]][Flag][0]);
						}
						else
						{
							DestroyPickup(CTF[Server[Current]][Flag][0]);
						}
						
						CTF[Server[Current]][Flag][0] = CreatePickup(Red_Flag, Pickup_Type, data[0], data[1], (data[2] + 0.5), Round_VW);
						SendClientMessageToAll(-1, "[Инфо]: {00FF40}Комманда дефендеров потеряла флаг противника!");
					}
				}
			}
		}
	}
	
    SetPVarInt(playerid, "ComboKills", 0);
    
    for(new i; i != 3; i++)
    {
        for(new x; x != 5; x++)
        {
	    	GangZoneHideForPlayer(playerid, Number[i][Zone][x]);
	   	}
    }
    
	return SpawnPlayer(playerid);
}



StopSpectate(playerid)
{
	if(GetPVarInt(playerid,"SpecID") == -1)
	{
		return 1;
	}
	
	TogglePlayerSpectating(playerid, false);
	PlayerTextDrawHide(playerid, Player[playerid][SpecText]);
	
	new string[16];
	
	format(string, sizeof string, "HP: %.0f", ReturnPlayerHealth(playerid));
	PlayerTextDrawSetString(playerid, Player[playerid][HealthBar], string);
	PlayerTextDrawShow(playerid, Player[playerid][HealthBar]);
	
	SetPVarInt(playerid, "SpecID", -1);
	
	return SpawnPlayer(playerid);
}



public OnPlayerBanCheck(playerid);
public OnPlayerBanCheck(playerid)
{
	new
		string_data[32],
	    rows, fields
  	;
  	
	cache_get_data(rows,fields);
	
    if(rows)
	{
	    SendClientMessage(playerid,-1,"[Инфо]: {AFAFAF}Вы забанены на этом сервере");
		cache_get_field_content(0,"Name",string_data);
		SendClientMessageF(playerid,-1,"[Инфо]: {AFAFAF}Ник в момент бана: {FF0000}%s",string_data);
		cache_get_field_content(0,"AdminName",string_data);
	    SendClientMessageF(playerid,-1,"[Инфо]: {AFAFAF}Администратор, выдавший бан: {FF0000}%s",string_data);
		cache_get_field_content(0,"Reason",string_data);
		SendClientMessageF(playerid,-1,"[Инфо]: {AFAFAF}Причина бана: {FFFF00}%s",string_data);
		cache_get_field_content(0,"Date",string_data);
	    SendClientMessageF(playerid,-1,"[Инфо]: {AFAFAF}Дата бана: {FFFF00}%s",string_data);
		return Kick(playerid);
	}

	return 1;
}



public OnPlayerBanned(playerid);
public OnPlayerBanned(playerid)
{
    SendClientMessageToAllF(-1,"[Инфо]: {AFAFAF}Игрок {FF0000}%s [ID: %i, IP: %s]{AFAFAF}вышел из игры {FF0000}(Забанен)", Player[playerid][Name], playerid, Player[playerid][IP]);

	return Kick(playerid);
}



public OnPlayerUnBanRequied(adminid, pName[]);
public OnPlayerUnBanRequied(adminid, pName[])
{
	new
	    query[64],
	    rows, fields
	;

	cache_get_data(rows,fields);
	
	if(!rows)
	{
		SendClientMessageF(adminid,-1,"[Ошибка]: {AFAFAF}Ника {FF0000}%s {AFAFAF}нет в банлисте",pName);
		
		return 1;
	}
	
	mysql_format(mysqlHandle, query, sizeof query, "DELETE FROM `Banlist` WHERE `Name` = SHA2('%s', 512)", pName);
	mysql_function_query(mysqlHandle, query, false, "OnPlayerUnBanSuccess", "is", adminid, pName);
	
	return 1;
}



public OnPlayerUnBanSuccess(adminid, pName[]);
public OnPlayerUnBanSuccess(adminid, pName[])
{
    SendClientMessageToAllF(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}разбанил ник {FFFF00}'%s'",Player[adminid][Name],pName);
    
    return 1;
}



public OnArenaLoad();
public OnArenaLoad()
{
	new rows;
	new fields;
	new string[64];
		
	cache_get_data(rows, fields, mysqlHandle);
	
	printf("Арены: %i строк, %i полей (Всего %i яйчеек данных)", rows, fields, (rows * fields));
	fields = GetTickCount();
	
	while(rows--)
	{
		Arena[rows][Exists] = true;
		Arena[rows][Interior] = cache_get_field_content_int(rows, "interior", mysqlHandle);
		
		cache_get_field_content(rows, "cp", string, mysqlHandle);
		
		for(new x; x != 3; x++)
		{
		    Arena[rows][CP][x] = fparam(string, ',', x);
		}
		
		for(new spawn, array, id[12]; spawn != Max_Spawns; spawn++, array += 3)
		{
			format(id, sizeof id, "a%i", spawn);
 			cache_get_field_content(rows, id, string, mysqlHandle);

			for(new x; x != 3; x++)
			{
			    Arena[rows][AttSpawn][array + x] = fparam(string, ',', x);
			}
	    
    		format(id, sizeof id, "d%i", spawn);
	    	cache_get_field_content(rows, id, string, mysqlHandle);
	    	
	    	for(new x; x != 3; x++)
	    	{
	    	    Arena[rows][DefSpawn][array + x] = fparam(string, ',', x);
			}
		}
		
		cache_get_field_content(rows, "quad", string, mysqlHandle);
		
		for(new x; x != 4; x++)
		{
		    Arena[rows][Quad][x] = fparam(string, ',', x);
		}
		
		if((Arena[rows][Quad][0] != 3000.0) && (Arena[rows][Quad][1] != -3000.0))
		{
			Arena[rows][GangZone][0] = GangZoneCreate(Arena[rows][Quad][0], Arena[rows][Quad][3], 3000.0, 3000.0);
			Arena[rows][GangZone][1] = GangZoneCreate(Arena[rows][Quad][2], -3000.0, 3000.0, Arena[rows][Quad][3]);
			Arena[rows][GangZone][2] = GangZoneCreate(-3000.0, Arena[rows][Quad][1], Arena[rows][Quad][0], 3000.0);
			Arena[rows][GangZone][3] = GangZoneCreate(-3000.0, -3000.0, Arena[rows][Quad][2], Arena[rows][Quad][1]);
		}
	}
	
	printf("Загрузка арен завершена (%i msec)", (GetTickCount() - fields));
	
	return 1;
}



public OnBaseLoad();
public OnBaseLoad()
{
	new string[64];
	new rows;
	new fields;
		
	cache_get_data(rows, fields, mysqlHandle);
	
	printf("Базы: %i строк, %i полей (Всего %i яйчеек данных)", rows, fields, (rows * fields));
	fields = GetTickCount();
	
	while(rows--)
	{
 		Base[rows][Exists] = true;
	    Base[rows][Interior] = cache_get_field_content_int(rows, "interior", mysqlHandle);
	    
		cache_get_field_content(rows, "cp", string, mysqlHandle);
		
		for(new x; x != 3; x++)
		{
		    Base[rows][CP][x] = fparam(string, ',', x);
		}
		
		for(new spawn, array, id[12]; spawn != Max_Spawns; spawn++, array += 3)
		{
			format(id, sizeof id, "a%i", spawn);
			cache_get_field_content(rows, id, string, mysqlHandle);
			
			for(new x; x != 3; x++)
			{
			    Base[rows][AttSpawn][array + x] = fparam(string, ',', x);
			}
			
			format(id, sizeof id, "d%i", spawn);
			cache_get_field_content(rows, id, string, mysqlHandle);
			
			for(new x; x != 3; x++)
			{
			    Base[rows][DefSpawn][array + x] = fparam(string, ',', x);
			}
		}
	}
	
	printf("Загрузка баз завершена (%i msec)", (GetTickCount() - fields));
	
	return 1;
}



public OnCTFLoad();
public OnCTFLoad()
{
	new string[64];
	new rows;
	new fields;
	    
	cache_get_data(rows, fields, mysqlHandle);
	
	printf("CTF: %i строк, %i полей (Всего %i яйчеек данных)", rows, fields, (rows * fields));
	fields = GetTickCount();
	
	while(rows--)
	{
	    CTF[rows][Exists] = true;
	    CTF[rows][Interior] = cache_get_field_content_int(rows, "interior", mysqlHandle);
	    
		cache_get_field_content(rows, "cp", string, mysqlHandle);
		
		for(new x; x != 3; x++)
		{
		    CTF[rows][CP][x] = fparam(string, ',', x);
		}
		
	    cache_get_field_content(rows, "acp", string, mysqlHandle);
	    
	    for(new x; x != 3; x++)
	    {
	        CTF[rows][ACP][x] = fparam(string, ',', x);
		}

	    cache_get_field_content(rows, "dcp", string, mysqlHandle);
	    
	    for(new x; x != 3; x++)
	    {
	        CTF[rows][DCP][x] = fparam(string, ',', x);
		}
	    
	    for(new spawn, array, id[12]; spawn != Max_Spawns; spawn++, array += 3)
	    {
			format(id, sizeof id, "a%i", spawn);
			cache_get_field_content(rows, id, string, mysqlHandle);
			
			for(new x; x != 3; x++)
			{
			    CTF[rows][AttSpawn][array + x] = fparam(string, ',', x);
			}
			
			format(id, sizeof id, "d%i", spawn);
			cache_get_field_content(rows, id, string, mysqlHandle);

			for(new x; x != 3; x++)
			{
			    CTF[rows][DefSpawn][array + x] = fparam(string, ',', x);
			}
		}
		
		cache_get_field_content(rows, "quad", string, mysqlHandle);
		
		for(new x; x != 4; x++)
		{
		    CTF[rows][Quad][x] = fparam(string, ',', x);
		}
  		
	    if((CTF[rows][Quad][0] != 3000.0) && (CTF[rows][Quad][1] != -3000.0))
	    {
     		CTF[rows][GangZone][0] = GangZoneCreate(CTF[rows][Quad][0], CTF[rows][Quad][3], 3000.0, 3000.0);
   			CTF[rows][GangZone][1] = GangZoneCreate(CTF[rows][Quad][2], -3000.0, 3000.0, CTF[rows][Quad][3]);
     		CTF[rows][GangZone][2] = GangZoneCreate(-3000.0, CTF[rows][Quad][1], CTF[rows][Quad][0], 3000.0);
      		CTF[rows][GangZone][3] = GangZoneCreate(-3000.0, -3000.0, CTF[rows][Quad][2], CTF[rows][Quad][1]);
		}
	}
	
	printf("Загрузка CTF завершена (%i msec)", (GetTickCount() - fields));
	
	return 1;
}



public OnDMLoad();
public OnDMLoad()
{
	new string[64];
	new rows;
	new fields;
	    
	cache_get_data(rows, fields, mysqlHandle);
	
	printf("DM: %i строк, %i полей (Всего %i яйчеек данных)", rows, fields, (rows * fields));
	fields = GetTickCount();
	
	while(rows--)
	{
	    DM[rows][Exists] = true;
	    DM[rows][Interior] = cache_get_field_content_int(rows, "interior", mysqlHandle);
	    DM[rows][W][0] = cache_get_field_content_int(rows, "weapon1", mysqlHandle);
	    DM[rows][W][1] = cache_get_field_content_int(rows, "weapon2", mysqlHandle);
	    
		for(new spawn, array, id[12]; spawn != 5; spawn++, array += 3)
		{
  			format(id, sizeof id, "s%i", spawn);
	    	cache_get_field_content(rows, id, string, mysqlHandle);
	    	
	    	for(new x; x != 3; x++)
	    	{
	    	    DM[rows][Spawns][array + x] = fparam(string, ',', x);
			}
		}
		
		cache_get_field_content(rows, "quad", string, mysqlHandle);

		for(new x; x != 4; x++)
		{
		    DM[rows][Quad][x] = fparam(string, ',', x);
		}
		
		if((DM[rows][Quad][0] != 3000.0) && (DM[rows][Quad][1] != -3000.0))
		{
			DM[rows][GangZone][0] = GangZoneCreate(DM[rows][Quad][0], DM[rows][Quad][3], 3000.0, 3000.0);
			DM[rows][GangZone][1] = GangZoneCreate(DM[rows][Quad][2], -3000.0, 3000.0, DM[rows][Quad][3]);
	 		DM[rows][GangZone][2] = GangZoneCreate(-3000.0, DM[rows][Quad][1], DM[rows][Quad][0], 3000.0);
	  		DM[rows][GangZone][3] = GangZoneCreate(-3000.0, -3000.0, DM[rows][Quad][2], DM[rows][Quad][1]);
		}
	}
	
	printf("Загрузка DM завершена (%i msec)", (GetTickCount() - fields));
	
	return 1;
}



public ExitGameMode();
public ExitGameMode()
{
	foreach_p(i)
	{
		Kick(i);
	}
	
    mysql_close(mysqlHandle);
    
    regex_delete_all();
    
    socket_stop_listen(Socket:querySocketHandle);
    socket_stop_listen(Socket:addonSocketHandle);
    socket_destroy(Socket:querySocketHandle);
    socket_destroy(Socket:addonSocketHandle);
    
	DestroyGangZones();
	DestroyTextDraws();
	
	return SendRconCommand("exit");
}



public ServerProcessor();
public ServerProcessor()
{
	new loop[2];
	new team[2][12];
	new string[256];
	
	gettime(loop[0], loop[0], loop[1]);
	
	GetGVarString("Team_Name", team[0], 12, Team_Attack);
	GetGVarString("Team_Name", team[1], 12, Team_Defend);
	
	SendRconCommandF("worldtime %s (%i) : (%i) %s", team[0], GetGVarInt("Score", Team_Attack), GetGVarInt("Score", Team_Defend), team[1]);
	
	if(!GetGVarInt("Locked"))
	{
		/*if(!(loop_time[1] & 1))
		{
		    switch(GetGVarInt("HostName"))
		    {
		        case 0:
		        {
		            SetGVarInt("HostName",1);
		            SendRconCommand("hostname Go Rush | Тренировочный™");
				}
				case 1:
				{
				    SetGVarInt("HostName",2);
		            SendRconCommand("hostname Go Rush | Training™");
				}
				case 2:
		        {
		            SetGVarInt("HostName",3);
		            SendRconCommand("hostname Go Rush | Классический Тренинг™");
				}
				case 3:
				{
				    SetGVarInt("HostName",0);
		            SendRconCommand("hostname Go Rush | Classic Training™");
				}
			}
		}*/
	}
	else
	{
	    if(GetOnlinePlayers() < 1)
	    {
	        SetGVarInt("Locked", 0);
	        TextDrawHideForAll(Server[SLocked]);
		}

	    /*if(!(loop_time[1] & 1))
	    {
	        switch(GetGVarInt("HostName"))
	        {
	            case 0:
	            {
	                SetGVarInt("HostName",1);
	                SendRconCommand("hostname (ЗАКРЫТ) Go Rush | Тренировочный™");
				}
				case 1:
				{
				    SetGVarInt("HostName",2);
				    SendRconCommand("hostname (LOCKED) Go Rush | Training™");
				}
				case 2:
	            {
	                SetGVarInt("HostName",3);
	                SendRconCommand("hostname (ЗАКРЫТ) Go Rush | Классический Тренинг™");
				}
				case 3:
				{
				    SetGVarInt("HostName",0);
				    SendRconCommand("hostname (LOCKED) Go Rush | Classic Training™");
				}
			}
		}*/
	}

	if(((loop[0] == 30) && !loop[1]) || (!loop[0] && !loop[1]))
	{
		Convert(((GetTickCount() - GetGVarInt("UpTime")) / 1000), string);
		printf("[Инфо]: Аптайм сервера: %s", string);
	}

	if(!GetOnlinePlayers())
	{
		return 1;
	}
	
	if((GetOnlinePlayers() < 2) && GetGVarInt("Paused"))
	{
		SetGVarInt("Paused", 0);
	}

	if(!(loop[1] % 10))
	{
	    foreach_p(playerid)
	    {
	        if((GetPlayerPing(playerid) > GetGVarInt("MaxPing")) && GetPVarInt(playerid, "Spawned") && !GetPVarInt(playerid, "AFK_In"))
	        {
	            GivePVarInt(playerid, "Ping_Exceeds", 1);
	            
				if(GetPVarInt(playerid, "Ping_Exceeds") >= GetGVarInt("MaxPingExceeds"))
				{
				    SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был автоматически кикнут {FFFF00}(Причина: Высокий пинг (%i))", Player[playerid][Name], GetPlayerPing(playerid));
                    SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}вышел из игры {FF0000}(Кикнут)", Player[playerid][Name]);
					Kick(playerid);
					
				    continue;
				}
				
				SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Пинг игрока {FF0000}%s {FFFFFF}(%i) {AFAFAF}превышает допустимый {FFFFFF}(%i) {FFFF00}(Предупреждение %i/%i)", Player[playerid][Name], GetPlayerPing(playerid), GetGVarInt("MaxPing"), GetPVarInt(playerid, "Ping_Exceeds"), GetGVarInt("MaxPingExceeds"));
			}

			if(!GetPVarInt(playerid, "Playing") && (GetPVarInt(playerid, "DM_Zone") == -1) && (GetPVarInt(playerid, "DuelID") == -1) && (GetPlayerState(playerid) != 7))
			{
				format(string, sizeof string, "Статистика игрока\nУбийств: %i | Смертей: %i\nСоотношение: %.2f", GetPVarInt(playerid, "Kills"), GetPVarInt(playerid, "Deaths"), GetRatio(GetPVarInt(playerid, "Kills"), GetPVarInt(playerid, "Deaths")));
				Update3DTextLabelText(Player[playerid][AtHead], 0x00FF40FF, string);
			}
			
			if(GetPVarInt(playerid, "Muted"))
			{
			    GivePVarInt(playerid, "Mute_Time", -10);
			    
			    if(GetPVarInt(playerid, "Mute_Time") <= 0)
			    {
			        SetPVarInt(playerid, "Mute_Time", 0);
			        SetPVarInt(playerid, "Muted", 0);
			        
			        SendClientMessage(playerid, -1, "[Инфо]: {AFAFAF}Срок наказания истек, теперь вы можете писать в чат");
				}
			}
		}
	}

	if((Server[Current] == -1) || GetGVarInt("Starting"))
	{
	    TextDrawSetString(Server[ArenaAndTime], "~r~~h~None~n~~r~~h~Time: ~y~None");
	    TextDrawShowForAll(Server[ArenaAndTime]);
	    
	    TextDrawSetStringF(Server[Main], "~y~~h~] ~r~~h~%s ~w~~h~(%i/%i): ~y~~h~] ~r~~h~HP: %.1f ~y~~h~] ~r~~h~Score: %i                              ~b~~h~%s ~w~~h~(%i/%i): ~y~~h~] ~b~~h~HP: %.1f ~y~~h~] ~b~~h~Score: %i ~y~~h~]", team[0], AttsActive(), AttsOnline(), AttHp(), GetGVarInt("Score", Team_Attack), team[1], DefsActive(), DefsOnline(), DefHp(), GetGVarInt("Score", Team_Defend));
	    TextDrawShowForAll(Server[Main]);
	}
	
	foreach_p(playerid)
	{
		if(!GetPVarInt(playerid, "Spawned"))
		{
			continue;
		}
		
		new vehCount;
		
		for(new x = MAX_VEHICLES; x != -1; --x)
		{
		    if(IsPlayerInVehicle(playerid, x))
		    {
		        vehCount++;
			}
		}
		
		if(vehCount > 1)
		{
		    SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был автоматически забанен {FFFF00}(Причина: Баг двух водителей)", Player[playerid][Name]);
			mysql_ban(playerid, INVALID_PLAYER_ID, -1, "Баг двух водителей", "AntiCheat");
			
			continue;
		}
		
		if(ReturnPlayerArmour(playerid) > 0.0)
		{
		    SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был автоматически забанен {FFFF00}(Причина: Броня)", Player[playerid][Name]);
			mysql_ban(playerid, INVALID_PLAYER_ID, -1, "Броня", "AntiCheat");
			
			continue;
		}

		new weapon = GetPlayerWeapon(playerid);
		new Float:speed = GetPlayerSpeedXY(playerid);
		
		if(GetPlayerMoney(playerid) > 0)
		{
		    SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был автоматически забанен {FFFF00}(Причина: Деньги)", Player[playerid][Name]);
			mysql_ban(playerid, INVALID_PLAYER_ID, -1, "Деньги", "AntiCheat");
			
			continue;
		}
		
		if(GetPlayerSpecialAction(playerid) == 2)
		{
		    SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был автоматически забанен {FFFF00}(Причина: JetPack)", Player[playerid][Name]);
			mysql_ban(playerid, INVALID_PLAYER_ID, -1, "JetPack", "AntiCheat");
			
			continue;
		}

		if(GetGVarInt("AntiCheat_FastWalk"))
		{
		    if(!IsPlayerInAnyVehicle(playerid) && (GetPVarInt(playerid, "DM_Zone") == -1) && (GetPlayerSurfingVehicleID(playerid) == INVALID_VEHICLE_ID) && (speed > 50.0))
		    {
      			SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был автоматически забанен {FFFF00}(Причина: Cleo Fastwalk)", Player[playerid][Name]);
				mysql_ban(playerid, INVALID_PLAYER_ID, -1, "Cleo Fastwalk", "AntiCheat");
				
				continue;
			}
		}
		
		/*switch(WeaponID)
		{
			case 7..15, 18, 22, 26, 27, 28, 32, 35..45:
			{
			    if(GetGVarInt("AntiCheat_Weapon"))
				{
				    SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был автоматически забанен {FFFF00}(Причина: Чит на оружие)",Player[playerid][Name]);
					mysql_ban(playerid, INVALID_PLAYER_ID, -1, "Чит на оружие", "AntiCheat");
					
					continue;
				}
			}
		}*/
		
		if(!GetPVarInt(playerid, "Playing"))
		{
			continue;
		}

		/*if(GetPlayerState(playerid) == 1 && WeaponID && (WeaponID != GetPVarInt(playerid,"Weapon_1") && WeaponID != GetPVarInt(playerid,"Weapon_2") && WeaponID != GetPVarInt(playerid,"Weapon_3")))
		{
		    if(GetGVarInt("AntiCheat_Weapon"))
			{
   				SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был автоматически забанен {FFFF00}(Причина: Чит на оружие)",Player[playerid][Name]);
				mysql_ban(playerid, INVALID_PLAYER_ID, -1, "Чит на оружие", "AntiCheat");
				
				continue;
			}
		}*/

		if(GetGVarInt("AntiBug_K"))
	    {
		    if((GetPlayerAnimationIndex(playerid) == 747) && (speed > 30.0) && /*IsAngularVelocity(playerid) &&*/ (weapon == 4))
		    {
		        SetPVarInt(playerid, "KnifeTick", GetTickCount());
		        
				SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был автоматически удален из раунда {FFFF00}(Причина: Баг ножа)", Player[playerid][Name]);

				ClearAnimations(playerid, true);
				RemoveFromRound(playerid);
				
				continue;
		    }
	    }

	    if(GetGVarInt("AntiBug_S"))
		{
			if((1160 < GetPlayerAnimationIndex(playerid) < 1163) && (speed > 25.0) && /*IsAngularVelocity(playerid) &&*/ ((22 < weapon < 26) || (28 < weapon < 35)))
			{
   				GivePVarInt(playerid, "Slide_Ticks", 1);
   				
			    SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игроку {FF0000}%s {AFAFAF}было выдано предупреждение за баг скольжение {FFFF00}(%i/5)", Player[playerid][Name], GetPVarInt(playerid, "Slide_Ticks"));
                ClearAnimations(playerid, true);
                
				if(GetPVarInt(playerid, "Slide_Ticks") >= 5)
			    {
       				SetPVarInt(playerid, "Slide_Ticks", 0);
       				
			        SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был автоматически удален из раунда {FFFF00}(Причина: Использование бага скольжение, игнорирование предупреждений)", Player[playerid][Name]);

					ClearAnimations(playerid, true);
					RemoveFromRound(playerid);
			        
			        continue;
				}
			}
		}
	}

	if(GetGVarInt("AFK_System"))
 	{
		foreach_p(playerid)
		{
			if(GetPVarInt(playerid, "AFK_Check_1") > 100000)
			{
			    SetPVarInt(playerid, "AFK_Check_1", 1);
			    SetPVarInt(playerid, "AFK_Check_2", 0);
			}

			if((GetPVarInt(playerid, "AFK_Check_1") == GetPVarInt(playerid, "AFK_Check_2")) && GetPVarInt(playerid, "Spawned") && !GetGVarInt("Paused"))
			{
			    GivePVarInt(playerid, "AFK_Check_3", 1);
			    
			    if(GetPVarInt(playerid, "AFK_Check_3") > 3)
			    {
			        SetPVarInt(playerid, "AFK_In", 1);
			        
			        if(strfind(Player[playerid][Name], "AFK_", false) == -1)
			        {
				        strins(Player[playerid][Name], "AFK_", 0, MAX_PLAYER_NAME);
				        SetPlayerName(playerid, Player[playerid][Name]);
					}
					
			        if(GetGVarInt("AFK_Show"))
			        {
			            Convert(GetPVarInt(playerid,"AFK_Check_3"), string);
			            strins(string, "AFK: ", 0);
			            
			            SetPlayerChatBubble(playerid, string, GetPlayerColor(playerid), 50.0, 1200);
					}
					
					if(GetGVarInt("AFK_Kick"))
					{
					    if(GetPVarInt(playerid,"AFK_Check_3") >= GetGVarInt("AFK_KickTime"))
					    {
					        SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был автоматически кикнут {FFFF00}(Причина: Долгий AFK)", Player[playerid][Name]);
					        SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}вышел из игры {FF0000}(Кикнут)", Player[playerid][Name]);

							Kick(playerid);
					        
					        continue;
						}
					}
					
					if(GetGVarInt("AFK_Remove") && (Server[Current] != -1))
					{
					    if((GetPVarInt(playerid,"AFK_Check_3") >= GetGVarInt("AFK_RemoveTime")) && GetPVarInt(playerid,"Playing"))
					    {
					        SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был автоматически удален из раунда {FFFF00}(Причина: Долгий AFK)", Player[playerid][Name]);

							RemoveFromRound(playerid);
							
							continue;
						}
					}
				}
			}

			if(GetPVarInt(playerid,"AFK_Check_1") > GetPVarInt(playerid,"AFK_Check_2"))
			{
			    SetPVarInt(playerid, "AFK_Check_2", GetPVarInt(playerid, "AFK_Check_1"));
			    SetPVarInt(playerid, "AFK_Check_3", 0);
			    SetPVarInt(playerid, "AFK_In", 0);
			    
			    if(!strfind(Player[playerid][Name], "AFK_", false))
			    {
			        strdel(Player[playerid][Name], 0, 4);
			        SetPlayerName(playerid, Player[playerid][Name]);
				}
			}

			if(!GetPVarInt(playerid,"AFK_In") && GetPVarInt(playerid,"Spawned") && !GetGVarInt("Paused"))
			{
			    GivePVarInt(playerid, "AtServer_S", 1);
			    
			    if(GetPVarInt(playerid, "AtServer_S") >= 60)
			    {
			        SetPVarInt(playerid, "AtServer_S", 0);
			        GivePVarInt(playerid, "AtServer_M", 1);
			        
			        if(GetPVarInt(playerid, "AtServer_M") >= 60)
			        {
			            SetPVarInt(playerid, "AtServer_M", 0);
			        	GivePVarInt(playerid, "AtServer_H", 1);
			        	
			            if(GetPVarInt(playerid, "AtServer_H") >= 24)
			            {
			                SetPVarInt(playerid, "AtServer_H", 0);
			        		GivePVarInt(playerid, "AtServer_D", 1);
						}
					}
				}
			}

			if((GetPVarInt(playerid,"SpecID") != -1) && (GetPlayerState(playerid) == 9) && !GetPVarInt(playerid,"AFK_In"))
			{
			    new i = GetPVarInt(playerid, "SpecID");
       			new slot[3];
				new name[24];

			    for(new x; x != 13; x++)
				{
					GetPlayerWeaponData(i, x, PlayerWeapons[i][0][x], PlayerWeapons[i][1][x]);
				}
				
				slot[0] = GetWeaponSlot(GetPVarInt(i, "Weapon_1")),
				slot[1] = GetWeaponSlot(GetPVarInt(i, "Weapon_2")),
				slot[2] = GetWeaponSlot(GetPVarInt(i, "Weapon_3"));
				
				strcpy(name, Player[i][Name]);
				ReplaceStyleChars(name);
				
			    switch(GetPVarInt(i, "Weapon_3"))
				{
					case 0:
					{
						format(string, sizeof string, "~r~~h~%s (ID: %i)~n~~y~~h~%s (%i)~n~~y~~h~%s (%i)~n~~r~~h~Ping: %i ~y~~h~] ~b~~h~FPS: %i", name, i, WeaponNames[PlayerWeapons[i][0][slot[0]]], PlayerWeapons[i][1][slot[0]], WeaponNames[PlayerWeapons[i][0][slot[1]]], PlayerWeapons[i][1][slot[1]], GetPlayerPing(i), GetPVarInt(i, "FPS"));
					}
					
					case 16, 17:
					{
						format(string, sizeof string, "~r~~h~%s (ID: %i)~n~~y~~h~%s (%i)~n~~y~~h~%s (%i)~n~~y~~h~%s (%i)~n~~r~~h~Ping: %i ~y~~h~] ~b~~h~FPS: %i", name, i, WeaponNames[PlayerWeapons[i][0][slot[0]]], PlayerWeapons[i][1][slot[0]], WeaponNames[PlayerWeapons[i][0][slot[1]]], PlayerWeapons[i][1][slot[1]], WeaponNames[PlayerWeapons[i][0][slot[2]]], PlayerWeapons[i][1][slot[2]], GetPlayerPing(i), GetPVarInt(i, "FPS"));
					}
					
					default:
					{
						format(string, sizeof string, "~r~~h~%s (ID: %i)~n~~y~~h~%s (%i)~n~~y~~h~%s (%i)~n~~y~~h~%s~n~~r~~h~Ping: %i ~y~~h~] ~b~~h~FPS: %i", name, i, WeaponNames[PlayerWeapons[i][0][slot[0]]], PlayerWeapons[i][1][slot[0]], WeaponNames[PlayerWeapons[i][0][slot[1]]], PlayerWeapons[i][1][slot[1]], WeaponNames[PlayerWeapons[i][0][slot[2]]], GetPlayerPing(i), GetPVarInt(i, "FPS"));
					}
				}

                PlayerTextDrawSetString(playerid, Player[playerid][SpecText], string);
				PlayerTextDrawShow(playerid, Player[playerid][SpecText]);
				
				GetPlayerKeys(playerid, i, i, i);
				
				if(i < 0)
				{
					ReverseSpectate(playerid);
				}
				else if(i > 0)
				{
					AdvanceSpectate(playerid);
				}
			}
		}
	}

	if((Server[Current] != -1) && !GetGVarInt("Starting"))
	{
		new Float:pos[3];
		
	    TextDrawSetStringF(Server[Main], "~y~~h~] ~r~~h~%s ~w~~h~(%i/%i): ~y~~h~] ~r~~h~HP: %.1f ~y~~h~] ~r~~h~Score: %i                              ~b~~h~%s ~w~~h~(%i/%i): ~y~~h~] ~b~~h~HP: %.1f ~y~~h~] ~b~~h~Score: %i ~y~~h~]", team[0], AttsActive(), AttsOnline(), AttHp(), GetGVarInt("Score", Team_Attack), team[1], DefsActive(), DefsOnline(), DefHp(), GetGVarInt("Score", Team_Defend));
	    TextDrawShowForAll(Server[Main]);
				
	    switch(GetGVarInt("GameType"))
	    {
	        case Gametype_Base:
	        {
		        TextDrawSetStringF(Server[ArenaAndTime], "~r~~h~Base: ~y~%i~n~~r~~h~Time: ~y~%02i:%02i", Server[Current], GetGVarInt("ModeMin"), GetGVarInt("ModeSec"));
		        TextDrawShowForAll(Server[ArenaAndTime]);
		        
		        SendRconCommandF("mapname Base: %i [%02i:%02i]", Server[Current], GetGVarInt("ModeMin"), GetGVarInt("ModeSec"));
		        
				foreach_p(playerid)
				{
				    if(!GetPVarInt(playerid, "Playing"))
					{
						continue;
					}
				    
				    if(GetPVarInt(playerid, "Team") == Team_Defend)
				    {
						if(!PlayerToPoint(GetGVarFloat("Base_Distance"), playerid, Base[Server[Current]][CP][0], Base[Server[Current]][CP][1], Base[Server[Current]][CP][2]) && GetPVarInt(playerid, "Playing"))
						{
						    GivePVarInt(playerid, "Disqual_Time", -1);
						    
							GameTextForPlayerF(playerid, "~y~Come Back to ~b~Base~n~~y~In ~r~%i ~y~seconds~n~~y~or you will be~n~~r~Disqalified", 1200, 3, GetPVarInt(playerid, "Disqual_Time"));
							
							PlayerPlaySound(playerid, 1084, 0.0, 0.0, 0.0);
							
							if(GetPVarInt(playerid, "Disqual_Time") <= 0)
							{
							    SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок %s был автоматически дисквалифицирован {FFFF00}(Причина: Сильная отдаленость от базы)", Player[playerid][Name]);
								RemoveFromRound(playerid);
							}
						}
						else
						{
						    if(GetPVarInt(playerid, "Disqual_Time") != GetGVarInt("DissTime"))
							{
								SetPVarInt(playerid, "Disqual_Time", GetGVarInt("DissTime"));
							}
						}
					}

					if(GetGVarInt("Paused"))
					{
						GameTextForPlayer(playerid, "~y~~h~Game~n~~r~~h~Paused", 1200, 3);
					}
				}

				if(!AttsAlive())
				{
    				if(!DefsAlive()) return SetWin(Team_None);
					else return SetWin(Team_Defend);
				}
				else if(!DefsAlive())
				{
    				if(!AttsAlive()) return SetWin(Team_None);
					else return SetWin(Team_Attack);
				}

				GiveGVarInt("ModeSec", -1, 0);
				
			    if(!GetGVarInt("ModeSec") && GetGVarInt("ModeMin"))
			    {
			        SetGVarInt("ModeSec", 59);
			        GiveGVarInt("ModeMin", -1, 0);
				}

				if(!GetGVarInt("ModeSec") && !GetGVarInt("ModeMin"))
				{
					SetWin(Team_Defend);
					
					return 1;
				}
			}
			
			case Gametype_Arena:
			{
			    if(!GetGVarInt("CW"))
			    {
			        TextDrawSetStringF(Server[ArenaAndTime], "~r~~h~Arena: ~y~%i~n~~r~~h~Time: ~y~%02i:%02i", Server[Current], GetGVarInt("ModeMin"), GetGVarInt("ModeSec"));
			        TextDrawShowForAll(Server[ArenaAndTime]);
			        
			        SendRconCommandF("mapname Arena: %i [%02i:%02i]", Server[Current], GetGVarInt("ModeMin"), GetGVarInt("ModeSec"));
				}
				else
				{
				    TextDrawSetStringF(Server[ArenaAndTime], "~r~~h~Arena: ~y~%i~n~~r~~h~Time: ~y~None", Server[Current]);
				    TextDrawShowForAll(Server[ArenaAndTime]);
				    
					SendRconCommandF("mapname Arena: %i", Server[Current]);
				}
				
			    foreach_p(playerid)
			    {
			        if(GetPlayerPos(playerid, pos[0], pos[1], pos[2]) && !GetPlayerInterior(playerid) && ((Arena[Server[Current]][Quad][2] < pos[0]) || (Arena[Server[Current]][Quad][0] > pos[0]) || (Arena[Server[Current]][Quad][3] < pos[1]) || (Arena[Server[Current]][Quad][1] > pos[1])) && GetPVarInt(playerid, "Playing"))
			        {
			            GivePVarInt(playerid, "Disqual_Time", -1);
			            
						GameTextForPlayerF(playerid, "~y~Come Back to ~r~Arena~n~~y~In ~r~%i ~y~seconds~n~~y~or you will be~n~~r~Disqalified", 1200, 3, GetPVarInt(playerid, "Disqual_Time"));
						
						PlayerPlaySound(playerid, 1084, 0.0, 0.0, 0.0);
						
						if(GetPVarInt(playerid, "Disqual_Time") <= 0)
						{
						    SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был автоматически дисквалифицирован {FFFF00}(Причина: Уход за границы раунда)", Player[playerid][Name]);
							RemoveFromRound(playerid);
						}
					}
					else
					{
					    if(GetPVarInt(playerid, "Disqual_Time") != GetGVarInt("DissTime"))
						{
							SetPVarInt(playerid, "Disqual_Time", GetGVarInt("DissTime"));
						}
					}
				}

				if(!AttsAlive())
				{
    				if(!DefsAlive()) return SetWin(Team_None);
					else return SetWin(Team_Defend);
				}
				else if(!DefsAlive())
				{
    				if(!AttsAlive()) return SetWin(Team_None);
					else return SetWin(Team_Attack);
				}

				if(!GetGVarInt("CW"))
				{
					GiveGVarInt("ModeSec", -1, 0);
					
				    if(!GetGVarInt("ModeSec") && GetGVarInt("ModeMin"))
				    {
				        SetGVarInt("ModeSec", 59);
				        GiveGVarInt("ModeMin", -1, 0);
					}

					if(!GetGVarInt("ModeSec") && !GetGVarInt("ModeMin"))
					{
					    if(AttHp() == DefHp()) return SetWin(Team_None);
					    else if(AttHp() > DefHp()) return SetWin(Team_Attack);
					    else return SetWin(Team_Defend);
					}
				}
			}
			
			case Gametype_CTF:
			{
				TextDrawSetStringF(Server[ArenaAndTime], "~r~~h~CTF: ~y~%i~n~~r~~h~Time: ~y~%02i:%02i", Server[Current], GetGVarInt("ModeMin"), GetGVarInt("ModeSec"));
				TextDrawShowForAll(Server[ArenaAndTime]);
				
				SendRconCommandF("mapname CTF: %i [%02i:%02i]", Server[Current], GetGVarInt("ModeMin"), GetGVarInt("ModeSec"));
				
			    foreach_p(playerid)
			    {
			        if(GetPlayerPos(playerid, pos[0], pos[1], pos[2]) && !GetPlayerInterior(playerid) && ((CTF[Server[Current]][Quad][2] < pos[0]) || (CTF[Server[Current]][Quad][0] > pos[0]) || (CTF[Server[Current]][Quad][3] < pos[1]) || (CTF[Server[Current]][Quad][1] > pos[1])) && GetPVarInt(playerid, "Playing"))
			        {
			            GivePVarInt(playerid, "Disqual_Time", -1);

						GameTextForPlayerF(playerid, "~y~Come Back to ~r~zone~n~~y~In ~r~%i ~y~seconds~n~~y~or you will be~n~~r~Disqalified", 1200, 3, GetPVarInt(playerid, "Disqual_Time"));
						
						PlayerPlaySound(playerid, 1084, 0.0, 0.0, 0.0);
						
						if(GetPVarInt(playerid, "Disqual_Time") <= 0)
						{
						    SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был автоматически дисквалифицирован {FFFF00}(Причина: Уход за границы раунда)", Player[playerid][Name]);
							RemoveFromRound(playerid);
						}
					}
					else
					{
					    if(GetPVarInt(playerid, "Disqual_Time") != GetGVarInt("DissTime"))
						{
							SetPVarInt(playerid, "Disqual_Time", GetGVarInt("DissTime"));
						}
					}
					
					switch(GetPVarInt(playerid,"Team"))
					{
					    case Team_Attack:
						{
							if(PlayerToPoint(10.0, playerid, CTF[Server[Current]][ACP][0], CTF[Server[Current]][ACP][1], CTF[Server[Current]][ACP][2]) && (playerid == CTF[Server[Current]][FlagOwner][1])) return SetWin(Team_Attack);
						}
						case Team_Defend:
						{
							if(PlayerToPoint(10.0, playerid, CTF[Server[Current]][DCP][0],CTF[Server[Current]][DCP][1],CTF[Server[Current]][DCP][2]) && (playerid == CTF[Server[Current]][FlagOwner][0])) return SetWin(Team_Defend);
						}
					}
				}

				if(AttsAlive() <= 0)
				{
    				if(DefsAlive() <= 0) return SetWin(Team_None);
					else return SetWin(Team_Defend);
				}
				else if(DefsAlive() <= 0)
				{
    				if(AttsAlive() <= 0) return SetWin(Team_None);
					else return SetWin(Team_Attack);
				}

				GiveGVarInt("ModeSec", -1, 0);
    			if(!GetGVarInt("ModeSec") && GetGVarInt("ModeMin"))
			    {
			    	SetGVarInt("ModeSec", 59);
        			GiveGVarInt("ModeMin", -1, 0);
				}

				if(!GetGVarInt("ModeSec") && !GetGVarInt("ModeMin"))
				{
    				if(AttHp() == DefHp()) return SetWin(Team_None);
				    else if(AttHp() > DefHp()) return SetWin(Team_Attack);
				    else return SetWin(Team_Defend);
				}
			}
		}
	}
	
	return 1;
}



public OnPlayerRegister(playerid, password[]);
public OnPlayerRegister(playerid, password[])
{
	new query[512];
	
	SHA512(password, query, sizeof query);
	SetPVarString(playerid, "password", query);

	mysql_format(mysqlHandle, query, sizeof query, "INSERT INTO `players` VALUES (SHA2('%s', 512), '%s', 0, 0, 0, 0, 0, 0, 0, 0, '0,0,0,0', 0, 0, 0, 0, 0, 0)", Player[playerid][Name], password);
	mysql_function_query(mysqlHandle, query, false, "OnPlayerLogin", "di", playerid, true);
	
 	return 1;
}



public OnPlayerSaved(playerid);
public OnPlayerSaved(playerid)
{
	new password[129];
	new query[512];
		
	GetPVarString(playerid, "password", password, sizeof password);
	
	mysql_format(mysqlHandle, query, sizeof query, "UPDATE `players` SET `password` = '%s', `banned` = %i, `admin` = %i, `roundruns` = %i WHERE `Name` = SHA2('%s', 512)", password, GetPVarInt(playerid, "Banned"), GetPVarInt(playerid, "Admin"), GetPVarInt(playerid, "RunsFromRound"), Player[playerid][Name]);
	mysql_function_query(mysqlHandle, query, false, "", "");

	format(password, sizeof password, "%i,%i,%i,%i", GetPVarInt(playerid, "AtServer_D"), GetPVarInt(playerid, "AtServer_H"), GetPVarInt(playerid, "AtServer_M"), GetPVarInt(playerid, "AtServer_S"));
	mysql_format(mysqlHandle, query, sizeof query, "UPDATE `players` SET `kills` = %i, `deaths` = %i, `knifekills` = %i, `knifedeaths` = %i, `dmkills` = %i, `dmdeaths` = %i, `at_server` = '%s' WHERE `Name` = SHA2('%s', 512)", GetPVarInt(playerid, "Kills"), GetPVarInt(playerid, "Deaths"), GetPVarInt(playerid, "KnifeKills"), GetPVarInt(playerid, "KnifeDeaths"), GetPVarInt(playerid, "DM_Kills"), GetPVarInt(playerid, "DM_Deaths"), password, Player[playerid][Name]);
	mysql_function_query(mysqlHandle, query, false, "", "");

	mysql_format(mysqlHandle, query, sizeof query, "UPDATE `players` SET `a_played` = %i, `b_played` = %i, `c_played` = %i, `teamwins` = %i, `teamloses` = %i WHERE `Name` = SHA2('%s', 512)", GetPVarInt(playerid, "A_Played"), GetPVarInt(playerid, "B_Played"), GetPVarInt(playerid, "C_Played"), GetPVarInt(playerid, "Team_Wins"), GetPVarInt(playerid, "Team_Loses"), Player[playerid][Name]);
	mysql_function_query(mysqlHandle, query, false, "", "");
	
	return 1;
}



public OnPlayerLogin(playerid, bool:passed);
public OnPlayerLogin(playerid, bool:passed)
{
	new query[140];
 	new rows;
	new fields;
  	
	cache_get_data(rows, fields, mysqlHandle);
	
	if(!rows)
	{
		ShowPlayerRegisterDialog(playerid);
		
		return 1;
	}
	
	if(!GetPVarInt(playerid, "Logged"))
	{
	    mysql_format(mysqlHandle, query, sizeof query, "SELECT `password` FROM `players` WHERE `name` = SHA2('%s', 512) LIMIT 1", Player[playerid][Name]);
	    mysql_function_query(mysqlHandle, query, true, "OnPlayerPasswordReceived", "i", playerid);
	    
	    return 1;
	}
	
	SetPVarInt(playerid, "Banned", cache_get_field_content_int(0, "banned", mysqlHandle));
	
	if(GetPVarInt(playerid, "Banned"))
	{
	    SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был автоматически кикнут {FFFF00}(Причина: Забаненый аккаунт)", Player[playerid][Name]);
        SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}вышел из игры {FF0000}(Кикнут)", Player[playerid][Name]);
		Kick(playerid);
		
		return 0;
	}
	
	SetPVarInt(playerid, "Admin", cache_get_field_content_int(0, "admin", mysqlHandle));
	
	SetPVarInt(playerid, "Kills", cache_get_field_content_int(0, "kills", mysqlHandle));
	SetPlayerScore(playerid, GetPVarInt(playerid, "Kills"));
	SetPVarInt(playerid, "Deaths", cache_get_field_content_int(0, "deaths", mysqlHandle));
	SetPVarInt(playerid, "KnifeKills", cache_get_field_content_int(0, "knifekills", mysqlHandle));
	SetPVarInt(playerid, "KnifeDeaths", cache_get_field_content_int(0, "knifedeaths", mysqlHandle));
	SetPVarInt(playerid, "DM_Kills", cache_get_field_content_int(0, "dmkills", mysqlHandle));
	SetPVarInt(playerid, "DM_Deaths", cache_get_field_content_int(0, "dmdeaths", mysqlHandle));
	
	cache_get_field_content(0, "at_server", query);

	SetPVarInt(playerid,"AtServer_D", iparam(query, ',', 0));
	SetPVarInt(playerid,"AtServer_H", iparam(query, ',', 1));
	SetPVarInt(playerid,"AtServer_M", iparam(query, ',', 2));
	SetPVarInt(playerid,"AtServer_S", iparam(query, ',', 3));
	
	SetPVarInt(playerid, "A_Played", cache_get_field_content_int(0, "a_played", mysqlHandle));
	SetPVarInt(playerid, "B_Played", cache_get_field_content_int(0, "b_played", mysqlHandle));
	SetPVarInt(playerid, "C_Played", cache_get_field_content_int(0, "c_played", mysqlHandle));

	SetPVarInt(playerid, "RunsFromRound", cache_get_field_content_int(0, "roundruns", mysqlHandle));
	SetPVarInt(playerid, "Team_Wins", cache_get_field_content_int(0, "teamwins", mysqlHandle));
	SetPVarInt(playerid, "Team_Loses", cache_get_field_content_int(0, "teamloses", mysqlHandle));

	TogglePlayerSpectating(playerid, false);
	
	switch(GetPVarInt(playerid,"Admin"))
	{
		case 1: return SendClientMessage(playerid,-1,"[Инфо]: {AFAFAF}Вы успешно вошли {FF0000}(VIP)");
		case 2: return SendClientMessage(playerid,-1,"[Инфо]: {AFAFAF}Вы успешно вошли {FF0000}(Модератор)");
		case 3: return SendClientMessage(playerid,-1,"[Инфо]: {AFAFAF}Вы успешно вошли {FF0000}(Гл. Модератор)");
		case 4: return SendClientMessage(playerid,-1,"[Инфо]: {AFAFAF}Вы успешно вошли {FF0000}(Администратор)");
		case 5: return SendClientMessage(playerid,-1,"[Инфо]: {AFAFAF}Вы успешно вошли {FF0000}(Гл. Администратор)");
	}
	
	SendClientMessage(playerid,-1,"[Инфо]: {AFAFAF}Вы успешно вошли");
	
	return 1;
}



public OnPlayerPasswordReceived(playerid);
public OnPlayerPasswordReceived(playerid)
{
	new password[129];
	
	cache_get_field_content(0, "password", password);
	SetPVarString(playerid, "password", password);
	
	CallLocalFunction("LoginKick", "ii", playerid, GetGVarInt("MaxLoginTime"));
	
	ShowPlayerLoginDialog(playerid);
	
	return 1;
}



public OnPlayerLoginFailed(playerid);
public OnPlayerLoginFailed(playerid)
{
    GivePVarInt(playerid, "Login_Attempts", 1);
    SendClientMessageF(playerid, -1, "[Инфо]: {AFAFAF}Неверный пароль! {FF0000}(%i/3)", GetPVarInt(playerid, "Login_Attempts"));

	if(GetPVarInt(playerid, "Login_Attempts") >= 3)
    {
		SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был автоматически кикнут {FFFF00}(Причина: Исчерпаны попытки ввода пароля)", Player[playerid][Name]);
  		SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}вышел из игры {FF0000}(Кикнут)", Player[playerid][Name]);
    	Kick(playerid);
    	
    	return 1;
	}
	
	ShowPlayerLoginDialog(playerid);
	
	return 1;
}



public HideDamage(playerid);
public HideDamage(playerid)
{
	for(new i; i != 2; i++)
	{
		PlayerTextDrawHide(playerid,Player[playerid][Damage][i]);
	}
	
	SetPVarInt(playerid, "ShootCombo", 0);
	SetPVarInt(playerid, "DamageTimer", -1);
}



public DetachTrailer(vehicleid);
public DetachTrailer(vehicleid)
{
	return DetachTrailerFromVehicle(vehicleid);
}



public VoteKickMove(time);
public VoteKickMove(time)
{
	if(!GetGVarInt("VoteKick_Active")) return 1;
	if(GetOnlinePlayers() <= 3) return StopVoteKick();
	
	new
	    int_data = floatround((GetOnlinePlayers() / 1.5),floatround_floor),
	    string_data[64]
	;
	
	GetGVarString("VoteKick_Reason",string_data);
	
	if(time <= 0)
	{
		if(GetGVarInt("VoteKick_Votes") >= int_data)
		{
		    SendClientMessageToAllF(-1,"[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был кикнут голосованием {FFFF00}(Причина: %s)",Player[GetGVarInt("VoteKick_ID")][Name],string_data);
		    SendClientMessageToAllF(-1,"[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}вышел из игры {FF0000}(Кикнут голосованием)",Player[GetGVarInt("VoteKick_ID")][Name]);
		    return Kick(GetGVarInt("VoteKick_ID"));
		}
		return StopVoteKick();
	}
	
	if(GetGVarInt("VoteKick_Votes") >= int_data)
	{
 		SendClientMessageToAllF(-1,"[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был кикнут голосованием {FFFF00}(Причина: %s)",Player[GetGVarInt("VoteKick_ID")][Name],string_data);
 		SendClientMessageToAllF(-1,"[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}вышел из игры {FF0000}(Кикнут голосованием)",Player[GetGVarInt("VoteKick_ID")][Name]);
 		return Kick(GetGVarInt("VoteKick_ID"));
	}
	
	strcpy(string_data,Player[GetGVarInt("VoteKick_ID")][Name]);
	ReplaceStyleChars(string_data);

	TextDrawSetStringF(VoteKickText, "VoteKick~n~%s (ID: %i)~n~Votes: (%i/%i)", string_data, GetGVarInt("VoteKick_ID"), GetGVarInt("VoteKick_Votes"), int_data);
	TextDrawShowForAll(VoteKickText);
	
	return SetTimerEx("VoteKickMove", 1000, false, "i", --time);
}



public VoteBanMove(time);
public VoteBanMove(time)
{
	if(!GetGVarInt("VoteBan_Active"))
	{
		return 1;
	}
	
	if(GetOnlinePlayers() <= 4)
	{
		return StopVoteBan();
	}
	
	new online = (GetOnlinePlayers() - 1);
	new string[128];
	
	GetGVarString("VoteBan_Reason", string);
	
	if(time <= 0)
	{
	    if(GetGVarInt("VoteBan_Votes") >= online)
	    {
	        SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был забанен голосованием {FFFF00}(Причина: %s)", Player[GetGVarInt("VoteBan_ID")][Name], string);
			format(string, sizeof string, "Забанен голосованием. Причина: %s", string);
			mysql_ban(GetGVarInt("VoteBan_ID"), INVALID_PLAYER_ID, -1, string, "VoteBan");
		}
		
		return StopVoteBan();
	}
	
	if(GetGVarInt("VoteBan_Votes") >= online)
 	{
  		SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был забанен голосованием {FFFF00}(Причина: %s)", Player[GetGVarInt("VoteBan_ID")][Name], string);
		format(string, sizeof string, "Забанен голосованием. Причина: %s", string);
		mysql_ban(GetGVarInt("VoteBan_ID"), INVALID_PLAYER_ID, -1, string, "VoteBan");
		
		return StopVoteBan();
	}
	
	strcpy(string, Player[GetGVarInt("VoteBan_ID")][Name]);
	ReplaceStyleChars(string);
	
	TextDrawSetStringF(VoteBanText, "VoteBan~n~%s (ID: %i)~n~Votes: (%i/%i)", string, GetGVarInt("VoteBan_ID"), GetGVarInt("VoteBan_Votes"), online);
	TextDrawShowForAll(VoteBanText);
	
	return SetTimerEx("VoteBanMove", 1000, false, "i", --time);
}



public Balance(Type);
public Balance(Type)
{
	if(GetActivePlayers() < 2)
	{
		return 1;
	}
	
 	new
	 	Count,
	 	Players = ((AttsActive() + DefsActive()) >> 1),
		bool:Swap = false
	;
	
   	foreach_p(i)
   	{
   	    if(GetPVarInt(i,"DM_Zone") != -1 || GetPVarInt(i,"DuelID") != -1 || GetPVarInt(i,"No_Play") || (GetPVarInt(i,"Team") != Team_Attack && GetPVarInt(i,"Team") != Team_Defend)) continue;
		if(Type == BalanceType_2)
		{
		    if(!Swap)
		    {
		        SetPVarInt(i,"Team",Team_Defend);
		        SetPlayerColor(i,GetGVarInt("Team_Color_L",Team_Defend));
		        Swap = true;
            	SetSpawnInfo(i,Team_Defend,GetGVarInt("Skin_Def"),0.0,0.0,0.0,0.0,0,0,0,0,0,0);
             	SpawnPlayer(i);
				continue;
			}
			else
			{
			    SetPVarInt(i,"Team",Team_Attack);
			    SetPlayerColor(i,GetGVarInt("Team_Color_L",Team_Attack));
			    Swap = false;
          		SetSpawnInfo(i,Team_Attack,GetGVarInt("Skin_Att"),0.0,0.0,0.0,0.0,0,0,0,0,0,0);
            	SpawnPlayer(i);
				continue;
			}
		}
		else if(Type == BalanceType_1)
		{
		    if(Count < Players)
		    {
		        SetPVarInt(i,"Team",Team_Defend);
		        SetPlayerColor(i,GetGVarInt("Team_Color_L",Team_Defend));
		        Count++;
            	SetSpawnInfo(i,Team_Defend,GetGVarInt("Skin_Def"),0.0,0.0,0.0,0.0,0,0,0,0,0,0);
             	SpawnPlayer(i);
				continue;
			}
			else
			{
			    SetPVarInt(i,"Team",Team_Attack);
			    SetPlayerColor(i,GetGVarInt("Team_Color_L",Team_Attack));
       			SetSpawnInfo(i,Team_Attack,GetGVarInt("Skin_Att"),0.0,0.0,0.0,0.0,0,0,0,0,0,0);
          		SpawnPlayer(i);
				continue;
			}
		}
		else if(Type == BalanceType_Random) return CallLocalFunction("Balance","d",random(2) + 1);
	}
	
	SendClientMessageToAllF(-1,"[Инфо]: {00FF40}AutoBalance: {AFAFAF}Комманды автоматически сбалансированы {FFFF00}(№%i)",Type);
	
	return 1;
}



public SwapAll();
public SwapAll()
{
	foreach_p(i)
	{
	    if(GetPVarInt(i,"DM_Zone") != -1 || GetPVarInt(i,"DuelID") != -1 || GetPVarInt(i,"No_Play")) continue;
	    switch(GetPVarInt(i,"Team"))
	    {
	        case Team_Attack:
			{
				SetTeam(i,Team_Defend);
			}
	        case Team_Defend:
			{
				SetTeam(i,Team_Attack);
			}
		}
	}
	
	new
	    int_data = GetGVarInt("Score",Team_Attack),
	    string_data[2][12]
	;
	
	GetGVarString("Team_Name",string_data[0],12,Team_Attack);
	GetGVarString("Team_Name",string_data[1],12,Team_Defend);
	
	SetGVarString("Team_Name",string_data[1],Team_Attack);
	SetGVarString("Team_Name",string_data[0],Team_Defend);
	
	SetGVarInt("Score",GetGVarInt("Score",Team_Defend),Team_Attack);
	SetGVarInt("Score",int_data,Team_Defend);
	
	SendClientMessageToAll(-1,"[Инфо]: {00FF40}AutoSwap: {AFAFAF}Комманды автоматически сменены местами");
}



public ClearMinusHealth(playerid);
public ClearMinusHealth(playerid)
{
	SetPVarFloat(playerid,"HP_Combo",0.0);
	SetPVarInt(playerid,"ClearTimer",-1);
	
	PlayerTextDrawHide(playerid,Player[playerid][HealthMinus]);
	TextDrawHideForPlayer(playerid,Server[Barrier][5]);
	TextDrawHideForPlayer(playerid,Server[Barrier][6]);
	
	Update3DTextLabelText(Player[playerid][AtHead],GetPlayerColor(playerid)," ");
}



public Intro(playerid);
public Intro(playerid)
{
	if(!GetPVarInt(playerid,"Connected"))
	{
		return 1;
	}
	
	SetPVarInt(playerid, "Camera_0", 1);
	HideDialog(playerid);
	SetPlayerVirtualWorld(playerid, Intro_VW);
	TextDrawShowForPlayer(playerid, Server[BlackFullScreen]);
	PlayerPlaySound(playerid, 1068, 0.0, 0.0, 0.0);
	SetPlayerCameraPos(playerid, 0.0, 0.0, 0.0 + 50.0);
	
	CallLocalFunction("DrawLetters", "ii", playerid, 0);
	
	return 1;
}



public DrawLetters(playerid, numb);
public DrawLetters(playerid, numb)
{
	if(!GetPVarInt(playerid,"Connected") || numb < 0) return 1;
	
	switch(numb)
	{
	    case 0, 1: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "B");
	    case 2: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJI");
	    case 3: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIA");
	    case 4: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIAD");
	    case 5: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIADO");
	    case 6: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIADOK");
	    case 7: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIADOKC");
	    case 8: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIADOKC's");
	    case 9: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIADOKC's ]");
	    case 10: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIADOKC's ] T");
	    case 11: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIADOKC's ] Tr");
	    case 12: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIADOKC's ] Tra");
	    case 13: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIADOKC's ] Trai");
	    case 14: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIADOKC's ] Train");
	    case 15: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIADOKC's ] Traini");
	    case 16: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIADOKC's ] Trainin");
	    case 17..19: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIADOKC's ] Training");
	    case 20: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIADOKC's ] Training~n~b");
	    case 21: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIADOKC's ] Training~n~bL");
	    case 22: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIADOKC's ] Training~n~bLe");
	    case 23: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIADOKC's ] Training~n~bLea");
	    case 24: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIADOKC's ] Training~n~bLeag");
	    case 25: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIADOKC's ] Training~n~bLeagu");
	    case 26: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIADOKC's ] Training~n~bLeague");
	    case 27: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIADOKC's ] Training~n~bLeague v");
	    case 28: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIADOKC's ] Training~n~bLeague v2");
	    case 29: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIADOKC's ] Training~n~bLeague v2.");
	    case 30: PlayerTextDrawSetString(playerid, Player[playerid][IntroLetters], "BJIADOKC's ] Training~n~bLeague v2.0");
	    default:
		{
			CallLocalFunction("LenDot", "if", playerid, 1.0);
			
			return 1;
		}
	}
	
	PlayerTextDrawShow(playerid,Player[playerid][IntroLetters]);
	PlayerPlaySound(playerid,40402,0.0,0.0,0.0);
	
	SetTimerEx("DrawLetters", 250, false, "ii", playerid, ++numb);
	
	return 1;
}



public LenDot(playerid, Float:len);
public LenDot(playerid, Float:len)
{
	if(len >= 65.0)
	{
		CallLocalFunction("IntroEnd", "i", playerid);
		
		return 1;
	}
	
    PlayerTextDrawLetterSize(playerid, Player[playerid][Dot], len, 1.000000);
    PlayerTextDrawShow(playerid, Player[playerid][Dot]);
    PlayerPlaySound(playerid, 40405, 0.0, 0.0, 0.0);
    
    SetTimerEx("LenDot", 50, false, "if", playerid, (len + 2.5));
    
    return 1;
}



public IntroEnd(playerid);
public IntroEnd(playerid)
{
	if(!GetPVarInt(playerid,"Connected"))
	{
		return 1;
	}
	
	new query[128];
		
	PlayerPlaySound(playerid, 1083, 0.0, 0.0, 0.0);
	SetPVarInt(playerid, "Camera_0", false);
  	SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s [ID: %i, IP: %s] {AFAFAF}подключился к серверу", Player[playerid][Name], playerid, Player[playerid][IP]);
	SetPlayerVirtualWorld(playerid, Intro_VW);
	SetPlayerInterior(playerid, GetGVarInt("MainInterior"));
	ResetPlayerWeapons(playerid);
	
	mysql_format(mysqlHandle, query, sizeof query, "SELECT * FROM `players` WHERE `name` = SHA2('%s', 512) LIMIT 1", Player[playerid][Name]);
	mysql_function_query(mysqlHandle, query, false, "OnPlayerLogin", "di", playerid, false);
	
	// temp
	
	TogglePlayerSpectating(playerid, false);
	PlayerTextDrawSetString(playerid, Player[playerid][TeamText], "~w~~h~>> ~r~~h~Attack ~w~~h~<<     ~b~Defend     ~y~Refferee");
	PlayerTextDrawShow(playerid, Player[playerid][TeamText]);
	
	return 1;
}



public ModeCountTimer(sec);
public ModeCountTimer(sec)
{
	if(!GetGVarInt("Starting")) return 1;
	if(sec <= 0) return CallLocalFunction("StrapUpAll","");

	switch(GetGVarInt("GameType"))
	{
		case Gametype_Arena:
		{
			TextDrawSetStringF(Server[ModeStartText][2], "Arena: %i~n~Starting in %i seconds", Server[Current], sec);
		}
		case Gametype_Base:
		{
			TextDrawSetStringF(Server[ModeStartText][2], "Base: %i~n~Starting in %i seconds", Server[Current], sec);
		}
		case Gametype_CTF:
		{
			TextDrawSetStringF(Server[ModeStartText][2], "CTF: %i~n~Starting in %i seconds", Server[Current], sec);
		}
	}
	
	SendRconCommandF("mapname Starting... [%i sec]", sec);
	
	foreach_p(i)
	{
	    if(!GetPVarInt(i, "Playing") || GetPVarInt(i, "No_Play") || GetPVarInt(i, "AFK_In"))
		{
			continue;
		}
	    
		for(new x; x != 3; x++)
		{
			TextDrawShowForPlayer(i, Server[ModeStartText][x]);
		}
		
		if(sec <= 4)
		{
			PlayerPlaySound(i, 1056, 0.0, 0.0, 0.0);
		}
	}
	
	return SetTimerEx("ModeCountTimer", 1000, false, "i", --sec);
}



public StrapUpAll();
public StrapUpAll()
{
	if(!GetGVarInt("Starting"))
	{
		return 1;
	}
	
	SetGVarInt("Starting", false);
	SetGVarInt("Busy", false);
	
	if((GetOnlinePlayers() <= 1) || (GetActivePlayers() <= 1))
	{
		StopRound();
		SendClientMessageToAll(-1,"[Ошибка]: {AFAFAF}Невозможно запустить раунд: недостаточно игроков");
		
		return 1;
	}
	
	new idx,
		Float:A
	;
	
	foreach_p(i)
	{
	    if(!GetPVarInt(i,"Playing") || GetPVarInt(i,"No_Play")) continue;
	    if(GetPVarInt(i,"AFK_In"))
	    {
	        if(GetPVarInt(i,"Playing"))
	        {
	            SetPVarInt(i,"Playing",0);
	            SendClientMessage(i,-1,"[Инфо]: {AFAFAF}Вы встали в AFK во время старта раунда, и были автоматически дисквалифицированы");
				SpawnPlayer(i);
				continue;
			}
		}
		for(new x = 2; x != -1; --x)
		{
			TextDrawHideForPlayer(i,Server[ModeStartText][x]);
		}
		SetPVarInt(i,"Camera_0",0);
		SetPlayerHealth(i,200.0);
		SetPlayerScore(i,200);
		PlayerTextDrawSetString(i, Player[i][HealthBar], "Protected");
		PlayerTextDrawShow(i,Player[i][HealthBar]);
		SetPlayerVirtualWorld(i,Round_VW);
		PlayerPlaySound(i,1057,0.0,0.0,0.0);
		switch(GetGVarInt("GameType"))
		{
		    case Gametype_Base:
		    {
		        SetPlayerInterior(i,Base[Server[Current]][Interior]);
		        switch(GetPVarInt(i,"Team"))
		        {
		            case Team_Attack:
		            {
		                SetPlayerPos(i,Base[Server[Current]][AttSpawn][idx],Base[Server[Current]][AttSpawn][idx + 1],Base[Server[Current]][AttSpawn][idx + 2]);
		                SetPlayerColor(i,GetGVarInt("Team_Color_R",Team_Attack));
		                AngleCalculator(A,Base[Server[Current]][AttSpawn][idx],Base[Server[Current]][AttSpawn][idx + 1],Base[Server[Current]][CP][0],Base[Server[Current]][CP][1]);
						SetPlayerFacingAngle(i,A);
					}
					case Team_Defend:
					{
					    SetPlayerPos(i,Base[Server[Current]][DefSpawn][idx],Base[Server[Current]][DefSpawn][idx + 1],Base[Server[Current]][DefSpawn][idx + 2]);
					    SetPlayerColor(i,GetGVarInt("Team_Color_R",Team_Defend));
					    AngleCalculator(A,Base[Server[Current]][DefSpawn][idx],Base[Server[Current]][DefSpawn][idx + 1],Base[Server[Current]][CP][0],Base[Server[Current]][CP][1]);
						SetPlayerFacingAngle(i,A);
					}
					case Team_Refferee:
					{
					    SetPlayerPos(i,floatadd(Base[Server[Current]][CP][0],floatrandom(15)),floatadd(Base[Server[Current]][CP][1],floatrandom(15)),floatadd(Base[Server[Current]][CP][2],1.0));
						SetPlayerColor(i,GetGVarInt("Team_Color_R",Team_Refferee));
						SetPlayerFacingAngle(i,floatrandom(360));
					}
				}

			}
			case Gametype_Arena:
			{
			    SetPlayerInterior(i,Arena[Server[Current]][Interior]);
			    switch(GetPVarInt(i,"Team"))
		        {
		            case Team_Attack:
		            {
		                SetPlayerPos(i,Arena[Server[Current]][AttSpawn][idx],Arena[Server[Current]][AttSpawn][idx + 1],Arena[Server[Current]][AttSpawn][idx + 2]);
		                SetPlayerColor(i,GetGVarInt("Team_Color_R",Team_Attack));
		                AngleCalculator(A,Arena[Server[Current]][AttSpawn][idx],Arena[Server[Current]][AttSpawn][idx + 1],Arena[Server[Current]][CP][0],Arena[Server[Current]][CP][1]);
						SetPlayerFacingAngle(i,A);
					}
					case Team_Defend:
					{
					    SetPlayerPos(i,Arena[Server[Current]][DefSpawn][idx],Arena[Server[Current]][DefSpawn][idx + 1],Arena[Server[Current]][DefSpawn][idx + 2]);
					    SetPlayerColor(i,GetGVarInt("Team_Color_R",Team_Defend));
					    AngleCalculator(A,Arena[Server[Current]][DefSpawn][idx],Arena[Server[Current]][DefSpawn][idx + 1],Arena[Server[Current]][CP][0],Arena[Server[Current]][CP][1]);
						SetPlayerFacingAngle(i,A);
					}
					case Team_Refferee:
					{
					    SetPlayerPos(i,floatadd(Arena[Server[Current]][CP][0],floatrandom(15)),floatadd(Arena[Server[Current]][CP][1],floatrandom(15)),floatadd(Arena[Server[Current]][CP][2],1.0));
						SetPlayerColor(i,GetGVarInt("Team_Color_R",Team_Refferee));
						SetPlayerFacingAngle(i,floatrandom(360));
					}
				}
			}
			case Gametype_CTF:
			{
			    SetPlayerInterior(i,CTF[Server[Current]][Interior]);
			    switch(GetPVarInt(i,"Team"))
		        {
		            case Team_Attack:
		            {
		                SetPlayerPos(i,CTF[Server[Current]][AttSpawn][idx],CTF[Server[Current]][AttSpawn][idx + 1],CTF[Server[Current]][AttSpawn][idx + 2]);
		                SetPlayerColor(i,GetGVarInt("Team_Color_R",Team_Attack));
		                AngleCalculator(A,CTF[Server[Current]][AttSpawn][idx],CTF[Server[Current]][AttSpawn][idx + 1],CTF[Server[Current]][CP][0],CTF[Server[Current]][CP][1]);
						SetPlayerFacingAngle(i,A);
					}
					case Team_Defend:
					{
					    SetPlayerPos(i,CTF[Server[Current]][DefSpawn][idx],CTF[Server[Current]][DefSpawn][idx + 1],CTF[Server[Current]][DefSpawn][idx + 2]);
					    SetPlayerColor(i,GetGVarInt("Team_Color_R",Team_Defend));
					    AngleCalculator(A,CTF[Server[Current]][DefSpawn][idx],CTF[Server[Current]][DefSpawn][idx + 1],CTF[Server[Current]][CP][0],CTF[Server[Current]][CP][1]);
						SetPlayerFacingAngle(i,A);
					}
					case Team_Refferee:
					{
					    SetPlayerPos(i,floatadd(CTF[Server[Current]][CP][0],floatrandom(15)),floatadd(CTF[Server[Current]][CP][1],floatrandom(15)),floatadd(CTF[Server[Current]][CP][2],1.0));
						SetPlayerColor(i,GetGVarInt("Team_Color_R",Team_Refferee));
						SetPlayerFacingAngle(i,floatrandom(360));
					}
				}
			}
		}
		
		idx += 3;
		
		if(idx == 27)
		{
			idx = 0;
		}
		
	    SetCameraBehindPlayer(i);
		PlayerStopSound(i);
		HideDialog(i);
		TogglePlayerControllable(i,true);
		
		Update3DTextLabelText(Player[i][AtHead],GetPlayerColor(i)," ");
		
		if(GetPVarInt(i,"Team") != Team_Refferee)
		{
			if(!GetPVarInt(i,"Weapon_1") || !GetPVarInt(i,"Weapon_2"))
			{
				ShowPlayerFirstWeapDialog(i);
			}
			else
			{
				ShowPlayerChangeWeapDialog(i);
			}
		}
	}
	switch(GetGVarInt("GameType"))
	{
		case Gametype_Base:
		{
		    foreach_p(i)
		    {
		        if(!GetPVarInt(i,"Playing") || GetPVarInt(i,"No_Play") || GetPVarInt(i,"AFK_In")) continue;
		        SetPlayerCheckpoint(i,Base[Server[Current]][CP][0],Base[Server[Current]][CP][1],Base[Server[Current]][CP][2],10.0);
		        if(GetPVarInt(i,"Team") != Team_Attack) continue;
		    	SendClientMessage(i,-1,"[Инфо]: {AFAFAF}Для спавна транспорта {FFFF00}(макс. 3 штуки) {AFAFAF}используйте комманду {FF0000}/car");
		    	continue;
			}
		}
		case Gametype_CTF:
		{
	        foreach_p(i)
			{
				if(!GetPVarInt(i,"Playing") || GetPVarInt(i,"No_Play") || GetPVarInt(i,"AFK_In")) continue;
				SendClientMessage(i,-1,"[Инфо]: {AFAFAF}Для победы захватите флаг противника и принесите на свою базу");
			}
			CTF[Server[Current]][Flag][0] = CreatePickup(Red_Flag,Pickup_Type,CTF[Server[Current]][ACP][0],CTF[Server[Current]][ACP][1],CTF[Server[Current]][ACP][2] + 0.1,Round_VW);
			CTF[Server[Current]][Flag][1] = CreatePickup(Blue_Flag,Pickup_Type,CTF[Server[Current]][DCP][0],CTF[Server[Current]][DCP][1],CTF[Server[Current]][DCP][2] + 0.1,Round_VW);
		}
	}
	
	return SetTimer("NoProtect",5000,false);
}



public NoProtect();
public NoProtect()
{
	foreach_p(i)
	{
	    if(!GetPVarInt(i, "Playing") || GetPVarInt(i, "No_Play"))
		{
			continue;
		}
		
	    PlayerTextDrawSetString(i, Player[i][HealthBar], "HP: 100");
    	PlayerTextDrawShow(i, Player[i][HealthBar]);
    	
		SetPlayerHealth(i, 100.0);
		SetPlayerScore(i, 100);
	}
	
	SetGVarInt("Weap_ChangeTick",GetTickCount());
}



public NoProtectAdd(playerid);
public NoProtectAdd(playerid)
{
    PlayerTextDrawSetString(playerid, Player[playerid][HealthBar], "HP: 100");
    PlayerTextDrawShow(playerid, Player[playerid][HealthBar]);
    
	SetPlayerHealth(playerid, 100.0);
	SetPlayerScore(playerid, 100);
}



public WideCameraRotate();
public WideCameraRotate()
{
	if(!GetGVarInt("Starting") || !GetGVarInt("Busy"))
	{
		return 1;
	}
	
	foreach_p(i)
	{
		if(!GetPVarInt(i,"Playing") || !GetPVarInt(i,"Camera_0") || GetPVarInt(i,"No_Play") || GetPVarInt(i,"AFK_In")) continue;
		if(GetPVarFloat(i,"Intro_CamTimes") >= 360.0)
		{
			SetPVarFloat(i,"Intro_CamTimes",0.0);
		}
		else
		{
			GivePVarFloat(i,"Intro_CamTimes",0.8);
		}
		GivePVarFloat(i,"IntroCam_X",floatmul(100.0,floatsin(GetPVarFloat(i,"Intro_CamTimes"),degrees)));
		GivePVarFloat(i,"IntroCam_Y",floatmul(100.0,floatcos(GetPVarFloat(i,"Intro_CamTimes"),degrees)));
		GivePVarFloat(i,"IntroCam_Z",0.2);
		SetPlayerCameraPos(i,GetPVarFloat(i,"IntroCam_X"),GetPVarFloat(i,"IntroCam_Y"),GetPVarFloat(i,"IntroCam_Z"));
		switch(GetGVarInt("GameType"))
		{
			case Gametype_Base:
			{
				SetPVarFloat(i,"IntroCam_X",Base[Server[Current]][CP][0]);
				SetPVarFloat(i,"IntroCam_Y",Base[Server[Current]][CP][1]);
				SetPlayerCameraLookAt(i,Base[Server[Current]][CP][0],Base[Server[Current]][CP][1],Base[Server[Current]][CP][2]);
			}
			case Gametype_Arena:
			{
	  			SetPVarFloat(i,"IntroCam_X",Arena[Server[Current]][CP][0]);
		    	SetPVarFloat(i,"IntroCam_Y",Arena[Server[Current]][CP][1]);
			    SetPlayerCameraLookAt(i,Arena[Server[Current]][CP][0],Arena[Server[Current]][CP][1],Arena[Server[Current]][CP][2]);
			}
			case Gametype_CTF:
			{
			    SetPVarFloat(i,"IntroCam_X",CTF[Server[Current]][CP][0]);
			    SetPVarFloat(i,"IntroCam_Y",CTF[Server[Current]][CP][1]);
			    SetPlayerCameraLookAt(i,CTF[Server[Current]][CP][0],CTF[Server[Current]][CP][1],CTF[Server[Current]][CP][2]);
			}
		}
	}
	
	return SetTimer("WideCameraRotate", 50, false);
}



public VoteCountTimer(sec);
public VoteCountTimer(sec)
{
	if(Server[Current] != -1 || !GetGVarInt("Voting")) return 1;
	
	SendRconCommandF("mapname Voting... [%i sec]", sec);
	
	TextDrawSetStringF(Server[VoteText][0], "Voting (%i sec)~n~/base (id)~n~/arena (id)~n~/ctf (id)", sec);
	TextDrawSetString(Server[VoteText][1], vote_string);
	
	for(new i = 1; i != -1; --i)
	{
		TextDrawShowForAll(Server[VoteText][i]);
	}
	
	TextDrawShowForAll(Server[Barrier][7]);
	TextDrawShowForAll(Server[Barrier][8]);
	
	if(sec <= 0)
	{
	    new
			i, max_data,
			BestArena, BestBase, BestCTF
		;

		for(i = 0, max_data = GetGVarInt("A_Count"); i != max_data; i++)
	    {
	        if(!Arena[i][Exists]) continue;
	        if(Arena[i][Votes] > Arena[BestArena][Votes])
	        {
	            BestArena = i;
	            continue;
			}
		}

		for(i = 0, max_data = GetGVarInt("B_Count"); i != max_data; i++)
		{
		    if(!Base[i][Exists]) continue;
		    if(Base[i][Votes] > Base[BestBase][Votes])
		    {
		        BestBase = i;
		        continue;
			}
		}

		for(i = 0, max_data = GetGVarInt("C_Count"); i != max_data; i++)
		{
			if(!CTF[i][Exists]) continue;
			if(CTF[i][Votes] > CTF[BestCTF][Votes])
			{
			    BestCTF = i;
			    continue;
			}
		}

		if
		(
		Arena[BestArena][Votes] > Base[BestBase][Votes]
		&& Arena[BestArena][Votes] > CTF[BestCTF][Votes]
		) return CallLocalFunction("StartMode","dd",BestArena,Gametype_Arena);

		if
		(
		Base[BestBase][Votes] > Arena[BestArena][Votes]
		&& Base[BestBase][Votes] > CTF[BestCTF][Votes]
		) return CallLocalFunction("StartMode","dd",BestBase,Gametype_Base);

		if
		(
		CTF[BestCTF][Votes] > Arena[BestArena][Votes]
		&& CTF[BestCTF][Votes] > Base[BestBase][Votes]
		) return CallLocalFunction("StartMode","dd",BestCTF,Gametype_CTF);
		
		switch(random(3))
  		{
  			case 0: return CallLocalFunction("StartMode","dd",BestBase,Gametype_Base);
  			case 1: return CallLocalFunction("StartMode","dd",BestArena,Gametype_Arena);
  			case 2: return CallLocalFunction("StartMode","dd",BestCTF,Gametype_CTF);
		}
	}
	return SetTimerEx("VoteCountTimer",1000,false,"d",--sec);
}



public HideWin();
public HideWin()
{
	SetGVarInt("Busy", false);
	StopSoundForAll();
	SendRconCommand("mapname Lobby");
	
 	for(new i; i != Max_Teams; i++)
 	{
 		for(new x; x != 5; x++)
	 	{
	 		TextDrawHideForAll(TeamTextDraw[i][x]);
		}
	}
}



public StopVote();
public StopVote()
{
	if(!GetGVarInt("Voting")) return 1;
	
	SetGVarInt("Voting",0);
	SendRconCommand("mapname Lobby");
	
	new
	    i
	;
	
	for(i = GetGVarInt("A_Count"); i != -1; --i)
	{
		Arena[i][Votes] = 0;
	}
	
	for(i = GetGVarInt("B_Count"); i != -1; --i)
	{
		Base[i][Votes] = 0;
	}
	
	for(i = GetGVarInt("C_Count"); i != -1; --i)
	{
		CTF[i][Votes] = 0;
	}
	
	for(i = 0; i != 2; i++)
	{
		TextDrawHideForAll(Server[VoteText][i]);
	}
	
	TextDrawHideForAll(Server[Barrier][7]);
	TextDrawHideForAll(Server[Barrier][8]);
	
	foreach_p(x)
	{
		SetPVarInt(x, "Voted", 0);
	}
	
	return 1;
}



public StartMode(id, Gametype);
public StartMode(id, Gametype)
{
    StopVote();
    
	if(GetOnlinePlayers() <= 1 || GetActivePlayers() <= 1) return SendClientMessageToAll(-1,"[Ошибка]: {AFAFAF}Невозможно запустить раунд: недостаточно игроков");
	
	SetGVarInt("Busy",1);
	SetGVarInt("Starting",1);
	Server[Current] = id;
	SetGVarInt("GameType",Gametype);
	SetGVarInt("ModeMin",GetGVarInt("Default_ModeMin"));
	SetGVarInt("ModeSec",1);
	
	ClearKillChat();
	
	new
		x,
		string_data[32]
	;
	
	switch(Gametype)
	{
		case Gametype_Base:
		{
		    SendRconCommandF("mapname Base %i starting...", id);
		    
			foreach_p(i)
			{
			    if(GetPVarInt(i,"No_Play") || (GetPlayerState(i) != 7 && !GetPVarInt(i,"Spawned"))) continue;
			    if(GetPVarInt(i,"AFK_In"))
			    {
			        SendClientMessage(i,-1,"[Инфо]: {AFAFAF}Вы были AFK во время старта раунда, поэтому не допущены до него");
			        continue;
				}
			    if(GetPVarInt(i,"SpecID") != -1)
				{
					StopSpectate(i);
				}
			    if(GetPVarInt(i,"DM_Zone") != -1)
			    {
			        GangZoneHideForPlayer(i,GetGVarInt("DM_GZ_1",GetPVarInt(i,"DM_Zone")));
			        GangZoneHideForPlayer(i,GetGVarInt("DM_GZ_2",GetPVarInt(i,"DM_Zone")));
			        GangZoneHideForPlayer(i,GetGVarInt("DM_GZ_3",GetPVarInt(i,"DM_Zone")));
			        GangZoneHideForPlayer(i,GetGVarInt("DM_GZ_4",GetPVarInt(i,"DM_Zone")));
					SetPVarInt(i,"DM_Zone",-1);
					SetPlayerWorldBounds(i,20000.0,-20000.0,20000.0,-20000.0);
				}
				if(GetPVarInt(i,"DuelID") != -1)
		        {
		            SetPVarInt(i,"DuelID",-1);
		            ResetPlayerWeapons(i);
				}
			    HideDialog(i);
				PlayerStopSound(i);
				PlayerPlaySound(i,1142,0.0,0.0,0.0);
				SetPVarInt(i,"Camera_0",1);
				SetPVarInt(i,"Playing",1);
				SetPVarInt(i,"ComboKills",0);
				SetPVarInt(i,"CBug_Ticks",0);
				SetPVarInt(i,"Slide_Ticks",0);
				SetPVarInt(i,"Disqual_Time",GetGVarInt("DissTime"));
				SetPVarInt(i,"Cars_Spawned",0);
				SetPVarFloat(i,"LastHealth",100.0);
				if(IsPlayerInAnyVehicle(i))
				{
					SetPlayerPos(i,0.0,0.0,5.0);
				}
				if(GetPVarInt(i,"CarID") != 0xFFFF)
				{
					DestroyVehicleEx(GetPVarInt(i,"CarID"),i);
				}
				SetPVarFloat(i,"IntroCam_X",Base[id][CP][0]);
				SetPVarFloat(i,"IntroCam_Y",Base[id][CP][1]);
				SetPVarFloat(i,"IntroCam_Z",Base[id][CP][2] + 20.0);
				SetPVarFloat(i,"Intro_CamTimes",0.0);
				SetPlayerInterior(i,Base[id][Interior]);
				SetPlayerPos(i,floatadd(Base[id][CP][0],floatrandom(10)),floatadd(Base[id][CP][1],floatrandom(10)),floatadd(Base[id][CP][2],500.0));
				TogglePlayerControllable(i,false);
				PlayerTextDrawSetString(i, Player[i][HealthBar], "Protected");
    			PlayerTextDrawShow(i,Player[i][HealthBar]);
				SetPlayerHealth(i,200.0);
				SetPlayerScore(i,200);
				SetPlayerVirtualWorld(i,i);
			}
		}
		case Gametype_Arena:
		{
		    SendRconCommandF("mapname Arena %i starting...", id);
		    
			foreach_p(i)
			{
			    if(GetPVarInt(i,"No_Play") || (GetPlayerState(i) != 7 && !GetPVarInt(i,"Spawned"))) continue;
                if(GetPVarInt(i,"AFK_In"))
			    {
			        SendClientMessage(i,-1,"[Инфо]: {AFAFAF}Вы были AFK во время старта раунда, поэтому не допущены до него");
			        continue;
				}
				if(GetPVarInt(i,"SpecID") != -1) StopSpectate(i);
			    if(GetPVarInt(i,"DM_Zone") != -1)
			    {
			        GangZoneHideForPlayer(i,GetGVarInt("DM_GZ_1",GetPVarInt(i,"DM_Zone")));
			        GangZoneHideForPlayer(i,GetGVarInt("DM_GZ_2",GetPVarInt(i,"DM_Zone")));
			        GangZoneHideForPlayer(i,GetGVarInt("DM_GZ_3",GetPVarInt(i,"DM_Zone")));
			        GangZoneHideForPlayer(i,GetGVarInt("DM_GZ_4",GetPVarInt(i,"DM_Zone")));
					SetPVarInt(i,"DM_Zone",-1);
					SetPlayerWorldBounds(i,20000.0,-20000.0,20000.0,-20000.0);
				}
				if(GetPVarInt(i,"DuelID") != -1)
		        {
		            SetPVarInt(i,"DuelID",-1);
		            ResetPlayerWeapons(i);
				}
				HideDialog(i);
			    PlayerStopSound(i);
			    for(x = 3; x != -1; --x)
			    {
					GangZoneShowForPlayer(i,Arena[id][GangZone][x],GetGVarInt("Zone_Color"));
				}
			    PlayerPlaySound(i,1142,0.0,0.0,0.0);
			    SetPVarInt(i,"Camera_0",1);
			    SetPVarInt(i,"Playing",1);
			    SetPVarInt(i,"ComboKills",0);
			    SetPVarInt(i,"CBug_Ticks",0);
			    SetPVarInt(i,"Slide_Ticks",0);
				SetPVarFloat(i,"LastHealth",100.0);
				if(IsPlayerInAnyVehicle(i))
				{
					SetPlayerPos(i,0.0,0.0,5.0);
				}
			    if(GetPVarInt(i,"CarID") != 0xFFFF)
				{
					DestroyVehicleEx(GetPVarInt(i,"CarID"),i);
				}
			    SetPVarInt(i,"Disqual_Time",GetGVarInt("DissTime"));
			    SetPVarFloat(i,"IntroCam_X",Arena[id][CP][0]);
				SetPVarFloat(i,"IntroCam_Y",Arena[id][CP][1]);
				SetPVarFloat(i,"IntroCam_Z",Arena[id][CP][2] + 20.0);
				SetPVarFloat(i,"Intro_CamTimes",0.0);
				SetPlayerInterior(i,Arena[id][Interior]);
			    SetPlayerPos(i,floatadd(Arena[id][CP][0],floatrandom(10)),floatadd(Arena[id][CP][1],floatrandom(10)),floatadd(Arena[id][CP][2],500.0));
			    TogglePlayerControllable(i,false);
			    PlayerTextDrawSetString(i, Player[i][HealthBar], "Protected");
    			PlayerTextDrawShow(i,Player[i][HealthBar]);
				SetPlayerHealth(i,200.0);
				SetPlayerScore(i,200);
				SetPlayerVirtualWorld(i,i);
			}
			valstr(string_data,id);
		    CreateNumb(Arena[id][Quad][0],Arena[id][Quad][1],Arena[id][Quad][2],Arena[id][Quad][3],string_data,GetGVarFloat("Number_Size"));
		}
		case Gametype_CTF:
		{
		    SendRconCommandF("mapname CTF %i starting...", id);
		    
		    CTF[id][FlagOwner][0] = INVALID_PLAYER_ID;
		    CTF[id][FlagOwner][1] = INVALID_PLAYER_ID;
		    
		    if(IsValidObject(CTF[id][Flag][0]))
			{
				DestroyObject(CTF[id][Flag][0]);
			}
		    else
			{
				DestroyPickup(CTF[id][Flag][0]);
			}
			
		    if(IsValidObject(CTF[id][Flag][1]))
			{
				DestroyObject(CTF[id][Flag][1]);
			}
			else
			{
				DestroyPickup(CTF[id][Flag][1]);
			}
			
			foreach_p(i)
			{
			    if(GetPVarInt(i,"No_Play") || (GetPlayerState(i) != 7 && !GetPVarInt(i,"Spawned"))) continue;
			    if(GetPVarInt(i,"AFK_In"))
			    {
			        SendClientMessage(i,-1,"[Инфо]: {AFAFAF}Вы были AFK во время старта раунда, поэтому не допущены до него");
			        continue;
				}
			    if(GetPVarInt(i,"SpecID") != -1)
				{
					StopSpectate(i);
				}
			    if(GetPVarInt(i,"DM_Zone") != -1)
			    {
			        GangZoneHideForPlayer(i,GetGVarInt("DM_GZ_1",GetPVarInt(i,"DM_Zone")));
			        GangZoneHideForPlayer(i,GetGVarInt("DM_GZ_2",GetPVarInt(i,"DM_Zone")));
			        GangZoneHideForPlayer(i,GetGVarInt("DM_GZ_3",GetPVarInt(i,"DM_Zone")));
			        GangZoneHideForPlayer(i,GetGVarInt("DM_GZ_4",GetPVarInt(i,"DM_Zone")));
					SetPVarInt(i,"DM_Zone",-1);
					SetPlayerWorldBounds(i,20000.0,-20000.0,20000.0,-20000.0);
				}
				if(GetPVarInt(i,"DuelID") != -1)
		        {
		            SetPVarInt(i,"DuelID",-1);
		            ResetPlayerWeapons(i);
				}
			    HideDialog(i);
			    PlayerStopSound(i);
			    for(x = 3; x != -1; --x)
			    {
					GangZoneShowForPlayer(i,CTF[id][GangZone][x],GetGVarInt("Zone_Color"));
				}
			    PlayerPlaySound(i,1142,0.0,0.0,0.0);
			    SetPVarInt(i,"Camera_0",1);
			    SetPVarInt(i,"Playing",1);
			    SetPVarInt(i,"ComboKills",0);
			    SetPVarInt(i,"CBug_Ticks",0);
			    SetPVarInt(i,"Slide_Ticks",0);
				SetPVarFloat(i,"LastHealth",100.0);
				if(IsPlayerInAnyVehicle(i))
				{
					SetPlayerPos(i,0.0,0.0,5.0);
				}
			    if(GetPVarInt(i,"CarID") != 0xFFFF)
				{
					DestroyVehicleEx(GetPVarInt(i,"CarID"),i);
				}
			    SetPVarInt(i,"Disqual_Time",GetGVarInt("DissTime"));
			    SetPVarFloat(i,"IntroCam_X",CTF[id][CP][0]);
				SetPVarFloat(i,"IntroCam_Y",CTF[id][CP][1]);
				SetPVarFloat(i,"IntroCam_Z",CTF[id][CP][2] + 20.0);
				SetPVarFloat(i,"Intro_CamTimes",0.0);
				SetPlayerInterior(i,CTF[id][Interior]);
			    SetPlayerPos(i,floatadd(CTF[id][CP][0],floatrandom(10)),floatadd(CTF[id][CP][1],floatrandom(10)),floatadd(CTF[id][CP][2],500.0));
			    TogglePlayerControllable(i,false);
			    PlayerTextDrawSetString(i, Player[i][HealthBar], "Protected");
    			PlayerTextDrawShow(i,Player[i][HealthBar]);
				SetPlayerHealth(i,200.0);
				SetPlayerScore(i,200);
				SetPlayerVirtualWorld(i,i);
			}
			valstr(string_data,id);
		    CreateNumb(CTF[id][Quad][0],CTF[id][Quad][1],CTF[id][Quad][2],CTF[id][Quad][3],string_data,GetGVarFloat("Number_Size"));
		}
		default: return 1;
	}
	
	CallLocalFunction("WideCameraRotate","");
	return CallLocalFunction("ModeCountTimer","d",GetGVarInt("Default_Counting"));
}



public LoginKick(playerid, time);
public LoginKick(playerid, time)
{
	if(!GetPVarInt(playerid,"Connected") || GetPVarInt(playerid,"Logged")) return 0;
	
	new string[48];
	
	format(string, sizeof string, "Login in %i Seconds~n~Or you will be kicked", time);
	PlayerTextDrawSetString(playerid,Player[playerid][LoginText], string);
	PlayerTextDrawShow(playerid,Player[playerid][LoginText]);
	
	if(time <= 0)
	{
	    SendClientMessageToAllF(-1,"[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был автоматически кикнут {FFFF00}(Причина: Истекло время логина в аккаунт)",Player[playerid][Name]);
	    SendClientMessageToAllF(-1,"[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}вышел из игры {FF0000}(Кикнут)",Player[playerid][Name]);
	    Kick(playerid);
	    
	    return 1;
	}
	
	return SetTimerEx("LoginKick", 1000, false, "ii", playerid, --time);
}



public Marker(playerid);
public Marker(playerid)
{
	foreach_p(i)
	{
		if(GetPVarInt(playerid,"Team") != GetPVarInt(i,"Team") || i == playerid) continue;
		SetPlayerMarkerForPlayer(i,playerid,GetGVarInt("Team_Color_R",GetPVarInt(playerid,"Team")));
	}
	
	return 1;
}



public GBugCheck(playerid, gWeap, gAmmo);
public GBugCheck(playerid, gWeap, gAmmo)
{
	if(!GetPVarInt(playerid,"Connected") || !gWeap || !gAmmo) return 1;
	
	new
		i = GetWeaponSlot(gWeap)
	;
	
	GetPlayerWeaponData(playerid,i,PlayerWeapons[playerid][0][i],PlayerWeapons[playerid][1][i]);
	
	if(PlayerWeapons[playerid][1][i] >= gAmmo)
	{
	    SendClientMessageToAllF(-1,"[Инфо]: {AFAFAF}У игрока {FF0000}%s {AFAFAF}подозрение на баг с гранатами",Player[playerid][Name]);
	    GivePlayerWeapon(playerid,gWeap,-(PlayerWeapons[playerid][1][i]));
	}
	
	return 1;
}



public CBugCheck(playerid);
public CBugCheck(playerid)
{
	if(GetPlayerSpecialAction(playerid) != 1)
	{
	    GivePVarInt(playerid,"CBug_Ticks",1);
	    
	    SendClientMessageToAllF(-1,"[Инфо]: {AFAFAF}Игроку {FF0000}%s {AFAFAF} выдано предупреждение за использование бага +С {FFFF00}(%i/3)",Player[playerid][Name],GetPVarInt(playerid,"CBug_Ticks"));
	    SendClientMessageF(playerid,-1,"[Инфо]: {AFAFAF}Не используй +С! {FFFF00}(Предупреждение %i/3)",GetPVarInt(playerid,"CBug_Ticks"));

		if(GetPVarInt(playerid,"CBug_Ticks") >= 3 && GetPVarInt(playerid,"Playing"))
	    {
	        SetPVarInt(playerid,"CBug_Ticks",0);
	        SendClientMessageToAllF(-1,"[Инфо]: {AFAFAF}Игрок %s был автоматически дисквалифицирован из раунда {FFFF00}(Причина: Использование бага +С, игнорирование предупреждений)",Player[playerid][Name]);
	        RemoveFromRound(playerid);
	        return 1;
		}
		
		new
			Float:float_data[3]
		;
		
    	GetPlayerPos(playerid,float_data[0],float_data[1],float_data[2]);
		SetPlayerPos(playerid,float_data[0],float_data[1],float_data[2] + 0.5);
	}
	
	return 1;
}



public Kill(playerid, tick);
public Kill(playerid, tick)
{
	if((GetTickCount() - tick) >= 5000)
	{
	    if(GetPVarInt(playerid,"ComboTimer") != -1)
		{
			KillTimer(GetPVarInt(playerid,"ComboTimer"));
		}
		
	    SetPVarInt(playerid,"ComboTimer",-1);
		TextDrawHideForAll(Server[Multi]);
		
	    return 1;
	}
	
	new
		string_data[32]
	;
	
	switch(random(4))
	{
 		case 0: string_data = "~r~~h~";
   		case 1: string_data = "~b~~h~";
	    case 2: string_data = "~y~~h~";
	    case 3: string_data = "~w~~h~";
	}
	switch(GetPVarInt(playerid,"ComboKills"))
	{
	    case 2: strcat(string_data,"Double Kill!");
		case 3: strcat(string_data,"Triple Kill!");
		case 4..19: strcat(string_data,"Multi Kill!");
	}
	
	TextDrawSetString(Server[Multi], string_data);
	
	foreach_p(i)
	{
 		if(!GetPVarInt(i, "Playing"))
		{
 			continue;
		}
		
   		TextDrawShowForPlayer(i,Server[Multi]);
	}
	
	return 1;
}



public OnGameModeInit()
{
	new amx_header_data[][] =
	{
		"de_amx",
		"array"
	};

	#pragma unused amx_header_data

	new amx_offset;
	
	#emit LOAD.pri amx_offset
	#emit STOR.pri amx_offset

	#pragma unused amx_offset
	
    ResetServerVars();
    
	mysql_log(LOG_ERROR | LOG_WARNING);
    mysqlHandle = mysql_connect(mysql_host, mysql_user, mysql_db, mysql_password);
    
    mysql_function_query(mysqlHandle, "SET NAMES " #mysql_charset, false, "", "");
    mysql_function_query(mysqlHandle, "SET SESSION character_set_server = " #mysql_charset, false, "", "");
    mysql_set_charset(#mysql_charset "_general_ci");
    
    CreateObjects();
	CreateVehicles();
	CreateTextDraws();
	
	mysql_function_query(mysqlHandle, "SELECT * FROM `objects` WHERE 1", true, "OnObjectsLoad", "");
	mysql_function_query(mysqlHandle, "SELECT * FROM `arena` WHERE 1", true, "OnArenaLoad", "");
	mysql_function_query(mysqlHandle, "SELECT * FROM `base` WHERE 1", true, "OnBaseLoad", "");
	mysql_function_query(mysqlHandle, "SELECT * FROM `ctf` WHERE 1", true, "OnCTFLoad", "");
	mysql_function_query(mysqlHandle, "SELECT * FROM `dm` WHERE 1", true, "OnDMLoad", "");
	
	
	textAdvertRegex = regex_build("(((\\w+):\\/\\/)|(www\\.|\\,|))+(([\\w\\.\\,_-]{2,}(\\.|\\,)[\\w]{2,6})|(([\\d]{1,3}(\\b))(\\s+|)(\\.|\\,|\\s)(\\s+|)[\\d]{1,3}(\\s+|)(\\.|\\,|\\s)(\\s+|)[\\d]{1,3}(\\s+|)(\\.|\\,|\\s)(\\s+|)[\\d]{1,3}))(((\\s+|)(\\:|\\;|\\s)(\\s+|)[\\d\\s]{2,}(\\b))|\\b)(\\/[\\w\\&amp\\;\\%_\\.\\/\\-\\~\\-]*)?");
	ipAdvertRegex = regex_build("([0-9\\s]{1,})+([(/|,.)?\\s]{1,})+([0-9\\s]{1,})+([(/|,.)?\\s]{1,})+([0-9\\s]{1,})+([(/|,.)?\\s]{1,})+([0-9\\s]{1,})");
	mailRegex = regex_build("[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?");
	nameRegex = regex_build("^[A-z0-9@=_\\[\\]\\.\\(\\)\\$]{3,24}$");
	passwordRegex = regex_build("[ а-яА-Яa-zA-Z0-9_,!\\.\\?\\-\\+\\(\\)]+");
	
	if(!regex_match_exid(mail_from, mailRegex))
	{
	    printf("Mail: \"From\" address (%s) is invalid", mail_from);
	}
	
	
	
	new string[256];
	
	GetServerVarAsString("hostname", string, sizeof string);
	mail_init(mail_host, mail_user, mail_password, mail_from, string);
	
	
	
	GetServerVarAsString("bind", string, sizeof string);
	querySocketHandle = _:socket_create(UDP);
	addonSocketHandle = _:socket_create(TCP);
	
	if(!isnull(string))
	{
	    //socket_bind(Socket:querySocketHandle, "127.0.0.2");
	    socket_bind(Socket:addonSocketHandle, string);
	}
	
	socket_set_max_connections(Socket:addonSocketHandle, MAX_PLAYERS);
	
	socket_listen(Socket:querySocketHandle, GetServerVarAsInt("port") + 1);
	socket_listen(Socket:addonSocketHandle, GetServerVarAsInt("port") + 1);
	
	new Socket:tmp = socket_create(UDP);
	socket_connect(tmp, "127.0.0.1", 7778);
	socket_send(tmp, "SAMPQUERY MAXPLAYERS", 20);
	
	
	
	Audio_SetPack("bLeague", true, false);
	
	
	
	SetTimer("ServerProcessor", 1000, true);
	
	if(GetGVarInt("TimeSync"))
	{
	    new
			time
		;
	    gettime(time);
		SetWorldTime(time);
	}
	else
	{
		SetWorldTime(GetGVarInt("ConstTime"));
	}
	
	SetWeather(GetGVarInt("Weather"));
	SetGravity(GetGVarFloat("Gravity"));
	
	UsePlayerPedAnims();
	AllowInteriorWeapons(true);
	DisableInteriorEnterExits();
	ShowNameTags(true);
	SetNameTagDrawDistance(25.0);
	DisableNameTagLOS();
	ShowPlayerMarkers(2);
	EnableStuntBonusForAll(false);
	SetTeamCount(MAX_PLAYERS);
	EnableVehicleFriendlyFire();

	new
		Float:X = GetGVarFloat("Lobby_Pos",0),
		Float:Y = GetGVarFloat("Lobby_Pos",1),
		Float:Z = GetGVarFloat("Lobby_Pos",2)
	;
	
	AddPlayerClassEx(Team_Attack,GetGVarInt("Skin_Att"),X,Y,Z,0.0,0,0,0,0,0,0);
	AddPlayerClassEx(Team_Defend,GetGVarInt("Skin_Def"),X,Y,Z,0.0,0,0,0,0,0,0);
	AddPlayerClassEx(Team_Refferee,GetGVarInt("Skin_Ref"),X,Y,Z,0.0,0,0,0,0,0,0);
	
	return 1;
}



CreateObjects()
{
    CreateObject(969, 257.081481, 1823.635253, 9.593836, 90.000000, 0.000000, 0.000000);
 	CreateObject(969, 257.081481, 1826.828735, 9.593836, 90.000000, 0.000000, 0.000000);
 	CreateObject(969, 257.081481, 1829.999877, 9.593836, 90.000000, 0.000000, 0.000000);
 	CreateObject(3798,1499.7790527344,-1145.0070800781,134.828125,0,0,0);
	CreateObject(3798,1499.7711181641,-1143.0643310547,134.828125,0,0,0);
	CreateObject(3798,1499.7628173828,-1141.2843017578,134.828125,0,0,0);
	CreateObject(3798,1499.7906494141,-1145.0093994141,136.83157348633,0,0,0);
	CreateObject(3798,1499.8231201172,-1143.0762939453,136.83157348633,0,0,0);
	CreateObject(3798,1510.4166259766,-1133.7760009766,134.828125,0,0,0);
	CreateObject(3798,1510.427734375,-1133.7609863281,136.83157348633,0,0,324);
	CreateObject(3798,1522.5418701172,-1124.5979003906,134.828125,0,0,0);
	CreateObject(3798,1522.4914550781,-1124.5751953125,136.83157348633,0,0,46);
	CreateObject(3798,1528.1400146484,-1142.1153564453,134.828125,0,0,0);
	CreateObject(3798,1528.1383056641,-1144.0893554688,134.828125,0,0,0);
	CreateObject(3798,1528.1197509766,-1142.0874023438,136.83157348633,0,0,0);
	CreateObject(3798,1528.0999755859,-1144.0714111328,136.83157348633,0,0,0);
	CreateObject(3798,1537.0953369141,-1135.7368164063,134.828125,0,0,0);
	CreateObject(3798,1537.0861816406,-1135.7570800781,136.83157348633,0,0,0);
	CreateObject(3798,1543.0621337891,-1123.0217285156,134.828125,0,0,0);
	CreateObject(3798,1543.0834960938,-1121.0373535156,134.828125,0,0,0);
	CreateObject(3798,1542.9915771484,-1123.0163574219,136.83157348633,0,0,0);
	CreateObject(3798,1544.9478759766,-1123.0350341797,134.828125,0,0,0);
	CreateObject(3798,1503.1424560547,-1121.3590087891,134.828125,0,0,0);
	CreateObject(3798,1503.1072998047,-1121.3201904297,136.83157348633,0,0,28);
	CreateObject(3798,1541.4526367188,-1145.0336914063,134.828125,0,0,0);
	CreateObject(3798,1518.3863525391,-1143.1754150391,134.828125,0,0,0);
	CreateObject(3798,1518.4543457031,-1143.1159667969,136.83157348633,0,0,314);
	CreateObject(3798,1541.4403076172,-1145.0303955078,136.83157348633,0,0,304);
	CreateObject(5269,2223.2849121094,-2298.6674804688,14.855922698975,0,0,46);
	CreateObject(5269,2220.3435058594,-2295.8588867188,19.263778686523,0,0,44);
	CreateObject(5269,2220.2185058594,-2295.6623535156,14.855922698975,0,0,44);
	CreateObject(5269,2224.4094238281,-2299.7165527344,19.387094497681,0,0,46);
	CreateObject(5269,2228.259765625,-2303.9477539063,16.07371711731,0,0,48);
	CreateObject(5269,2214.587890625,-2289.5207519531,16.07371711731,0,0,46);
	CreateObject(5269,2214.5112304688,-2289.9462890625,20.604888916016,0,0,48);
	CreateObject(5269,2262.3967285156,-2253.7531738281,14.855922698975,0,0,44);
	CreateObject(5269,2267.3603515625,-2258.9765625,14.855922698975,0,0,44);
	CreateObject(5269,2178.0493164063,-2254.2819824219,16.079051971436,0,0,316);
	CreateObject(3798,2131.9855957031,-2278.8889160156,19.671875,0,0,46);
	CreateObject(3798,1281.0778808594,-1196.3350830078,93.2265625,0,0,0);
	CreateObject(3798,1281.0660400391,-1196.3369140625,95.230018615723,0,0,30);
	CreateObject(3798,1288.4587402344,-1189.4010009766,93.2265625,0,0,0);
	CreateObject(3798,1288.4334716797,-1189.4680175781,95.230018615723,0,0,0);
	CreateObject(3798,1288.2969970703,-1203.6804199219,93.2265625,0,0,0);
	CreateObject(3798,1288.5129394531,-1203.9626464844,95.230018615723,0,0,40);
	CreateObject(3633,1274.6022949219,-1191.3812255859,93.701362609863,0,0,0);
	CreateObject(3799,1004.7507324219,-1201.6022949219,53.90625,0,0,0);
	CreateObject(3799,1004.8453979492,-1190.6975097656,53.90625,0,0,0);
	CreateObject(3799,1015.9840087891,-1197.4722900391,53.90625,0,0,0);
	CreateObject(3799,1016.0595703125,-1194.6491699219,53.90625,0,0,0);
	CreateObject(3799,978.55041503906,-1186.5888671875,53.90625,0,0,0);
	CreateObject(3799,977.22088623047,-1203.1439208984,53.90625,0,0,0);
	CreateObject(3799,974.05541992188,-1193.779296875,53.90625,0,0,0);
	CreateObject(3799,1543.4719238281,-1351.7272949219,328.47332763672,0,0,0);
	CreateObject(3799,1537.8181152344,-1359.8333740234,328.46151733398,0,0,0);
	CreateObject(3799,1554.7767333984,-1355.0494384766,328.45663452148,0,0,0);
	CreateObject(7900,-1307.8038330078,-134.24981689453,16.477396011353,0,0,46);
	CreateObject(7901,-1307.8432617188,-134.31861877441,23.135292053223,0,0,46);
	CreateObject(7909,-1296.1489257813,-122.11698150635,16.477396011353,0,0,46);
	CreateObject(7910,-1296.228515625,-122.07195281982,23.135292053223,0,0,46);
	CreateObject(7911,-1284.5913085938,-109.94495391846,16.472923278809,0,0,46);
	CreateObject(7912,-1284.6068115234,-109.95294952393,23.130819320679,0,0,46);
	CreateObject(7913,-1272.4914550781,-110.49647521973,16.472923278809,0,0,314);
	CreateObject(7914,-1272.5240478516,-110.45573425293,23.130819320679,0,0,314);
	CreateObject(7915,-1260.7824707031,-122.61738586426,16.472923278809,0,0,314);
	CreateObject(7901,-1260.7337646484,-122.56716918945,23.130819320679,0,0,314);
	CreateObject(7907,-1249.0830078125,-134.75180053711,16.477396011353,0,0,314);
	CreateObject(7908,-1249.1010742188,-134.73443603516,23.142292022705,0,0,314);
	CreateObject(7909,-1249.6839599609,-146.88751220703,16.477396011353,0,0,226);
	CreateObject(7910,-1249.6092529297,-146.83572387695,23.135292053223,0,0,226);
	CreateObject(7913,-1261.2958984375,-158.88659667969,16.477396011353,0,0,226);
	CreateObject(7914,-1261.3424072266,-158.92538452148,23.135292053223,0,0,226);
	CreateObject(7915,-1273.0174560547,-171.06399536133,16.477396011353,0,0,226);
	CreateObject(7911,-1272.9729003906,-171.00416564941,23.135292053223,0,0,226);
	CreateObject(7906,-1284.8459472656,-170.34071350098,16.477396011353,0,0,134);
	CreateObject(7908,-1284.8458251953,-170.38175964355,23.139753341675,0,0,134);
	CreateObject(7913,-1296.5959472656,-158.15298461914,16.477396011353,0,0,134);
	CreateObject(7915,-1296.57421875,-158.15975952148,23.135292053223,0,0,134);
	CreateObject(7912,-1308.2697753906,-146.01480102539,16.477396011353,0,0,134);
	CreateObject(7906,-1307.908203125,-146.4029083252,23.213665008545,0,0,134);
	CreateObject(3799,977.30645751953,-1200.4506835938,53.90625,0,0,0);
	CreateObject(13607,-663.13195800781,367.70468139648,58.60376739502,0,0,0);
	CreateObject(13623,-663.11535644531,367.90579223633,66.39070892334,0,0,0);
	CreateObject(972,-1629.8848876953,684.34283447266,6.1875,0,0,88);
	CreateObject(974,-1621.9113769531,692.45825195313,8.9652404785156,0,0,94);
	CreateObject(3798,-1526.6783447266,1207.9185791016,24.3125,0,0,0);
	CreateObject(3798,-1526.7175292969,1208.0939941406,26.315956115723,0,0,0);
	CreateObject(3798,-1528.6450195313,1207.9508056641,24.3125,0,0,0);
	CreateObject(3798,-1541.7255859375,1123.9854736328,24.3125,0,0,0);
	CreateObject(3798,-1539.7205810547,1123.9537353516,24.3125,0,0,0);
	CreateObject(3798,-1539.7329101563,1123.8529052734,26.315956115723,0,0,0);
	CreateObject(3798,-1532.4426269531,1169.4122314453,24.3125,0,0,0);
	CreateObject(3798,-1534.3865966797,1169.3775634766,24.3125,0,0,0);
	CreateObject(3798,-1533.4532470703,1169.3587646484,26.315956115723,0,0,0);
	CreateObject(3798,-1926.5854492188,684.96990966797,144.3203125,0,0,0);
	CreateObject(3798,-1926.5954589844,684.97222900391,146.32376098633,0,0,0);
	CreateObject(3798,-1926.5598144531,686.94055175781,144.3203125,0,0,0);
	CreateObject(3798,-1924.4794921875,684.98693847656,144.3203125,0,0,0);
	CreateObject(3798,-1979.2204589844,635.02221679688,144.3203125,0,0,0);
	CreateObject(3798,-1981.1960449219,635.04333496094,144.3203125,0,0,0);
	CreateObject(3798,-1979.3497314453,635.02044677734,146.32376098633,0,0,0);
	CreateObject(3798,-1979.2230224609,633.14074707031,144.3203125,0,0,0);
	CreateObject(3798,-1925.0751953125,630.29626464844,144.3203125,0,0,0);
	CreateObject(3798,-1980.4484863281,683.36517333984,144.3203125,0,0,0);
	CreateObject(3798,-2235.7060546875,7.6322002410889,58.007846832275,0,0,0);
	CreateObject(3798,-2233.7355957031,7.6561393737793,58.007846832275,0,0,0);
	CreateObject(3798,-2235.7165527344,7.6531744003296,60.011302947998,0,0,0);
	CreateObject(3798,-2220.1591796875,-53.589401245117,58.007846832275,0,0,0);
	CreateObject(3798,-2222.1123046875,-53.591060638428,58.007846832275,0,0,0);
	CreateObject(3798,-2220.1794433594,-53.589649200439,60.011302947998,0,0,0);
	CreateObject(7040,-2709.1342773438,681.05718994141,68.389266967773,0,0,0);
	CreateObject(7040,-2647.0439453125,604.94274902344,68.096466064453,0,0,0);
	CreateObject(13607,843.91717529297,480.55639648438,106.0871887207,0,0,0);
	CreateObject(13623,843.96545410156,480.25302124023,115.61543273926,0,0,0);
	CreateObject(3798,2193.0700683594,2184.7680664063,102.87860107422,0,0,0);
	CreateObject(3799,2229.1137695313,2183.9956054688,102.87860107422,0,0,338);
	CreateObject(3800,2186.9213867188,2193.662109375,105.22840118408,0,0,0);
	CreateObject(1271,2186.6245117188,2195.5375976563,105.5783996582,0,0,0);
	CreateObject(3799,2187.3767089844,2174.4790039063,105.01809692383,0,0,337.99987792969);
	CreateObject(3799,2187.63671875,2174.345703125,102.87860107422,0,0,337.99987792969);
	CreateObject(3799,2188.2219238281,2197.5515136719,102.87860107422,0,0,355.99987792969);
	CreateObject(3799,2186.8779296875,2194.1264648438,102.87860107422,0,0,317.99548339844);
	CreateObject(3799,2188.3798828125,2200.6025390625,102.87860107422,0,0,359.99987792969);
	CreateObject(3799,2188.3198242188,2197.6159667969,105.01809692383,0,0,359.99450683594);
	CreateObject(3799,2208.4216308594,2206.9909667969,102.87860107422,0,0,337.99987792969);
	CreateObject(3799,2208.6513671875,2207.1306152344,105.01809692383,0,0,337.99987792969);
	CreateObject(3799,2211.0144042969,2193.8908691406,102.87860107422,0,0,23.999877929688);
	CreateObject(3800,2277.2248535156,2203.4165039063,105.22840118408,0,0,0);
	CreateObject(3798,2224.3503417969,2178.6765136719,102.87860107422,0,0,0);
	CreateObject(3798,2224.3798828125,2176.6696777344,102.87860107422,0,0,0);
	CreateObject(3798,2224.4165039063,2174.6674804688,102.87860107422,0,0,0);
	CreateObject(3798,2224.5046386719,2172.6225585938,102.87860107422,0,0,0);
	CreateObject(3798,2224.3974609375,2177.5578613281,104.88205718994,0,0,0);
	CreateObject(3798,2295.009765625,2197.6474609375,102.87860107422,0,0,0);
	CreateObject(3798,2224.5185546875,2176.7082519531,106.88551330566,0,0,0);
	CreateObject(3799,2188.73046875,2176.9921875,102.87860107422,0,0,337.99987792969);
	CreateObject(3799,2301.4287109375,2176.8422851563,102.87860107422,0,0,337.99987792969);
	CreateObject(3799,2300.2822265625,2174.138671875,102.87860107422,0,0,337.99987792969);
	CreateObject(3799,2301.1616210938,2175.8408203125,105.01809692383,0,0,337.99987792969);
	CreateObject(3799,2302.5556640625,2179.560546875,102.87860107422,0,0,337.99987792969);
	CreateObject(3799,2303.6103515625,2182.2900390625,102.87860107422,0,0,337.99987792969);
	CreateObject(3799,2302.9638671875,2180.14453125,105.01809692383,0,0,337.99987792969);
	CreateObject(3798,2224.4677734375,2175.5634765625,104.88205718994,0,0,0);
	CreateObject(3798,2295.0244140625,2195.6572265625,102.87860107422,0,0,0);
	CreateObject(3798,2294.8952636719,2196.7119140625,104.88205718994,0,0,322);
	CreateObject(3798,2295.72265625,2200.095703125,102.87860107422,0,0,321.99829101563);
	CreateObject(3799,2276.197265625,2203.9338378906,102.87860107422,0,0,5.9998779296875);
	CreateObject(3799,2288.6689453125,2182.0576171875,102.87860107422,0,0,5.99853515625);
	CreateObject(3799,2280.3935546875,2174.80078125,102.87860107422,0,0,5.99853515625);
	CreateObject(3798,2280.8884277344,2175.1357421875,105.22840118408,0,0,351.99829101563);
	CreateObject(3799,2288.9235839844,2183.5034179688,105.22840118408,0,0,5.99853515625);
	CreateObject(3799,2288.14453125,2185.0322265625,102.87860107422,0,0,5.99853515625);
	CreateObject(3800,2210.8310546875,2193.171875,105.22840118408,0,0,0);
	CreateObject(3799,2270.4189453125,2195.5187988281,102.87860107422,0,0,5.99853515625);
	CreateObject(8378,1798.8013916016,2144.0930175781,12.655561447144,0,0,0);
	CreateObject(8378,1804.76171875,2044.4072265625,12.619625091553,0,0,0);
	CreateObject(3798,1801.9621582031,2069.5615234375,4.9097061157227,0,0,354);
	CreateObject(3798,1813.23828125,2068.208984375,2.9369237422943,0,0,13.99658203125);
	CreateObject(3798,1811.3486328125,2067.4619140625,2.9138774871826,0,0,13.99658203125);
	CreateObject(3798,1790.3560791016,2077.3295898438,4.9097061157227,0,0,27.995971679688);
	CreateObject(3798,1800.98828125,2069.2099609375,2.90625,0,0,353.99597167969);
	CreateObject(3800,1805.2333984375,2082.8330078125,2.9062502384186,0,0,0);
	CreateObject(3798,1799.2878417969,2065.6096191406,2.8839268684387,0,0,353.99597167969);
	CreateObject(3800,1812.0888671875,2068.1474609375,4.9173336029053,0,0,0);
	CreateObject(3800,1806.3647460938,2081.3134765625,2.90625,0,0,0);
	CreateObject(3800,1805.3852539063,2082.4326171875,5.0736894607544,0,0,0);
	CreateObject(3800,1805.35546875,2082.609375,3.9899697303772,0,0,0);
	CreateObject(3798,1793.6279296875,2069.8095703125,2.90625,0,0,353.99597167969);
	CreateObject(3798,1809.0827636719,2131.1303710938,2.9138774871826,0,0,27.9931640625);
	CreateObject(3798,1789.6455078125,2076.892578125,2.90625,0,0,27.9931640625);
	CreateObject(3798,1787.916015625,2075.9443359375,2.90625,0,0,27.9931640625);
	CreateObject(3798,1782.5008544922,2077.0639648438,2.9090971946716,0,0,1.9931640625);
	CreateObject(3798,1782.140625,2067.279296875,2.9193849563599,0,0,1.988525390625);
	CreateObject(3798,1784.26953125,2065.49609375,2.90625,0,0,1.988525390625);
	CreateObject(3798,1812.6916503906,2080.9587402344,2.9212985038757,0,0,13.99658203125);
	CreateObject(3798,1814.2041015625,2083.25390625,2.9645195007324,0,0,13.99658203125);
	CreateObject(3798,1814.2041015625,2083.25390625,2.9645195007324,0,0,13.99658203125);
	CreateObject(3798,1803.09375,2069.185546875,2.90625,0,0,353.99597167969);
	CreateObject(3798,1791.4208984375,2077.8935546875,2.90625,0,0,27.9931640625);
	CreateObject(3800,1790.1103515625,2118.6789550781,2.90625,0,0,0);
	CreateObject(3798,1787.0399169922,2120.9760742188,2.90625,0,0,27.9931640625);
	CreateObject(3798,1787.9906005859,2118.6540527344,2.90625,0,0,27.9931640625);
	CreateObject(3798,1787.6204833984,2120.5625,4.9097061157227,0,0,27.9931640625);
	CreateObject(3798,1781.0717773438,2116.0710449219,2.9499378204346,0,0,71.9931640625);
	CreateObject(3798,1778.6767578125,2120.1845703125,3.0183818340302,0,0,71.987915039063);
	CreateObject(3798,1791.9655761719,2127.3645019531,2.90625,0,0,77.9931640625);
	CreateObject(3798,1794.0899658203,2127.9584960938,2.909835100174,0,0,77.991943359375);
	CreateObject(3800,1794.0185546875,2127.5148925781,4.913290977478,0,0,0);
	CreateObject(3800,1781.9217529297,2124.1481933594,2.9256467819214,0,0,0);
	CreateObject(3800,1781.9005126953,2123.9965820313,4.0093660354614,0,0,0);
	CreateObject(3800,1782.9562988281,2124.7724609375,2.90625,0,0,0);
	CreateObject(3800,1783.0941162109,2124.7561035156,3.9899694919586,0,0,0);
	CreateObject(3800,1782.740234375,2124.6059570313,5.0736889839172,0,0,0);
	CreateObject(3798,1815.9395751953,2127.841796875,3.0141167640686,0,0,27.9931640625);
	CreateObject(3798,1814.0621337891,2126.6323242188,2.9604642391205,0,0,27.9931640625);
	CreateObject(3798,1812.1597900391,2125.3891601563,2.913877248764,0,0,27.9931640625);
	CreateObject(3798,1815.4832763672,2127.7719726563,5.0175728797913,0,0,27.9931640625);
	CreateObject(3798,1801.5137939453,2118.4418945313,2.90625,0,0,83.9931640625);
	CreateObject(3800,1803.0289306641,2117.822265625,2.90625,0,0,0);
	CreateObject(3800,1801.0831298828,2118.2431640625,4.9097061157227,0,0,0);
	CreateObject(3800,1799.76953125,2118.4157714844,2.8921599388123,0,0,0);
	CreateObject(3798,1806.9969482422,2114.4956054688,2.9138777256012,0,0,79.9931640625);
	CreateObject(3798,1809.0218505859,2113.9338378906,2.9138774871826,0,0,79.991455078125);
	CreateObject(3798,1807.9272460938,2115.0212402344,4.9173336029053,0,0,79.991455078125);
	CreateObject(8378,-2177.0261230469,2630.8666992188,64.330703735352,0,0,74);
	CreateObject(8378,-2071.01171875,2606.92578125,64.039764404297,0,0,61.995849609375);
	CreateObject(3630,-2154.3618164063,2634.0825195313,56.184322357178,0,0,120);
	CreateObject(3630,-2090.0048828125,2613.552734375,56.016181945801,0,0,27.998657226563);
	CreateObject(3798,-2148.1071777344,2622.1337890625,57.098434448242,0,0,0);
	CreateObject(3798,-2147.8642578125,2621.65234375,55.09497833252,0,0,0);
	CreateObject(3798,-2148.203125,2623.703125,55.093627929688,0,0,0);
	CreateObject(3798,-2099.7153320313,2608.7639160156,56.968608856201,0,0,348);
	CreateObject(3798,-2139.6416015625,2638.5009765625,55.095092773438,0,0,347.99743652344);
	CreateObject(3798,-2134.0126953125,2633.185546875,54.711784362793,0,0,347.99743652344);
	CreateObject(3798,-2136.423828125,2631.7021484375,54.718563079834,0,0,347.99743652344);
	CreateObject(3798,-2128.103515625,2622.7001953125,54.707416534424,0,0,347.99743652344);
	CreateObject(3798,-2100.154296875,2628.19140625,54.997253417969,0,0,347.99743652344);
	CreateObject(3798,-2100.017578125,2626.1533203125,54.993392944336,0,0,347.99743652344);
	CreateObject(3798,-2100.3212890625,2627.150390625,56.996849060059,0,0,347.99743652344);
	CreateObject(3798,-2105.9599609375,2621.7060546875,54.640697479248,0,0,347.99743652344);
	CreateObject(3798,-2106.44921875,2619.8046875,54.641139984131,0,0,347.99743652344);
	CreateObject(3798,-2117.1044921875,2631.1044921875,55.066291809082,0,0,347.99743652344);
	CreateObject(3798,-2099.83984375,2608.9013671875,54.965152740479,0,0,347.99743652344);
	CreateObject(10230,1447.3387451172,-5569.4194335938,7.2511539459229,0,0,0);
	CreateObject(10231,1446.5345458984,-5570.9741210938,8.3070011138916,0,0,0);
	CreateObject(10140,1462.0600585938,-5570.4565429688,7.3852734565735,0,0,0);
	CreateObject(10229,1447.119140625,-5570.849609375,6.0999999046326,0,0,0);
	CreateObject(3577,-2358.7158203125,449.38650512695,74.397911071777,0,0,37.996215820313);
	CreateObject(3798,-2350.9191894531,438.462890625,72.254127502441,0,0,68);
	CreateObject(3798,-2354.6416015625,412.1083984375,72.2578125,0,0,0);
	CreateObject(3798,-2352.9052734375,424.5029296875,72.2578125,0,0,43.994750976563);
	CreateObject(3798,-2371.6240234375,447.5869140625,72.2578125,0,0,43.9892578125);
	CreateObject(3798,-2338.1904296875,412.392578125,72.2578125,0,0,43.9892578125);
	CreateObject(3798,-2389.66015625,450.955078125,72.2578125,0,0,43.9892578125);
	CreateObject(3798,-2392.9169921875,467.34539794922,72.2578125,0,0,43.994750976563);
	CreateObject(3798,-2371.0129394531,430.98873901367,72.2578125,0,0,43.994750976563);
	CreateObject(3630,-2387.3291015625,439.27722167969,73.74674987793,0,0,302);
	CreateObject(3630,-2435.4619140625,456.0592956543,73.750434875488,0,0,301.99768066406);
	CreateObject(3798,-2415.2673339844,461.72634887695,72.2578125,0,0,43.994750976563);
	CreateObject(3798,-2436.7316894531,438.59161376953,72.2578125,0,0,35.994750976563);
	CreateObject(7040,-2370.6047363281,417.30136108398,75.685592651367,0,0,0);
	CreateObject(3630,-2380.7600097656,462.22775268555,73.750434875488,0,0,309.99768066406);
	CreateObject(18367,-2314.7800292969,438.27456665039,72.467193603516,8,0,316);
	CreateObject(3630,-2325.6469726563,474.33990478516,74.234809875488,0,0,309.99572753906);
	CreateObject(3458,-2354.6428222656,463.51675415039,70.931770324707,0,359,0);
	CreateObject(3630,-2297.3737792969,466.76080322266,74.234809875488,0,0,309.99572753906);
	CreateObject(7040,-2291.6403808594,434.96936035156,76.169967651367,0,0,0);
	CreateObject(3798,-2321.6403808594,456.60827636719,72.7421875,0,0,67.999877929688);
	CreateObject(3798,-2308.9074707031,479.72406005859,72.735900878906,0,0,67.999877929688);
	CreateObject(3798,-2302.9895019531,452.37103271484,74.745086669922,0,0,43.999877929688);
	CreateObject(18367,-2314.779296875,438.2744140625,72.467193603516,7.998046875,0,315.99975585938);
	CreateObject(3798,-2275.5126953125,467.31640625,72.7421875,0,0,99.99755859375);
	CreateObject(3798,-2302.0876464844,492.40185546875,74.745643615723,0,0,99.992065429688);
	CreateObject(3798,-2283.9580078125,485.109375,72.7421875,0,0,99.99755859375);
	CreateObject(3798,-2263.765625,482.1201171875,72.7421875,0,0,99.99755859375);
	CreateObject(3798,-2252.9892578125,470.583984375,72.7421875,0,0,99.99755859375);
	CreateObject(3798,-2368.8525390625,444.71362304688,72.254127502441,0,0,43.9892578125);
	CreateObject(3798,-2370.2734375,446.154296875,72.254127502441,0,0,43.9892578125);
	CreateObject(3798,-2371.017578125,447.03903198242,74.261268615723,0,0,43.9892578125);
	CreateObject(3577,-2358.734375,449.5302734375,73.040321350098,0,0,37.996215820313);
	CreateObject(3798,-2389.4223632813,451.08679199219,74.261268615723,0,0,43.9892578125);
	CreateObject(3798,-2339.53125,413.89166259766,72.2578125,0,0,43.9892578125);
	CreateObject(3798,-2338.4311523438,412.70803833008,74.261268615723,0,0,43.9892578125);
	CreateObject(3798,-2303.8359375,452.9404296875,72.7421875,0,0,67.999877929688);
	CreateObject(3798,-2301.91015625,451.6171875,72.7421875,0,0,43.994750976563);
	CreateObject(3798,-2299.7802734375,490.798828125,72.7421875,0,0,99.992065429688);
	CreateObject(3798,-2301.9833984375,492.4306640625,72.7421875,0,0,99.992065429688);
	CreateObject(3798,-2319.5986328125,456.0751953125,72.7421875,0,0,67.999877929688);
	CreateObject(3798,-2275.8759765625,469.3076171875,72.7421875,0,0,99.99755859375);
	CreateObject(3798,-2275.220703125,465.40771484375,72.7421875,0,0,99.99755859375);
	CreateObject(3798,-2275.1892089844,466.21829223633,74.745643615723,0,0,99.99755859375);
	CreateObject(7416,2323.575,1282.791,9.839,0.0,0.0,0.0);
	CreateObject(17864,2458.738,1290.593,16.244,0.104,0.0,101.250);
	CreateObject(8395,2323.564,1241.679,84.769,-74.771,0.0,0.0);
	CreateObject(8395,2323.742,1324.910,85.004,-74.771,0.0,-180.000);
	CreateObject(8395,2364.907,1283.242,84.901,-74.771,0.0,-270.000);
	CreateObject(8395,2282.479,1283.210,85.331,-74.771,0.0,-450.000);
	CreateObject(3452,2373.732,1269.533,15.570,0.0,0.0,90.000);
	CreateObject(3453,2368.263,1239.306,15.563,0.0,0.0,0.0);
	CreateObject(3452,2373.729,1299.136,15.570,0.0,0.0,90.000);
	CreateObject(3453,2367.369,1328.471,15.571,0.0,0.0,90.000);
	CreateObject(3452,2337.158,1333.939,15.570,0.0,0.0,180.000);
	CreateObject(3452,2307.540,1333.942,15.545,0.0,0.0,-180.000);
	CreateObject(3453,2278.218,1327.557,15.546,0.0,0.0,-180.000);
	CreateObject(3452,2338.935,1232.927,15.563,0.0,0.0,-360.000);
	CreateObject(3452,2309.309,1232.928,15.563,0.0,0.0,-360.000);
	CreateObject(3453,2279.099,1238.403,15.563,0.0,0.0,-90.000);
	CreateObject(3452,2272.723,1267.667,15.545,0.0,0.0,-450.000);
	CreateObject(3452,2272.741,1297.293,15.546,0.0,0.0,-450.000);
	CreateObject(7191,2364.759,1297.298,10.971,0.0,0.0,0.0);
	CreateObject(7191,2364.768,1270.020,10.971,0.0,0.0,0.0);
	CreateObject(7191,2336.833,1324.960,10.971,0.0,0.0,90.000);
	CreateObject(7191,2309.390,1324.957,10.971,0.0,0.0,90.000);
	CreateObject(7191,2281.705,1296.787,10.946,0.0,0.0,180.000);
	CreateObject(7191,2281.726,1269.535,10.996,0.0,0.0,-180.000);
	CreateObject(7191,2309.798,1241.871,10.963,0.0,0.0,-90.000);
	CreateObject(7191,2337.037,1241.894,10.963,0.0,0.0,-90.000);
	CreateObject(980,2362.003,1322.009,10.145,0.0,0.0,-45.000);
	CreateObject(980,2363.991,1324.032,12.949,-88.522,0.0,-45.000);
	CreateObject(980,2284.691,1322.124,10.170,0.0,0.0,45.000);
	CreateObject(980,2282.734,1324.080,12.970,-88.522,0.0,45.000);
	CreateObject(980,2284.529,1244.806,10.212,0.0,0.0,135.000);
	CreateObject(980,2282.561,1242.838,13.012,-88.522,0.0,135.000);
	CreateObject(980,2361.866,1244.756,10.162,0.0,0.0,225.000);
	CreateObject(980,2363.820,1242.773,13.012,-88.522,0.0,225.000);
	CreateObject(3534,2323.677,1283.234,89.550,0.0,0.0,0.0);
}



public OnGameModeExit()
{
	CallLocalFunction("ExitGameMode","");
	
	return 1;
}



public OnDNS(host[], ip[], extra)
{
	return 1;
}



public OnReverseDNS(ip[], host[], extra)
{
	if(!strcmp(ip, host, false))
	{
	    printf("Error while retrieving host for IP %s", ip);

	    return 1;
	}

	if(GetPVarInt(extra, "Connected"))
	{
	    SetPVarString(extra, "dns", host);
	}

	return 1;
}



public onUDPReceiveData(Socket:id, data[], data_len, remote_client_ip[], remote_client_port)
{
	if(data_len > 64)
	{
	    return 1;
	}
	
	printf("Received from %s:%i --- %s", remote_client_ip, remote_client_port, data);
	
	new check[32];
	new type[32];
	
	sparam(check, sizeof check, data, ' ', 0);
	
	if(strcmp(check, "SAMPQUERY", false))
	{
	    return 1;
	}
	
	sparam(type, sizeof type, data, ' ', 1, 1);
	
	if(!strcmp(type, "HOSTNAME"))
	{
	    new packet[256];
	    
	    GetServerVarAsString("hostname", packet, sizeof packet);
	    strins(packet, "SAMPQUERY HOSTNAME ", 0);
	    socket_connect(id, remote_client_ip, remote_client_port);
	    socket_send(id, packet, strlen(packet));
	    
	    return 1;
	}
	else if(!strcmp(type, "MAPNAME"))
	{
	    new packet[64];
	    
	    GetServerVarAsString("mapname", packet, sizeof packet);
	    strins(packet, "SAMPQUERY MAPNAME ", 0);
	    socket_connect(id, remote_client_ip, remote_client_port);
	    socket_send(id, packet, strlen(packet));
	    
	    return 1;
	}
	else if(!strcmp(type, "MODENAME"))
	{
	    new packet[64];
	    
	    GetServerVarAsString("gamemodetext", packet, sizeof packet);
	    strins(packet, "SAMPQUERY MODENAME ", 0);
	    socket_connect(id, remote_client_ip, remote_client_port);
	    socket_send(id, packet, strlen(packet));

	    return 1;
	}
	else if(!strcmp(type, "GRAVITY"))
	{
	    new packet[48];
	    
	    GetServerVarAsString("gravity", packet, sizeof packet);
	    format(packet, sizeof packet, "SAMPQUERY GRAVITY %f", floatstr(packet));
	    socket_connect(id, remote_client_ip, remote_client_port);
	    socket_send(id, packet, strlen(packet));

	    return 1;
	}
	else if(!strcmp(type, "MAXPLAYERS"))
	{
	    new packet[32];
	    
		format(packet, sizeof packet, "SAMPQUERY MAXPLAYERS %i", GetMaxPlayers());
		socket_connect(id, remote_client_ip, remote_client_port);
		socket_send(id, packet, strlen(packet));
		
		return 1;
	}
	else if(!strcmp(type, "ONLINEPLAYERS"))
	{
	    new packet[48];
	    
	    format(packet, sizeof packet, "SAMPQUERY ONLINEPLAYERS %i", GetOnlinePlayers());
	    socket_connect(id, remote_client_ip, remote_client_port);
	    socket_send(id, packet, strlen(packet));
	    
	    return 1;
	}
	else if(!strcmp(type, "PLAYERLIST"))
	{
	    new packet[(MAX_PLAYERS * MAX_PLAYER_NAME) + 32];
	    
		foreach_p(i)
		{
			strcat(packet, "\n");
		    strcat(packet, Player[i][Name]);
		}
		
		format(packet, sizeof packet, "SAMPQUERY PLAYERLIST %s", packet);
		socket_connect(id, remote_client_ip, remote_client_port);
		socket_send(id, packet, strlen(packet));
		
		return 1;
	}
	else if(!strfind(type, "PLAYERID"))
	{
	    new playerid;
	    new player_name[24];
	    
	    sparam(player_name, sizeof player_name, data, ' ', 2, 1);
	    
	    if(isnull(player_name))
	    {
	        return 1;
		}
		
		foreach_p(i)
		{
		    if(!strcmp(player_name, Player[i][Name], false))
		    {
		        playerid = i;
		        
		        break;
			}
		}
		
		new packet[32];
		
		format(packet, sizeof packet, "SAMPQUERY PLAYERID %s %i", player_name, playerid);
		socket_connect(id, remote_client_ip, remote_client_port);
	    socket_send(id, packet, strlen(packet));

	    return 1;
	}
	else if(!strfind(type, "PLAYERNAME"))
	{
	    new playerid = iparam(data, ' ', 2);
	    
	    if(!GetPVarInt(playerid, "Connected"))
	    {
	        return 1;
		}
		
		new packet[64];
		
		format(packet, sizeof packet, "SAMPQUERY PLAYERNAME %i %s", playerid, Player[playerid][Name]);
		socket_connect(id, remote_client_ip, remote_client_port);
	    socket_send(id, packet, strlen(packet));

	    return 1;
	}
	else if(!strfind(type, "PLAYERPING"))
	{
	    new playerid = iparam(data, ' ', 2);
	    
	    if(!GetPVarInt(playerid, "Connected"))
	    {
	        return 1;
		}
		
		new packet[48];
		
		format(packet, sizeof packet, "SAMPQUERY PLAYERPING %i %i", playerid, GetPlayerPing(playerid));
		socket_bind(id, "127.0.0.1");
		socket_connect(id, remote_client_ip, remote_client_port);
		socket_send(id, packet, strlen(packet));
		
		return 1;
	}
	else if(!strfind(type, "PLAYERSCORE"))
	{
	    new playerid = iparam(data, ' ', 2);
	    
	    if(!GetPVarInt(playerid, "Connected"))
	    {
	        return 1;
		}
		
		new packet[48];
		
		format(packet, sizeof packet, "SAMPQUERY PLAYERSCORE %i %i", playerid, GetPlayerScore(playerid));
		socket_connect(id, remote_client_ip, remote_client_port);
	    socket_send(id, packet, strlen(packet));

	    return 1;
	}
	
	return 1;
}



public onSocketReceiveData(Socket:id, remote_clientid, data[], data_len)
{
	printf("Incoming TCP data from %i --- %s", remote_clientid, data);
	
	return 1;
}



public OnMailSendSuccess(index, to[], subject[], message[], type)
{
	return 1;
}



public OnMailSendError(index, to[], subject[], message[], type, error[], error_code)
{
	return 1;
}



public OnVehicleStreamIn(vehicleid, forplayerid)
{
	if(Server[Current] != -1 && GetGVarInt("GameType") == Gametype_Base)
	{
	    if(GetPVarInt(forplayerid,"Team") != Team_Attack)
		{
			SetVehicleParamsForPlayer(vehicleid,forplayerid,false,true);
		}
	    else
		{
			SetVehicleParamsForPlayer(vehicleid,forplayerid,false,false);
		}
	}
	
	return 1;
}



public OnVehicleStreamOut(vehicleid, forplayerid)
{
	if(Server[Current] != -1 && GetGVarInt("GameType") == Gametype_Base)
	{
		SetVehicleParamsForPlayer(vehicleid,forplayerid,false,false);
	}
	
	return 1;
}



public OnPlayerConnect(playerid)
{
	if(Player[playerid][pConnect])
	{
		Kick(playerid);
		
		return 1;
	}
	
	Player[playerid][pConnect] = true;
    ResetPlayerVars(playerid);
    cvector_push_back(playersVector, playerid);
	
	
    if(IsPlayerNPC(playerid))
	{
		Kick(playerid);
		
		return 1;
	}
    
    
    
    GetPlayerName(playerid, Player[playerid][Name], MAX_PLAYER_NAME);
    mysql_real_escape_string(Player[playerid][Name], Player[playerid][Name], mysqlHandle, MAX_PLAYER_NAME);
    
    /*if(!regex_match_exid(Player[playerid][Name], nameRegex))
	{
	    Kick(playerid);
	    
	    return 1;
	}*/
    
    if(!strfind(Player[playerid][Name], "AFK_", false))
	{
		Kick(playerid);
		
		return 1;
	}
    
    
    
	new playerClient[12];
	
    GetPlayerVersion(playerid, playerClient, sizeof playerClient);
    
    if(strfind(playerClient, samp_current_version, false) == -1)
    {
		Kick(playerid);
		
		return 1;
	}
	
	
	
	new ipCounter;
	
	GetPlayerIp(playerid, Player[playerid][IP], 16);
	mysql_real_escape_string(Player[playerid][IP], Player[playerid][IP], mysqlHandle, 16);
	
	foreach_p(i)
	{
	    if((i == playerid) || strcmp(Player[playerid][IP], Player[i][IP], true))
		{
			continue;
		}
		
	    if(++ipCounter > 2)
	    {
	        Kick(playerid);
	    	
	    	return 1;
		}
	}
	
	
	
	if(GetGVarInt("Locked"))
	{
	    SendClientMessage(playerid, -1, "[Инфо]: {AFAFAF}Сервер закрыт! {FF0000}(Кик) {FFFF00}| {FFFFFF}[Info]: {AFAFAF}Server locked! {FF0000}(Kick)");
	    Kick(playerid);
	    
	    SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}попытался зайти на закрытый сервер и был кикнут", Player[playerid][Name]);
	    
	    return 1;
	}
	

	
	new playerIP[16];
	new playerSerial[129];
	
	SetPVarInt(playerid, "Connected", true);
	SetPlayerColor(playerid, GetGVarInt("Connect_Color"));
	SetPlayerFightingStyle(playerid, 6);
	
	gpci(playerid, playerSerial, sizeof playerSerial);
	
	strcpy(playerIP, Player[playerid][IP]);
	strdel(playerIP, strfind(playerIP, ".", false, 4), strlen(playerIP));
	strcat(playerSerial, playerIP);
	
	
	
	new query[192];
	
	mysql_format(mysqlHandle, query, sizeof query, "SELECT * FROM `banlist` WHERE `serial` = SHA2('%s', 512) LIMIT 1", playerSerial);
    mysql_function_query(mysqlHandle, query, true, "OnPlayerBanCheck", "i", playerid);
    
    PlayAudioStreamForPlayer(playerid, "http://127.0.0.1/intro.mp3");
	SetPVarInt(playerid, "audio_play", true);
	
	CreatePlayerTextDraws(playerid);
	
	for(new i = 74; i != -1; --i)
	{
		TextDrawShowForPlayer(playerid,Server[Gradient][i]);
	}
	
	for(new i = 2; i != -1; --i)
	{
		TextDrawShowForPlayer(playerid,Server[Barrier][i]);
	}
	
	TextDrawShowForPlayer(playerid,Server[ArenaAndTime]);
	TextDrawShowForPlayer(playerid,Server[Main]);
	
	for(new i = 24; i != -1; --i)
	{
		SendClientMessage(playerid, -1, "\0");
	}
	
	SendClientMessage(playerid, -1, "[Инфо]: {AFAFAF}Настройки сервера:");
	SendClientMessage(playerid, -1, "\0");
	SendClientMessageF(playerid, -1, "[Инфо]: {FFFF00}onfoot_rate: %i", GetServerVarAsInt("onfoot_rate"));
	SendClientMessageF(playerid, -1, "[Инфо]: {FFFF00}incar_rate: %i", GetServerVarAsInt("incar_rate"));
	SendClientMessageF(playerid, -1, "[Инфо]: {FFFF00}weapon_rate: %i", GetServerVarAsInt("weapon_rate"));
	SendClientMessageF(playerid, -1, "[Инфо]: {FFFF00}stream_rate: %i", GetServerVarAsInt("stream_rate"));
	SendClientMessage(playerid, -1, "\0");
	SendClientMessage(playerid, -1, "[Инфо]: {FFFF00}/cmd {AFAFAF}- основные комманды {FFFFFF}| {FFFF00}/help {AFAFAF}- помощь по моду");
	SendClientMessage(playerid, -1, "[Инфо]: {AFAFAF}На сервере стоит антибаг на {FF0000}+C, Slide, Knife Bug, Grenade Bug");
	SendClientMessage(playerid, -1, "[Инфо]: {AFAFAF}Опробуйте новый игровой режим: {FF0000}CTF (Capture The Flag, захват флага)");
	SendClientMessage(playerid, -1, "\0");
	
	if(strcmp(playerClient, samp_current_version, false))
	{
		SendClientMessageF(playerid, -1, "[Инфо]: {AFAFAF}Ваша версия клиента {FF0000}(%s) {AFAFAF}устарела", playerClient);
		SendClientMessage(playerid, -1, "[Инфо]: {AFAFAF}Установите новую версию клиента {FF0000}" #samp_current_version " {AFAFAF}для более комфортной игры");
	}
	
	TogglePlayerSpectating(playerid, true);
	CallLocalFunction("Intro", "i", playerid);
	
	return 1;
}



public Audio_OnClientConnect(playerid)
{
	if(!IsPlayerConnected(playerid))
	{
	    printf("Audio: Client %i connected before in-game join, or player already disconnected", playerid);
	    
	    return 1;
	}

    Audio_TransferPack(playerid);

	return 1;
}



public OnPlayerDisconnect(playerid, reason)
{
	Player[playerid][pConnect] = false;
	SetPVarInt(playerid, "Connected", false);
	Update3DTextLabelText(Player[playerid][AtHead], -1, " ");
    DestroyPlayerTextDraws(playerid);
    
	foreach_p(i)
	{
		if((i == playerid) || (GetPVarInt(i, "SpecID") != playerid))
		{
			continue;
		}
		
		AdvanceSpectate(i);
	}
	
	if(GetPVarInt(playerid,"SpecID") != -1)
	{
		StopSpectate(playerid);
	}
	
	if(!strfind(Player[playerid][Name], "AFK_", false))
	{
		strdel(Player[playerid][Name], 0, 4);
		SetPlayerName(playerid, Player[playerid][Name]);
	}
	
	if((Server[Current] != -1) && GetPVarInt(playerid, "Playing"))
	{
	    switch(reason)
	    {
	        case 0:
			{
				SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}вышел из игры {FF0000}(Обрыв связи) {FFFF00}[Здоровье: %.1f]", Player[playerid][Name], GetPVarFloat(playerid, "LastHealth"));
			}
			
	        case 1:
			{
				SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}вышел из игры {FF0000}(Выход) {FFFF00}[Здоровье: %.1f]", Player[playerid][Name], GetPVarFloat(playerid, "LastHealth"));
				GivePVarInt(playerid, "RunsFromRound", 1);
			}
		}
		
		if(GetGVarInt("GameType") == Gametype_CTF)
		{
		    new
		        Float:float_data[3]
			;
			GetPlayerPos(playerid,float_data[0],float_data[1],float_data[2]);
			
		    switch(GetPVarInt(playerid,"Team"))
		    {
		        case Team_Attack:
		        {
		            if(playerid == CTF[Server[Current]][FlagOwner][1])
		            {
		                CTF[Server[Current]][FlagOwner][1] = 0xFFFF;
						if(IsValidObject(CTF[Server[Current]][Flag][1]))
						{
							DestroyObject(CTF[Server[Current]][Flag][1]);
						}
						else
						{
							DestroyPickup(CTF[Server[Current]][Flag][1]);
						}
						CTF[Server[Current]][Flag][1] = CreatePickup(Blue_Flag,Pickup_Type,float_data[0],float_data[1],float_data[2] + 1.0,Round_VW);
						SendClientMessageToAll(-1,"[Инфо]: {00FF40}Комманда атакеров потеряла флаг противника!");
					}
				}
				case Team_Defend:
		        {
		            if(playerid == CTF[Server[Current]][FlagOwner][0])
		            {
		                CTF[Server[Current]][FlagOwner][0] = 0xFFFF;
						if(IsValidObject(CTF[Server[Current]][Flag][0]))
						{
							DestroyObject(CTF[Server[Current]][Flag][0]);
						}
						else
						{
							DestroyPickup(CTF[Server[Current]][Flag][0]);
						}
						CTF[Server[Current]][Flag][0] = CreatePickup(Red_Flag,Pickup_Type,float_data[0],float_data[1],float_data[2] + 1.0,Round_VW);
						SendClientMessageToAll(-1,"[Инфо]: {00FF40}Комманда дефендеров потеряла флаг противника!");
					}
				}
			}
		}
	}
	else
	{
	    switch(reason)
	    {
	        case 0:
			{
				SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}вышел из игры {FF0000}(Обрыв связи)", Player[playerid][Name]);
			}
			
	        case 1:
			{
				SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}вышел из игры {FF0000}(Выход)", Player[playerid][Name]);
			}
		}
	}
	
	if(GetPVarInt(playerid, "Logged"))
	{
		CallLocalFunction("OnPlayerSaved", "i", playerid);
	}
	
	if(GetGVarInt("VoteKick_Voted", playerid))
	{
		GiveGVarInt("VoteKick_Votes", -1, 0);
	}
	
	if(GetGVarInt("VoteBan_Voted", playerid))
	{
		GiveGVarInt("VoteBan_Votes", -1, 0);
	}
	
	if(playerid == GetGVarInt("VoteKick_ID"))
	{
		StopVoteKick();
	}
	
	if(playerid == GetGVarInt("VoteBan_ID"))
	{
		StopVoteBan();
	}
	
	Player[playerid][Name][0] = 0;
	Player[playerid][IP][0] = 0;
	
	playerid = cvector_find(playersVector, playerid);
	
	if(playerid != -1)
	{
		cvector_remove(playersVector, playerid);
	}
	
	return 1;
}



public Audio_OnClientDisconnect(playerid)
{
	DeletePVar(playerid, "audio_play");

	if(IsPlayerConnected(playerid))
	{
	    printf("Audio: Client %i disconnected before in-game leave", playerid);
	    
	    return 1;
	}

	return 1;
}



public Audio_OnTransferFile(playerid, file[], current, total, result)
{
	if(current == total)
	{
	    SetPVarInt(playerid, "audio_ready", true);
	}

	return 1;
}



public Audio_OnPlay(playerid, handleid)
{
	SetPVarInt(playerid, "audio_play", true);

	return 1;
}



public Audio_OnStop(playerid, handleid)
{
	DeletePVar(playerid, "audio_play");

	return 1;
}



public Audio_OnTrackChange(playerid, handleid, track[])
{
	return 1;
}



public Audio_OnRadioStationChange(playerid, station)
{
	return 1;
}



public Audio_OnGetPosition(playerid, handleid, seconds)
{
	return 1;
}



public OnPlayerText(playerid, text[])
{
	if((GetTickCount() - GetPVarInt(playerid, "Text_Time")) <= 2000)
	{
		GivePVarInt(playerid, "Flooder", 1);
		
		if(GetPVarInt(playerid, "Flooder") > 10)
		{
			mysql_ban(playerid, INVALID_PLAYER_ID, -1, "Флуд-атакер (флуд в чат)", "AntiFlood");
			
			return 1;
		}
		
		SendClientMessage(playerid, -1, "[Инфо]: {AFAFAF}Хорош флудить!");
		
		return 0;
	}
	
	SetPVarInt(playerid, "Text_Time", GetTickCount());
	SetPVarInt(playerid, "Flooder", 0);

	if(isnull(text))
	{
	    return 0;
	}
	
	if(strlen(text) > 128)
	{
	    mysql_ban(playerid, INVALID_PLAYER_ID, -1, "Длина текста превышает лимит", "AntiHack");
	    
	    return 0;
	}

	if(emptyMessage(text))
	{
		SendClientMessage(playerid, -1, "[Ошибка]: {AFAFAF}Отправка пустых сообщений запрещена");
		
		return 0;
	}

    spaceGroupsToSpaces(text);
    trimSideSpaces(text);

    if(tooManyUpperChars(text))
	{
		SendClientMessage(playerid, -1, "[Инфо]: {AFAFAF}Отключи CAPS LOCK!");
		
		return 0;
	}
	
	if(!strfind(Player[playerid][Name], "AFK_", false))
	{
		strdel(Player[playerid][Name], 0, 4);
	}
	
	regex_replace_exid(text, textAdvertRegex, "{FF0000}РЕКЛАМА", text, 128);
	regex_replace_exid(text, ipAdvertRegex, "{FF0000}РЕКЛАМА", text, 128);
	
	if(((text[0] == '#') || (text[0] == '№')) && !isnull(text[1]) && !emptyMessage(text[1]) && (GetPVarInt(playerid,"Admin") > 0))
	{
	    foreach_p(i)
	    {
	        if(!GetPVarInt(i, "Admin"))
			{
				continue;
			}
			
	        SendClientMessageF(i, -1, "[Админ-чат]: {FF0000}%s {AFAFAF}[%i]: {FFFFFF}%s", Player[playerid][Name], playerid, text[1]);
		}
		
		return 0;
	}

	if((text[0] == '!') && !isnull(text[1]) && !emptyMessage(text[1]))
	{
	    switch(GetPVarInt(playerid, "Team"))
	    {
	        case Team_Attack, Team_Defend, Team_Refferee:
	        {
	            foreach_p(i)
				{
				    if(GetPVarInt(i, "Team") != GetPVarInt(playerid, "Team"))
					{
						continue;
					}
					
				    SendClientMessageF(i, GetPlayerColor(playerid), "[Комманда] %s {FFFF00}[%i]: {AFAFAF}%s", Player[playerid][Name], playerid, text[1]);
				}
				
				return 0;
			}
			default:
			{
				SendClientMessage(playerid, -1, "[Ошибка]: {AFAFAF}Вы не в комманде!");
				
				return 0;
			}
		}
	}
	
	if(GetPVarInt(playerid, "Muted"))
	{
		SendClientMessage(playerid, -1, "[Ошибка]: {AFAFAF}Вы заткнуты");
		
		return 0;
	}

	SendClientMessageToAllF(GetPlayerColor(playerid), "%s {FFFF00}[%i]: {FFFFFF}%s", Player[playerid][Name], playerid, text);
	
	return 0;
}



public OnPlayerUpdate(playerid)
{
	GivePVarInt(playerid, "AFK_Check_1", 1);
	
	if(GetPVarInt(playerid, "AFK_In"))
	{
		return 1;
	}
	
	new vID = GetPlayerVehicleID(playerid);
	
	if(vID != 0)
	{
	    if(!GetPVarInt(playerid, "STextDrawSet"))
		{
			SetPVarInt(playerid, "STextDrawSet", 1);
		}
		
	    new model = GetVehicleModel(vID);
		
		if(!IsPlane(model) && !IsHelicopter(model) && (GetPlayerSpeedXY(playerid) > 250.0) && (GetPlayerState(playerid) == 2))
		{
		    SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был автоматически забанен {FFFF00}(Причина: Спидхак)", Player[playerid][Name]);
		    return mysql_ban(playerid, INVALID_PLAYER_ID, -1, "Спидхак", "AntiCheat");
		}
		
		model -= 400;
		
		if((model & 0x80000000))
		{
			return 1;
		}
		
		new string[96];
		
		format(string, sizeof string, "~r~~h~~h~%s~n~~r~~h~Speed: %.1f KM/H~n~~r~Health: %i", CarList[model], GetPlayerSpeedXY(playerid), floatmul(floatdiv(floatsub(ReturnVehicleHealth(vID), 250.0), 750.0), 100.0));
		PlayerTextDrawSetString(playerid, Player[playerid][Speedometer], string);
		PlayerTextDrawShow(playerid, Player[playerid][Speedometer]);
		
		TextDrawShowForPlayer(playerid, Server[Barrier][3]);
		TextDrawShowForPlayer(playerid, Server[Barrier][4]);
	}
	else
	{
		if(GetPVarInt(playerid, "STextDrawSet"))
		{
			PlayerTextDrawHide(playerid, Player[playerid][Speedometer]);
			
			TextDrawHideForPlayer(playerid, Server[Barrier][3]);
			TextDrawHideForPlayer(playerid, Server[Barrier][4]);
			
			SetPVarInt(playerid, "STextDrawSet", 0);
		}
	}
	
	new drunk = GetPlayerDrunkLevel(playerid);
	
	if(drunk < 100)
	{
		SetPlayerDrunkLevel(playerid, 2000);
	}
	else
	{
		if(GetPVarInt(playerid, "Last_FPS") != drunk)
		{
			new fps = (GetPVarInt(playerid, "Last_FPS") - drunk);
			
			if((0 < fps < 200))
			{
				SetPVarInt(playerid, "FPS", --fps);
			}
			
			SetPVarInt(playerid, "Last_FPS", drunk);
		}
	}
	
	if(GetPVarInt(playerid, "Playing"))
	{
	    foreach_p(i)
		{
		    if(!GetPVarInt(i, "Playing") || (i == playerid))
			{
				continue;
			}
			
			if(GetPVarInt(playerid, "Team") != GetPVarInt(i, "Team"))
			{
				SetPlayerMarkerForPlayer(i, playerid, (GetPlayerColor(playerid) & 0xFFFFFF00));
			}
			else
			{
				SetPlayerMarkerForPlayer(i, playerid, (GetPlayerColor(playerid) | 0x000000FF));
			}
		}
	}
	
	return 1;
}



public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	switch(source)
	{
	    default:
	    {
	        new
	            int_data[12]
			;
			
	        SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	        if(playerid == clickedplayerid) return CallLocalFunction("cmd_mystats","ds",playerid,"\1");
	        valstr(int_data,clickedplayerid);
			return CallLocalFunction("_spec","ds",playerid,int_data);
		}
	}
	return 1;
}



public OnPlayerRequestClass(playerid, classid)
{
    if(!GetPVarInt(playerid, "Logged"))
	{
		return 1;
	}
    
	switch(classid)
	{
	    case 0:
	    {
	        PlayerTextDrawSetString(playerid, Player[playerid][TeamText], "~l~>> ~r~~h~Attack ~l~<<     ~b~Defend     ~y~Refferee");
			PlayerTextDrawShow(playerid, Player[playerid][TeamText]);
			PlayerPlaySound(playerid, 33611, 0.0, 0.0, 0.0);
		}
		case 1:
		{
		    PlayerTextDrawSetString(playerid, Player[playerid][TeamText], "~r~Attack     ~l~>> ~b~~h~Defend ~l~<<     ~y~Refferee");
			PlayerTextDrawShow(playerid, Player[playerid][TeamText]);
			PlayerPlaySound(playerid, 35819, 0.0, 0.0, 0.0);
		}
		case 2:
		{
		    PlayerTextDrawSetString(playerid, Player[playerid][TeamText], "~r~Attack     ~b~Defend     ~l~>> ~y~~h~Refferee ~l~<<");
			PlayerTextDrawShow(playerid, Player[playerid][TeamText]);
			PlayerPlaySound(playerid, 35202, 0.0, 0.0, 0.0);
		}
	}
	
	return 1;
}



public OnPlayerRequestSpawn(playerid)
{
    if(GetPVarInt(playerid, "Camera_0"))
	{
		SendClientMessage(playerid, -1, "[Ошибка]: {AFAFAF}Вы не можете заспавниться во время показа интро");
		
		return 0;
	}
	
	if(!GetPVarInt(playerid, "Logged"))
	{
		SendClientMessage(playerid, -1, "[Ошибка]: {AFAFAF}Сначала войдите в аккаунт!");
		
		return 0;
	}

	TeamFix(playerid);
	
	TextDrawHideForPlayer(playerid,Server[BlackFullScreen]);
	PlayerTextDrawHide(playerid,Player[playerid][IntroLetters]);
	PlayerTextDrawHide(playerid,Player[playerid][TeamText]);
	PlayerTextDrawHide(playerid,Player[playerid][Dot]);
	
	if(GetPVarInt(playerid, "audio_play"))
	{
	    StopAudioStreamForPlayer(playerid);
	    
	    DeletePVar(playerid, "audio_play");
	}
	
	return 1;
}



public OnVehicleSpawn(vehicleid)
{
	if(vehicleid >= MAX_VEHICLES)
	{
		DestroyVehicle(vehicleid);
	}
	
	cvector_push_back(vehiclesVector, vehicleid);
	
	return 1;
}



public OnVehicleDeath(vehicleid, killerid)
{
	DestroyVehicleEx(vehicleid);
	
	vehicleid = cvector_find(vehiclesVector, vehicleid);

	if(vehicleid != -1)
	{
	    cvector_remove(vehiclesVector, vehicleid);
	}
	
	return 1;
}



public OnVehicleMod(playerid, vehicleid, componentid)
{
	if(!GetPlayerInterior(playerid) && (GetPlayerState(playerid) == 2))
	{
	    RemoveVehicleComponent(vehicleid, componentid);
	    SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был автоматически забанен {FFFF00}(Причина: Крашер)", Player[playerid][Name]);
	    mysql_ban(playerid, INVALID_PLAYER_ID, -1, "Крашер", "AntiHack");
	    
	    return 0;
	}
	
	return 1;
}



public OnPlayerExitVehicle(playerid, vehicleid)
{
	if(ReturnVehicleHealth(vehicleid) <= 250.0)
	{
		DestroyVehicleEx(vehicleid);
	}
	
	return 1;
}



public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	if(ReturnVehicleHealth(vehicleid) <= 250.0)
	{
		SendClientMessage(playerid, -1, "[Инфо]: {AFAFAF}Этой тачке пиздец, так что не советую в нее заходить");
		ClearAnimations(playerid, true);
	}
	
	return 1;
}



public OnPlayerStateChange(playerid, newstate, oldstate)
{
	switch(newstate)
	{
	    case PLAYER_STATE_DRIVER:
	    {
	        new seat = GetPlayerVehicleSeat(playerid);
	        
	        SetPVarInt(playerid, "MassCarSpawn", GetTickCount());

			if(seat != 128)
			{
				if(!seat)
				{
					seat = GetVehicleModel(GetPlayerVehicleID(playerid));
					if(!(400 <= seat <= 611) || ((MaxPassengers[seat - 400 >>> 3] >>> (((seat - 400) & 7) << 2) & 15) == 15))
					{
						Kick(playerid);
						
						return 1;
					}
				}
				else
				{
					Kick(playerid);
					
					return 1;
				}
			}
			
			if(GetPVarInt(playerid, "audio_play"))
	        {
	            Audio_StopRadio(playerid);
			}
			
	        foreach_p(i)
			{
				if(GetPlayerVehicleID(playerid) != GetPVarInt(i, "CarID"))
				{
					continue;
				}
				
				SetPVarInt(i, "CarID", INVALID_VEHICLE_ID);
				SetPVarInt(playerid, "CarID", GetPlayerVehicleID(playerid));
			}
			
			foreach_p(i)
		    {
		        if(GetPVarInt(i, "SpecID") != playerid)
				{
					continue;
				}
				
		        SetPlayerVirtualWorld(i, GetPlayerVirtualWorld(playerid));
			    SetPlayerInterior(i, GetPlayerInterior(playerid));
		        TogglePlayerSpectating(i, true);
		        PlayerSpectateVehicle(i, GetPlayerVehicleID(playerid));
			}
		}
		
		case PLAYER_STATE_PASSENGER:
		{
		    new model = GetVehicleModel(GetPlayerVehicleID(playerid));
		    
			if((400 <= model <= 611))
			{
				model -= 400;
				
				new seat = GetPlayerVehicleSeat(playerid);
				
				if(seat != 128)
				{
					model = ((MaxPassengers[model >>> 3] >>> ((model & 7) << 2)) & 15);
					
					if(!model || (model == 15))
					{
						Kick(playerid);
						
						return 1;
					}
					else if(!(0 < seat <= model))
					{
						Kick(playerid);
						
						return 1;
					}
				}
				else
				{
					Kick(playerid);
					
					return 1;
				}
			}
			
			if(GetPVarInt(playerid, "audio_play"))
	        {
	            Audio_StopRadio(playerid);
			}
			
		    foreach_p(i)
		    {
		        if(GetPVarInt(i, "SpecID") != playerid)
				{
					continue;
				}
				
		        SetPlayerVirtualWorld(i, GetPlayerVirtualWorld(playerid));
			    SetPlayerInterior(i, GetPlayerInterior(playerid));
		        TogglePlayerSpectating(i, true);
		        PlayerSpectateVehicle(i, GetPlayerVehicleID(playerid));
			}
		}
		
		case PLAYER_STATE_ONFOOT:
		{
		    foreach_p(i)
		    {
		        if(GetPVarInt(i, "SpecID") != playerid)
				{
					continue;
				}
				
		        SetPlayerVirtualWorld(i, GetPlayerVirtualWorld(playerid));
			    SetPlayerInterior(i, GetPlayerInterior(playerid));
		        TogglePlayerSpectating(i, true);
		        PlayerSpectatePlayer(i, playerid);
			}
		}
	}
	
	switch(oldstate)
	{
	    case PLAYER_STATE_DRIVER:
	    {
	        if((GetTickCount() - GetPVarInt(playerid, "MassCarSpawn")) <= 250)
	        {
	            SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был автоматически забанен {FFFF00}(Причина: CarSpawn)", Player[playerid][Name]);
				mysql_ban(playerid, INVALID_PLAYER_ID, -1, "CarSpawn", "AntiHack");
				
				return 1;
			}
		}
	}
	
	if(GetGVarInt("AntiCheat_Load"))
	{
	    if(((newstate == PLAYER_STATE_DRIVER) && (oldstate == PLAYER_STATE_PASSENGER)) || ((newstate == PLAYER_STATE_PASSENGER) && (oldstate == PLAYER_STATE_DRIVER)))
	    {
	        SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был автоматически забанен {FFFF00}(Причина: Cleo Loading)", Player[playerid][Name]);
			mysql_ban(playerid, INVALID_PLAYER_ID, -1, "Cleo Loading", "AntiHack");
			
			return 1;
		}
	}
	
	return 1;
}



public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(GetPVarInt(playerid,"SpecID") != -1)
	{
	    if(newkeys & 65536 || newkeys & 16384 || newkeys & 4) return AdvanceSpectate(playerid);
	    if(newkeys & 131072 || newkeys & 8192 || newkeys & 128) return ReverseSpectate(playerid);
	    if(newkeys & 8)
		{
		    SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
			return CallLocalFunction("cmd_specoff","ds",playerid,"\1");
		}
	}

	if(JustDown(16384))
	{
	    SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
		return CallLocalFunction("cmd_rsp","ds",playerid,"\1");
	}

	if(Pressed(4) && GetPlayerState(playerid) == 2)
	{
		AddVehicleComponent(GetPlayerVehicleID(playerid),1010);
	}
	else
	{
		RemoveVehicleComponent(GetPlayerVehicleID(playerid),1010);
	}

	if(JustDown(8192))
	{
	    if(!GetPVarInt(playerid,"Playing")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы должны находиться в раунде");
	    if((GetTickCount() - GetPVarInt(playerid,"Mayak_Time")) <= (20 * 1000)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете использовать маячок слишком часто");

		new
		    string_data[32]
		;
		
		SetPVarInt(playerid,"Mayak_Time",GetTickCount());
	    GetGVarString("Mayak",string_data,32,random(6));
	    foreach_p(i)
	    {
	        if(GetPVarInt(i,"Team") != GetPVarInt(playerid,"Team") || !GetPVarInt(i,"Playing")) continue;
	        SendClientMessageF(i,GetPlayerColor(playerid),"[Команда] {00FF40}%s: {FFFF00}%s",Player[playerid][Name],string_data);
            PlayerPlaySound(i,1083,0,0,0);
			if(i == playerid) continue;
	        SetPlayerMarkerForPlayer(i,playerid,0xAFAFAFFF);
		}
		
		SetTimerEx("Marker",10000,false,"d",playerid);
		
		return 1;
	}

	#define CBUG_COMBINATION(%0,%1) \
	    ((%0 & KEY_FIRE) || (%0 & KEY_CROUCH) || (%0 & KEY_SPRINT)) && ((%1 & KEY_FIRE) || (%1 & KEY_CROUCH) || (%1 & KEY_SPRINT))
	if(CBUG_COMBINATION(newkeys,oldkeys) && IsBugWeapon(GetPlayerWeapon(playerid)) && GetPVarInt(playerid,"Playing") && GetGVarInt("AntiBug_C") && (GetTickCount() - GetPVarInt(playerid,"CBug_Time")) >= 500)
	{
	    SetPVarInt(playerid,"CBug_Time",GetTickCount());
		SetTimerEx("CBugCheck",500,false,"d",playerid);
	}

	if(((newkeys & 4) || (oldkeys & 4)) && ((GetPlayerWeapon(playerid) == 16) || (GetPlayerWeapon(playerid) == 17)) && GetPVarInt(playerid,"Playing") && GetGVarInt("AntiBug_G") && (GetTickCount() - GetPVarInt(playerid,"GBug_Time")) >= 1500)
	{
	    GetPlayerWeaponData(playerid,8,PlayerWeapons[playerid][0][8],PlayerWeapons[playerid][1][8]);
	    SetPVarInt(playerid,"GBug_Time",GetTickCount());
		SetTimerEx("GBugCheck",1500,false,"ddd",playerid,PlayerWeapons[playerid][0][8],PlayerWeapons[playerid][1][8]);
	}
	
	return 1;
}



public OnPlayerPickUpPickup(playerid, pickupid)
{
	if(Server[Current] == -1 || GetGVarInt("GameType") != Gametype_CTF || !GetPVarInt(playerid,"Playing")) return 1;
	
	switch(GetPVarInt(playerid,"Team"))
	{
	    case Team_Attack:
	    {
	        if(GetGVarInt("GameType") == Gametype_CTF)
	        {
		        if(pickupid == CTF[Server[Current]][Flag][0])
		        {
					if(!PlayerToPoint(10.0,playerid,CTF[Server[Current]][ACP][0],CTF[Server[Current]][ACP][1],CTF[Server[Current]][ACP][2]))
					{
					    SendClientMessageToAll(-1,"[Инфо]: {00FF40}Комманда атакеров вернула свой флаг на базу");
					    CTF[Server[Current]][FlagOwner][0] = 0xFFFF;
					    DestroyPickup(CTF[Server[Current]][Flag][0]);
						CTF[Server[Current]][Flag][0] = CreatePickup(Red_Flag,Pickup_Type,CTF[Server[Current]][ACP][0],CTF[Server[Current]][ACP][1],CTF[Server[Current]][ACP][2] + 1.0,Round_VW);
						return 1;
					}
					return 1;
				}
		        else if(pickupid == CTF[Server[Current]][Flag][1])
		        {
		            SendClientMessageToAll(-1,"[Инфо]: {00FF40}Комманда атакеров завладела вражеским флагом!");
					CTF[Server[Current]][FlagOwner][1] = playerid;
					DestroyPickup(CTF[Server[Current]][Flag][1]);
		            CTF[Server[Current]][Flag][1] = CreateObject(Blue_Flag,0.0,0.0,0.0,0.0,0.0,0.0);
		            AttachObjectToPlayer(CTF[Server[Current]][Flag][1],playerid,0.0,-0.25,-0.15,0.0,0.0,0.0);
		            return 1;
				}
			}
		}
		case Team_Defend:
		{
		    if(GetGVarInt("GameType") == Gametype_CTF)
		    {
			    if(pickupid == CTF[Server[Current]][Flag][1])
		        {
					if(!PlayerToPoint(10.0,playerid,CTF[Server[Current]][DCP][0],CTF[Server[Current]][DCP][1],CTF[Server[Current]][DCP][2]))
					{
					    SendClientMessageToAll(-1,"[Инфо]: {00FF40}Комманда атакеров вернула свой флаг на базу");
					    CTF[Server[Current]][FlagOwner][1] = 0xFFFF;
					    DestroyPickup(CTF[Server[Current]][Flag][1]);
						CTF[Server[Current]][Flag][1] = CreatePickup(Blue_Flag,Pickup_Type,CTF[Server[Current]][DCP][0],CTF[Server[Current]][DCP][1],CTF[Server[Current]][DCP][2] + 1.0,Round_VW);
						return 1;
					}
					return 1;
				}
		        else if(pickupid == CTF[Server[Current]][Flag][0])
		        {
		            SendClientMessageToAll(-1,"[Инфо]: {00FF40}Комманда дефендеров завладела вражеским флагом!");
					CTF[Server[Current]][FlagOwner][0] = playerid;
					DestroyPickup(CTF[Server[Current]][Flag][0]);
		            CTF[Server[Current]][Flag][0] = CreateObject(Red_Flag,0.0,0.0,0.0,0.0,0.0,0.0);
		            AttachObjectToPlayer(CTF[Server[Current]][Flag][0],playerid,0.0,-0.25,-0.15,0.0,0.0,0.0);
		            return 1;
				}
			}
		}
		default: return 1;
	}
	
	return 1;
}



public OnPlayerTakeDamage(playerid, issuerid, Float:amount, weaponid)
{
	if(GetPVarInt(playerid,"Killed"))
	{
	    SetPVarInt(playerid,"Killed",0);
	    return 1;
	}
	
	new string[128];
	new Float:health;
	
    GivePVarFloat(playerid, "HP_Combo", amount);

	health = floatabs(floatsub(ReturnPlayerHealth(playerid), amount));
	SetPVarFloat(playerid, "LastHealth", health);
	
	if(GetPVarInt(playerid, "Playing"))
	{
		SetPlayerScore(playerid, floatround(health));
	}
	
	format(string, sizeof string, "~r~~h~-%.0f~n~~r~Health: %.0f", GetPVarFloat(playerid, "HP_Combo"), health);
	PlayerTextDrawSetString(playerid, Player[playerid][HealthMinus], string);
	PlayerTextDrawShow(playerid, Player[playerid][HealthMinus]);
	
	TextDrawShowForPlayer(playerid,Server[Barrier][5]);
	TextDrawShowForPlayer(playerid,Server[Barrier][6]);
	
	format(string, sizeof string, "HP: %.0f", health);
	PlayerTextDrawSetString(playerid, Player[playerid][HealthBar], string);
	PlayerTextDrawShow(playerid, Player[playerid][HealthBar]);
	
	if(GetPVarInt(playerid, "ClearTimer") != -1)
	{
		KillTimer(GetPVarInt(playerid, "ClearTimer"));
	}
	
	SetPVarInt(playerid, "ClearTimer", SetTimerEx("ClearMinusHealth", 2500, false, "i", playerid));
	
	if(GetPVarInt(issuerid, "Connected"))
	{
	    if((GetPVarInt(playerid, "DuelID") == -1) && (GetPVarInt(issuerid, "DuelID") == -1))
	    {
		    if(!GetPVarInt(playerid, "Playing") || !GetPVarInt(issuerid, "Playing"))
			{
				return 1;
			}
			
		    if(GetPVarInt(playerid, "Team") == GetPVarInt(issuerid,"Team"))
			{
				return 1;
			}
	    }
	    else
		{
			format(string, sizeof string, "-%.0f HP", GetPVarFloat(playerid, "HP_Combo"));
			Update3DTextLabelText(Player[playerid][AtHead], GetPlayerColor(playerid), string);
		}
		
		GivePVarInt(issuerid, "ShootCombo", 1);

		format(string, sizeof string, "%s~n~%s (-%.0f HP, %ix Combo)~n~Ping: %i / FPS: %i~n~Distance: %.1fm", Player[playerid][Name], WeaponNames[weaponid], GetPVarFloat(playerid, "HP_Combo"), GetPVarInt(issuerid,"ShootCombo"), GetPlayerPing(playerid), GetPVarInt(playerid, "FPS"), GetDistanceBetweenPlayers(issuerid, playerid));
		PlayerTextDrawSetString(issuerid, Player[issuerid][Damage][0], string);
		PlayerTextDrawShow(issuerid, Player[issuerid][Damage][0]);
		
		format(string, sizeof string, "%s~n~%s (-%.0f HP, %ix Combo)~n~Ping: %i / FPS: %i~n~Distance: %.1fm", Player[issuerid][Name], WeaponNames[weaponid], GetPVarFloat(playerid, "HP_Combo"), GetPVarInt(issuerid,"ShootCombo"), GetPlayerPing(issuerid), GetPVarInt(issuerid, "FPS"), GetDistanceBetweenPlayers(issuerid, playerid));
		PlayerTextDrawSetString(playerid, Player[playerid][Damage][1], string);
		PlayerTextDrawShow(playerid, Player[playerid][Damage][1]);
		
		if(GetPVarInt(issuerid, "DamageTimer") != -1)
		{
			KillTimer(GetPVarInt(issuerid, "DamageTimer"));
		}
		
		SetPVarInt(issuerid, "DamageTimer", SetTimerEx("HideDamage", 2500, false, "i", issuerid));
		
		if(GetPVarInt(playerid, "DamageTimer") != -1)
		{
			KillTimer(GetPVarInt(playerid, "DamageTimer"));
		}
		
		SetPVarInt(playerid, "DamageTimer", SetTimerEx("HideDamage", 2500, false, "i", playerid));
	}
	
	return 1;
}



public OnPlayerDeath(playerid, killerid, reason)
{
	SetPVarInt(playerid, "Spawned", 0);
	SetPVarInt(playerid, "Change_Weapon", 0);
	SetPVarInt(playerid, "ComboKills", 0);
	SetPVarFloat(playerid,"LastHealth", 0.0);
	
	if(GetPVarInt(playerid,"ComboTimer") != -1)
	{
		KillTimer(GetPVarInt(playerid, "ComboTimer"));
	}
	
	SetPVarInt(playerid, "ComboTimer", -1);
	GivePVarInt(playerid, "MassDeaths", 1);
	
	if(GetPVarInt(playerid, "MassDeaths") > 1)
	{
	    SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был автоматически забанен {FFFF00}(Причина: FakeKill флуд)", Player[playerid][Name]);
	    mysql_ban(playerid, INVALID_PLAYER_ID, -1, "FakeKill флуд", "AntiHack");
	    
	    return 1;
	}
	
	if(killerid == playerid)
	{
	    SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был автоматически забанен {FFFF00}(Причина: Selfkill)", Player[playerid][Name]);
	    mysql_ban(playerid, INVALID_PLAYER_ID, -1, "Selfkill", "AntiHack");
	    
	    return 1;
	}
	
	new
		string_data[128],
		Float:float_data[3]
	;
	
	TextDrawShowForPlayer(playerid,Server[RedFullScreen]);
	
	PlayerTextDrawSetString(playerid, Player[playerid][HealthBar], "HP: 0");
	PlayerTextDrawShow(playerid, Player[playerid][HealthBar]);
	
	GetPlayerPos(playerid,float_data[0],float_data[1],float_data[2]);
	SetPlayerCameraPos(playerid,floatadd(float_data[0],floatrandom(10)),floatadd(float_data[1],floatrandom(10)),floatadd(float_data[2],5.0));
	SetPlayerCameraLookAt(playerid,float_data[0],float_data[1],float_data[2]);
	if(GetPVarInt(playerid,"CarID") != 0xFFFF)
	{
		DestroyVehicleEx(GetPVarInt(playerid,"CarID"),playerid);
	}
	if(GetPVarInt(playerid,"DM_Zone") != -1)
	{
	    GivePVarInt(playerid,"DM_Deaths",1);
	    GivePVarInt(killerid,"DM_Kills",1);
	    GangZoneHideForPlayer(playerid,GetGVarInt("DM_GZ_1",GetPVarInt(playerid,"DM_Zone")));
	    GangZoneHideForPlayer(playerid,GetGVarInt("DM_GZ_2",GetPVarInt(playerid,"DM_Zone")));
	    GangZoneHideForPlayer(playerid,GetGVarInt("DM_GZ_3",GetPVarInt(playerid,"DM_Zone")));
	    GangZoneHideForPlayer(playerid,GetGVarInt("DM_GZ_4",GetPVarInt(playerid,"DM_Zone")));
	    format(string_data,128,"Убийца: %s (ID: %i)\nОружие: %s\nРасстояние: %.2f",Player[killerid][Name],killerid,WeaponNames[reason],GetDistanceBetweenPlayers(playerid,killerid));
	    Update3DTextLabelText(Player[playerid][AtHead],GetPlayerColor(killerid),string_data);
	    SendClientMessageF(playerid,-1,"[Инфо]: {AFAFAF}Вас убил {FF0000}%s (ID: %i) {FFFF00}(Оружие: %s, Расстояние: %.2f)",Player[killerid][Name],killerid,WeaponNames[reason],GetDistanceBetweenPlayers(playerid,killerid));
	    SendClientMessageF(killerid,-1,"[Инфо]: {AFAFAF}Вы убили {FF0000}%s (ID: %i) {FFFF00}(Оружие: %s, Расстояние: %.2f)",Player[playerid][Name],playerid,WeaponNames[reason],GetDistanceBetweenPlayers(playerid,killerid));
	    return PlayerPlaySound(killerid,1150,0.0,0.0,0.0);
	}
	if(GetPVarInt(playerid,"DuelID") != -1)
	{
	    format(string_data,128,"Убийца: %s (ID: %i)\nОружие: %s\nРасстояние: %.2f",Player[killerid][Name],killerid,WeaponNames[reason],GetDistanceBetweenPlayers(playerid,killerid));
	    Update3DTextLabelText(Player[playerid][AtHead],GetPlayerColor(killerid),string_data);
	    SendClientMessageF(playerid,-1,"[Инфо]: {AFAFAF}Вас убил {FF0000}%s (ID: %i) {FFFF00}(Оружие: %s, Расстояние: %.2f)",Player[killerid][Name],killerid,WeaponNames[reason],GetDistanceBetweenPlayers(playerid,killerid));
	    SendClientMessageF(killerid,-1,"[Инфо]: {AFAFAF}Вы убили {FF0000}%s (ID: %i) {FFFF00}(Оружие: %s, Расстояние: %.2f)",Player[playerid][Name],playerid,WeaponNames[reason],GetDistanceBetweenPlayers(playerid,killerid));
	    return PlayerPlaySound(killerid,1150,0.0,0.0,0.0);
	}
	SetPlayerColor(playerid,GetGVarInt("Team_Color_L",GetPVarInt(playerid,"Team")));
	
    foreach_p(i)
	{
		if(GetPVarInt(i,"SpecID") != playerid) continue;
		AdvanceSpectate(i);
	}
	
	if(GetPVarInt(playerid,"Playing"))
	{
	    SetPVarInt(playerid,"Playing",0);
	    SetPlayerScore(playerid,0);
	    DisablePlayerCheckpoint(playerid);
	    
	    new
	        i, x
		;
		
	    switch(GetGVarInt("GameType"))
	    {
		    case Gametype_Arena:
		    {
				for(i = 2; i != -1; --i)
				{
				    for(x = 4; x != -1; --x)
				    {
				    	GangZoneHideForPlayer(playerid,Number[i][Zone][x]);
				    }
				}
				for(i = 3; i != -1; --i)
				{
					GangZoneHideForPlayer(playerid,Arena[Server[Current]][GangZone][i]);
				}
			}
			case Gametype_CTF:
	        {
				for(i = 2; i != -1; --i)
				{
				    for(x = 4; x != -1; --x)
				    {
				    	GangZoneHideForPlayer(playerid,Number[i][Zone][x]);
				    }
				}
				for(i = 3; i != -1; --i)
				{
					GangZoneHideForPlayer(playerid,CTF[Server[Current]][GangZone][i]);
				}
				switch(GetPVarInt(playerid,"Team"))
				{
				    case Team_Attack:
				    {
				        if(playerid == CTF[Server[Current]][FlagOwner][1])
				        {
				            SendClientMessageToAll(-1,"[Инфо]: {00FF40}Комманда атакеров потеряла флаг противника!");
				            CTF[Server[Current]][FlagOwner][1] = 0xFFFF;
				            if(IsValidObject(CTF[Server[Current]][Flag][1]))
							{
								DestroyObject(CTF[Server[Current]][Flag][1]);
							}
				            else
							{
								DestroyPickup(CTF[Server[Current]][Flag][1]);
							}
				            CTF[Server[Current]][Flag][1] = CreatePickup(Blue_Flag,Pickup_Type,float_data[0],float_data[1],float_data[2] + 1.0,Round_VW);
						}
					}
					case Team_Defend:
				    {
				        if(playerid == CTF[Server[Current]][FlagOwner][0])
				        {
				            SendClientMessageToAll(-1,"[Инфо]: {00FF40}Комманда дефендеров потеряла флаг противника!");
				            CTF[Server[Current]][FlagOwner][0] = 0xFFFF;
				            if(IsValidObject(CTF[Server[Current]][Flag][0]))
							{
								DestroyObject(CTF[Server[Current]][Flag][0]);
							}
				            else
							{
								DestroyPickup(CTF[Server[Current]][Flag][0]);
							}
				            CTF[Server[Current]][Flag][0] = CreatePickup(Red_Flag,Pickup_Type,float_data[0],float_data[1],float_data[2] + 1.0,Round_VW);
						}
					}
				}
			}
		}
		if(killerid == 0xFFFF)
		{
			SendDeathMessage(500,playerid,reason);
		}
		else
		{
		    SendDeathMessage(killerid,playerid,reason);
		    format(string_data,128,"Убийца: %s (ID: %i)\nОружие: %s\nРасстояние: %.2f",Player[killerid][Name],killerid,WeaponNames[reason],GetDistanceBetweenPlayers(playerid,killerid));
		    Update3DTextLabelText(Player[playerid][AtHead],GetPlayerColor(killerid),string_data);
		    SendClientMessageF(playerid,-1,"[Инфо]: {AFAFAF}Вас убил {FF0000}%s (ID: %i) {FFFF00}(Оружие: %s, Расстояние: %.2f)",Player[killerid][Name],killerid,WeaponNames[reason],GetDistanceBetweenPlayers(playerid,killerid));
		    SendClientMessageF(killerid,-1,"[Инфо]: {AFAFAF}Вы убили {FF0000}%s (ID: %i) {FFFF00}(Оружие: %s, Расстояние: %.2f)",Player[playerid][Name],playerid,WeaponNames[reason],GetDistanceBetweenPlayers(playerid,killerid));
		    PlayerPlaySound(killerid,1150,0.0,0.0,0.0);
		    GivePVarInt(killerid,"Kills",1);
		    GivePVarInt(killerid,"ComboKills",1);
		    
		    if(reason == 4)
			{
			    if((GetTickCount() - GetPVarInt(killerid,"KnifeTick")) <= 7500)
			    {
			        SetPVarInt(playerid,"KnifeAdd",1);
			        return 1;
				}
				GivePVarInt(killerid,"KnifeKills",1);
				GivePVarInt(playerid,"KnifeDeaths",1);
			}
			
			switch(GetPVarInt(killerid,"ComboKills"))
			{
			    case 2..19:
			    {
			        if(GetPVarInt(killerid,"ComboTimer") != -1) return 1;
			        SetPVarInt(killerid,"ComboTimer",SetTimerEx("Kill",250,true,"dd",killerid,GetTickCount()));
				}
			}
		}
		GivePVarInt(playerid,"Deaths",1);
	}
	
	return 1;
}



public OnPlayerSpawn(playerid)
{
	new
	    string_data[48]
	;
	
	TogglePlayerControllable(playerid,true);
	SetPlayerSpecialAction(playerid, 0);
	SetPVarInt(playerid,"MassDeaths",0);
	if(GetPVarInt(playerid,"SyncSpawn"))
	{
	    SetPVarInt(playerid,"SyncSpawn",0);
	    SetPlayerPos(playerid,GetPVarFloat(playerid,"SyncPos_X"),GetPVarFloat(playerid,"SyncPos_Y"),GetPVarFloat(playerid,"SyncPos_Z"));
	    SetPlayerVelocity(playerid,GetPVarFloat(playerid,"SyncVelo_X"),GetPVarFloat(playerid,"SyncVelo_Y"),GetPVarFloat(playerid,"SyncVelo_Z"));
	    SetPlayerFacingAngle(playerid,GetPVarFloat(playerid,"SyncAng"));
	    SetPlayerHealth(playerid,GetPVarFloat(playerid,"SyncHealth"));
	    SetPlayerInterior(playerid,GetPVarInt(playerid,"SyncInt"));
		SetPlayerVirtualWorld(playerid,GetPVarInt(playerid,"SyncVW"));
		SetPlayerSkin(playerid,GetPVarInt(playerid,"SyncSkin"));
		SetPlayerSpecialAction(playerid,GetPVarInt(playerid,"SyncSpecAct"));
		SetPlayerColor(playerid,GetPVarInt(playerid,"SyncColor"));
		SetPlayerTeam(playerid,GetPVarInt(playerid,"SyncTeam"));
		SetPlayerScore(playerid,GetPVarInt(playerid,"SyncScore"));
		SetPlayerDrunkLevel(playerid,GetPVarInt(playerid,"SyncDLevel"));
		SetPlayerFightingStyle(playerid,GetPVarInt(playerid,"SyncFStyle"));
		ResetPlayerWeapons(playerid);
		
		for(new i = 12; i != -1; --i)
		{
			GivePlayerWeapon(playerid,PlayerWeapons[playerid][0][i],PlayerWeapons[playerid][1][i]);
		}
		
        SetCameraBehindPlayer(playerid);
		PlayerPlaySound(playerid,1057,0.0,0.0,0.0);
		SendClientMessageF(playerid,-1,"[Инфо]: {AFAFAF}Синхронизация проведена успешно {FFFFFF}| {AFAFAF}Время проведения синхронизации: {FFFF00}%i мсек",GetTickCount() - GetPVarInt(playerid,"SyncTick"));
		SendClientMessageToAllF(-1,"[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}синхронизировался",Player[playerid][Name]);
		valstr(string_data,playerid);
		
		foreach_p(i)
		{
			if(GetPVarInt(i,"SpecID") != playerid) continue;
   			SetPVarInt(i,"CMD_Time",(GetTickCount() - 2501));
   			CallLocalFunction("cmd_spec","ds",i,string_data);
		}
		
		return 1;
	}
	SetPVarInt(playerid,"Spawned",1);
	
	if(GetPVarInt(playerid,"KnifeAdd"))
	{
	    SendClientMessageToAllF(-1,"[Инфо]: {FF0000}%s {AFAFAF}был автоматически добавлен в раунд {FFFF00}(Причина: Жертва бага ножа)",Player[playerid][Name]);
	    SetPVarInt(playerid,"KnifeAdd",0);
	    return AddToRound(playerid);
	}
	
	TextDrawHideForPlayer(playerid,Server[RedFullScreen]);
	SetPlayerFightingStyle(playerid, 6);
	SetPlayerHealth(playerid, 100.0);
	
	PlayerTextDrawSetString(playerid, Player[playerid][HealthBar], "HP: 100");
	PlayerTextDrawShow(playerid, Player[playerid][HealthBar]);
	
	if(GetPVarInt(playerid,"DM_Zone") == -1)
	{
		ResetPlayerWeapons(playerid);
		switch(GetPVarInt(playerid,"Team"))
		{
		    case Team_Attack: SetPlayerSkin(playerid,GetGVarInt("Skin_Att"));
		    case Team_Defend: SetPlayerSkin(playerid,GetGVarInt("Skin_Def"));
		    case Team_Refferee: SetPlayerSkin(playerid,GetGVarInt("Skin_Ref"));
		}
		Attach3DTextLabelToPlayer(Player[playerid][AtHead],playerid,0.0,0.0,3.0);
		Update3DTextLabelText(Player[playerid][AtHead],GetPlayerColor(playerid)," ");
		SetPlayerVirtualWorld(playerid,Lobby_VW);
		SetPlayerInterior(playerid,GetGVarInt("MainInterior"));
		DisablePlayerCheckpoint(playerid);
		SetPlayerColor(playerid,GetGVarInt("Team_Color_L",GetPVarInt(playerid,"Team")));
		SetPlayerTeam(playerid,GetPVarInt(playerid,"Team"));
	    SetPVarInt(playerid,"Camera_0",0);
		PlayerStopSound(playerid);
		SetCameraBehindPlayer(playerid);
		ClearAnimations(playerid,true);
		SetPlayerPos(playerid,floatadd(GetGVarFloat("Lobby_Pos",0),floatrandom(10)),floatadd(GetGVarFloat("Lobby_Pos",1),floatrandom(10)),GetGVarFloat("Lobby_Pos",2));
		return SetPlayerFacingAngle(playerid,floatrandom(360));
	}
	else
	{
	    SetPlayerVirtualWorld(playerid,Dm_VW);
	    SetPlayerInterior(playerid,GetGVarInt("DM_Int",GetPVarInt(playerid,"DM_Zone")));
	    SetPlayerSkin(playerid,RandomSkin[random(100)]);
		SetPlayerHealth(playerid,100.0);
	    Attach3DTextLabelToPlayer(Player[playerid][AtHead],playerid,0.0,0.0,3.0);
		Update3DTextLabelText(Player[playerid][AtHead],GetPlayerColor(playerid)," ");
	    new randspawn = (random(5) * 3);
		SetPlayerWorldBounds(playerid,GetGVarFloat("DM_Q_2",GetPVarInt(playerid,"DM_Zone")),GetGVarFloat("DM_Q_0",GetPVarInt(playerid,"DM_Zone")),GetGVarFloat("DM_Q_3",GetPVarInt(playerid,"DM_Zone")),GetGVarFloat("DM_Q_1",GetPVarInt(playerid,"DM_Zone")));
		SetPlayerPos(playerid,DM[GetPVarInt(playerid,"DM_Zone")][Spawns][randspawn],DM[GetPVarInt(playerid,"DM_Zone")][Spawns][randspawn + 1],DM[GetPVarInt(playerid,"DM_Zone")][Spawns][randspawn + 2]);
		SetCameraBehindPlayer(playerid);
		GangZoneShowForPlayer(playerid,GetGVarInt("DM_GZ_1",GetPVarInt(playerid,"DM_Zone")),GetGVarInt("Zone_Color"));
		GangZoneShowForPlayer(playerid,GetGVarInt("DM_GZ_2",GetPVarInt(playerid,"DM_Zone")),GetGVarInt("Zone_Color"));
		GangZoneShowForPlayer(playerid,GetGVarInt("DM_GZ_3",GetPVarInt(playerid,"DM_Zone")),GetGVarInt("Zone_Color"));
		GangZoneShowForPlayer(playerid,GetGVarInt("DM_GZ_4",GetPVarInt(playerid,"DM_Zone")),GetGVarInt("Zone_Color"));
		GivePlayerWeapon(playerid,GetGVarInt("DM_Weapon_1",GetPVarInt(playerid,"DM_Zone")),(Never << 1));
		GivePlayerWeapon(playerid,GetGVarInt("DM_Weapon_2",GetPVarInt(playerid,"DM_Zone")),(Never << 1));

		GameTextForPlayerF(playerid, "~y~%s + %s~n~~r~Go Go Go!!!", 2000, 3, WeaponNames[GetGVarInt("DM_Weapon_1", GetPVarInt(playerid, "DM_Zone"))], WeaponNames[GetGVarInt("DM_Weapon_2", GetPVarInt(playerid, "DM_Zone"))]);
		SetPlayerTeam(playerid, playerid);
		SetPlayerColor(playerid, -1);
	}
	
	return 1;
}



public OnRconLoginAttempt(ip[], password[], success)
{
	new playerid = INVALID_PLAYER_ID;
	
	foreach_p(i)
	{
	    if(strcmp(Player[i][IP], ip, false))
		{
			continue;
		}
		
	    playerid = i;
	    
	    break;
	}

	if(!GetPVarInt(playerid, "Spawned"))
	{
		SendClientMessage(playerid, -1, "[Ошибка]: {AFAFAF}Вы должны быть заспавнены");
		
		return 1;
	}
	
	if(GetPVarInt(playerid, "Admin") == 5)
	{
		SendClientMessage(playerid, -1, "[Ошибка]: {AFAFAF}Вы уже залогинены в РКОН панель");
		
		return 1;
	}

	if(!success)
	{
		SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s [ID: %i, IP: %s] {AFAFAF}был автоматически забанен {FFFF00}(Причина: Неудачная попытка логина в RCON)", Player[playerid][Name], playerid, ip);
		mysql_ban(playerid, INVALID_PLAYER_ID, -1, "Неверный RCON", "AntiHack");
		
		return 1;
	}
	
	SendClientMessage(playerid, -1, "[Инфо]: {AFAFAF}Вы успешно вошли в РКОН панель");
	SetPVarInt(playerid, "Admin", 5);
	
	return 1;
}



public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
		case Register:
		{
			#pragma unused listitem
			
		    switch(response)
		    {
		    	case false:
				{
					ShowPlayerRegisterDialog(playerid);
					
					return 1;
				}
				
		  		case true:
		    	{
		    	    if(/*!regex_match_exid(inputtext, passwordRegex) || */!(4 < strlen(inputtext) <= 20) || IsNumeric(inputtext))
					{
					    SendClientMessage(playerid,-1,"[Инфо]: {AFAFAF}Неверный формат пароля!");
		    			ShowPlayerRegisterDialog(playerid);
		    			
		    			return 1;
					}
					
					SetPVarInt(playerid, "Logged", true);
					
					PlayerPlaySound(playerid, 33611, 0.0, 0.0, 0.0);
					
					PlayerTextDrawHide(playerid, Player[playerid][LoginText]);
					PlayerTextDrawSetString(playerid, Player[playerid][TeamText], "~w~~h~>> ~r~~h~Attack ~w~~h~<<     ~b~Defend     ~y~Refferee");
     				PlayerTextDrawShow(playerid, Player[playerid][TeamText]);
     				
		 			CallLocalFunction("OnPlayerRegister", "is", playerid, inputtext);
		 			
		 			return 1;
		    	}
			}
			
			return 1;
		}
		
		case Login:
		{
			#pragma unused listitem
			
		    switch(response)
		    {
		    	case false:
		     	{
		      		SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был автоматически кикнут {FFFF00}(Причина: Отказ от логина)", Player[playerid][Name]);
		        	SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}вышел из игры {FF0000}(Кикнут)", Player[playerid][Name]);

					return Kick(playerid);
				}
				
		  		case true:
		    	{
                   	if(isnull(inputtext) || /*!regex_match_exid(inputtext, passwordRegex) || */!(4 < strlen(inputtext) <= 20) || IsNumeric(inputtext))
					{
						CallLocalFunction("OnPlayerLoginFailed", "i", playerid);
						
						return 1;
					}
                   	
                   	new input[129];
		    	    new password[129];

		    	    SHA512(inputtext, input, sizeof input);
		       		GetPVarString(playerid, "password", password, sizeof password);
		       		
		       		if(strcmp(input, password, false))
		       		{
		       		    CallLocalFunction("OnPlayerLoginFailed", "i", playerid);
		       		    
		       		    return 1;
					}
		       		
					SetPVarInt(playerid, "Logged", 1);
					SetPVarInt(playerid, "Login_Attempts", 0);
					
					PlayerPlaySound(playerid, 33611, 0.0, 0.0, 0.0);
					
					PlayerTextDrawHide(playerid, Player[playerid][LoginText]);
     				PlayerTextDrawSetString(playerid, Player[playerid][TeamText], "~w~~h~>> ~r~~h~Attack ~w~~h~<<     ~b~Defend     ~y~Refferee");
					PlayerTextDrawShow(playerid, Player[playerid][TeamText]);
					
		 			CallLocalFunction("OnPlayerLogin", "ii", playerid, true);
		 			
		 			return 1;
		    	}
			}
			
			return 1;
		}
		
		case Changepass:
		{
			#pragma unused listitem
			
		    switch(response)
		    {
		    	case false:
				{
					SendClientMessage(playerid, -1, "[Инфо]: {AFAFAF}Вы отказались от смены пароля");
					
					return 1;
				}
				
		     	case true:
		      	{
		       		if(isnull(inputtext) || /*!regex_match_exid(inputtext, passwordRegex) || */!(4 <= strlen(inputtext) <= 20) || IsNumeric(inputtext))
		         	{
		          		SendClientMessage(playerid, -1, "[Ошибка]: {AFAFAF}Длина пароля должна быть не меньше 4 и не больше 20 символов, также пароль не должен состоять из одних чисел");
		            	ShowPlayerChangepassDialog(playerid);
		            	
		            	return 1;
					}
					
					new input[129];
					new password[129];
					
					SHA512(inputtext, input, sizeof input);
					GetPVarString(playerid, "password", password, sizeof password);
					
					if(!strcmp(input, password, false))
					{
		   				SendClientMessage(playerid, -1, "[Ошибка]: {AFAFAF}Этот пароль уже установлен");
					    ShowPlayerChangepassDialog(playerid);
					    
					    return 1;
					}
					
					SetPVarString(playerid, "password", input);
					
					SendClientMessageF(playerid, -1, "[Инфо]: {AFAFAF}Вы успешно сменили себе пароль на {FFFF00}'%s'", inputtext);
					
					return 1;
		   		}
			}
			
			return 1;
		}
		
		case Resetstats:
		{
			#pragma unused listitem
			
		    switch(response)
		    {
		    	case false:
				{
					SendClientMessage(playerid, -1, "[Инфо]: {AFAFAF}Вы отказались от сброса статистики");
					
					return 1;
				}
				
		     	case true:
		      	{
		      	    new input[129];
		      	    new password[129];
		      	    
		       		SHA512(inputtext, input, sizeof input);
					GetPVarString(playerid, "password", password, sizeof password);
					
		   			if(isnull(inputtext) || /*!regex_match_exid(inputtext, passwordRegex) || */!(4 < strlen(inputtext) <= 20) || IsNumeric(inputtext) || strcmp(input, password, false))
		    		{
				    	GivePVarInt(playerid, "Login_Attempts", 1);
		     			SendClientMessageF(playerid, -1, "[Ошибка]: {AFAFAF}Неверный пароль {FF0000}(%i/3)", GetPVarInt(playerid, "Login_Attempts"));

						if(GetPVarInt(playerid, "Login_Attempts") >= 3)
		       			{
		    		    	SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}был автоматически кикнут {FFFF00}(Причина: Неудачная попытка сброса статистики)", Player[playerid][Name]);
		     		    	SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}вышел из игры {FF0000}(Кикнут)", Player[playerid][Name]);
		      		    	Kick(playerid);
		      		    	
		      		    	return 1;
						}
						
		  				ShowPlayerResetstatsDialog(playerid);
		  				
		  				return 1;
					}
					
					SetPVarInt(playerid, "Logged", true);
					DeletePVar(playerid, "Login_Attempts");
					
					DeletePVar(playerid, "RunsFromRound");
					DeletePVar(playerid, "Kills");
					DeletePVar(playerid, "Deaths");
					DeletePVar(playerid, "KnifeKills");
					DeletePVar(playerid, "KnifeDeaths");
					DeletePVar(playerid, "DM_Kills");
					DeletePVar(playerid, "DM_Deaths");
					DeletePVar(playerid, "AtServer_D");
					DeletePVar(playerid, "AtServer_H");
					DeletePVar(playerid, "AtServer_M");
					DeletePVar(playerid, "AtServer_S");
					DeletePVar(playerid, "A_Played");
					DeletePVar(playerid, "B_Played");
					DeletePVar(playerid, "C_Played");
					DeletePVar(playerid, "Team_Wins");
					DeletePVar(playerid, "Team_Loses");
					
					SendClientMessage(playerid, -1, "[Инфо]: {AFAFAF}Статистика успешно сброшена");
					
					return 1;
				}
			}
			
			return 1;
		}
		
		case Weapon:
		{
			#pragma unused inputtext
			
		    switch(GetPVarInt(playerid, "Weapon_1"))
			{
		 		case 0:
		   		{
		     		switch(response)
		       		{
		         		case false:
		           		{
		             		SendClientMessage(playerid, -1, "[Ошибка]: {AFAFAF}Вы не можете остаться безоружным");
		               		ShowPlayerFirstWeapDialog(playerid);
		               		
		               		return 1;
						}
						
						case true:
						{
		    				switch(listitem)
						    {
		        				case 0:
						        {
		            				SetPVarInt(playerid, "Weapon_1", 24);
						            ShowPlayerSecWeapDialog(playerid);
						            
						            return 1;
								}
								case 1:
								{
				    				SetPVarInt(playerid, "Weapon_1", 23);
								    ShowPlayerSecWeapDialog(playerid);
								    
								    return 1;
								}
								case 2:
								{
				    				SetPVarInt(playerid, "Weapon_1", 25);
								    ShowPlayerSecWeapDialog(playerid);
								    
								    return 1;
								}
								case 3:
								{
				    				SetPVarInt(playerid, "Weapon_1", 29);
								    ShowPlayerSecWeapDialog(playerid);
								    
								    return 1;
								}
								case 4:
								{
		    						SetPVarInt(playerid, "Weapon_1", 30);
								    ShowPlayerSecWeapDialog(playerid);
								    
								    return 1;
								}
								case 5:
								{
				    				SetPVarInt(playerid, "Weapon_1", 31);
								    ShowPlayerSecWeapDialog(playerid);
								    
								    return 1;
								}
								case 6:
								{
				    				SetPVarInt(playerid, "Weapon_1", 33);
								    ShowPlayerSecWeapDialog(playerid);
								    
								    return 1;
								}
								case 7:
								{
				    				SetPVarInt(playerid, "Weapon_1", 34);
								    ShowPlayerSecWeapDialog(playerid);
								    
								    return 1;
								}
							}
						}
					}
				}
				
				default:
				{
		  			switch(GetPVarInt(playerid, "Weapon_2"))
			    	{
		      			case 0:
			        	{
		          			switch(response)
			            	{
		              			case false:
			                	{
		                  			DeletePVar(playerid, "Weapon_1");
			                    	DeletePVar(playerid, "Weapon_2");
				                    DeletePVar(playerid, "Weapon_3");
				                    
				                    ShowPlayerFirstWeapDialog(playerid);
				                    
				                    return 1;
								}
								
								case true:
								{
				    				switch(listitem)
								    {
				        				case 0:
								        {
				            				if(GetPVarInt(playerid, "Weapon_1") == 23)
								            {
				                				SendClientMessage(playerid, -1, "[Ошибка]: {AFAFAF}Оружие такого типа уже выбрано");
								                ShowPlayerSecWeapDialog(playerid);
								                
								                return 1;
											}
											
											SetPVarInt(playerid, "Weapon_2", 24);
											ShowPlayerThirdWeapDialog(playerid);
											
											return 1;
										}
										
										case 1:
										{
						    				if(GetPVarInt(playerid, "Weapon_1") == 24)
										    {
		            							SendClientMessage(playerid, -1, "[Ошибка]: {AFAFAF}Оружие такого типа уже выбрано");
					                			ShowPlayerSecWeapDialog(playerid);
					                			
					                			return 1;
											}
											
											SetPVarInt(playerid, "Weapon_2", 23);
											ShowPlayerThirdWeapDialog(playerid);
											
											return 1;
										}
										
										case 2:
										{
						    				SetPVarInt(playerid, "Weapon_2", 25);
										    ShowPlayerThirdWeapDialog(playerid);
										    
										    return 1;
										}
										
										case 3:
										{
						    				SetPVarInt(playerid, "Weapon_2", 29);
										    ShowPlayerThirdWeapDialog(playerid);
										    
										    return 1;
										}
										
										case 4:
										{
						    				if(GetPVarInt(playerid, "Weapon_1") == 31)
										    {
		            							SendClientMessage(playerid, -1, "[Ошибка]: {AFAFAF}Оружие такого типа уже выбрано");
					                			ShowPlayerSecWeapDialog(playerid);
					                			
					                			return 1;
											}
											
											SetPVarInt(playerid, "Weapon_2", 30);
											ShowPlayerThirdWeapDialog(playerid);
											
											return 1;
										}
										
										case 5:
										{
						    				if(GetPVarInt(playerid, "Weapon_1") == 30)
										    {
		            							SendClientMessage(playerid, -1, "[Ошибка]: {AFAFAF}Оружие такого типа уже выбрано");
					                			ShowPlayerSecWeapDialog(playerid);
					                			
					                			return 1;
											}
											
											SetPVarInt(playerid, "Weapon_2", 31);
											ShowPlayerThirdWeapDialog(playerid);
											
											return 1;
										}
										
										case 6:
										{
						    				if(GetPVarInt(playerid, "Weapon_1") == 34)
										    {
		            							SendClientMessage(playerid, -1, "[Ошибка]: {AFAFAF}Оружие такого типа уже выбрано");
					                			ShowPlayerSecWeapDialog(playerid);
					                			
					                			return 1;
											}
											
											SetPVarInt(playerid, "Weapon_2", 33);
											ShowPlayerThirdWeapDialog(playerid);
											
											return 1;
										}
										
										case 7:
										{
						    				if(GetPVarInt(playerid, "Weapon_1") == 33)
										    {
		            							SendClientMessage(playerid, -1, "[Ошибка]: {AFAFAF}Оружие такого типа уже выбрано");
					                			ShowPlayerSecWeapDialog(playerid);
					                			
					                			return 1;
											}
											
											SetPVarInt(playerid, "Weapon_2", 34);
											ShowPlayerThirdWeapDialog(playerid);
											
											return 1;
										}
									}
								}
							}
						}
						
						default:
						{
		    				switch(GetPVarInt(playerid, "Weapon_3"))
						    {
		        				case 0:
						        {
		            				switch(response)
						            {
		                				case false:
						                {
		                    				DeletePVar(playerid, "Weapon_3");
						                    CheckPack(playerid);
						                    
						                    return 1;
										}
										
										case true:
										{
						    				switch(listitem)
										    {
						        				case 0:
										        {
						            				SetPVarInt(playerid, "Weapon_3", 4);
										            CheckPack(playerid);
										            
										            return 1;
												}
												
												case 1:
												{
								    				SetPVarInt(playerid, "Weapon_3", 5);
												    CheckPack(playerid);
												    
												    return 1;
												}
												
												case 2:
												{
			    									SetPVarInt(playerid, "Weapon_3", 6);
												    CheckPack(playerid);
												    
												    return 1;
												}
												
												case 3:
												{
								    				SetPVarInt(playerid, "Weapon_3", 3);
												    CheckPack(playerid);

													return 1;
												}
												
												case 4:
												{
													ShowPlayerThirdWeapDialog(playerid);
													
													return 1;
												}
												
												case 5:
												{
								    				if(GetPlayerInterior(playerid))
												    {
								        				SendClientMessage(playerid, -1, "[Ошибка]: {AFAFAF}Гранаты в интерьере запрещены");
												        ShowPlayerThirdWeapDialog(playerid);
												        
												        return 1;
													}
													
													SetPVarInt(playerid, "Weapon_3", 16);
													CheckPack(playerid);
													
													return 1;
												}
												
												case 6:
												{
								    				SetPVarInt(playerid, "Weapon_3", 17);
												    CheckPack(playerid);
												    
												    return 1;
												}
											}
										}
									}
								}
								
								default:
								{
									CheckPack(playerid);
									
									return 1;
								}
							}
						}
					}
				}
			}
			
			return 1;
		}
		
		case Weapon_Change:
		{
			#pragma unused inputtext
			#pragma unused listitem
			
		    switch(response)
		    {
		    	case false:
		     	{
					DeletePVar(playerid,"Weapon_1");
					DeletePVar(playerid,"Weapon_2");
					DeletePVar(playerid,"Weapon_3");
					
					ShowPlayerFirstWeapDialog(playerid);
					
					return 1;
				}
				
				case true:
				{
					GivePlayerWeapons(playerid);
					
					return 1;
				}
			}
			
			return 1;
		}
		
		case CarList_Main:
		{
			#pragma unused inputtext
			
			new string[1512];
			
			switch(response)
		 	{
		  		case false:
		  		{
				  	SendClientMessage(playerid, -1, "[Инфо]: {AFAFAF}Вы отказались от выбора транспорта");
				  	
				  	return 1;
				}
				
		    	case true:
		     	{
		      		switch(listitem)
		        	{
		         		case 0:
						{
		    				GetGVarString("Vehicles", string);
							ShowPlayerDialog(playerid, CarList_Auto, DIALOG_STYLE_LIST, "{FFFFFF}Автомобили", string, "Выбор", "Назад");
							
							return 1;
						}
						
		    			case 1:
						{
							GetGVarString("Bikes", string);
							ShowPlayerDialog(playerid, CarList_Bikes, DIALOG_STYLE_LIST, "{FFFFFF}Мотоциклы", string, "Выбор", "Назад");
							
							return 1;
						}
						
		    			case 2:
						{
							GetGVarString("Bicycles", string);
							ShowPlayerDialog(playerid, CarList_Bicycle, DIALOG_STYLE_LIST, "{FFFFFF}Велосипеды", string, "Выбор", "Назад");
							
							return 1;
						}
						
		    			case 3:
						{
							GetGVarString("Boats", string);
							ShowPlayerDialog(playerid, CarList_Boats, DIALOG_STYLE_LIST, "{FFFFFF}Лодки", string, "Выбор", "Назад");
							
							return 1;
						}
						
		    			case 4:
						{
							GetGVarString("Heli", string);
							ShowPlayerDialog(playerid, CarList_Heli, DIALOG_STYLE_LIST, "{FFFFFF}Вертолеты", string, "Выбор", "Назад");
							
							return 1;
						}
						
		    			case 5:
						{
							GetGVarString("Planes", string);
							ShowPlayerDialog(playerid, CarList_Planes, DIALOG_STYLE_LIST, "{FFFFFF}Самолеты", string, "Выбор", "Назад");
							
							return 1;
						}
					}
				}
			}
			
			return 1;
		}
		
		case CarList_Auto:
		{
			#pragma unused inputtext
			
			switch(response)
		 	{
		  		case false:
		  		{
			  		ShowPlayerDialog(playerid, CarList_Main, DIALOG_STYLE_LIST, "{FFFFFF}Выбор транспорта", "{FFFFFF}Автомобили\nМотоциклы\nВелосипеды\nЛодки\nВертолеты\nСамолеты", "Дальше", "Отмена");
			  		
			  		return 1;
				}
				
		    	case true:
		     	{
		     	    new string[12];
		     	    
		     	    SetPVarInt(playerid, "CMD_Time", (GetTickCount() - 2501));
					valstr(string, GetGVarInt("iVehicles", listitem));
					
					CallLocalFunction("_car", "isi", playerid, string, strlen(string));
					
					return 1;
				}
			}
			
			return 1;
		}
		
		case CarList_Bikes:
		{
			#pragma unused inputtext
			
			switch(response)
		 	{
		  		case false:
		  		{
			  		ShowPlayerDialog(playerid, CarList_Main, DIALOG_STYLE_LIST, "{FFFFFF}Выбор транспорта", "{FFFFFF}Автомобили\nМотоциклы\nВелосипеды\nЛодки\nВертолеты\nСамолеты", "Дальше", "Отмена");
			  		
			  		return 1;
				}
				
		    	case true:
		     	{
		     	    new string[12];
		     	    
		     	    SetPVarInt(playerid, "CMD_Time", (GetTickCount() - 2501));
		      		valstr(string, GetGVarInt("iBikes", listitem));
		      		
					CallLocalFunction("_car", "isi", playerid, string, strlen(string));
					
					return 1;
				}
			}
			
			return 1;
		}
		
		case CarList_Bicycle:
		{
			#pragma unused inputtext
			
			switch(response)
		 	{
		  		case false:
		  		{
				  	ShowPlayerDialog(playerid, CarList_Main, DIALOG_STYLE_LIST, "{FFFFFF}Выбор транспорта", "{FFFFFF}Автомобили\nМотоциклы\nВелосипеды\nЛодки\nВертолеты\nСамолеты", "Дальше", "Отмена");
				  	
				  	return 1;
				}
				
		    	case true:
		     	{
		     	    new string[12];
		     	    
		     	    SetPVarInt(playerid, "CMD_Time", (GetTickCount() - 2501));
		      		valstr(string, GetGVarInt("iBicycles", listitem));
		      		
					CallLocalFunction("_car", "isi", playerid, string, strlen(string));
					
					return 1;
				}
			}
			
			return 1;
		}
		
		case CarList_Boats:
		{
			#pragma unused inputtext
			
			switch(response)
		 	{
		  		case false:
		  		{
				  	ShowPlayerDialog(playerid, CarList_Main, DIALOG_STYLE_LIST, "{FFFFFF}Выбор транспорта", "{FFFFFF}Автомобили\nМотоциклы\nВелосипеды\nЛодки\nВертолеты\nСамолеты", "Дальше", "Отмена");
				  	
				  	return 1;
				}
				
		    	case true:
		     	{
		     	    new string[12];
		     	    
		     	    SetPVarInt(playerid, "CMD_Time", (GetTickCount() - 2501));
		      		valstr(string, GetGVarInt("iBoats", listitem));
		      		
					CallLocalFunction("_car", "isi", playerid, string, strlen(string));
					
					return 1;
				}
			}
			
			return 1;
		}
		
		case CarList_Heli:
		{
			#pragma unused inputtext
			
			switch(response)
		 	{
		  		case false:
		  		{
				  	ShowPlayerDialog(playerid, CarList_Main, DIALOG_STYLE_LIST, "{FFFFFF}Выбор транспорта", "{FFFFFF}Автомобили\nМотоциклы\nВелосипеды\nЛодки\nВертолеты\nСамолеты", "Дальше", "Отмена");
				  	
				  	return 1;
				}
				
		    	case true:
		     	{
		     	    new string[12];
		     	    
		     	    SetPVarInt(playerid, "CMD_Time", (GetTickCount() - 2501));
		      		valstr(string, GetGVarInt("iHeli", listitem));
		      		
					CallLocalFunction("_car", "isi", playerid, string, strlen(string));
					
					return 1;
				}
			}
			
			return 1;
		}
		
		case CarList_Planes:
		{
			#pragma unused inputtext
			
			switch(response)
		 	{
		  		case false:
		  		{
				  	ShowPlayerDialog(playerid, CarList_Main, DIALOG_STYLE_LIST, "{FFFFFF}Выбор транспорта", "{FFFFFF}Автомобили\nМотоциклы\nВелосипеды\nЛодки\nВертолеты\nСамолеты", "Дальше", "Отмена");
				  	
				  	return 1;
				}
				
		    	case true:
		     	{
		     	    new string[12];
		     	    
		     	    SetPVarInt(playerid, "CMD_Time", (GetTickCount() - 2501));
		      		valstr(string ,GetGVarInt("iPlanes", listitem));
		      		
					CallLocalFunction("_car", "isi", playerid, string, strlen(string));
					
					return 1;
				}
			}
			
			return 1;
		}
		
		case HelpDialog:
		{
			#pragma unused inputtext
			
			switch(response)
		 	{
		  		case false:
	  			{
				  	return 1;
				}
				
		    	case true:
		     	{
		      		switch(listitem)
		        	{
		         		case 0:
					 	{
						 	SetPVarInt(playerid, "CMD_Time", (GetTickCount() - 2501));
						 	CallLocalFunction("_cmd", "isi", playerid, "\1", 0);
						 	
						 	return 1;
						}
						
		           		case 1:
			   			{
		   					SetPVarInt(playerid, "CMD_Time", (GetTickCount() - 2501));
						   	CallLocalFunction("_info", "isi", playerid, "\1", 0);
						   	
						   	return 1;
						}
						
		             	case 2:
					 	{
						 	SetPVarInt(playerid, "CMD_Time", (GetTickCount() - 2501));
					 		CallLocalFunction("_acmd", "isi", playerid, "\1", 0);
					 		
					 		return 1;
						}
						
		              	case 3:
				  		{
						  	SetPVarInt(playerid, "CMD_Time", (GetTickCount() - 2501));
						  	CallLocalFunction("_mcmd", "isi", playerid, "\1", 0);
						  	
						  	return 1;
						}
					}
				}
			}
			
			return 1;
		}
		
		case Duel_Weapon:
		{
			#pragma unused inputtext
			
		    switch(response)
		    {
		    	case false:
				{
					return 1;
				}
				
		     	case true:
		      	{
		       		switch(listitem)
		         	{
		          		case 0: SetPVarInt(playerid, "DuelID", 24);
		            	case 1: SetPVarInt(playerid, "DuelID", 23);
		             	case 2: SetPVarInt(playerid, "DuelID", 25);
		              	case 3: SetPVarInt(playerid, "DuelID", 26);
		               	case 4: SetPVarInt(playerid, "DuelID", 28);
		                case 5: SetPVarInt(playerid, "DuelID", 29);
		                case 6: SetPVarInt(playerid, "DuelID", 30);
				        case 7: SetPVarInt(playerid, "DuelID", 31);
		          		case 8: SetPVarInt(playerid, "DuelID", 34);
		            	case 9:
		             	{
		              		SetPlayerTeam(playerid, playerid);
			    			SetPlayerHealth(playerid, 100.0);
				    		SetPlayerScore(playerid, 0);
				    		SetPlayerVirtualWorld(playerid, GetPVarInt(playerid, "DuelID"));
		        			SetPlayerInterior(playerid, 0);
		        			
		           			new io = random(2);
		           			
		              		SetPlayerPos(playerid, GrenadesLocation[io][0], GrenadesLocation[io][1], GrenadesLocation[io][2]);
							ResetPlayerWeapons(playerid);
							
							GivePlayerWeapon(playerid, 16, cellmax);
							
							SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}зашел на дуель {FFFF00}(Оружие: Grenades)", Player[playerid][Name]);
							
							return 1;
		     			}
					}
					
					ShowPlayerDialog(playerid, Duel_Location, DIALOG_STYLE_LIST, "{FFFFFF}Выбор локации", "{FFFFFF}Локация 1\nЛокация 2\nЛокация 3\nЛокация 4\nЛокация 5", "Старт!", "Отмена");
					
					return 1;
				}
			}
			
			return 1;
		}
		
		case Duel_Location:
		{
			#pragma unused inputtext
			
			switch(response)
		 	{
		  		case false:
		    	{
		     		SetPVarInt(playerid, "DuelID", -1);
		       		ShowPlayerDialog(playerid, Duel_Weapon, DIALOG_STYLE_LIST, "{FFFFFF}Выбор оружия для дуели", "{FFFFFF}Desert Eagle\nShotgun\nM4\nSniper Rifle\nGrenades", "Выбор", "Отмена");
		       		
		       		return 1;
				}
				
				case true:
				{
		  			SetPlayerTeam(playerid, playerid);
			    	SetPlayerHealth(playerid, 100.0);
				    SetPlayerScore(playerid, 0);
				    SetPlayerColor(playerid, -1);
					SetPlayerVirtualWorld(playerid, GetPVarInt(playerid, "DuelID"));
		   			ResetPlayerWeapons(playerid);
					GivePlayerWeapon(playerid, GetPVarInt(playerid, "DuelID"), cellmax);
					
					new io = random(2);
					
					switch(GetPVarInt(playerid, "DuelID"))
		   			{
		      			case 24:
			        	{
		          			SetPlayerInterior(playerid, 0);
			            	SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}зашел на дуель {FFFF00}(Оружие: Desert Eagle, Локация: %i)", Player[playerid][Name], (listitem + 1));

							switch(listitem)
				            {
		              			case 0: SetPlayerPos(playerid, DeagleLocation_1[io][0], DeagleLocation_1[io][1], DeagleLocation_1[io][2]);
			                	case 1: SetPlayerPos(playerid, DeagleLocation_2[io][0], DeagleLocation_2[io][1], DeagleLocation_2[io][2]);
				                case 2: SetPlayerPos(playerid, DeagleLocation_3[io][0], DeagleLocation_3[io][1], DeagleLocation_3[io][2]);
				                case 3: SetPlayerPos(playerid, DeagleLocation_4[io][0], DeagleLocation_4[io][1], DeagleLocation_4[io][2]);
				                case 4: SetPlayerPos(playerid, DeagleLocation_5[io][0], DeagleLocation_5[io][1], DeagleLocation_5[io][2]);
							}
						}
						
						case 25:
		    			{
		       				SetPlayerInterior(playerid, 0);
		           			SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}зашел на дуель {FFFF00}(Оружие: Shotgun, Локация: %i)", Player[playerid][Name], (listitem + 1));

							switch(listitem)
				            {
		              			case 0: SetPlayerPos(playerid, ShotLocation_1[io][0], ShotLocation_1[io][1], ShotLocation_1[io][2]);
			                	case 1: SetPlayerPos(playerid, ShotLocation_2[io][0], ShotLocation_2[io][1], ShotLocation_2[io][2]);
				                case 2: SetPlayerPos(playerid, ShotLocation_3[io][0], ShotLocation_3[io][1], ShotLocation_3[io][2]);
				                case 3: SetPlayerPos(playerid, ShotLocation_4[io][0], ShotLocation_4[io][1], ShotLocation_4[io][2]);
				                case 4: SetPlayerPos(playerid, ShotLocation_5[io][0], ShotLocation_5[io][1], ShotLocation_5[io][2]);
							}
						}
						
						case 31:
		    			{
		       				SetPlayerInterior(playerid, 0);
		           			SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}зашел на дуель {FFFF00}(Оружие: M4, Локация: %i)", Player[playerid][Name], (listitem + 1));

							switch(listitem)
				            {
		              			case 0: SetPlayerPos(playerid, M4Location_1[io][0], M4Location_1[io][1], M4Location_1[io][2]);
			                	case 1: SetPlayerPos(playerid, M4Location_2[io][0], M4Location_2[io][1], M4Location_2[io][2]);
			                	case 2: SetPlayerPos(playerid, M4Location_3[io][0], M4Location_3[io][1], M4Location_3[io][2]);
				                case 3: SetPlayerPos(playerid, M4Location_4[io][0], M4Location_4[io][1], M4Location_4[io][2]);
				                case 4: SetPlayerPos(playerid, M4Location_5[io][0], M4Location_5[io][1], M4Location_5[io][2]);
							}
						}
						
						case 34:
		    			{
		       				SetPlayerInterior(playerid, 0);
		           			SendClientMessageToAllF(-1, "[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}зашел на дуель {FFFF00}(Оружие: Sniper Rifle, Локация: %i)", Player[playerid][Name], (listitem + 1));

							switch(listitem)
				            {
		              			case 0: SetPlayerPos(playerid, SniperLocation_1[io][0], SniperLocation_1[io][1], SniperLocation_1[io][2]);
			                	case 1: SetPlayerPos(playerid, SniperLocation_2[io][0], SniperLocation_2[io][1], SniperLocation_2[io][2]);
				                case 2: SetPlayerPos(playerid, SniperLocation_3[io][0], SniperLocation_3[io][1], SniperLocation_3[io][2]);
				                case 3: SetPlayerPos(playerid, SniperLocation_4[io][0], SniperLocation_4[io][1], SniperLocation_4[io][2]);
				                case 4:
								{
									SetPlayerPos(playerid, SniperLocation_5[io][0], SniperLocation_5[io][1], SniperLocation_5[io][2]);
									SetPlayerInterior(playerid, 15);
								}
							}
						}
					}
				}
			}
			
			return 1;
		}
		
		case SwitchDialog:
		{
			#pragma unused inputtext
			
			switch(response)
		 	{
		  		case false:
		  		{
				  	SendClientMessage(playerid, -1, "[Инфо]: {AFAFAF}Вы отказались от смены комманды");
				  	
				  	return 1;
				}
				
				case true:
				{
		  			switch(listitem)
			    	{
		      			case 0:
					  	{
						  	SetPVarInt(playerid, "CMD_Time", (GetTickCount() - 2501));
						  	CallLocalFunction("_team", "isi", playerid, "att", 3);
						  	
						  	return 1;
						}
						
			        	case 1:
						{
							SetPVarInt(playerid, "CMD_Time", (GetTickCount() - 2501));
							CallLocalFunction("_team", "isi", playerid, "def", 3);
							
							return 1;
						}
						
				        case 2:
						{
							SetPVarInt(playerid, "CMD_Time", (GetTickCount() - 2501));
							CallLocalFunction("_team", "isi", playerid, "ref", 3);
							
							return 1;
						}
					}
				}
			}
			
			return 1;
		}
		
		case OnlyText:
		{
			#pragma unused inputtext
			#pragma unused listitem
			
			switch(response)
		 	{
		  		default:
	  			{
				  	return 1;
				}
			}
			
			return 1;
		}
	}
	
	return 0;
}



public OnPlayerCommandPerformed(playerid, command[], params[], params_length, return_code)
{
	if(return_code != 1)
	{
		SendClientMessageF(playerid, -1, "[Ошибка]: {AFAFAF}Комманды {FF0000}%s {AFAFAF}не существует, для списка комманд введите {FFFF00}/cmd", command);
		
		return 1;
	}
	
	return 1;
}



public OnPlayerCommandReceived(playerid, command[], params[], params_length)
{
    if((GetTickCount() - GetPVarInt(playerid, "CMD_Time")) <= 1500)
	{
		GivePVarInt(playerid, "FastCMD", 1);
		
		if(GetPVarInt(playerid, "FastCMD") > 10)
		{
			mysql_ban(playerid, INVALID_PLAYER_ID, -1, "Флуд коммандами", "AntiFlood");
			
			return 1;
		}
		
		SendClientMessage(playerid, -1, "[Инфо]: {AFAFAF}Не флуди коммандами!");
		
		return 0;
	}
	
	SetPVarInt(playerid, "CMD_Time", GetTickCount());
	SetPVarInt(playerid, "FastCMD", 0);
	
	return 1;
}





/*CMD:credits(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_info","ds",playerid,"\1");
}

CMD:info(playerid,params[])
{
	#pragma unused params
	new
	    string_data[2048]
	;
	GetGVarString("Info",string_data);
	return ShowPlayerDialog(playerid,OnlyText,0,"{FFFFFF}bLeague | Авторы:",string_data,"Ок","Отмена");
}

CMD:help(playerid,params[])
{
	#pragma unused params
	return ShowPlayerDialog(playerid,HelpDialog,2,"{FFFFFF}bLeague | Помощь:","{FFFFFF}Основные комманды мода\nСоздатели мода\nКомманды администратора\nКомманды модератора","Ок","Отмена");
}

CMD:uptime(playerid,params[])
{
	#pragma unused params
	new
	    string_data[32]
	;
	
	Convert(((GetTickCount() - GetGVarInt("UpTime")) / 1000),string_data);
	SendClientMessageFplayerid,-1,"[Инфо]: {AFAFAF}Аптайм сервера: {FFFF00}%s",string_data);
	
	return 1;
}

CMD:mystats(playerid,params[])
{
	#pragma unused params
	new
		int_data[12]
	;
	
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	valstr(int_data,playerid);
	return CallLocalFunction("cmd_stats","ds",playerid,int_data);
}*/

/*CMD:stats(playerid,params[])
{
	if(isnull(params))
	{
		SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
		return CallLocalFunction("cmd_mystats","ds",playerid,"\1");
	}
	if(IsNumeric(params))
	{
	    new id = strval(params);
	    if(!GetPVarInt(id,"Connected")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрока (%i) нет на сервере",id);
        format(String256,256,"{FFFFFF}bLeague | Статистика игрока %s",Player[id][Name]);
        new RegS[24], LoginS[24];
        GetPVarString(id,"Reg_Date",RegS,24);
        GetPVarString(id,"Login_Date",LoginS,24);
		format(String2048,2048,"{FFFFFF}Ник: %s | Дата регистрации: %s | Дата входа: %s\nВремя игры на сервере: %i дней, %i:%02d:%02d",Player[id][Name],RegS,LoginS,GetPVarInt(id,"AtServer_D"),GetPVarInt(id,"AtServer_H"),GetPVarInt(id,"AtServer_M"),GetPVarInt(id,"AtServer_S"));
		format(String2048,2048,"%s\nСыграно раундов: %i | Побегов с раундов: %i\nКоммандных побед: %i | Коммандных поражений: %i",String2048,GetPVarInt(id,"B_Played") + GetPVarInt(id,"A_Played") + GetPVarInt(id,"C_Played"),GetPVarInt(id,"RunsFromRound"),GetPVarInt(id,"Team_Wins"),GetPVarInt(id,"Team_Loses"));
		format(String2048,2048,"%s\nСыграно баз: %i | Сыграно арен: %i | Сыграно CTF: %i\nУбийств в раундах: %i | Смертей в раундах: %i | Соотношение: %.2f",String2048,GetPVarInt(id,"B_Played"),GetPVarInt(id,"A_Played"),GetPVarInt(id,"C_Played"),GetPVarInt(id,"Kills"),GetPVarInt(id,"Deaths"),GetRatio(GetPVarInt(id,"Kills"),GetPVarInt(id,"Deaths")));
		format(String2048,2048,"%s\nУбийств на DM: %i | Смертей на DM: %i | Соотношение: %.2f\nУбийств с ножа: %i | Смертей от ножа: %i | Соотношение: %.2f",String2048,GetPVarInt(id,"DM_Kills"),GetPVarInt(id,"DM_Deaths"),GetRatio(GetPVarInt(id,"DM_Kills"),GetPVarInt(id,"DM_Deaths")),GetPVarInt(id,"KnifeKills"),GetPVarInt(id,"KnifeDeaths"),GetRatio(GetPVarInt(id,"KnifeKills"),GetPVarInt(id,"KnifeDeaths")));
		format(String2048,2048,"%s\nВсего убийств: %i | Всего смертей: %i | Общее соотношение: %.2f",String2048,(GetPVarInt(id,"Kills") + GetPVarInt(id,"DM_Kills")),(GetPVarInt(id,"Deaths") + GetPVarInt(id,"DM_Deaths")),GetRatio((GetPVarInt(id,"Kills") + GetPVarInt(id,"DM_Kills")),(GetPVarInt(id,"Deaths") + GetPVarInt(id,"DM_Deaths"))));
		return ShowPlayerDialog(playerid,OnlyText,0,String256,String2048,"Ок","Отмена");
	}
	else
	{
	    if(strlen(params) > 20) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Слишком длинное имя");
		mysql_real_escape_string(params,params);
		if(!strcmp(params,Player[playerid][Name],true))
		{
		    SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
			return CallLocalFunction("cmd_mystats","ds",playerid,"\1");
		}
	    format(Player[playerid][Query],128,"SELECT * FROM `Accounts` WHERE `Name`='%s'",params);
	    mysql_query(Player[playerid][Query]);
	    mysql_store_result();
	    if(!mysql_num_rows())
		{
			mysql_free_result();
			return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрок %s не найден. Проверьте правильность ввода ника",params);
		}
		new RegDate[32], LoginDate[32],
		RRuns, Kills,Deaths,
		KKills, KDeaths,
		DMKills, DMDeaths,
		AtServerD, AtServerH,
		AtServerM, AtServerS,
		APlayed, BPlayed, CPlayed,
		TWins, TLoses;
		mysql_fetch_row(Player[playerid][Query]);
		mysql_free_result();
		sparam(RegDate,32,Player[playerid][Query],0x7C,Q_RegDate);
		sparam(LoginDate,32,Player[playerid][Query],0x7C,Q_LoginDate);
		RRuns = iparam(Player[playerid][Query],0x7C,Q_RRuns);
		Kills = iparam(Player[playerid][Query],0x7C,Q_Kills);
		Deaths = iparam(Player[playerid][Query],0x7C,Q_Deaths);
		KKills = iparam(Player[playerid][Query],0x7C,Q_KKills);
		KDeaths = iparam(Player[playerid][Query],0x7C,Q_KDeaths);
		DMKills = iparam(Player[playerid][Query],0x7C,Q_DMKills);
		DMDeaths = iparam(Player[playerid][Query],0x7C,Q_DMDeaths);
		sparam(String32,32,Player[playerid][Query],0x7C,Q_AtServer);
		AtServerD = iparam(String32,0x2C,0);
		AtServerH = iparam(String32,0x2C,1);
		AtServerM = iparam(String32,0x2C,2);
		AtServerS = iparam(String32,0x2C,3);
		APlayed = iparam(Player[playerid][Query],0x7C,Q_APlayed);
		BPlayed = iparam(Player[playerid][Query],0x7C,Q_BPlayed);
		CPlayed = iparam(Player[playerid][Query],0x7C,Q_CPlayed);
		TWins = iparam(Player[playerid][Query],0x7C,Q_TWins);
		TLoses = iparam(Player[playerid][Query],0x7C,Q_TLoses);
		format(String128,128,"{FFFFFF}bLeague | Статистика игрока %s",params);
		format(String2048,2048,"{FFFFFF}Ник: %s | Дата регистрации: %s | Дата входа: %s\nВремя игры на сервере: %i дней, %i:%02d:%02d",params,RegDate,LoginDate,AtServerD,AtServerH,AtServerM,AtServerS);
		format(String2048,2048,"%s\nСыграно раундов: %i | Побегов с раундов: %i\nКоммандных побед: %i | Коммандных поражений: %i",String2048,APlayed + BPlayed + CPlayed,RRuns,TWins,TLoses);
		format(String2048,2048,"%s\nСыграно баз: %i | Сыграно арен: %i | Сыграно CTF: %i\nУбийств в раундах: %i | Смертей в раундах: %i | Соотношение: %.2f",String2048,BPlayed,APlayed,CPlayed,Kills,Deaths,GetRatio(Kills,Deaths));
		format(String2048,2048,"%s\nУбийств на DM: %i | Смертей на DM: %i | Соотношение: %.2f\nУбийств с ножа: %i | Смертей от ножа: %i | Соотношение: %.2f",String2048,DMKills,DMDeaths,GetRatio(DMKills,DMDeaths),KKills,KDeaths,GetRatio(KKills,KDeaths));
		format(String2048,2048,"%s\nВсего убийств: %i | Всего смертей: %i | Общее соотношение: %.2f",String2048,(Kills + KKills + DMKills),(Deaths + KDeaths + DMDeaths),GetRatio((Kills + KKills + DMKills),(Deaths + KDeaths + DMDeaths)));
	}
	return ShowPlayerDialog(playerid,OnlyText,0,String128,String2048,"Ок","Отмена");
}*/

/*CMD:cmd(playerid,params[])
{
	#pragma unused params
	new
	    string_data[2048]
	;
	
	GetGVarString("UsualCommands",string_data);
	return ShowPlayerDialog(playerid,OnlyText,0,"{FFFFFF}bLeague | Комманды мода:",string_data,"Ок","Отмена");
}

CMD:acmd(playerid,params[])
{
	#pragma unused params
	if(!GetPVarInt(playerid,"Admin")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
    if(GetPVarInt(playerid,"Admin") < 4)
	{
		SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
		return CallLocalFunction("cmd_mcmd","ds",playerid,"\1");
	}
	
	new
	    string_data[2048]
	;
	
	GetGVarString("AdminCommands",string_data);
	return ShowPlayerDialog(playerid,OnlyText,0,"{FFFFFF}bLeague | Админ комманды:",string_data,"Ок","Отмена");
}

CMD:mcmd(playerid,params[])
{
	#pragma unused params
	if(GetPVarInt(playerid,"Admin") > 3)
	{
		SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
		return CallLocalFunction("cmd_acmd","ds",playerid,"\1");
	}
 	if(!GetPVarInt(playerid,"Admin")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");

	new
	    string_data[2048]
	;
	
	GetGVarString("ModerCommands",string_data);
	return ShowPlayerDialog(playerid,OnlyText,0,"{FFFFFF}bLeague | Комманды модератора:",string_data,"Ок","Отмена");
}

CMD:admins(playerid,params[])
{
	#pragma unused params
	if(!GetPVarInt(playerid,"Spawned")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не заспавнены");

	new
		aCount[2]
	;
	
	foreach_p(i)
	{
	    if(!GetPVarInt(i,"Admin")) continue;
	    if(GetPVarInt(i,"Admin") > 3)
		{
			aCount[0]++;
		}
		else if(4 > GetPVarInt(i,"Admin") > 1)
		{
			aCount[1]++;
		}
	}
	switch(aCount[0])
	{
	    case 0:
	    {
	        switch(aCount[1])
	        {
	            case 0: SendClientMessage(playerid,-1,"[Инфо]: {AFAFAF}Администрации онлайн нет");
	            default: SendClientMessageF(playerid,-1,"[Инфо]: {AFAFAF}На сервере %i модераторов",aCount[1]);
			}
		}
		default:
		{
		    switch(aCount[1])
		    {
		        case 0: SendClientMessageF(playerid,-1,"[Инфо]: {AFAFAF}На сервере %i администраторов",aCount[0]);
		        default: SendClientMessageF(playerid,-1,"[Инфо]: {AFAFAF}На сервере %i администраторов и %i модераторов",aCount[0],aCount[1]);
			}
		}
	}
	return 1;
}

CMD:sql(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") != 5) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/sql [запрос]");
	if(strfind(params,"SELECT",true) != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Запрос `SELECT` не поддерживается");
	mysql_function_query(mysqlHandle, params, false, "", "");
	SendClientMessageF(playerid,-1,"[Инфо]: {AFAFAF}Запрос к MySQL БД успешно выполнен {FFFF00}(%s)",params);
	return 1;
}

CMD:getip(playerid,params[])
{
    if(GetPVarInt(playerid,"Admin") < 2) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
    if(isnull(params) || !IsNumeric(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/getip [id]");
    new
		id = strval(params)
	;
    if(!GetPVarInt(id,"Connected"))
	{
		SendClientMessageF(playerid,-1,"[Ошибка]: {AFAFAF}Игрока (%i) нет на сервере", id);
		
		return 1;
	}
	
	SendClientMessageF(playerid,-1,"[Инфо]: {AFAFAF}IP адрес игрока {FF0000}%s {AFAFAF}- {FFFF00}%s", Player[id][Name], Player[id][IP]);
	
	return 1;
}

CMD:changepass(playerid,params[])
{
	#pragma unused params
	if(GetPVarInt(playerid,"Playing") || GetPVarInt(playerid,"DM_Zone") != -1 || GetPVarInt(playerid,"DuelID") != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Это можно делать только на лобби!");
	if(!GetPVarInt(playerid,"Logged")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не авторизованны для данного действия");
	if(!GetPVarInt(playerid,"Spawned")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы должны заспавниться для выполнения этой комманды");
	return ShowPlayerChangepassDialog(playerid);
}

CMD:resetstats(playerid,params[])
{
	#pragma unused params
	if(GetPVarInt(playerid,"Playing") || GetPVarInt(playerid,"DM_Zone") != -1 || GetPVarInt(playerid,"DuelID") != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Это можно делать только на лобби!");
 	if(!GetPVarInt(playerid,"Logged")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не авторизованны для данного действия");
	if(!GetPVarInt(playerid,"Spawned")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы должны заспавниться для выполнения комманд");
	return ShowPlayerResetstatsDialog(playerid);
}

CMD:w(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
    return CallLocalFunction("cmd_weap","ds",playerid,"\1");
}

CMD:weapon(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_weap","ds",playerid,"\1");
}

CMD:weap(playerid,params[])
{
	#pragma unused params
	if(!GetPVarInt(playerid,"Playing")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Смена пака возможна только на раунде");
	if(GetPVarInt(playerid,"Change_Weapon")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы уже использовали возможность смены пака");
	if(GetPlayerState(playerid) == 7) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы мертвы");
	if(!GetPVarInt(playerid,"Spawned")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не заспавнены");
 	if((GetTickCount() - GetGVarInt("Weap_ChangeTick")) >= (GetGVarInt("Weap_ChangeTime") * 1000)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Время перевыбора оружия истекло!");
  	if(!GetPVarInt(playerid,"Weapon_1") || !GetPVarInt(playerid,"Weapon_2"))
  	{
  		ShowPlayerFirstWeapDialog(playerid);
	}
	else
	{
		ShowPlayerChangeWeapDialog(playerid);
	}
	SetPVarInt(playerid,"Change_Weapon",1);
	return 1;
}

CMD:gunmenu(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_gmenu","ds",playerid,params);
}

CMD:giveweapons(playerid,params[])
{
    SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_gmenu","ds",playerid,params);
}

CMD:weapmenu(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_gmenu","ds",playerid,params);
}

CMD:gw(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_gmenu","ds",playerid,params);
}

CMD:gmenu(playerid,params[])
{
	if(!GetPVarInt(playerid,"Admin")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(Server[Current] == -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Раунд не запущен");
	if(GetGVarInt("Starting")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Нельзя дать возможность перевыбора оружия во время запуска раунда");
	if(GetGVarInt("Busy")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Нельзя выдать меню перевыбора во время спавн-протекции");
	if(isnull(params) || !IsNumeric(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/gmenu [id]");
	new
		id = strval(params)
	;
	if(!GetPVarInt(id,"Connected")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрока (%i) нет на сервере",id);
	if(!GetPVarInt(id,"Spawned")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрок не заспавнен");
	if(!GetPVarInt(id,"Playing")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрок не находится в раунде");
    if(!GetPVarInt(id,"Weapon_1") || !GetPVarInt(id,"Weapon_2")) ShowPlayerFirstWeapDialog(id);
	else ShowPlayerChangeWeapDialog(id);
	if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}выдал меню перевыбора оружий игроку {FF0000}%s",Player[playerid][Name],Player[id][Name]);
	else return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}выдал меню перевыбора оружий игроку {FF0000}%s",Player[playerid][Name],Player[id][Name]);
}

CMD:s(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_rsp","ds",playerid,"\1");
}

CMD:rsp(playerid,params[])
{
	#pragma unused params
	if((GetTickCount() - GetPVarInt(playerid,"SyncTick")) <= 30000) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Ты синхронизируешься слишком часто");
	if(!GetGVarInt("SyncEnabled")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Синхронизация отключена администратором");
	if
	(
	GetPlayerState(playerid) != 1
	|| !GetPVarInt(playerid,"Playing")
	|| Server[Current] == -1
	|| GetGVarInt("Starting")
	|| GetPlayerVirtualWorld(playerid) != Round_VW
	|| GetPlayerSurfingVehicleID(playerid) != 0xFFFF
	) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Невозможно начать синхронизацию");
	SetPVarInt(playerid,"SyncTick",GetTickCount());
	SendClientMessage(playerid,-1,"[Инфо]: {AFAFAF}Синхронизация...");
	SyncPlayer(playerid);
	return 1;
}

CMD:sync(playerid,params[])
{
	if(isnull(params))
	{
		SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
		return CallLocalFunction("cmd_rsp","ds",playerid,"\1");
	}
	if(GetPVarInt(playerid,"Admin") < 4) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У вас нет доступа к этой комманде");
 	if(!strcmp(params,"on",true))
	{
 		if(GetGVarInt("SyncEnabled")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Синхронизация уже включена!");
 		SetGVarInt("SyncEnabled",1);
 		return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}включил синхронизацию",Player[playerid][Name]);
	}
	else if(!strcmp(params,"off",true))
	{
 		if(!GetGVarInt("SyncEnabled")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Синхронизация уже выключена");
 		SetGVarInt("SyncEnabled",0);
 		return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}выключил синхронизацию",Player[playerid][Name]);
	}
	return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/sync [on/off/без параметров]");
}

CMD:unpause(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_pause","ds",playerid,"off");
}

CMD:pause(playerid,params[])
{
    if(isnull(params))
	{
		SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
		return CallLocalFunction("cmd_pause","ds",playerid,"on");
	}
	if(GetPVarInt(playerid,"Admin") < 2) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(Server[Current] == -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Раунд не запущен");
	if(GetGVarInt("Starting")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Нельзя поставить игру на паузу во время запуска раунда");
	if(!strcmp(params,"on",true))
	{
	    if(GetGVarInt("Paused")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игра уже находится в режиме паузы");
	    SetGVarInt("Paused",1);
	    foreach_p(i)
		{
			if(GetPVarInt(i,"Playing"))
			{
				TogglePlayerControllable(i,false);
			}
		}
		if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}приостановил раунд",Player[playerid][Name]);
		else return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}приостановил раунд",Player[playerid][Name]);
	}
	else if(!strcmp(params,"off",true))
	{
	    if(!GetGVarInt("Paused")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игра не находится в режиме паузы");
	    SetGVarInt("Paused", false);
	    
	    foreach_p(i)
		{
			if(GetPVarInt(i, "Playing"))
			{
				TogglePlayerControllable(i, true);
				GameTextForPlayer(i,"~y~~h~Game~n~~b~~h~Continued!", 1200, 3);
			}
		}
		
		if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}возобновил раунд",Player[playerid][Name]);
		else return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}возобновил раунд",Player[playerid][Name]);
	}
	return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/pause [on | off]");
}

CMD:nplay(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_noplay","ds",playerid,"\1");
}

CMD:noplay(playerid,params[])
{
	#pragma unused params
	if(GetPVarInt(playerid,"No_Play")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы уже отключили игру в раундах, для включения введите {FFFF00}/play");
	SetPVarInt(playerid,"No_Play",1);
	return SendClientMessage(playerid,-1,"[Инфо]: {AFAFAF}Теперь вы не будете играть в раундах, для отключения введите {FFFF00}/play");
}

CMD:play(playerid,params[])
{
	#pragma unused params
	if(!GetPVarInt(playerid,"No_Play")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас уже есть возможность игры в раундах!");
	SetPVarInt(playerid,"No_Play",0);
	return SendClientMessage(playerid,-1,"[Инфо]: {AFAFAF}Вы вернули возможность играть в раундах");
}

CMD:stop(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_end","ds",playerid,"\1");
}

CMD:stopround(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_end","ds",playerid,"\1");
}

CMD:endround(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_end","ds",playerid,"\1");
}

CMD:end(playerid,params[])
{
	#pragma unused params
	if(GetPVarInt(playerid,"Admin") < 2) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(Server[Current] == -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Раунд не запущен");
	if(GetGVarInt("Starting") || GetGVarInt("Busy")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Нельзя остановить раунд во время запуска");
	StopRound();
	if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}остановил раунд",Player[playerid][Name]);
	else return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}остановил раунд",Player[playerid][Name]);
}

CMD:voteend(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_stopvote","ds",playerid,"\1");
}

CMD:endvote(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_stopvote","ds",playerid,"\1");
}

CMD:svote(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_stopvote","ds",playerid,"\1");
}

CMD:stopvote(playerid,params[])
{
	#pragma unused params
	if(GetPVarInt(playerid,"Admin") < 2) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(!GetGVarInt("Voting")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Голосование не запущено");
    StopVote();
	if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}остановил голосование",Player[playerid][Name]);
	else return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}остановил голосование",Player[playerid][Name]);
}

CMD:slock(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
    return CallLocalFunction("cmd_lock","ds",playerid,"on");
}

CMD:close(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
    return CallLocalFunction("cmd_lock","ds",playerid,"on");
}

CMD:lockserver(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
    return CallLocalFunction("cmd_lock","ds",playerid,"on");
}

CMD:lock(playerid,params[])
{
    if(GetPVarInt(playerid,"Admin") < 2) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
    if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/lock [on | off]");
    if(!strcmp(params,"on",true))
    {
	    if(GetGVarInt("Locked")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Сервер уже закрыт!");
	    SetGVarInt("Locked",1);
	    TextDrawShowForAll(Server[SLocked]);
	    if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}закрыл сервер",Player[playerid][Name]);
		else return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}закрыл сервер",Player[playerid][Name]);
	}
	else if(!strcmp(params,"off",true))
	{
	    if(!GetGVarInt("Locked")) return SendClientMessage(playerid,-1,"[Инфо]: {AFAFAF}Сервер уже открыт!");
	    SetGVarInt("Locked",0);
	    TextDrawHideForAll(Server[SLocked]);
		if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}открыл сервер",Player[playerid][Name]);
		else return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}открыл сервер",Player[playerid][Name]);
	}
	return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/lock [on | off]");
}

CMD:open(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
    return CallLocalFunction("cmd_lock","ds",playerid,"off");
}

CMD:unlock(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
    return CallLocalFunction("cmd_lock","ds",playerid,"off");
}

CMD:sunlock(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
    return CallLocalFunction("cmd_lock","ds",playerid,"off");
}

CMD:unlockserver(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
    return CallLocalFunction("cmd_lock","ds",playerid,"off");
}

CMD:reloadgame(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_reload","ds",playerid,"game");
}

CMD:reload(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") != 5) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/reload [game | server]");
	if(Server[Current] != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Это можно делать только на лобби");
	if(!strcmp(params,"game",true))
	{
	    SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}перезагрузил все базы/арены/CTF/DM/дуели",Player[playerid][Name]);
	    mysql_function_query(mysqlHandle,"SELECT * FROM `Arenas` WHERE 1",true,"OnArenasLoad","");
		mysql_function_query(mysqlHandle,"SELECT * FROM `Bases` WHERE 1",true,"OnBasesLoad","");
		mysql_function_query(mysqlHandle,"SELECT * FROM `CTF` WHERE 1",true,"OnCTFsLoad","");
		mysql_function_query(mysqlHandle,"SELECT * FROM `DM` WHERE 1",true,"OnDMsLoad","");
	    return 1;
	}
	else if(!strcmp(params,"server",true))
	{
	    SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}включил перезапуск сервера",Player[playerid][Name]);
		CallLocalFunction("ExitGameMode","");
		return 1;
	}
	return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/reload [config | game | server]");
}

CMD:srestart(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_reload","ds",playerid,"server");
}

CMD:restartserver(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_reload","ds",playerid,"server");
}

CMD:gmx(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_reload","ds",playerid,"server");
}

CMD:resetscores(playerid,params[])
{
	#pragma unused params
	if(GetPVarInt(playerid,"Admin") < 4) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(Server[Current] != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Это можно делать только на лобби");
	for(new i = (Max_Teams - 1); i != -1; --i)
	{
		SetGVarInt("Score",0,i);
	}
	return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}обнулил очки всем коммандам",Player[playerid][Name]);
}

CMD:specoff(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_spec","ds",playerid,"off");
}
	
CMD:spec(playerid,params[])
{
    if(!strcmp(params,"off",true)) 
    {
        if(GetPVarInt(playerid,"SpecID") == -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не следите");
		StopSpectate(playerid);
		return SendClientMessage(playerid,-1,"[Инфо]: {AFAFAF}Слежка окончена");
	}
	if(isnull(params) || !IsNumeric(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/spec [id]");
	if(!GetPVarInt(playerid,"Spawned")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не заспавнены");
	if(GetPVarInt(playerid,"Playing") || GetPVarInt(playerid,"DM_Zone") != -1 || GetPVarInt(playerid,"DuelID") != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы находитесь в игре");
	if(GetGVarInt("Starting") || Server[Current] == -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете начать слежку");
	new
		id = strval(params)
	;
	if(!GetPVarInt(id,"Connected")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрока (%i) нет на сервере",id);
	if(!GetPVarInt(id,"Playing")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрок не в раунде");
	if(id == playerid) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете следить за собой!");
	if(GetPVarInt(id,"SpecID") != -1 || GetPlayerState(id) == 9) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрок уже следит");
	if(GetPVarInt(id,"Team") != GetPVarInt(playerid,"Team") && GetPVarInt(playerid,"Team") != Team_Refferee) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете следить за игроками другой комманды");
	if(!GetPVarInt(id,"Spawned")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрок не заспавнен");
	SetPVarInt(playerid,"SpecID",id);
	SetPlayerVirtualWorld(playerid,GetPlayerVirtualWorld(id));
 	SetPlayerInterior(playerid,GetPlayerInterior(id));
 	if(GetPlayerState(playerid) != 9) PlayerTextDrawHide(playerid,Player[playerid][HealthBar]);
	TogglePlayerSpectating(playerid,true);
	if(IsPlayerInAnyVehicle(id)) PlayerSpectateVehicle(playerid,GetPlayerVehicleID(id));
	else PlayerSpectatePlayer(playerid,id);
	return 1;
}

CMD:report(playerid,params[])
{
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/report [id] [причина]");
	if(GetPVarInt(playerid,"Admin") > 0) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы администрация блеать!");
	if(!GetPVarInt(playerid,"Spawned")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не заспавнены");
	if(GetAdmins() < 1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Администрации онлайн нет!");
	new
	    str_param[12],
	    id
 	;
	if(sscanf(params,"ds[12]",id,str_param)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/report [id] [причина]");
	if(!GetPVarInt(id,"Connected")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрока (%i) нет на сервере",id);
	if(IsPlayerAdmin(id) || GetPVarInt(id,"Moderator")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете отправить жалобу на администратора/модератора");
	if(strlen(str_param) < 2 || strlen(str_param) > 10) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Неверная длина причины (от 2 до 10 символов)");
	foreach_p(i)
	{
		if(GetPVarInt(i,"Moderator") || IsPlayerAdmin(i))
		{
			SendClientMessage(i,-1,"[Инфо]: {FF0000}%s [ID: %i] {00FF40}отправил жалобу на {FF0000}%s [ID: %i], {FFFF00}(Причина: %s)",Player[playerid][Name],playerid,Player[id][Name],id,str_param);
		}
	}
	return SendClientMessage(playerid,-1,"[Инфо]: {AFAFAF}Ваша жалоба направлена всем администраторам, находящимся на сервере");
}

CMD:carspawn(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_car","ds",playerid,params);
}

CMD:spawncar(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_car","ds",playerid,params);
}

CMD:car(playerid,params[])
{
	if(Server[Current] == -1 || (Server[Current] != -1 && (!GetPVarInt(playerid,"Playing") || GetPVarInt(playerid,"No_Play"))))
	{
		SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
		return CallLocalFunction("cmd_veh","ds",playerid,params);
	}
	if(isnull(params)) return ShowPlayerDialog(playerid,CarList_Main,2,"{FFFFFF}Выбор транспорта","{FFFFFF}Автомобили\nМотоциклы\nВелосипеды\nЛодки\nВертолеты\nСамолеты","Дальше","Отмена");
	if(!GetPVarInt(playerid,"Spawned")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Ты не заспавнен");
	if(GetGVarInt("Starting")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете создать транспорт во время запуска раунда");
	if(GetPVarInt(playerid,"Team") != Team_Attack) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Только атака может спавнить транспорт");
	if(GetGVarInt("GameType") != Gametype_Base || GetPVarInt(playerid,"DM_Zone") != -1 || GetPVarInt(playerid,"DuelID") != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Транспорт возможно создавать только на базах");
	if(!PlayerToPoint(GetGVarFloat("Base_Distance"),playerid,Base[Server[Current]][AttSpawn][0],Base[Server[Current]][AttSpawn][1],Base[Server[Current]][AttSpawn][2])) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы слишком далеко от своего респауна и не можете создавать транспорт");
	if(GetPVarInt(playerid,"Cars_Spawned") >= 3) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы заспавнили максимально допустимое количество транспорта");
	if(IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы уже находитесь в транспорте");
 	new
		vid
	;
	if(!IsNumeric(params))
	{
		vid = sscanf_vehicle(params);
	}
 	else
 	{
	 	vid = strval(params);
	}
 	if(!(400 <= vid <= 611)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Неверный ID транспорта (%i)",vid);
 	for(new i, size = sizeof(ForbiddenVehicles); i != size; i++)
 	{
		if(ForbiddenVehicles[i] == vid) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете заспавнить этот транспорт");
	}
	SpawnVehicle(playerid,vid);
	return SendClientMessage(playerid,-1,"[Инфо]: {FF0000}%s {AFAFAF}- Транспорт создан {FFFF00}(%i/3)",CarList[vid - 400],GetPVarInt(playerid,"Cars_Spawned"));
}

CMD:v(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_veh","ds",playerid,params);
}

CMD:vehicle(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_veh","ds",playerid,params);
}

CMD:veh(playerid,params[])
{
	if(GetPVarInt(playerid,"Playing"))
	{
		SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
		return CallLocalFunction("cmd_car","ds",playerid,params);
	}
	if(IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы уже находитесь в транспорте");
	if(GetPVarInt(playerid,"SpecID") != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Невозможно создать транспорт во время слежки");
	if(!GetPVarInt(playerid,"Spawned")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не заспавнены");
	if(GetPVarInt(playerid,"DM_Zone") != -1 || GetPVarInt(playerid,"DuelID") != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Невозможно создать транспорт на DM/Дуели");
	if(isnull(params)) return ShowPlayerDialog(playerid,CarList_Main,2,"{FFFFFF}Выбор транспорта","{FFFFFF}Автомобили\nМотоциклы\nВелосипеды\nЛодки\nВертолеты\nСамолеты","Дальше","Отмена");
	new
		vid
	;
	if(!IsNumeric(params))
	{
		vid = sscanf_vehicle(params);
	}
	else
	{
		vid = strval(params);
	}
	if(!(400 <= vid <= 611)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Неверный ID транспорта (%i)",vid);
 	for(new i, size = sizeof(ForbiddenVehicles); i != size; i++)
  	{
 		if(ForbiddenVehicles[i] == vid) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете заспавнить этот транспорт");
	}
	SpawnVehicle(playerid,vid);
	return SendClientMessage(playerid,-1,"[Инфо]: {FF0000}%s {AFAFAF}- Транспорт создан",CarList[vid - 400]);
}

CMD:a(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_arena","ds",playerid,params);
}

CMD:arena(playerid,params[])
{
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/arena [0-%i | random]",GetGVarInt("A_Count") - 1);
	if(!GetPVarInt(playerid,"Spawned")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы должны быть заспавнены чтобы голосовать");
	if(!GetGVarInt("Vote_Avalible")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Возможность голосовать за базы/арены отключена администратором");
	if(GetPVarInt(playerid,"No_Play")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете проголосовать так как у Вас отключена игра на базах/аренах");
	if(GetOnlinePlayers() <= 1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Ты один на сервере!");
	if(GetActivePlayers() <= 1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У остальных игроков выключена игра на базах/аренах");
	if(AttsOnline() <= 0) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}На сервере нет атакеров для начала игры");
	if(DefsOnline() <= 0) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}На сервере нет дефендеров для начала игры");
	if(Server[Current] != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Раунд уже запущен!");
	if(GetGVarInt("Starting")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Нельзя голосовать во время запуска раунда");
	if(GetGVarInt("Busy")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}С конца раунда не прошло 5 секунд, вы не можете голосовать!");
	if(GetPVarInt(playerid,"Voted")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы уже проголосовали");

	new
	    arenaid,
		fake_name[24],
		pack[48]
	;
	
	if(!strcmp(params,"r",true) || !strcmp(params,"rand",true) || !strcmp(params,"random",true))
	{
	    if(!GetGVarInt("Voting"))
	    {
	        SetGVarInt("Voting",1);
	        SetPVarInt(playerid,"Voted",1);
	        
	        new
				i
			;
			
			for(i = GetGVarInt("A_Count"); i != -1; --i)
			{
				Arena[i][Votes] = 0;
			}
			
			for(i = GetGVarInt("B_Count"); i != -1; --i)
			{
				Base[i][Votes] = 0;
			}
			
			for(i = GetGVarInt("C_Count"); i != -1; --i)
			{
				CTF[i][Votes] = 0;
			}

			ARENA_RANDOM:
			arenaid = random(GetGVarInt("A_Count"));
	        if(!Arena[arenaid][Exists]) goto ARENA_RANDOM;
	        
	        Arena[arenaid][Votes]++;
	        SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}проголосовал за случайную арену {FFFF00}(%i)",Player[playerid][Name],arenaid);

			strcpy(fake_name,Player[playerid][Name]);
			ReplaceStyleChars(fake_name);
	        format(pack,48,"%s - Arena: %i",fake_name,arenaid);
	        strpack(vote_string,pack);
	        
			return CallLocalFunction("VoteCountTimer","d",GetGVarInt("Default_VotingTime"));
		}
		else
		{
			SetPVarInt(playerid,"Voted",1);
			
			ARENA_RANDOM_2:
			arenaid = random(GetGVarInt("A_Count"));
	        if(!Arena[arenaid][Exists]) goto ARENA_RANDOM_2;
	        
	        Arena[arenaid][Votes]++;
	        
			strcpy(fake_name,Player[playerid][Name]);
			ReplaceStyleChars(fake_name);
	        format(pack,48,"~n~%s - Arena: %i",fake_name,arenaid);
	        strcat(vote_string,pack);
	        
			return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}проголосовал за случайную арену {FFFF00}(%i)",Player[playerid][Name],arenaid);
		}
	}
	if(!IsNumeric(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/arena [0-%i | random]",GetGVarInt("A_Count") - 1);

	arenaid = strval(params);
	
	if(!(0 <= arenaid < GetGVarInt("A_Count")) || !Arena[arenaid][Exists]) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Арены №%i не существует",arenaid);
	if(!GetGVarInt("Voting"))
	{
	    SetGVarInt("Voting",1);
	    SetPVarInt(playerid,"Voted",1);
        
        new
			i
		;

		for(i = GetGVarInt("A_Count"); i != -1; --i)
		{
			Arena[i][Votes] = 0;
		}

		for(i = GetGVarInt("B_Count"); i != -1; --i)
		{
			Base[i][Votes] = 0;
		}

		for(i = GetGVarInt("C_Count"); i != -1; --i)
		{
			CTF[i][Votes] = 0;
		}
		
        Arena[arenaid][Votes]++;
        
		strcpy(fake_name,Player[playerid][Name]);
		ReplaceStyleChars(fake_name);
        format(pack,48,"%s - Arena: %i",fake_name,arenaid);
        strpack(vote_string,pack);
        
        return CallLocalFunction("VoteCountTimer","d",GetGVarInt("Default_VotingTime"));
	}
	else
	{
	    SetPVarInt(playerid,"Voted",1);
	    
	    Arena[arenaid][Votes]++;
	    
		strcpy(fake_name,Player[playerid][Name]);
		ReplaceStyleChars(fake_name);
	    format(pack,48,"~n~%s - Arena: %i",fake_name,arenaid);
	    strcat(vote_string,pack);
	}
	return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}проголосовал за арену {FFFF00}№%i",Player[playerid][Name],arenaid);
}

CMD:b(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_base","ds",playerid,params);
}

CMD:base(playerid,params[])
{
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/base [0-%i | random]",GetGVarInt("B_Count") - 1);
	if(!GetPVarInt(playerid,"Spawned")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы должны быть заспавнены чтобы голосовать");
	if(!GetGVarInt("Vote_Avalible")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Возможность голосовать за базы/арены/ctf отключена администратором");
	if(GetOnlinePlayers() <= 1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Ты один на сервере!");
	if(AttsOnline() <= 0) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}На сервере нет атакеров для начала игры");
	if(DefsOnline() <= 0) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}На сервере нет дефендеров для начала игры");
	if(Server[Current] != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Раунд уже запущен!");
	if(GetGVarInt("Starting")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Нельзя голосовать во время запуска раунда");
	if(!GetGVarInt("Starting") && GetGVarInt("Busy")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}С конца раунда не прошло 5 секунд, вы не можете голосовать!");
	if(GetPVarInt(playerid,"Voted")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы уже проголосовали");

	new
	    baseid,
		fake_name[24],
		pack[48]
	;
	
	if(!strcmp(params,"r",true) || !strcmp(params,"rand",true) || !strcmp(params,"random",true))
	{
	    if(!GetGVarInt("Voting"))
	    {
	        SetGVarInt("Voting",1);
	        SetPVarInt(playerid,"Voted",1);
	        
	        new
				i
			;

			for(i = GetGVarInt("A_Count"); i != -1; --i)
			{
				Arena[i][Votes] = 0;
			}

			for(i = GetGVarInt("B_Count"); i != -1; --i)
			{
				Base[i][Votes] = 0;
			}

			for(i = GetGVarInt("C_Count"); i != -1; --i)
			{
				CTF[i][Votes] = 0;
			}
			
			BASE_RANDOM:
			baseid = random(GetGVarInt("B_Count"));
	        if(!Base[baseid][Exists]) goto BASE_RANDOM;
	        
	        Base[baseid][Votes]++;
	        SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}проголосовал за случайную базу {FFFF00}(%i)",Player[playerid][Name],baseid);

			strcpy(fake_name,Player[playerid][Name]);
			ReplaceStyleChars(fake_name);
	        format(pack,48,"%s - Base: %i",fake_name,baseid);
	        strpack(vote_string,pack);
	        
			return CallLocalFunction("VoteCountTimer","d",GetGVarInt("Default_VotingTime"));
		}
		else
		{
			SetPVarInt(playerid,"Voted",1);
			
			BASE_RANDOM_2:
			baseid = random(GetGVarInt("B_Count"));
	        if(!Base[baseid][Exists]) goto BASE_RANDOM_2;
	        
	        Base[baseid][Votes]++;
	        
			strcpy(fake_name,Player[playerid][Name]);
			ReplaceStyleChars(fake_name);
			format(pack,48,"~n~%s - Base: %i",fake_name,baseid);
			strcat(vote_string,pack);
			
			return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}проголосовал за случайный CTF {FFFF00}(%i)",Player[playerid][Name],baseid);
		}
	}
	if(!IsNumeric(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/base [0-%i | random]",GetGVarInt("B_Count") - 1);

	baseid = strval(params);
	
	if(!(0 <= baseid < GetGVarInt("B_Count")) || !Base[baseid][Exists]) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Базы №%i не существует",baseid);
	if(!GetGVarInt("Voting"))
	{
	    SetGVarInt("Voting",1);
	    SetPVarInt(playerid,"Voted",1);
	    
     	new
			i
		;

		for(i = GetGVarInt("A_Count"); i != -1; --i)
		{
			Arena[i][Votes] = 0;
		}

		for(i = GetGVarInt("B_Count"); i != -1; --i)
		{
			Base[i][Votes] = 0;
		}

		for(i = GetGVarInt("C_Count"); i != -1; --i)
		{
			CTF[i][Votes] = 0;
		}
		
        Base[baseid][Votes]++;
        SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}проголосовал за базу {FFFF00}№%i",Player[playerid][Name],baseid);

		strcpy(fake_name,Player[playerid][Name]);
		ReplaceStyleChars(fake_name);
		format(pack,48,"%s - Base: %i",fake_name,baseid);
		strpack(vote_string,pack);
		
		return CallLocalFunction("VoteCountTimer","d",GetGVarInt("Default_VotingTime"));
	}
	else
	{
	    SetPVarInt(playerid,"Voted",1);
	    
	    Base[baseid][Votes]++;
	    
		strcpy(fake_name,Player[playerid][Name]);
		ReplaceStyleChars(fake_name);
		format(pack,48,"~n~%s - Base: %i",fake_name,baseid);
		strcat(vote_string,pack);
	}
	return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}проголосовал за базу {FFFF00}№%i",Player[playerid][Name],baseid);
}

CMD:c(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_ctf","ds",playerid,params);
}

CMD:ctf(playerid,params[])
{
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/ctf [0-%i | random]",GetGVarInt("C_Count") - 1);
	if(!GetGVarInt("C_Count")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Не могу запустить голосование за CTF. Нет подходящих CTF зон");
	if(!GetPVarInt(playerid,"Spawned")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы должны быть заспавнены чтобы голосовать");
	if(!GetGVarInt("Vote_Avalible")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Возможность голосовать за базы/арены/ctf отключена администратором");
	if(GetOnlinePlayers() <= 1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Ты один на сервере!");
	if(AttsOnline() <= 0) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}На сервере нет атакеров для начала игры");
	if(DefsOnline() <= 0) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}На сервере нет дефендеров для начала игры");
	if(Server[Current] != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Раунд уже запущен!");
	if(GetGVarInt("Starting")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Нельзя голосовать во время запуска раунда");
	if(!GetGVarInt("Starting") && GetGVarInt("Busy")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}С конца раунда не прошло 5 секунд, вы не можете голосовать!");
	if(GetPVarInt(playerid,"Voted")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы уже проголосовали");

	new
	    ctfid,
		fake_name[24],
		pack[48]
	;
	
	if(!strcmp(params,"r",true) || !strcmp(params,"rand",true) || !strcmp(params,"random",true))
	{
	    if(!GetGVarInt("Voting"))
	    {
	        SetGVarInt("Voting",1);
	        SetPVarInt(playerid,"Voted",1);
	        
	        new
				i
			;

			for(i = GetGVarInt("A_Count"); i != -1; --i)
			{
				Arena[i][Votes] = 0;
			}

			for(i = GetGVarInt("B_Count"); i != -1; --i)
			{
				Base[i][Votes] = 0;
			}

			for(i = GetGVarInt("C_Count"); i != -1; --i)
			{
				CTF[i][Votes] = 0;
			}
			
	        CTF_RANDOM:
			ctfid = random(GetGVarInt("C_Count"));
	        if(!CTF[ctfid][Exists]) goto CTF_RANDOM;
	        
	        CTF[ctfid][Votes]++;
	        SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}проголосовал за случайный CTF {FFFF00}(%i)",Player[playerid][Name],ctfid);

			strcpy(fake_name,Player[playerid][Name]);
			ReplaceStyleChars(fake_name);
	        format(pack,48,"%s - CTF: %i",fake_name,ctfid);
	        strpack(vote_string,pack);
	        
			return CallLocalFunction("VoteCountTimer","d",GetGVarInt("Default_VotingTime"));
		}
		else
		{
			SetPVarInt(playerid,"Voted",1);
			
			CTF_RANDOM_2:
			ctfid = random(GetGVarInt("C_Count"));
	        if(!CTF[ctfid][Exists]) goto CTF_RANDOM_2;
	        
	        CTF[ctfid][Votes]++;
	        
			strcpy(fake_name,Player[playerid][Name]);
			ReplaceStyleChars(fake_name);
			format(pack,48,"~n~%s - CTF: %i",fake_name,ctfid);
			strcat(vote_string,pack);
			
			return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}проголосовал за случайный CTF {FFFF00}(%i)",Player[playerid][Name],ctfid);
		}
	}
	if(!IsNumeric(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/ctf [0-%i | random]",GetGVarInt("C_Count") - 1);

	ctfid = strval(params);
	
	if(!(0 <= ctfid < GetGVarInt("C_Count")) || !CTF[ctfid][Exists]) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}CTF №%i не существует",ctfid);
	if(!GetGVarInt("Voting"))
	{
	    SetGVarInt("Voting",1);
	    SetPVarInt(playerid,"Voted",1);
	    
        new
			i
		;

		for(i = GetGVarInt("A_Count"); i != -1; --i)
		{
			Arena[i][Votes] = 0;
		}

		for(i = GetGVarInt("B_Count"); i != -1; --i)
		{
			Base[i][Votes] = 0;
		}

		for(i = GetGVarInt("C_Count"); i != -1; --i)
		{
			CTF[i][Votes] = 0;
		}
		
        CTF[ctfid][Votes]++;
		SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}проголосовал за CTF {FFFF00}№%i",Player[playerid][Name],ctfid);

		strcpy(fake_name,Player[playerid][Name]);
		ReplaceStyleChars(fake_name);
		format(pack,48,"%s - CTF: %i",fake_name,ctfid);
		strpack(vote_string,pack);
		
		return CallLocalFunction("VoteCountTimer","d",GetGVarInt("Default_VotingTime"));
	}
	else
	{
	    SetPVarInt(playerid,"Voted",1);
	    
	    CTF[ctfid][Votes]++;
	    
		strcpy(fake_name,Player[playerid][Name]);
		ReplaceStyleChars(fake_name);
		format(pack,48,"~n~%s - CTF: %i",fake_name,ctfid);
		strcat(vote_string,pack);
	}
	return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}проголосовал за CTF {FFFF00}№%i",Player[playerid][Name],ctfid);
}

CMD:dmzone(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_dm","ds",playerid,params);
}

CMD:dm(playerid,params[])
{
	new
		dmid
	;
	
	if(!strcmp(params,"r",true) || !strcmp(params,"rand",true) || !strcmp(params,"random",true))
	{
	    Randomise:
	    dmid = random(GetGVarInt("D_Count"));
	    if(!DM[dmid][Exists]) goto Randomise;
	}
	else
	{
	    if(!IsNumeric(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/dm [1-%i]",GetGVarInt("D_Count"));
	    dmid = (strval(params) - 1);
	}
	if(GetPVarInt(playerid,"Playing")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы на раунде!");
	if(!GetPVarInt(playerid,"Spawned")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не заспавнены");
	if(GetPVarInt(playerid,"DuelID") != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Сначала выйдите из дуели!");
	if(GetPVarInt(playerid,"DM_Zone") != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы уже находитесь на DM!");
	if(GetPVarInt(playerid,"SpecID") != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы следите");
	if(!(0 <= dmid < GetGVarInt("D_Count")) || !DM[dmid][Exists]) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}DM зоны №%i не существует",dmid + 1);
	if(IsPlayerInAnyVehicle(playerid)) SetPlayerPos(playerid,0.0,0.0,10.0);
	SetPVarInt(playerid,"DM_Zone",dmid);
	SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}зашел на DM {FFFF00}№%i",Player[playerid][Name],dmid + 1);
	SendClientMessage(playerid,-1,"[Инфо]: {FFFF00}/leave {AFAFAF}- выйти из DM");
	return SpawnPlayer(playerid);
}

CMD:d(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_duel","ds",playerid,"\1");
}

CMD:duel(playerid,params[])
{
	#pragma unused params
	if(GetPVarInt(playerid,"Playing")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Ты в раунде!");
	if(GetPVarInt(playerid,"Dm_Zone") != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Сначала выйди из DM!");
	if(!GetPVarInt(playerid,"Spawned")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не заспавнены");
	if(GetPVarInt(playerid,"SpecID") != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Сначала выйдите из режима слежки");
	if(GetPVarInt(playerid,"DuelID") != -1) return ShowPlayerDialog(playerid,Duel_Weapon,2,"{FFFFFF}Смена оружия для дуели","{FFFFFF}Desert Eagle\nShotgun\nM4\nSniper Rifle\nGrenades","Выбор","Отмена");
	return ShowPlayerDialog(playerid,Duel_Weapon,2,"{FFFFFF}Выбор оружия для дуели","{FFFFFF}Desert Eagle\nShotgun\nM4\nSniper Rifle\nGrenades","Выбор","Отмена");
}

CMD:vote(playerid,params[])
{
    if(GetPVarInt(playerid,"Admin") < 2) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(!strcmp(params,"on",true))
	{
	    if(GetGVarInt("Vote_Avalible")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Возможность голосования уже включена");
	    SetGVarInt("Vote_Avalible",1);
	    return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}включил возможность голосования за базы/арены",Player[playerid][Name]);
	}
	else if(!strcmp(params,"off",true))
	{
	    if(!GetGVarInt("Vote_Avalible")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Возможность голосования уже отключена");
	    SetGVarInt("Vote_Avalible",0);
	    if(GetGVarInt("Voting")) StopVote();
	    return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}отключил возможность голосования за базы/арены",Player[playerid][Name]);
	}
	return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/vote [on | off]");
}

CMD:arenastart(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_sarena","ds",playerid,params);
}

CMD:startarena(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_sarena","ds",playerid,params);
}

CMD:sarena(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 2) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(Server[Current] != -1 || GetGVarInt("Starting") || GetGVarInt("Busy")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Арена уже запущена, запускается, или не прошло 5 секунд после конца игры");
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/sarena [0-%i | random]",GetGVarInt("A_Count") - 1);
	if(!strcmp(params,"r",true) || !strcmp(params,"rand",true) || !strcmp(params,"random",true))
	{
	    new
			arenaid
		;
		
	    Randomise:
	    arenaid = random(GetGVarInt("A_Count"));
		if(!Arena[arenaid][Exists]) goto Randomise;
	    if(GetGVarInt("Voting")) StopVote();
	    CallLocalFunction("StartMode","dd",arenaid,Gametype_Arena);
	    if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}запускает случайную арену {FFFF00}(%i)",Player[playerid][Name],arenaid);
	    else return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}запускает случайную арену {FFFF00}(%i)",Player[playerid][Name],arenaid);
	}
	if(!IsNumeric(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/sarena [0-%i | random]",GetGVarInt("A_Count") - 1);
	new arenaid = strval(params);
	if(!(0 <= arenaid < GetGVarInt("A_Count")) || !Arena[arenaid][Exists]) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Арены №%i не существует",arenaid);
	if(GetGVarInt("Voting")) StopVote();
	CallLocalFunction("StartMode","dd",arenaid,Gametype_Arena);
	if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}запускает арену {FFFF00}№%i",Player[playerid][Name],arenaid);
	else return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}запускает арену {FFFF00}№%i",Player[playerid][Name],arenaid);
}

CMD:basestart(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_sbase","ds",playerid,params);
}

CMD:startbase(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_sbase","ds",playerid,params);
}

CMD:sbase(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 2) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(Server[Current] != -1 || GetGVarInt("Starting") || GetGVarInt("Busy")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}База уже запущена, запускается, или не прошло 5 секунд после конца игры");
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/sbase [0-%i | random]",GetGVarInt("B_Count") - 1);
	if(!strcmp(params,"r",true) || !strcmp(params,"rand",true) || !strcmp(params,"random",true))
	{
	    new
			baseid
		;
		
	    Randomise:
	    baseid = random(GetGVarInt("B_Count"));
	    if(!Base[baseid][Exists]) goto Randomise;
	    if(GetGVarInt("Voting")) StopVote();
	    CallLocalFunction("StartMode","dd",baseid,Gametype_Base);
	    if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}запускает случайную базу {FFFF00}(%i)",Player[playerid][Name],baseid);
	    else return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}запускает случайную базу {FFFF00}(%i)",Player[playerid][Name],baseid);
	}
	if(!IsNumeric(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/sbase [0-%i | random]",GetGVarInt("B_Count") - 1);
	new baseid = strval(params);
	if(!(0 <= baseid < GetGVarInt("B_Count")) || !Base[baseid][Exists]) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Базы №%i не существует",baseid);
	if(GetGVarInt("Voting")) StopVote();
	CallLocalFunction("StartMode","dd",baseid,Gametype_Base);
	if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}запускает базу {FFFF00}№%i",Player[playerid][Name],baseid);
	else return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}запускает базу {FFFF00}№%i",Player[playerid][Name],baseid);
}

CMD:ctfstart(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_sctf","ds",playerid,params);
}

CMD:startctf(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_sctf","ds",playerid,params);
}

CMD:sctf(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 2) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(Server[Current] != -1 || GetGVarInt("Starting") || GetGVarInt("Busy")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Арена уже запущена, запускается, или не прошло 5 секунд после конца игры");
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/sctf [0-%i | random]",GetGVarInt("C_Count") - 1);
	if(!strcmp(params,"r",true) || !strcmp(params,"rand",true) || !strcmp(params,"random",true))
	{
	    new
			ctfid
		;
		
	    Randomise:
	    ctfid = random(GetGVarInt("C_Count"));
	    if(!CTF[ctfid][Exists]) goto Randomise;
	    if(GetGVarInt("Voting")) StopVote();
	    CallLocalFunction("StartMode","dd",ctfid,Gametype_CTF);
	    if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}запускает случайный CTF {FFFF00}(%i)",Player[playerid][Name],ctfid);
	    else return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}запускает случайный CTF {FFFF00}(%i)",Player[playerid][Name],ctfid);
	}
	if(!IsNumeric(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/sctf [0-%i | random]",GetGVarInt("C_Count") - 1);
	new ctfid = strval(params);
	if(!(0 <= ctfid < GetGVarInt("C_Count")) || !CTF[ctfid][Exists]) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}CTF №%i не существует",ctfid);
	if(GetGVarInt("Voting")) StopVote();
	CallLocalFunction("StartMode","dd",ctfid,Gametype_CTF);
	if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}запускает CTF {FFFF00}№%i",Player[playerid][Name],ctfid);
	else return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}запускает CTF {FFFF00}№%i",Player[playerid][Name],ctfid);
}

CMD:switch(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_team","ds",playerid,"\1");
}

CMD:changeteam(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_team","ds",playerid,"\1");
}

CMD:team(playerid,params[])
{
	if(isnull(params))
	{
	    new
	        team_data[3][12],
	        string_data[128]
		;
		
	    GetGVarString("Team_Name",team_data[0],12,Team_Attack);
	    GetGVarString("Team_Name",team_data[1],12,Team_Defend);
	    GetGVarString("Team_Name",team_data[2],12,Team_Refferee);
	    format(string_data,128,"{FFFFFF}Атакеры (%s)\nДефендеры (%s)\nРеффери (%s)",team_data[0],team_data[1],team_data[2]);
		return ShowPlayerDialog(playerid,SwitchDialog,2,"{FFFFFF}Выбор комманды",string_data,"Выбор","Отмена");
	}
	if(Server[Current] != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Это можно сделать только вне раунда");
	if(GetGVarInt("Busy")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}С конца раунда не прошло 5 секунд, подождите");
	if(!GetPVarInt(playerid,"Spawned")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не заспавнены");
	if(GetPVarInt(playerid,"Playing") || GetPVarInt(playerid,"DM_Zone") != -1 || GetPVarInt(playerid,"DuelID") != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы должны находиться на лобби");
	if(!strcmp(params,"a",true) || !strcmp(params,"att",true) || !strcmp(params,"attack",true) || !strcmp(params,"attackers",true))
	{
		switch(GetPVarInt(playerid,"Team"))
		{
		    case Team_Attack: return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы уже находитесь в этой комманде!");
			default: SetTeam(playerid,Team_Attack);
		}
		return 1;
	}
	else if(!strcmp(params,"d",true) || !strcmp(params,"def",true) || !strcmp(params,"defend",true) || !strcmp(params,"defenders",true))
	{
	    switch(GetPVarInt(playerid,"Team"))
		{
		    case Team_Defend: return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы уже находитесь в этой комманде!");
			default: SetTeam(playerid,Team_Defend);
		}
		return 1;
	}
	else if(!strcmp(params,"r",true) || !strcmp(params,"ref",true) || !strcmp(params,"reffer",true) || !strcmp(params,"refferee",true))
	{
	    switch(GetPVarInt(playerid,"Team"))
		{
		    case Team_Refferee: return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы уже находитесь в этой комманде!");
			default: SetTeam(playerid,Team_Refferee);
		}
		return 1;
	}
	return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/team [att | def | ref]");
}

CMD:swap(playerid,params[])
{
	if(!isnull(params))
	{
		SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
		return CallLocalFunction("cmd_aswap","ds",playerid,params);
	}
	#pragma unused params
	if(Server[Current] != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Дождитесь окончания раунда");
	if(GetGVarInt("Busy")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}С конца раунда не прошло 5 секунд, подождите");
	if(!GetPVarInt(playerid,"Spawned")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не заспавнены");
	if(GetPVarInt(playerid,"Playing") || GetPVarInt(playerid,"DM_Zone") != -1 || GetPVarInt(playerid,"DuelID") != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы должны находиться на лобби");
	switch(GetPVarInt(playerid,"Team"))
	{
	    case Team_Attack: SetTeam(playerid,Team_Defend);
	    case Team_Defend: SetTeam(playerid,Team_Attack);
	    default: return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы находитесь в неверной комманде");
	}
	return 1;
}

CMD:aswap(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 2) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params) || !IsNumeric(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/aswap [id]");

	new
		id = strval(params)
	;
	
	if(Server[Current] != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Это можно сделать только вне раунда");
	if(GetGVarInt("Busy")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}С конца раунда не прошло 5 секунд, подождите");
	if(!GetPVarInt(id,"Connected")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрока (%i) нет на сервере",id);
	if(!GetPVarInt(id,"Spawned")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрок не заспавнен");
	if(GetPVarInt(id,"Playing") || GetPVarInt(id,"DM_Zone") != -1 || GetPVarInt(id,"DuelID") != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрок должен находиться на лобби");
	switch(GetPVarInt(id,"Team"))
	{
	    case Team_Attack: SetTeam(id,Team_Defend);
	    case Team_Defend: SetTeam(id,Team_Attack);
	    default:
	    {
	        switch(random(2))
	        {
	            case 0: SetTeam(id,Team_Defend);
	            case 1: SetTeam(id,Team_Attack);
			}
		}
	}
	if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}сменил комманду игроку {FF0000}%s",Player[playerid][Name],Player[id][Name]);
	else return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}сменил комманду игроку {FF0000}%s",Player[playerid][Name],Player[id][Name]);
}

CMD:swapall(playerid,params[])
{
	#pragma unused params
	if(GetPVarInt(playerid,"Admin") < 2) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(Server[Current] != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Это можно делать только вне раунда");
	if(GetGVarInt("Busy")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}С конца раунда не прошло 5 секунд, подождите");
    CallLocalFunction("SwapAll","");
	if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessage(playerid,-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}сменил комманды местами",Player[playerid][Name]);
	else return SendClientMessage(playerid,-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}сменил комманды местами",Player[playerid][Name]);
}

CMD:autoswap(playerid,params[])
{
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/autoswap [on | off]");
	if(GetPVarInt(playerid,"Admin") < 4) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(Server[Current] != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Настройки сервера можно менять только на лобби");
	if(!strcmp(params,"on",true))
	{
	    if(GetGVarInt("AutoSwap")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Автосвап уже включен");
	    SetGVarInt("AutoSwap",1);
	    return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}включил автосвап",Player[playerid][Name]);
	}
	else if(!strcmp(params,"off",true))
	{
	    if(!GetGVarInt("AutoSwap")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Автосвап уже выключен");
	    SetGVarInt("AutoSwap",0);
	    return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}выключил автосвап",Player[playerid][Name]);
	}
	return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/autoswap [on | off]");
}

CMD:balance(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 2) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(Server[Current] != -1 || GetGVarInt("Starting")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Невозможно сбалансировать комманды");
	if(GetGVarInt("Busy")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}С конца раунда не прошло 5 секунд, подождите");

	new
		type = BalanceType_Random
	;
	
	if(isnull(params) || !IsNumeric(params))
	{
		type = GetGVarInt("AutoBalance_Type");
	}
	else
	{
		type = strval(params);
	}
	if(!strcmp(params,"r",true) || !strcmp(params,"rand",true) || !strcmp(params,"random",true)) type = BalanceType_Random;
	if(!(0 <= type <= 2)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Неверный тип автобаланса (%i) {FFFF00}[0-2]",type);
    CallLocalFunction("Balance","d",type);
	if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}сбалансировал комманды",Player[playerid][Name]);
	else return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}сбалансировал комманды",Player[playerid][Name]);
}

CMD:autobalance(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_abalance","ds",playerid,params);
}

CMD:abalance(playerid,params[])
{
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/abalance [on | off]");
	if(GetPVarInt(playerid,"Admin") < 4) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(Server[Current] != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Настройки сервера можно менять только на лобби");
	if(!strcmp(params,"on",true))
	{
	    if(GetGVarInt("AutoBalance")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Автобаланс уже включен");
	    SetGVarInt("AutoBalance",1);
	    return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}включил автобаланс",Player[playerid][Name]);
	}
	else if(!strcmp(params,"off",true))
	{
	    if(!GetGVarInt("AutoBalance")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Автобаланс уже выключен");
	    SetGVarInt("AutoBalance",0);
	    return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}выключил автобаланс",Player[playerid][Name]);
	}
	return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/abalance [on | off]");
}

CMD:balancetype(playerid,params[])
{
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/balancetype [0,1 | random]");
	if(GetPVarInt(playerid,"Admin") < 4) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(Server[Current] != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Настройки сервера можно менять только на лобби");

	new
		type
	;
	
	if(!strcmp(params,"r",true) || !strcmp(params,"rand",true) || !strcmp(params,"random",true))
	{
		type = -1;
	}
	else
	{
	    if(!IsNumeric(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/balancetype [0,1 | random]");
	    type = strval(params);
	    if(type != 0 && type != 1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Неверный тип автобаланса (%i)",type);
	}
 	switch(++type)
 	{
 		case 0:
	 	{
 			SetGVarInt("AutoBalance_Type",BalanceType_Random);
	 		return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}изменил тип автобаланса на {FFFF00}'Рандом'",Player[playerid][Name]);
		}
		case 1:
        {
 			SetGVarInt("AutoBalance_Type",BalanceType_1);
	 		return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}изменил тип автобаланса на {FFFF00}'№1'",Player[playerid][Name]);
		}
		case 2:
		{
 			SetGVarInt("AutoBalance_Type",BalanceType_2);
	 		return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}изменил тип автобаланса на {FFFF00}'№2'",Player[playerid][Name]);
		}
	}
	return 1;
}

CMD:cw(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 4) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/cw [on | off]");
	if(Server[Current] != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Настройки сервера можно менять только на лобби");
	if(!strcmp(params,"on",true))
	{
	    if(GetGVarInt("CW")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}CW мод уже включен!");
	    SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}включил CW мод",Player[playerid][Name]);
	    SetGVarInt("CW",1);
		return 1;
	}
	else if(!strcmp(params,"off",true))
	{
	    if(!GetGVarInt("CW")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}CW мод уже выключен!");
	    SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}выключил CW мод",Player[playerid][Name]);
	    SetGVarInt("CW",0);
		return 1;
	}
	SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/cw [on | off]");
	return 1;
}

CMD:cbug(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 4) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/cbug [on | off]");
	if(Server[Current] != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Настройки сервера можно менять только на лобби");
	if(!strcmp(params,"on",true))
	{
	    if(GetGVarInt("AntiBug_C")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Анти +С уже включен!");
	    SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}включил анти +С баг",Player[playerid][Name]);
	    SetGVarInt("AntiBug_C",1);
		return 1;
	}
	else if(!strcmp(params,"off",true))
	{
	    if(!GetGVarInt("AntiBug_C")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Анти +С уже выключен!");
	    SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}выключил анти +С баг",Player[playerid][Name]);
	    SetGVarInt("AntiBug_C",0);
		return 1;
	}
	SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/cbug [on | off]");
	return 1;
}

CMD:sbug(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 4) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/sbug [on | off]");
	if(Server[Current] != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Настройки сервера можно менять только на лобби");
	if(!strcmp(params,"on",true))
	{
	    if(GetGVarInt("AntiBug_S")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Анти Slide уже включен!");
	    SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}включил анти Slide баг",Player[playerid][Name]);
	    SetGVarInt("AntiBug_S",1);
		return 1;
	}
	else if(!strcmp(params,"off",true))
	{
	    if(!GetGVarInt("AntiBug_S")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Анти Slide уже выключен!");
	    SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}выключил анти Slide баг",Player[playerid][Name]);
	    SetGVarInt("AntiBug_S",0);
		return 1;
	}
	SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/sbug [on | off]");
	return 1;
}

CMD:gbug(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 4) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/gbug [on | off]");
	if(Server[Current] != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Настройки сервера можно менять только на лобби");
	if(!strcmp(params,"on",true))
	{
	    if(GetGVarInt("AntiBug_G")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Анти Grenade Bug уже включен!");
	    SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}включил анти Grenade баг",Player[playerid][Name]);
	    SetGVarInt("AntiBug_G",1);
		return 1;
	}
	else if(!strcmp(params,"off",true))
	{
	    if(!GetGVarInt("AntiBug_G")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Анти Grenade Bug уже выключен!");
	    SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}выключил анти Grenade Bug баг",Player[playerid][Name]);
	    SetGVarInt("AntiBug_G",0);
		return 1;
	}
	SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/gbug [on | off]");
	return 1;
}

CMD:kbug(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 4) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/kbug [on | off]");
	if(Server[Current] != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Настройки сервера можно менять только на лобби");
	if(!strcmp(params,"on",true))
	{
	    if(GetGVarInt("AntiBug_K")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Анти Knife Bug уже включен!");
	    SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}включил анти Knife баг",Player[playerid][Name]);
	    SetGVarInt("AntiBug_K",1);
		return 1;
	}
	else if(!strcmp(params,"off",true))
	{
	    if(!GetGVarInt("AntiBug_K")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Анти Knife Bug уже выключен!");
	    SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}выключил анти Knife Bug баг",Player[playerid][Name]);
	    SetGVarInt("AntiBug_K",0);
		return 1;
	}
	SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/kbug [on | off]");
	return 1;
}

CMD:awh(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 4) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/awh [on | off]");
	if(Server[Current] != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Настройки сервера можно менять только на лобби");
	if(!strcmp(params,"on",true))
	{
	    if(GetGVarInt("AntiCheat_Weapon")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Античит на оружие уже включен!");
	    SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}включил античит на оружие",Player[playerid][Name]);
	    SetGVarInt("AntiCheat_Weapon",1);
		return 1;
	}
	else if(!strcmp(params,"off",true))
	{
	    if(!GetGVarInt("AntiCheat_Weapon")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Античит на оружие уже выключен!");
	    SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}выключил античит на оружие",Player[playerid][Name]);
	    SetGVarInt("AntiCheat_Weapon",0);
		return 1;
	}
	SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/awh [on | off]");
	return 1;
}

CMD:acl(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 4) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/acl [on | off]");
	if(Server[Current] != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Настройки сервера можно менять только на лобби");
	if(!strcmp(params,"on",true))
	{
	    if(GetGVarInt("AntiCheat_Load")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Анти Loading уже включен!");
	    SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}включил анти Loading",Player[playerid][Name]);
	    SetGVarInt("AntiCheat_Load",1);
		return 1;
	}
	else if(!strcmp(params,"off",true))
	{
	    if(!GetGVarInt("AntiCheat_Load")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Анти Loading уже выключен!");
	    SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}выключил анти Loading",Player[playerid][Name]);
	    SetGVarInt("AntiCheat_Load",0);
		return 1;
	}
	SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/acl [on | off]");
	return 1;
}

CMD:afw(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 4) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/afw [on | off]");
	if(Server[Current] != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Настройки сервера можно менять только на лобби");
	if(!strcmp(params,"on",true))
	{
	    if(GetGVarInt("AntiCheat_FastWalk")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Анти FastWalk уже включен!");
	    SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}включил анти FastWalk",Player[playerid][Name]);
	    SetGVarInt("AntiCheat_FastWalk",1);
		return 1;
	}
	else if(!strcmp(params,"off",true))
	{
	    if(!GetGVarInt("AntiCheat_FastWalk")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Анти FastWalk уже выключен!");
	    SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}выключил анти FastWalk",Player[playerid][Name]);
	    SetGVarInt("AntiCheat_FastWalk",0);
		return 1;
	}
	SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/afw [on | off]");
	return 1;
}

CMD:teamname(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_tname","ds",playerid,params);
}

CMD:tname(playerid,params[])
{
    if(GetPVarInt(playerid,"Admin") < 4) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
    if(Server[Current] != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Смену имени можно делать только на лобби");
    if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/tname [att | def | ref] [имя]");

	new
	    str_param[4],
	    str_param_2[10]
 	;
 	
	if(sscanf(params,"s[4]s[10]",str_param,str_param_2)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/tname [att | def | ref] [имя]");
	if(isnull(str_param)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Введите комманду, которой хотите назначить имя");
	if(isnull(str_param_2)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Введите желаемое имя комманды");
	if(strlen(str_param_2) > 8) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Имя комманды должно быть максимум 8 символов");
	if(!strcmp(str_param,"att",true) || !strcmp(str_param,"attack",true) || !strcmp(str_param,"attackers",true))
	{
		SetGVarString("Team_Name",str_param_2,Team_Attack);
		return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}сменил имя комманды атакеров на {FFFF00}'%s'",Player[playerid][Name],str_param_2);
	}
	else if(!strcmp(str_param,"def",true) || !strcmp(str_param,"defend",true) || !strcmp(str_param,"defenders",true))
	{
	    SetGVarString("Team_Name",str_param_2,Team_Defend);
	    return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}сменил имя комманды дефендеров на {FFFF00}'%s'",Player[playerid][Name],str_param_2);
	}
	else if(!strcmp(str_param,"ref",true) || !strcmp(str_param,"refferee",true))
	{
	    SetGVarString("Team_Name",str_param_2,Team_Refferee);
        return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}сменил имя комманды судей на {FFFF00}'%s'",Player[playerid][Name],str_param_2);
	}
	return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/tname [att | def | ref] [новое имя]");
}

CMD:changename(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_setname","ds",playerid,params);
}

CMD:setname(playerid,params[])
{
    if(GetPVarInt(playerid,"Admin") < 4) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
    if(Server[Current] != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Это нельзя сделать во время раунда");
    if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/setname [id] [имя]");

	new
        str_param[24],
        id
    ;
    
	if(sscanf(params,"ds[24]",id,str_param)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/setname [id] [имя]");
    if(!GetPVarInt(id,"Connected")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрока (%i) нет на сервере",id);
    if(isnull(str_param)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Введите новое имя");
    if(strlen(str_param) > 20) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Длина имени превышает допустимую");
    if(id == playerid) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете сменить имя себе");
    if(IsPlayerAdmin(id) || GetPVarInt(id,"Moderator")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете сменить имя администратору/модератору");
    SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}сменил имя игроку {FF0000}%s {AFAFAF}на {FFFF00}'%s'",Player[playerid][Name],Player[id][Name],str_param);
	new query[128];
	format(query,128,"UPDATE `Accounts` SET `Name` = '%s' WHERE `Name` = '%s'",str_param,Player[id][Name]);
	mysql_function_query(mysqlHandle,query,false,"OnPlayerNameChange","dss",playerid,Player[id][Name],str_param);
	strcpy(Player[id][Name],str_param);
	SetPlayerName(id,Player[id][Name]);
	return 1;
}

CMD:vkick(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_votekick","ds",playerid,params);
}

CMD:votekick(playerid,params[])
{
	if(isnull(params))
	{
		if(GetGVarInt("VoteKick_Active")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/votekick [id]");
		else return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/votekick [id] [причина]");
	}
	if(!GetPVarInt(playerid,"Spawned")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не заспавнены");
	if(GetGVarInt("VoteKick_Voted",playerid)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы уже проголосовали");
	if(GetGVarInt("VoteKick_Active"))
	{
	    new
			id = strval(params)
		;
		
	    if(id != GetGVarInt("VoteKick_ID")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Чтобы проголосовать за кик другого игрока дождитесь окончания текущего голосования");
	    if(playerid == GetGVarInt("VoteKick_ID") && id == playerid) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Ты идиот?");
		GiveGVarInt("VoteKick_Votes",1,0);
		SetGVarInt("VoteKick_Voted",1,playerid);
	    return SendClientMessageToAll(-1,"[Инфо]: {00FF40}Игрок {FF0000}%s {00FF40}добавил свой голос за кик игрока %s {FFFF00}(%i/%i)",Player[playerid][Name],Player[GetGVarInt("VoteKick_ID")][Name],GetGVarInt("VoteKick_Votes"),floatround(GetOnlinePlayers() / 1.5));
	}
	else
	{
	    new
	        str_param[12],
	        id
     	;
     	
		if(sscanf(params,"ds[12]",id,str_param)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/votekick [id] [причина]");
	    if(isnull(str_param)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Введите причину старта голосования");
	    if(strlen(str_param) > 10) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Слишком длинная причина");
		if(GetOnlinePlayers() <= 3) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Для старта голосования мало игроков");
		if(id == playerid) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете начать голосование против себя");
	    if(!GetPVarInt(id,"Connected")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрока (%i) нет на сервере",id);
	    if(!GetPVarInt(id,"Logged")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Дождитесь полного подключения игрока");
	    if(IsPlayerAdmin(id) || GetPVarInt(id,"Moderator")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете проголосовать за кик администратора");
	    if(GetGVarInt("VoteBan_Active") && GetGVarInt("VoteBan_ID") == id) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}За этого игрока уже идет вотебан-голосование");
	    SetGVarInt("VoteKick_Active",1);
	    SetGVarInt("VoteKick_Voted",1,playerid);
	    SetGVarInt("VoteKick_ID",id);
	    SetGVarInt("VoteKick_Votes",1);
	    SendClientMessageToAll(-1,"[Инфо]: {00FF40}Игрок {FF0000}%s {00FF40}инициировал голосование за кик игрока {FF0000}%s {FFFF00}(Причина: %s)",Player[playerid][Name],Player[id][Name],str_param);
	    SetGVarString("VoteKick_Reason",str_param);
	}
	return CallLocalFunction("VoteKickMove","d",30);
}

CMD:vban(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_voteban","ds",playerid,params);
}

CMD:voteban(playerid,params[])
{
	if(isnull(params))
	{
		if(GetGVarInt("VoteBan_Active")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/voteban [id]");
		else return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/voteban [id] [причина]");
	}
	if(!GetPVarInt(playerid,"Spawned")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не заспавнены");
	if(GetGVarInt("VoteBan_Voted",playerid)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы уже проголосовали");
	if(GetGVarInt("VoteBan_Active"))
	{
	    new
			id = strval(params)
		;
		
	    if(id != GetGVarInt("VoteBan_ID")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Чтобы проголосовать за бан другого игрока дождитесь окончания текущего голосования");
	    if(playerid == GetGVarInt("VoteBan_ID") && id == playerid) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Ты идиот?");
		GiveGVarInt("VoteBan_Votes",1,0);
		SetGVarInt("VoteBan_Voted",1,playerid);
	    return SendClientMessageToAll(-1,"[Инфо]: {00FF40}Игрок {FF0000}%s {00FF40}добавил свой голос за бан игрока %s {FFFF00}(%i/%i)",Player[playerid][Name],Player[GetGVarInt("VoteBan_ID")][Name],GetGVarInt("VoteBan_Votes"),GetOnlinePlayers() - 1);
	}
	else
	{
	    new
	        str_param[12],
	        id
     	;
     	
		if(sscanf(params,"ds[12]",id,str_param)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/voteban [id] [причина]");
	    if(isnull(str_param)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Введите причину старта голосования");
	    if(strlen(str_param) > 10) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Слишком длинная причина");
        if(GetOnlinePlayers() < 5) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Для старта голосования мало игроков");
		if(id == playerid) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете начать голосование против себя");
	    if(!GetPVarInt(id,"Connected")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрока (%i) нет на сервере",id);
		if(!GetPVarInt(id,"Logged")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Дождитесь полного подключения игрока");
	    if(IsPlayerAdmin(id) || GetPVarInt(id,"Moderator")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете проголосовать за бан администратора");
	    if(GetGVarInt("VoteKick_Active") && GetGVarInt("VoteKick_ID") == id) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}За этого игрока уже идет вотекик-голосование");
	    SetGVarInt("VoteBan_Active",1);
	    SetGVarInt("VoteBan_Voted",1,playerid);
	    SetGVarInt("VoteBan_ID",id);
	    SetGVarInt("VoteBan_Votes",1);
	    SendClientMessageToAll(-1,"[Инфо]: {00FF40}Игрок {FF0000}%s {00FF40}инициировал голосование за бан игрока {FF0000}%s {FFFF00}(Причина: %s)",Player[playerid][Name],Player[id][Name],str_param);
	    SetGVarString("VoteBan_Reason",str_param);
	}
	return CallLocalFunction("VoteBanMove","d",30);
}

CMD:diss(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_remove","ds",playerid,params);
}

CMD:disqual(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_remove","ds",playerid,params);
}

CMD:remove(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 2) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
    if(isnull(params) || !IsNumeric(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/remove [id]");

	new
		id = strval(params)
	;
	
    if(!GetPVarInt(id,"Connected")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрока (%i) нет на сервере",id);
    if(!GetPVarInt(id,"Playing")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрок не в раунде");
    RemoveFromRound(id);
	if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}дисквалифицировал игрока {FF0000}%s {AFAFAF}из раунда",Player[playerid][Name],Player[id][Name]);
	else return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}дисквалифицировал игрока {FF0000}%s {AFAFAF}из раунда",Player[playerid][Name],Player[id][Name]);
}

CMD:addplayer(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_add","ds",playerid,params);
}

CMD:add(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 2) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(Server[Current] == -1 || GetGVarInt("Starting")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Сейчас не раунд");
    if(isnull(params) || !IsNumeric(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/add [id]");

	new
		id = strval(params)
	;
	
    if(!GetPVarInt(id,"Connected")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрока (%i) нет на сервере",id);
    if(GetPVarInt(id,"Playing")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрок уже в раунде");
	if(GetPVarInt(id,"No_Play")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Данный игрок отключил игру на раундах");
	if(GetPVarInt(id,"AFK_In")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Этот игрок находится в режиме AFK");
    AddToRound(id);
	if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}добавил в раунд игрока {FF0000}%s",Player[playerid][Name],Player[id][Name]);
	else return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}добавил в раунд игрока {FF0000}%s",Player[playerid][Name],Player[id][Name]);
}

CMD:adminkill(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_akill","ds",playerid,params);
}

CMD:akill(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 2) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/akill [id] [причина]");

	new
	    str_param[22],
	    id
 	;
 	
	if(sscanf(params,"ds[22]",id,str_param)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/akill [id] [причина]");
    if(!GetPVarInt(id,"Connected")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрока (%i) нет на сервере",id);
    if(isnull(str_param)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Введите причину убийства");
    if(strlen(str_param) > 20) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Слишком длинная причина убийства");
    if(id == playerid) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Лентяй, введи {FFFF00}/kill {AFAFAF}!");
    if(IsPlayerAdmin(id)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете убить администратора");
    if(GetPVarInt(id,"AFK_In")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Этот игрок находится в режиме AFK");
	SetPVarInt(id,"Killed",1);
	SetPlayerHealth(id,0.0);
	if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}убил игрока {FF0000}%s {FFFF00}(Причина: %s)",Player[playerid][Name],Player[id][Name],str_param);
    return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}убил игрока {FF0000}%s {FFFF00}(Причина: %s)",Player[playerid][Name],Player[id][Name],str_param);
}

CMD:k(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_kill","ds",playerid,"\1");
}

CMD:kill(playerid,params[])
{
	#pragma unused params
	if(GetPlayerState(playerid) == 7) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы уже мертвы");
	if(GetGVarInt("Starting") && GetPVarInt(playerid,"Playing")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Это нельзя сделать во время запуска базы/арены");
	if(IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Сначала выйди из транспорта");
	if(!GetPVarInt(playerid,"Spawned")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не заспавнены");
	if(GetPVarInt(playerid,"SpecID") != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете убить себя во время слежки");
	
	SetPVarInt(playerid, "Killed", true);
	SetPlayerHealth(playerid, 0.0);
	PlayerTextDrawSetString(playerid, Player[playerid][HealthMinus], "~r~~h~-%.0f~n~~r~Health: 0", ReturnPlayerHealth(playerid));
	PlayerTextDrawShow(playerid, Player[playerid][HealthMinus]);
	
	PlayerTextDrawSetString(playerid, Player[playerid][HealthBar], "HP: 0");
	PlayerTextDrawShow(playerid, Player[playerid][HealthBar]);
	
	TextDrawShowForPlayer(playerid,Server[Barrier][5]);
	TextDrawShowForPlayer(playerid,Server[Barrier][6]);
	
	SetTimerEx("ClearMinusHealth", 2500, false, "i", playerid);
	
	HideDialog(playerid);
	return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}ввел комманду {FFFF00}/kill",Player[playerid][Name]);
}

CMD:slap(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_injure","ds",playerid,params);
}

CMD:injure(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 2) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/slap [id] [причина]");

	new
	    str_param[22],
	    id
 	;
 	
	if(sscanf(params,"ds[22]",id,str_param)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/slap [id] [причина]");
    if(!GetPVarInt(id,"Connected")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрока (%i) нет на сервере",id);
    if(isnull(str_param)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Введите причину пинка");
    if(strlen(str_param) > 20) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Слишком длинная причина пинка");
    if(id == playerid) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете пнуть себя");
    if(IsPlayerAdmin(id)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете пнуть администратора");
    if(GetPVarInt(id,"AFK_In")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Этот игрок находится в режиме AFK");
    if(IsPlayerInAnyVehicle(id))
	{
		DestroyVehicleEx(GetPlayerVehicleID(id));
	}
	
	new
		Float:V[3]
	;
	
	GetPlayerVelocity(id,V[0],V[1],V[2]);
	SetPlayerVelocity(id,V[0],V[1],V[2] + 1.0);
	
    if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}пнул игрока {FF0000}%s {FFFF00}(Причина: %s)",Player[playerid][Name],Player[id][Name],str_param);
    return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}пнул игрока {FF0000}%s {FFFF00}(Причина: %s)",Player[playerid][Name],Player[id][Name],str_param);
}

CMD:burn(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 2) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/burn [id] [причина]");

	new
	    str_param[22],
	    id
 	;
 	
	if(sscanf(params,"ds[22]",id,str_param)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/burn [id] [причина]");
    if(!GetPVarInt(id,"Connected")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрока (%i) нет на сервере",id);
    if(isnull(str_param)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Введите причину поджега");
    if(strlen(str_param) > 20) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Слишком длинная причина поджега");
    if(id == playerid) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете поджечь себя");
    if(IsPlayerAdmin(id)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете поджечь администратора");
    if(GetPVarInt(id,"AFK_In")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Этот игрок находится в режиме AFK");

	new
		Float:P[3]
	;
	
	GetPlayerPos(id,P[0],P[1],P[2]);
	CreateExplosion(P[0],P[1],P[2] + 3.0,1,10.0);
	
    if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}поджег игрока {FF0000}%s {FFFF00}(Причина: %s)",Player[playerid][Name],Player[id][Name],str_param);
    return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}поджег игрока {FF0000}%s {FFFF00}(Причина: %s)",Player[playerid][Name],Player[id][Name],str_param);
}

CMD:explode(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 2) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/explode [id] [причина]");

	new
	    str_param[22],
	    id
 	;
 	
	if(sscanf(params,"ds[22]",id,str_param)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/explode [id] [причина]");
    if(!GetPVarInt(id,"Connected")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрока (%i) нет на сервере",id);
    if(isnull(str_param)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Введите причину взрыва");
    if(strlen(str_param) > 20) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Слишком длинная причина взрыва");
    if(id == playerid) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете взорвать себя");
    if(IsPlayerAdmin(id)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете взорвать администратора");
    if(GetPVarInt(id,"AFK_In")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Этот игрок находится в режиме AFK");

	new
		Float:P[3]
	;
	
	GetPlayerPos(id,P[0],P[1],P[2]);
    CreateExplosion(P[0],P[1],P[2] + 9.0,7,10.0);
    
    if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}взорвал игрока {FF0000}%s {FFFF00}(Причина: %s)",Player[playerid][Name],Player[id][Name],str_param);
    return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}взорвал игрока {FF0000}%s {FFFF00}(Причина: %s)",Player[playerid][Name],Player[id][Name],str_param);
}

CMD:mute(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 2) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/mute [id] [минут] [причина]");

	new
	    str_param[22],
	    id, time
 	;
 	
	if(sscanf(params,"dds[22]",id,time,str_param)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/mute [id] [минут] [причина]");
    if(!GetPVarInt(id,"Connected")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрока (%i) нет на сервере",id);
    if(isnull(str_param)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Введите причину затычки");
    if(strlen(str_param) > 20) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Слишком длинная причина затычки");
    if(id == playerid) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете заткнуть себя");
    if(IsPlayerAdmin(id)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете заткнуть администратора");
    GivePVarInt(id,"Mute_Time",(time * 60));
	SetPVarInt(id,"Muted",1);
    if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessage(playerid,-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}заткнул игрока {FF0000}%s {AFAFAF} на %i минут {FFFF00}(Причина: %s)",Player[playerid][Name],Player[id][Name],time,str_param);
    return SendClientMessage(playerid,-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}заткнул игрока {FF0000}%s {AFAFAF} на %i минут {FFFF00}(Причина: %s)",Player[playerid][Name],Player[id][Name],time,str_param);
}

CMD:unmute(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 2) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params) || !IsNumeric(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/unmute [id]");

	new
		id = strval(params)
	;
	
    if(!GetPVarInt(id,"Connected")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрока (%i) нет на сервере",id);
    if(!GetPVarInt(id,"Muted")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрок не заткнут");
    if(id == playerid) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете разоткнуть себя");
    SetPVarInt(id,"Mute_Time",0);
	SetPVarInt(id,"Muted",0);
    if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessage(playerid,-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}разоткнул игрока {FF0000}%s",Player[playerid][Name],Player[id][Name]);
    else return SendClientMessage(playerid,-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}разоткнул игрока {FF0000}%s",Player[playerid][Name],Player[id][Name]);
}

CMD:cc(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_clear","ds",playerid,"chat");
}

CMD:ckc(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_clear","ds",playerid,"killchat");
}

CMD:ccd(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_clear","ds",playerid,"killchat");
}

CMD:cls(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_clear","ds",playerid,"console");
}

CMD:clear(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 3) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/clear [chat/killchat/console]");
	if(!strcmp(params,"chat",true))
	{
		ClearChat();
	    if(GetPVarInt(playerid,"Admin") != 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}очистил чат",Player[playerid][Name]);
    	else return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}очистил чат",Player[playerid][Name]);
	}
	else if(!strcmp(params,"killchat",true))
	{
		ClearKillChat();
	    if(GetPVarInt(playerid,"Admin") != 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}очистил килл чат",Player[playerid][Name]);
    	else return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}очистил килл чат",Player[playerid][Name]);
	}
	else if(!strcmp(params,"console",true))
	{
		ClearConsole();
		printf("[Инфо]: Администратор %s очистил консоль",Player[playerid][Name]);
	    if(GetPVarInt(playerid,"Admin") != 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}очистил консоль сервера",Player[playerid][Name]);
    	else return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}очистил консоль сервера",Player[playerid][Name]);
	}
    return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/clear [chat/killchat/console]");
}

CMD:gotoplayer(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_goto","ds",playerid,params);
}

CMD:goto(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 3) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/goto [id]");

	new id = strval(params);
	
    if(!GetPVarInt(id,"Connected")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрока (%i) нет на сервере",id);
    if(id == playerid) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете телепортироваться к себе");

	new Float:data[3];
	
	if(!IsPlayerInAnyVehicle(id) && !IsPlayerInAnyVehicle(playerid))
	{
		GetPlayerPos(id, data[0], data[1], data[2]);
		SetPlayerPos(playerid, data[0], data[1], floatadd(data[2], 2.0));
		
		SetPlayerFacingAngle(playerid, ReturnPlayerZAngle(id));
		
		GetPlayerVelocity(id, data[0], data[1], data[2]);
		SetPlayerVelocity(playerid, data[0], data[1], data[2]);
		
		SetPlayerInterior(playerid, GetPlayerInterior(id));
		SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(id));
		
		SetCameraBehindPlayer(playerid);
	}
	else if(IsPlayerInAnyVehicle(id) && !IsPlayerInAnyVehicle(playerid))
	{
     	SetPlayerInterior(playerid,GetPlayerInterior(id));
     	SetPlayerVirtualWorld(playerid,GetPlayerVirtualWorld(id));
		PutPlayerInVehicle(playerid,GetPlayerVehicleID(id),(GetPlayerVehicleSeat(id) ? 0 : 1));
	}
	else if(!IsPlayerInAnyVehicle(id) && IsPlayerInAnyVehicle(playerid))
	{
	    GetPlayerPos(id, data[0], data[1], data[2]);
		SetVehiclePos(GetPlayerVehicleID(playerid), floatadd(data[0], floatrandom(10)), floatadd(data[1], floatrandom(10)), floatadd(data[2], 1.0));

		GetPlayerFacingAngle(id, data[0]);
	    ReverseAngle(data[0]);
		SetVehicleZAngle(GetPlayerVehicleID(playerid), data[0]);
		
		GetPlayerVelocity(id, data[0], data[1], data[2]);
		SetVehicleVelocity(GetPlayerVehicleID(playerid), data[0], data[1], data[2]);
		
		SetPlayerInterior(playerid, GetPlayerInterior(id));
		LinkVehicleToInterior(GetPlayerVehicleID(playerid), GetPlayerInterior(id));
		
		SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(id));
		SetVehicleVirtualWorld(GetPlayerVehicleID(playerid), GetPlayerVirtualWorld(id));
	}
	else if(IsPlayerInAnyVehicle(id) && IsPlayerInAnyVehicle(playerid))
	{
		SetPlayerInterior(playerid, GetPlayerInterior(id));
		LinkVehicleToInterior(GetPlayerVehicleID(playerid), GetPlayerInterior(id));
		
		SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(id));
		SetVehicleVirtualWorld(GetPlayerVehicleID(playerid), GetVehicleVirtualWorld(GetPlayerVehicleID(id)));
		
		AttachTrailerToVehicle(GetPlayerVehicleID(playerid), GetPlayerVehicleID(id));
		SetTimerEx("DetachTrailer", 5000, false, "i", GetPlayerVehicleID(id));
	}
	
    if(GetPVarInt(playerid, "Admin") != 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}телепортировался к игроку {FF0000}%s",Player[playerid][Name],Player[id][Name]);
    else return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}телепортировался к игроку {FF0000}%s",Player[playerid][Name],Player[id][Name]);
}

CMD:gethere(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_get","ds",playerid,params);
}

CMD:get(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 3) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/get [id]");

	new
		id = strval(params)
	;
	
    if(!GetPVarInt(id,"Connected")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрока (%i) нет на сервере",id);
    if(id == playerid) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете телепортировать себя");
    if(GetPVarInt(id,"AFK_In")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Этот игрок находится в режиме AFK");

	new
	    Float:float_data[3]
	;
	
	if(!IsPlayerInAnyVehicle(id) && !IsPlayerInAnyVehicle(playerid))
	{
		GetPlayerPos(playerid,float_data[0],float_data[1],float_data[2]);
		SetPlayerPos(id,float_data[0],float_data[1],floatadd(float_data[2],2.0));
		GetPlayerFacingAngle(playerid,float_data[0]);
		ReverseAngle(float_data[0]);
		SetPlayerFacingAngle(id,float_data[0]);
		GetPlayerVelocity(playerid,float_data[0],float_data[1],float_data[2]);
		SetPlayerVelocity(id,float_data[0],float_data[1],float_data[2]);
		SetPlayerInterior(id,GetPlayerInterior(playerid));
		SetPlayerVirtualWorld(id,GetPlayerVirtualWorld(playerid));
		SetCameraBehindPlayer(id);
	}
	else if(IsPlayerInAnyVehicle(playerid) && !IsPlayerInAnyVehicle(id))
	{
     	SetPlayerInterior(id,GetPlayerInterior(playerid));
     	SetPlayerVirtualWorld(id,GetPlayerVirtualWorld(playerid));
		PutPlayerInVehicle(id,GetPlayerVehicleID(playerid),GetPlayerVehicleSeat(playerid)?0:1);
	}
	else if(!IsPlayerInAnyVehicle(playerid) && IsPlayerInAnyVehicle(id))
	{
	    GetPlayerPos(playerid,float_data[0],float_data[1],float_data[2]);
		SetVehiclePos(GetPlayerVehicleID(id),floatadd(float_data[0],floatrandom(10)),floatadd(float_data[1],floatrandom(10)),floatadd(float_data[2],1.0));
		GetPlayerFacingAngle(playerid,float_data[0]);
		ReverseAngle(float_data[0]);
		SetVehicleZAngle(GetPlayerVehicleID(id),float_data[0]);
		GetPlayerVelocity(playerid,float_data[0],float_data[1],float_data[2]);
		SetVehicleVelocity(GetPlayerVehicleID(id),float_data[0],float_data[1],float_data[2]);
		SetPlayerInterior(id,GetPlayerInterior(playerid));
		LinkVehicleToInterior(GetPlayerVehicleID(id),GetPlayerInterior(playerid));
		SetPlayerVirtualWorld(id,GetPlayerVirtualWorld(playerid));
		SetVehicleVirtualWorld(GetPlayerVehicleID(id),GetPlayerVirtualWorld(playerid));
	}
	else if(IsPlayerInAnyVehicle(id) && IsPlayerInAnyVehicle(playerid))
	{
		SetPlayerInterior(id,GetPlayerInterior(playerid));
		LinkVehicleToInterior(GetPlayerVehicleID(id),GetPlayerInterior(playerid));
		SetPlayerVirtualWorld(id,GetPlayerVirtualWorld(playerid));
		SetVehicleVirtualWorld(GetPlayerVehicleID(id),GetVehicleVirtualWorld(GetPlayerVehicleID(playerid)));
		AttachTrailerToVehicle(GetPlayerVehicleID(id),GetPlayerVehicleID(playerid));
		SetTimerEx("DetachTrailer",5000,false,"d",GetPlayerVehicleID(playerid));
	}
    if(GetPVarInt(playerid,"Admin") != 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}телепортировал к себе игрока {FF0000}%s",Player[playerid][Name],Player[id][Name]);
    else return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}телепортировал к себе игрока {FF0000}%s",Player[playerid][Name],Player[id][Name]);
}

CMD:maxping(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 4) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params) || !IsNumeric(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/maxping [число]");
	if(Server[Current] != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Настройки сервера можно менять только на лобби");

	new
		ping = strval(params)
	;
	
	if(ping < 30) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Слишком маленькое значение макс. пинга (%i)",ping);
	SetGVarInt("MaxPing",ping);
	return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}установил максимальный пинг на {FFFF00}'%i'",Player[playerid][Name],GetGVarInt("MaxPing"));
}

CMD:maxpingwarn(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 4) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params) || !IsNumeric(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/maxpingwarn [число]");
	if(Server[Current] != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Настройки сервера можно менять только на лобби");

	new
		ping = strval(params)
	;
	
	if(ping < 1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Слишком маленькое значение предупреждений (%i)",ping);
	SetGVarInt("MaxPingExceeds",ping);
	return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}установил количество предупреждений за высокий пинг на {FFFF00}'%i'",Player[playerid][Name],GetGVarInt("MaxPingExceeds"));
}

CMD:pm(playerid,params[])
{
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/pm [id] [текст]");

	new
	    str_param[102],
	    id
 	;
 	
	if(sscanf(params,"ds[102]",id,str_param)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/pm [id] [текст]");
	if(!GetPVarInt(id,"Connected")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрока (%i) нет на сервере",id);
	if(id == playerid) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете отправить PM себе");
	if(isnull(str_param) || emptyMessage(str_param)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Введите текст сообщения для отправки");
	if(strlen(str_param) > 100) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Слишком длинное сообщение, отправка невозможна");
	SendClientMessage(playerid,-1,"[Инфо]: {AFAFAF}PM для {FF0000}%s: {00FF40}%s",Player[id][Name],str_param);
	return SendClientMessage(id,-1,"[Инфо]: {AFAFAF}PM от {FF0000}%s: {00FF40}%s",Player[playerid][Name],str_param);
}

CMD:createlobby(playerid,params[])
{
	#pragma unused params
	if(GetPVarInt(playerid,"Admin") != 5) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(!GetPVarInt(playerid,"Spawned")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не заспавнены");
	if(Server[Current] != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Создать лобби можно только вне раунда");
	if(GetPVarInt(playerid,"SpecID") != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Выруби слежку!");
	if(GetPVarInt(playerid,"DM_Zone") != -1 || GetPVarInt(playerid,"DuelID") != -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Выйди из DM/дуели!");

	new
	    string_data[128],
		Float:X = GetGVarFloat("Lobby_Pos",0),
		Float:Y = GetGVarFloat("Lobby_Pos",1),
		Float:Z = GetGVarFloat("Lobby_Pos",2)
	;
	
	if(PlayerToPoint(1.0,playerid,X,Y,Z)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Зачем создавать лобби на одном и том же месте?");
	GetPlayerPos(playerid,X,Y,Z);
	SetGVarFloat("Lobby_Pos",X,0);
	SetGVarFloat("Lobby_Pos",Y,1);
	SetGVarFloat("Lobby_Pos",Z,2);
	SetGVarInt("MainInterior",GetPlayerInterior(playerid));
	GetGVarString("Lobby_3DText",string_data);
	Delete3DTextLabel(lobby_text);
	lobby_text = Create3DTextLabel(string_data,GetGVarInt("Main3D_Color"),X,Y,Z + 0.2,250.0,Lobby_VW,true);
	SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}установил новую позицию лобби на координатах: {FFFF00}X: %.2f, Y: %.2f, Z: %.2f",Player[playerid][Name],X,Y,Z);
	return 1;
}

CMD:lobbytxt(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_flytext","ds",playerid,params);
}

CMD:lobbytext(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_flytext","ds",playerid,params);
}

CMD:flytxt(playerid,params[])
{
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_flytext","ds",playerid,params);
}

CMD:flytext(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") != 5) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/flytext [текст]");
	spaceGroupsToSpaces(params);
	trimSideSpaces(params);
	SetGVarString("Lobby_3DText",params,128);
	Update3DTextLabelText(lobby_text,GetGVarInt("Main3D_Color"),params);
	SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}установил новый текст на лобби: {FFFF00}%s",Player[playerid][Name],params);
	return 1;
}

CMD:kick(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 2) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/kick [id] [причина]");

	new
	    str_param[22],
	    id
 	;
 	
	if(sscanf(params,"ds[22]",id,str_param)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/kick [id] [причина]");
    if(!GetPVarInt(id,"Connected")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрока (%i) нет на сервере",id);
    if(isnull(str_param)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Введите причину кика");
    if(strlen(str_param) > 20) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Слишком длинная причина кика");
    if(id == playerid) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете кикнуть себя");
    if(IsPlayerAdmin(id)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете кикнуть администратора");
    if(GetPVarInt(playerid,"Admin") > 3)
	{
		SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}кикнул игрока {FF0000}%s {FFFF00}(Причина: %s)",Player[playerid][Name],Player[id][Name],str_param);
	}
    else
	{
		SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}кикнул игрока {FF0000}%s {FFFF00}(Причина: %s)",Player[playerid][Name],Player[id][Name],str_param);
	}
    SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Игрок {FF0000}%s {AFAFAF}вышел из игры {FF0000}(Кикнут)",Player[id][Name]);
    return Kick(id);
}

CMD:ban(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 3) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/ban [id] [причина]");

	new
	    str_param[22],
	    id
	;
	
	if(sscanf(params,"ds[22]",id,str_param)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/ban [id] [причина]");
	if(!GetPVarInt(id,"Connected")) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Игрока (%i) нет на сервере",id);
    if(isnull(str_param)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Введите причину бана");
    if(strlen(str_param) > 20) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Слишком длинная причина бана");
    if(id == playerid) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете забанить себя");
    if(IsPlayerAdmin(id)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не можете забанить администратора");
	if(GetPVarInt(playerid,"Admin") != 3)
	{
		SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}забанил игрока {FF0000}%s {FFFF00}(Причина: %s)",Player[playerid][Name],Player[id][Name],str_param);
	}
    else
	{
		SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}забанил игрока {FF0000}%s {FFFF00}(Причина: %s)",Player[playerid][Name],Player[id][Name],str_param);
	}
	
    return mysql_ban(id, playerid, -1, str_param);
}

CMD:unban(playerid,params[])
{
	if(GetPVarInt(playerid,"Admin") < 4) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	if(isnull(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/unban [никнейм]");
	if(strlen(params) > 24) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Слишком длинный ник");

	new
		query[128]
	;
	
	mysql_real_escape_string(params, query);
 	format(query,128,"SELECT * FROM `Banlist` WHERE `Name` = '%s'",query);
  	return mysql_function_query(mysqlHandle,query,true,"OnPlayerUnBanRequied","ds",playerid,params);
}

CMD:leaveall(playerid,params[])
{
	#pragma unused params
	SetPVarInt(playerid,"CMD_Time",(GetTickCount() - 2501));
	return CallLocalFunction("cmd_leave","ds",playerid,"all");
}

CMD:leave(playerid,params[])
{
	if(!isnull(params))
	{
	    if(GetPVarInt(playerid,"Admin") < 2) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}У Вас нет доступа к этой комманде");
	    if(!strcmp(params,"all",true))
	    {
	        foreach_p(i)
    		{
		        if(GetPVarInt(i,"DM_Zone") == -1 && GetPVarInt(i,"DuelID") == -1) continue;
		        if(GetPVarInt(i,"DuelID") != -1)
		        {
		            SetPVarInt(i,"DuelID",-1);
		            ResetPlayerWeapons(i);
		            SetPlayerHealth(i,100.0);
		            SetPlayerScore(i,GetPVarInt(i,"Kills"));
		            SpawnPlayer(i);
		            continue;
				}
		        GangZoneHideForPlayer(i,GetGVarInt("DM_GZ_1",GetPVarInt(i,"DM_Zone")));
		        GangZoneHideForPlayer(i,GetGVarInt("DM_GZ_2",GetPVarInt(i,"DM_Zone")));
		        GangZoneHideForPlayer(i,GetGVarInt("DM_GZ_3",GetPVarInt(i,"DM_Zone")));
		        GangZoneHideForPlayer(i,GetGVarInt("DM_GZ_4",GetPVarInt(i,"DM_Zone")));
				SetPVarInt(i,"DM_Zone",-1);
				SetPlayerWorldBounds(i,20000.0,-20000.0,20000.0,-20000.0);
				SpawnPlayer(i);
			}
			if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}выгнал всех игроков из DM",Player[playerid][Name]);
			return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}выгнал всех игроков из DM",Player[playerid][Name]);
		}
	    if(!IsNumeric(params)) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Использование: {FF0000}/leave [id]");

		new
			id = strval(params)
		;
		
	    if(GetPVarInt(id,"DM_Zone") == -1 && GetPVarInt(id,"DuelID") == -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Данный игрок не на DM");
	    if(GetPVarInt(playerid,"DuelID") != -1)
	    {
	        SetPVarInt(id,"DuelID",-1);
         	ResetPlayerWeapons(id);
          	SetPlayerHealth(id,100.0);
           	SetPlayerScore(id,GetPVarInt(id,"Kills"));
           	SpawnPlayer(id);
           	goto Skip;
		}
	    GangZoneHideForPlayer(id,GetGVarInt("DM_GZ_1",GetPVarInt(id,"DM_Zone")));
     	GangZoneHideForPlayer(id,GetGVarInt("DM_GZ_2",GetPVarInt(id,"DM_Zone")));
      	GangZoneHideForPlayer(id,GetGVarInt("DM_GZ_3",GetPVarInt(id,"DM_Zone")));
       	GangZoneHideForPlayer(id,GetGVarInt("DM_GZ_4",GetPVarInt(id,"DM_Zone")));
	    SetPVarInt(id,"DM_Zone",-1);
	    SetPlayerWorldBounds(id,20000.0,-20000.0,20000.0,-20000.0);
	    SpawnPlayer(id);
	    Skip:
		if(GetPVarInt(playerid,"Admin") > 3) return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Администратор {FF0000}%s {AFAFAF}выгнал игрока {FF0000}%s {AFAFAF}из DM/Дуели",Player[playerid][Name],Player[id][Name]);
		return SendClientMessageToAll(-1,"[Инфо]: {AFAFAF}Модератор {FF0000}%s {AFAFAF}выгнал игрока {FF0000}%s {AFAFAF}из DM/Дуели",Player[playerid][Name],Player[id][Name]);
	}
	else
	{
	    if(GetPVarInt(playerid,"DM_Zone") == -1 && GetPVarInt(playerid,"DuelID") == -1) return SendClientMessage(playerid,-1,"[Ошибка]: {AFAFAF}Вы не на DM");
	    if(GetPVarInt(playerid,"DuelID") != -1)
	    {
	        SetPVarInt(playerid,"DuelID",-1);
         	ResetPlayerWeapons(playerid);
          	SetPlayerHealth(playerid,100.0);
           	SetPlayerScore(playerid,GetPVarInt(playerid,"Kills"));
           	SpawnPlayer(playerid);
           	goto Skip2;
		}
	    GangZoneHideForPlayer(playerid,GetGVarInt("DM_GZ_1",GetPVarInt(playerid,"DM_Zone")));
     	GangZoneHideForPlayer(playerid,GetGVarInt("DM_GZ_2",GetPVarInt(playerid,"DM_Zone")));
      	GangZoneHideForPlayer(playerid,GetGVarInt("DM_GZ_3",GetPVarInt(playerid,"DM_Zone")));
       	GangZoneHideForPlayer(playerid,GetGVarInt("DM_GZ_4",GetPVarInt(playerid,"DM_Zone")));
	    SetPVarInt(playerid,"DM_Zone",-1);
	    SetPlayerWorldBounds(playerid,20000.0,-20000.0,20000.0,-20000.0);
	    SpawnPlayer(playerid);
	}
	Skip2:
	return SendClientMessage(playerid,-1,"[Инфо]: {AFAFAF}Вы вышли из DM");
}*/

#endscript
