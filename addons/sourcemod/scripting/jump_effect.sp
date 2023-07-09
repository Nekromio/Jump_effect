#pragma semicolon 1

#include <sdktools_stringtables>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

#define pl(%0) for(int %0 = 1; %0 <= MaxClients; ++%0) if(IsClientInGame(%0))

bool
	bEnable,
	bEnableInvis;
int
	iLaser,
	iHalo;
float
	fStart,		// Начало
	fEnd,		// Окончание
	fLife,	// Время жизни
	fWidth,		// Ширина луча
	fAmplitude1,	// Амплитуда
	fAmplitude2,	// Амплитуда
	fAmplitude3,	// Амплитуда
	fPos2;

char Engine_Version;

#define GAME_UNDEFINED 0
#define GAME_CSS_34 1
#define GAME_CSS 2
#define GAME_CSGO 3

int GetCSGame()
{
	if (GetFeatureStatus(FeatureType_Native, "GetEngineVersion") == FeatureStatus_Available) 
	{ 
		switch (GetEngineVersion()) 
		{ 
			case Engine_SourceSDK2006: return GAME_CSS_34; 
			case Engine_CSS: return GAME_CSS; 
			case Engine_CSGO: return GAME_CSGO; 
		} 
	} 
	return GAME_UNDEFINED;
}

public Plugin myinfo =
{
	name		= "Jump effect/Эффект от прыжка",
	version		= "1.3.0 (rewritten by Grey83)",
	description	= "Волны от прыжков",
	author		= "Nek.'a 2x2 | ggwp.site",
	url			= "https://ggwp.site/"
}

public void OnPluginStart()
{
	Engine_Version = GetCSGame(); if (Engine_Version == GAME_UNDEFINED) SetFailState("Game is not supported!");
	ConVar cvar;
	cvar = CreateConVar("sm_jumpeffect_enable", "1", "Включить/выключить эффект волн при прыжке.", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Enable);
	bEnable = cvar.BoolValue;
	cvar = CreateConVar("sm_jumpeffect_invise", "1", "1 Включить только для своей команды, 0 отображение для всех", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Enable);
	bEnableInvis = cvar.BoolValue;
	//Начало
	cvar = CreateConVar("sm_stpos", "1.0", "начальное кольцо", _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Start);
	fStart = cvar.FloatValue;
	//Окончание
	cvar = CreateConVar("sm_undpos", "140.0", "Окончание кольца", _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_End);
	fEnd = cvar.FloatValue;
	//Время жизни
	cvar = CreateConVar("sm_timelifeeffect", "1.5", "Время жизни эффекта", _, true, 0.1);
	cvar.AddChangeHook(CVarChanged_Life);
	fLife = cvar.FloatValue;
	//Ширина луча
	cvar = CreateConVar("sm_widtheffect", "20.0", "Ширина луча", _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Width);
	fWidth = cvar.FloatValue;
	//Амплитуда
	cvar = CreateConVar("sm_amplitudeeffect1", "10.0", "Амплитуда 1-й волны", _, true);
	cvar.AddChangeHook(CVarChanged_Amplitude1);
	fAmplitude1 = cvar.FloatValue;
	cvar = CreateConVar("sm_amplitudeeffect2", "50.0", "Амплитуда 2-й волны", _, true);
	cvar.AddChangeHook(CVarChanged_Amplitude2);
	fAmplitude2 = cvar.FloatValue;
	cvar = CreateConVar("sm_amplitudeeffect3", "20.0", "Амплитуда 3-й волны");
	cvar.AddChangeHook(CVarChanged_Amplitude3);
	fAmplitude3 = cvar.FloatValue;
	cvar = CreateConVar("sm_pos2", "10", "Высота эффекта");
	cvar.AddChangeHook(CVarChanged_Pos2);
	fPos2 = cvar.FloatValue;

	HookEvent("player_jump", Event_Jump);

	AutoExecConfig(true, "jump_effect");
}

