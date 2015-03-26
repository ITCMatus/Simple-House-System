#include <a_samp>
#include <sscanf2> // By Y_Less					http://forum.sa-mp.com/showthread.php?t=120356
#include <streamer> // By Y_Less					http://forum.sa-mp.com/showthread.php?t=120356

#include <YSI\y_utils> // By Y_Less
#include <YSI\y_timers> // By Y_Less
#include <YSI\y_hooks> // By Y_Less 
#include <YSI\y_ini> // By Y_Less 
#include <YSI\y_iterate> // By Y_Less
#include <YSI\y_va> // By Y_Less

#define SCM va_SendClientMessage
#define SCMTA va_SendClientMessageToAll

#include <formatex> // By Slice:				http://forum.sa-mp.com/showthread.php?t=313488

#define MAX_HOUSES 50
#define INVALID_HOUSE_ID -1
#define DEFAULT_HOUSE_COST 50000
#define DEFAULT_HOUSE_OWNER "Nikto"
#define DEFAULT_HOUSE_PATCH "Houses/House%d.ini"

#define CONFIRM "Potvrdiť"
#define CANCEL "Zrušiť"

#define HOUSE_UNLOCKED 0
#define HOUSE_LOCKED 1

new HouseDoorState[2][11] = { "Odomknutý","Zamknutý" };

enum {
	DIALOG_HOUSE_FOR_SALE = 269,
	DIALOG_HOUSE_INFO,
	DIALOG_HOUSE_OWNER,
	DIALOG_HOUSE_GUEST

}

enum PortPosition {
	Float:I_X,
	Float:I_Y,
	Float:I_Z,
	Int
}

new HouseInterior[14][PortPosition] = {
	{2496.0837, -1694.6823, 1014.7422,	3},
	{2319.4561, -1025.5547, 1050.2109,	9},
	{234.6087, 1187.8195, 1080.2578,	3},
	{225.5700, 1240.1743, 1082.1406,	2},
	{226.6689, 1114.2357, 1080.9949,	5},// 5
	{295.1211, 1472.4385, 1080.2578,	15},
	{446.5904, 1397.3353, 1084.3047,	2},
	{260.9645, 1286.1227, 1080.2578,	4},
	{20002.8521, 1404.1110, 1084.4297,	5},// 10
	{140.1565, 1367.6558, 1083.8618,	5},
	{234.0911, 1064.3892, 1084.2113,	6},
	{-68.4557, 1353.2141, 1080.2109,	6},// 13
	{2365.2805, -1133.7350, 1050.8750,	8},
	{84.5941, 1323.0470, 1083.8594,		9}//15
};

enum HOUSE_INFO {
	Owner[MAX_PLAYER_NAME],
	ForSale,  
	Float:Pos[3],
	Cost,
	Interior,
	Time, 
	Locked,  
	Pickup,
	MapIcon,
	Text3D:Label
}

new gHouse[MAX_HOUSES][HOUSE_INFO];
new Iterator:HouseCount<MAX_HOUSES>;

new PlayerHouseDialog[MAX_PLAYERS] = {INVALID_HOUSE_ID, ...};
new PlayerInHouse[MAX_PLAYERS] = {INVALID_HOUSE_ID, ...};

//#define IsHouseForSale(%0) gHouse[%0][ForSale] == 1
//#define IsPlayerHouseOwner(%0, %1) (!strcmp(ReturnPlayerName(%0), gHouse[%1][Owner]))

stock IsHouseForSale(house) return gHouse[house][ForSale];

stock IsPlayerHouseOwner(playerid, house){
	if(!strcmp(ReturnPlayerName(playerid), gHouse[house][Owner], false)) return true;
	return false;
}

main (){

}

