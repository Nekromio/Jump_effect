#pragma semicolon 1

#include <sdktools_stringtables>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

ConVar
	cvEnable,
	cvEnableInvis,
	cvStart,
	cvEnd,
	cvLife,
	cvWidth,
	cvAmplitude[3],
	cvPos2;

int
	iLaser,
	iHalo,
	Engine_Version,
	game[4] = {0,1,2,3};		//0-UNDEFINED|1-css34|2-css|3-csgo

int GetCSGame()
{
	if (GetFeatureStatus(FeatureType_Native, "GetEngineVersion") == FeatureStatus_Available) 
	{
		switch (GetEngineVersion())
		{
			case Engine_SourceSDK2006: return game[1];
			case Engine_CSS: return game[2];
			case Engine_CSGO: return game[3];
		}
	}
	return game[0];
}

public APLRes AskPluginLoad2()
{
	Engine_Version = GetCSGame();
	if(!Engine_Version)
		SetFailState("Game is not supported!");
	return APLRes_Success;
}

public Plugin myinfo =
{
	name		= "Jump effect/Эффект от прыжка",
	version		= "1.4.1",
	description	= "Волны от прыжков",
	author		= "Nek.'a 2x2 | ggwp.site , by Grey83",
	url			= "https://ggwp.site/"
}

public void OnPluginStart()
{
	cvEnable = CreateConVar("sm_jumpeffect_enable", "1", "Включить/выключить эффект волн при прыжке.", _, true, _, true, 1.0);
	cvEnableInvis = CreateConVar("sm_jumpeffect_invise", "1", "1 Включить только для своей команды, 0 отображение для всех", _, true, _, true, 1.0);
	cvStart = CreateConVar("sm_stpos", "1.0", "начальное кольцо", _, true, 1.0);
	cvEnd = CreateConVar("sm_undpos", "140.0", "Окончание кольца", _, true, 1.0);
	cvLife = CreateConVar("sm_timelifeeffect", "1.5", "Время жизни эффекта", _, true, 0.1);
	cvWidth = CreateConVar("sm_widtheffect", "20.0", "Ширина луча", _, true, 1.0);
	cvAmplitude[0] = CreateConVar("sm_amplitudeeffect1", "10.0", "Амплитуда 1-й волны", _, true);
	cvAmplitude[1] = CreateConVar("sm_amplitudeeffect2", "50.0", "Амплитуда 2-й волны", _, true);
	cvAmplitude[2] = CreateConVar("sm_amplitudeeffect3", "20.0", "Амплитуда 3-й волны");
	cvPos2 = CreateConVar("sm_pos2", "10", "Высота эффекта");

	HookEvent("player_jump", Event_Jump);

	AutoExecConfig(true, "jump_effect");
}

public void OnMapStart()
{
	switch(GetCSGame())
	{
		case 1:
		{
			iLaser = PrecacheModel("sprites/laser.vmt");
			iHalo = PrecacheModel("sprites/halo.vmt");
		}
		case 2:
		{
			iLaser = PrecacheModel("sprites/laser.vmt");
			iHalo = PrecacheModel("sprites/halo01.vmt");
		}
		case 3:
		{
			iLaser = PrecacheModel("sprites/laserbeam.vmt");
			iHalo = PrecacheModel("sprites/halo.vmt");
		}
	}
}

void Event_Jump(Event event, const char[] name, bool dontBroadcast)
{
	if(!cvEnable.BoolValue || !iLaser || !iHalo)
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
	pos[2] += cvPos2.FloatValue;

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
			TE_SetupBeamRingPoint(pos, cvStart.FloatValue, cvEnd.FloatValue, iLaser, iHalo, 0, 0, cvLife.FloatValue, cvWidth.FloatValue, cvAmplitude[0].FloatValue, clr, 50, 0);
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
			TE_SetupBeamRingPoint(pos, cvStart.FloatValue, cvEnd.FloatValue, iLaser, iHalo, 0, 0, cvLife.FloatValue, cvWidth.FloatValue, cvAmplitude[1].FloatValue, clr, 50, 0);
		}
		case 2:
		{
			clr[0] = GetRandomInt(1, 255);
			clr[1] = GetRandomInt(1, 255);
			clr[2] = GetRandomInt(1, 255);
			TE_SetupBeamRingPoint(pos, cvStart.FloatValue, cvEnd.FloatValue, iLaser, iHalo, 0, 0, cvLife.FloatValue, cvWidth.FloatValue, cvAmplitude[2].FloatValue, clr, 50, 0);
		}
	}
	if(!cvEnableInvis.BoolValue) TE_SendToAll();
	else
	{
		int iTeam = GetClientTeam(client);
		TE_SendTo(iTeam);
	}
}

void TE_SendTo(int iTeam)
{
	int[] iClients = new int[MaxClients];
	int num;
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == iTeam)
	{
		iClients[num++] = i;
	}
	TE_Send(iClients, num);
}