public void CVarChanged_Enable(ConVar CVar, const char[] oldValue, const char[] newValue){bEnableInvis = CVar.BoolValue;bEnable = CVar.BoolValue;}
public void CVarChanged_Start(ConVar cvar, const char[] oldValue, const char[] newValue){fStart = cvar.FloatValue;}
public void CVarChanged_End(ConVar cvar, const char[] oldValue, const char[] newValue){fEnd = cvar.FloatValue;}
public void CVarChanged_Life(ConVar cvar, const char[] oldValue, const char[] newValue){fLife = cvar.FloatValue;}
public void CVarChanged_Width(ConVar cvar, const char[] oldValue, const char[] newValue){fWidth = cvar.FloatValue;}
public void CVarChanged_Amplitude1(ConVar cvar, const char[] oldValue, const char[] newValue){fAmplitude1 = cvar.FloatValue;}
public void CVarChanged_Amplitude2(ConVar cvar, const char[] oldValue, const char[] newValue){fAmplitude2 = cvar.FloatValue;}
public void CVarChanged_Amplitude3(ConVar cvar, const char[] oldValue, const char[] newValue){fAmplitude3 = cvar.FloatValue;}
public void CVarChanged_Pos2(ConVar cvar, const char[] oldValue, const char[] newValue){fPos2 = cvar.FloatValue;}

public void OnMapStart()
{
	if(Engine_Version == GAME_CSS)
	{
		iLaser = PrecacheModel("sprites/laser.vmt");
		iHalo = PrecacheModel("sprites/halo.vmt");
	}
	if(Engine_Version == GAME_CSS_34)
	{
		iLaser = PrecacheModel("sprites/laser.vmt");
		iHalo = PrecacheModel("sprites/halo01.vmt");		
	}
	if(Engine_Version == GAME_CSGO)
	{
		iLaser = PrecacheModel("sprites/laserbeam.vmt");
		iHalo = PrecacheModel("sprites/halo.vmt");
	}
}

public void Event_Jump(Event event, const char[] name, bool dontBroadcast)
{
	if(!bEnable || !iLaser || !iHalo)
		return;

	static bool t;
	static int client, ver, clr[4];
	static float pos[3];

	if(!(client = GetClientOfUserId(GetEventInt(event, "userid"))) || !IsClientInGame(client))
		return;

	t = GetClientTeam(client) == 2;
	ver = GetRandomInt(0, 2);
	clr[3] = 255;
	GetClientAbsOrigin(client, pos);
	pos[2] += fPos2;

	switch(ver)
	{
		case 0:
		{
			if(t)
			{
				clr[0] = GetRandomInt(1, 100);
				clr[1] = GetRandomInt(1, 100);
				clr[2] = GetRandomInt(1, 200);
			}
			else
			{
				clr[0] = GetRandomInt(1, 50);
				clr[1] = GetRandomInt(1, 50);
				clr[2] = GetRandomInt(1, 100);
			}
			TE_SetupBeamRingPoint(pos, fStart, fEnd, iLaser, iHalo, 0, 0, fLife, fWidth, fAmplitude1, clr, 50, 0);
		}
		case 1:
		{
			if(t)
			{
				clr[0] = GetRandomInt(1, 255);
				clr[1] = clr[2] = 1;
			}
			else
			{
				clr[0] = clr[1] = 1;
				clr[2] = GetRandomInt(1, 255);
			}
			TE_SetupBeamRingPoint(pos, fStart, fEnd, iLaser, iHalo, 0, 0, fLife, fWidth, fAmplitude2, clr, 50, 0);
		}
		case 2:
		{
			clr[0] = GetRandomInt(1, 255);
			clr[1] = GetRandomInt(1, 255);
			clr[2] = GetRandomInt(1, 255);
			TE_SetupBeamRingPoint(pos, fStart, fEnd, iLaser, iHalo, 0, 0, fLife, fWidth, fAmplitude3, clr, 50, 0);
		}
	}
	if(!bEnableInvis) TE_SendToAll();
	else
	{
		int iTeam = GetClientTeam(client);
		TE_SendTo(iTeam);
	}
}

void TE_SendTo(int iTeam)
{
	int[] iClients = new int[MaxClients]; 
	int iGo;
	switch(!iGo)
    {
        case 1: pl(ply) if(GetClientTeam(ply) == iTeam) iClients[iGo++] = ply;
        case 2: pl(ply) iClients[iGo++] = ply;
    }
	if(iGo > 0) TE_Send(iClients, iGo);
}