stock CreateDaveHouse(Float:x, Float:y, Float:z, int, cost = DEFAULT_HOUSE_COST)
{
	new id = Iter_Free(HouseCount);
	if(id == -1){
		printf("[ERROR] House c.%d Prekroceny limit domov %d",id,MAX_HOUSES);
		return 0;
	}
	if(int < 0 || int >= 14){ 
		printf("[ERROR] House c.%d Interier moze by iba v rozpati od 0 do 13",id);
		return 0;
	}
	Iter_Add(HouseCount, id);

	gHouse[id][Pos][0] = x;
	gHouse[id][Pos][1] = y;
	gHouse[id][Pos][2] = z;

	gHouse[id][Interior] = int;
	gHouse[id][Cost] = cost;	

	new str[128];
	format(str, 128, DEFAULT_HOUSE_PATCH, id);
	if(!INI_ParseFile(str, "LoadHouseInfo", .bExtra = true, .extra = id))
	{
		print("BBBBBBB");
		new INI:ini = INI_Open(str);
		INI_SetTag(ini, "Core");
		INI_WriteString(ini, "Owner", DEFAULT_HOUSE_OWNER);
		INI_WriteInt(ini, "Locked", 0);
		INI_WriteInt(ini, "Time", 0);
		INI_Close(ini);
		gHouse[id][ForSale] = 1;
		INI_ParseFile(str, "LoadHouseInfo", .bExtra = true, .extra = id);
	}
	print("B");
	if(gHouse[id][ForSale] == 1){
		format(str, 128, "Owner: %s\nCost: %d\nLocked: %s",gHouse[id][Owner], gHouse[id][Cost], HouseDoorState[gHouse[id][Locked]]);
		gHouse[id][Pickup] = CreatePickup(1273, 1, x, y, z);
		#if defined Streamer_IncludeFileVersion
			gHouse[id][MapIcon] = CreateDynamicMapIcon(x, y, z, 31, 0, 0);
			gHouse[id][Label] = CreateDynamic3DTextLabel(str, 0xCCCCCCAA, x, y, z, 100.0, .testlos = 1, .worldid = 0);	
		#else
			gHouse[id][Label] = Create3DTextLabel(str, 0xCCCCCCAA, x, y, z, 100.0, 0, 1);
		#endif
	}else{

		if(gettime() > gHouse[id][Time]+2592000){
			// zmazať majiteľa ALE treba to dorobiť
		}

		format(str, 128, "Owner: %s\nLocked: %s",gHouse[id][Owner], HouseDoorState[gHouse[id][Locked]]);
		gHouse[id][Pickup] = CreatePickup(1272, 1, x, y, z);
		#if defined Streamer_IncludeFileVersion
			gHouse[id][MapIcon] = CreateDynamicMapIcon(x, y, z, 32, 0, 0);
			gHouse[id][Label] = CreateDynamic3DTextLabel(str, 0xCCCCCCAA, x, y, z, 100.0, .testlos = 1, .worldid = 0);	
		#else
			gHouse[id][Label] = Create3DTextLabel(str, 0xCCCCCCAA, x, y, z, 100.0, 0, 1);
		#endif
	}
	return 1;
}

forward LoadHouseInfo(houseid, name[], value[]);
public LoadHouseInfo(houseid, name[], value[])
{
	printf("%d, %s, %s",houseid, name, value);
	INI_String("Owner", gHouse[houseid][Owner], MAX_PLAYER_NAME);
	if(!strcmp(gHouse[houseid][Owner], DEFAULT_HOUSE_OWNER, false)){
		gHouse[houseid][ForSale] = 1;
	}
	INI_Int("Locked", gHouse[houseid][Locked]);
	INI_Int("Time", gHouse[houseid][Time]);
	return 0;
}

task SaveHouses[60*60*1000](){
	foreach(new house : HouseCount)
	{
		new str[128];
		format(str, 128, DEFAULT_HOUSE_PATCH, house);
		new INI:ini = INI_Open(str);
		INI_SetTag(ini, "Core");
		INI_WriteString(ini, "Owner", gHouse[house][Owner]);
		INI_WriteInt(ini, "Locked", gHouse[house][Locked]);
		INI_WriteInt(ini, "Time", gHouse[house][Time]);
		INI_Close(ini);
	}
}


timer SaveHouse[60*1000](playerid){
	foreach(new house : HouseCount)
	{
		new name[30];
		GetPlayerName(playerid, name, 30);
		if(!strcmp(name, gHouse[house][Owner])){
			new str[128];
			format(str, 128, DEFAULT_HOUSE_PATCH, house);
			new INI:ini = INI_Open(str);
			INI_SetTag(ini, "Core");
			INI_WriteString(ini, "Owner", gHouse[house][Owner]);
			INI_WriteInt(ini, "Locked", gHouse[house][Locked]);
			INI_WriteInt(ini, "Time", gettime());
			INI_Close(ini);
		}
	}
}

public OnScriptInit()
{
	SetGameModeText("Blank Script"); 
	AddPlayerClass(0,-1957.3542,263.0048,47.7031,85.6310,0,0,0,0,0,0); // player4
	for(new i; i < 10; i++){
		CreateDaveHouse(0+(i*3), 0, 2.2, random(14));
	}

}

hook OnPlayerConnect(playerid){
	GivePlayerMoney(playerid, 250000);
	PlayerHouseDialog[playerid] = INVALID_HOUSE_ID;
	PlayerInHouse[playerid] = INVALID_HOUSE_ID;
}

hook OnPlayerDisconnect(playerid, reason){
	SaveHouse(playerid);
}

hook OnPlayerPickUpPickup(playerid, pickupid){
	foreach(new house : HouseCount){
		if(gHouse[house][Pickup] == pickupid){
			if(PlayerHouseDialog[playerid] == INVALID_HOUSE_ID){
				PlayerHouseDialog[playerid] = house;
				if(IsHouseForSale(house)){
					ShowPlayerDialog(playerid, DIALOG_HOUSE_FOR_SALE, DIALOG_STYLE_LIST, "House", "Kúpiť\nPrehliadka\nInformácie", CONFIRM, CANCEL);
				}else if(IsPlayerHouseOwner(playerid, house)){
					if(gHouse[house][Locked]== HOUSE_LOCKED){
						ShowPlayerDialog(playerid, DIALOG_HOUSE_OWNER, DIALOG_STYLE_LIST, "House", "Vstúpiť\nOdomknúť\nPredať\nInformácie", CONFIRM, CANCEL);
					}else{
						ShowPlayerDialog(playerid, DIALOG_HOUSE_OWNER, DIALOG_STYLE_LIST, "House", "Vstúpiť\nZamknúť\nPredať\nInformácie", CONFIRM, CANCEL);
					}
				}else{
					ShowPlayerDialog(playerid, DIALOG_HOUSE_GUEST, DIALOG_STYLE_LIST, "House", "Vstúpiť\nInformácie", CONFIRM, CANCEL);
				}
			}
		}
	}
}


hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]){
	if(PlayerHouseDialog[playerid] != INVALID_HOUSE_ID){
		new house = PlayerHouseDialog[playerid];
		PlayerHouseDialog[playerid] = INVALID_HOUSE_ID;
		if(dialogid == DIALOG_HOUSE_FOR_SALE){
			if(!response) return 1;
			if(listitem == 0){
				if(!IsHouseForSale(house)) return SCM(playerid, -1, "Dom č.%d už nie je na predaj!", house);
				if(GetPlayerMoney(playerid) < gHouse[house][Cost]) return SCM(playerid, -1, "Nemáš dostatok peňazí. Potrebuješ $%d",gHouse[house][Cost]);
			
				GivePlayerMoney(playerid, -gHouse[house][Cost]);
				format(gHouse[house][Owner], MAX_PLAYER_NAME, ReturnPlayerName(playerid));
				gHouse[house][ForSale] = 0;
			
				DestroyPickup(gHouse[house][Pickup]);
				gHouse[house][Pickup] = CreatePickup(1272, 1, gHouse[house][Pos][0], gHouse[house][Pos][1], gHouse[house][Pos][2]);
				new str[128];
				format(str, 128, "Owner: %s\nLocked: %s",gHouse[house][Owner], HouseDoorState[gHouse[house][Locked]]);
				#if defined Streamer_IncludeFileVersion
					DestroyDynamicMapIcon(gHouse[house][MapIcon]);
					gHouse[house][MapIcon] = CreateDynamicMapIcon(gHouse[house][Pos][0], gHouse[house][Pos][1], gHouse[house][Pos][2], 32, 0, 0);
					UpdateDynamic3DTextLabelText(gHouse[house][Label], 0xCCCCCCAA, str);
				#else
					Update3DTextLabelText(gHouse[house][Label], 0xCCCCCCAA, str);
				#endif				
			}	
			else if(listitem == 1){
				new hint = gHouse[house][Interior];
				SetPlayerPos(playerid, HouseInterior[hint][I_X], HouseInterior[hint][I_Y], HouseInterior[hint][I_Z]);
				SetPlayerInterior(playerid, HouseInterior[hint][Int]);
				SetPlayerVirtualWorld(playerid, MAX_HOUSES+house);
				PlayerInHouse[playerid] = house;
				SCM(playerid, -1, "Dom opustíš pri vchode klávesou ENTER/F");
			}
			else{
				new str[256];
				format(str, 256, "Owner: %s\nCost: %d\nLocked: %s\nInterior: %d\nPos: %0.2f, %0.2f, %0.2f"
					, gHouse[house][Owner], gHouse[house][Cost], HouseDoorState[gHouse[house][Locked]], gHouse[house][Interior], gHouse[house][Pos][0], gHouse[house][Pos][1], gHouse[house][Pos][2]);
				ShowPlayerDialog(playerid, DIALOG_HOUSE_INFO, DIALOG_STYLE_MSGBOX, "House Info", str, CONFIRM, CANCEL);
				PlayerHouseDialog[playerid] = house;
			}
			return 1;
		}

		else if(dialogid == DIALOG_HOUSE_OWNER){
			if(!response) return 1;
			//Vstúpiť\nZamknúť\nPredať\nInformácie
			if(listitem == 0){
				if(!IsPlayerHouseOwner(playerid, house)) return SCM(playerid, -1, "Niesi majiteľ domu č.%d",house);
				new hint = gHouse[house][Interior];
				SetPlayerPos(playerid, HouseInterior[hint][I_X], HouseInterior[hint][I_Y], HouseInterior[hint][I_Z]);
				SetPlayerInterior(playerid, HouseInterior[hint][Int]);
				SetPlayerVirtualWorld(playerid, MAX_HOUSES+house);
				PlayerInHouse[playerid] = house;
				SCM(playerid, -1, "Dom opustíš pri vchode klávesou ENTER/F");
			}
			else if(listitem == 1){
				if(!IsPlayerHouseOwner(playerid, house)) return SCM(playerid, -1, "Niesi majiteľ domu č.%d",house);
				gHouse[house][Locked] = !gHouse[house][Locked];
				SCM(playerid, -1, "Tvoj dom je od teraz pre ostatných hráčov %s",HouseDoorState[gHouse[house][Locked]]);
				new str[128];
				format(str, 128, "Owner: %s\nLocked: %s",gHouse[house][Owner], HouseDoorState[gHouse[house][Locked]]);
				#if defined Streamer_IncludeFileVersion
					UpdateDynamic3DTextLabelText(gHouse[house][Label], 0xCCCCCCAA, str);
				#else
					Update3DTextLabelText(gHouse[house][Label], 0xCCCCCCAA, str);
				#endif		
			}
			else if(listitem == 2){
				if(!IsPlayerHouseOwner(playerid, house)) return SCM(playerid, -1, "Niesi majiteľ domu č.%d",house);
				
				GivePlayerMoney(playerid, gHouse[house][Cost]/2);
				format(gHouse[house][Owner], MAX_PLAYER_NAME, DEFAULT_HOUSE_OWNER);
				gHouse[house][ForSale] = 1;
				gHouse[house][Locked] = HOUSE_UNLOCKED;
				gHouse[house][Time] = 0;

				DestroyPickup(gHouse[house][Pickup]);
				gHouse[house][Pickup] = CreatePickup(1273, 1, gHouse[house][Pos][0], gHouse[house][Pos][1], gHouse[house][Pos][2]);
				
				new str[128];
				format(str, 128, "Owner: %s\nCost: %d\nLocked: %s",gHouse[house][Owner], gHouse[house][Cost], HouseDoorState[gHouse[house][Locked]]);
				#if defined Streamer_IncludeFileVersion
					DestroyDynamicMapIcon(gHouse[house][MapIcon]);
					gHouse[house][MapIcon] = CreateDynamicMapIcon(gHouse[house][Pos][0], gHouse[house][Pos][1], gHouse[house][Pos][2], 31, 0, 0);
					UpdateDynamic3DTextLabelText(gHouse[house][Label], 0xCCCCCCAA, str);
				#else
					Update3DTextLabelText(gHouse[house][Label], 0xCCCCCCAA, str);
				#endif							
			}
			else{
				new str[256];
				format(str, 256, "Owner: %s\nCost: %d\nLocked: %s\nInterior: %d\nPos: %0.2f, %0.2f, %0.2f"
					, gHouse[house][Owner], gHouse[house][Cost], HouseDoorState[gHouse[house][Locked]], gHouse[house][Interior], gHouse[house][Pos][0], gHouse[house][Pos][1], gHouse[house][Pos][2]);
				ShowPlayerDialog(playerid, DIALOG_HOUSE_INFO, DIALOG_STYLE_MSGBOX, "House Info", str, CONFIRM, CANCEL);
				PlayerHouseDialog[playerid] = house;
			}
			return 1;
		}

		else if(dialogid == DIALOG_HOUSE_GUEST){
			if(!response) return 1;
			if(listitem == 0){
				if(gHouse[house][Locked] == HOUSE_LOCKED) return SCM(playerid, -1, "Dom č.%d je zamknutý", house);
				new hint = gHouse[house][Interior];
				SetPlayerPos(playerid, HouseInterior[hint][I_X], HouseInterior[hint][I_Y], HouseInterior[hint][I_Z]);
				SetPlayerInterior(playerid, HouseInterior[hint][Int]);
				SetPlayerVirtualWorld(playerid, MAX_HOUSES+house);
				PlayerInHouse[playerid] = house;
				SCM(playerid, -1, "Dom opustíš pri vchode klávesou ENTER/F");
			}
			else{
				new str[256];
				format(str, 256, "Owner: %s\nCost: %d\nLocked: %s\nInterior: %d\nPos: %0.2f, %0.2f, %0.2f"
					, gHouse[house][Owner], gHouse[house][Cost], HouseDoorState[gHouse[house][Locked]], gHouse[house][Interior], gHouse[house][Pos][0], gHouse[house][Pos][1], gHouse[house][Pos][2]);
				ShowPlayerDialog(playerid, DIALOG_HOUSE_INFO, DIALOG_STYLE_MSGBOX, "House Info", str, CONFIRM, CANCEL);
				PlayerHouseDialog[playerid] = house;
			}
			return 1;
		}
	}
	return 0;
}


hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys){
	if(PlayerInHouse[playerid] > INVALID_HOUSE_ID){
		if(newkeys == KEY_SECONDARY_ATTACK){
			new house = PlayerInHouse[playerid];
			new hint = gHouse[house][Interior];
			if(IsPlayerInRangeOfPoint(playerid, 1.5, HouseInterior[hint][I_X], HouseInterior[hint][I_Y], HouseInterior[hint][I_Z])){
				SetPlayerPos(playerid, gHouse[house][Pos][0], gHouse[house][Pos][1], gHouse[house][Pos][2]);
				SetPlayerInterior(playerid, 0);
				SetPlayerVirtualWorld(playerid, 0);
				PlayerInHouse[playerid] = INVALID_HOUSE_ID;
			}
		}
	}
}
