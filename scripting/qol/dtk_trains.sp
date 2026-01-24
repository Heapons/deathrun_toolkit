// #define DEBUG

#include <sourcemod>
#include <sdkhooks>

public Plugin myinfo =
{
	name		= "[DTK] QoL - Train Control",
	author		= "worMatty",
	description = "Patch func_track/tanktrains to prevent them being +used",
	version		= "1.0",
	url			= ""
};

ConVar g_cvEnabled;

public void OnPluginStart() {
	g_cvEnabled = CreateConVar("dtk_qol_patch_trains", "0", "Patch trains on spawn to disable user control. Disables itself on map change", _, true, 0.0, true, 1.0);
}

// disable plugin on map change
public void OnMapEnd() {
	g_cvEnabled.RestoreDefault();
}

// hook trains on creation for post-spawn modification
public void OnEntityCreated(int train, const char[] classname) {
	if (g_cvEnabled.BoolValue) {
		if (StrEqual(classname, "func_tracktrain") || StrEqual(classname, "func_tanktrain")) {
			SDKHook(train, SDKHook_SpawnPost, OnTrainPostSpawn);
		}
	}
}

// give trains the 'no user control' spawnflag after they spawn
void OnTrainPostSpawn(int train) {
	if (!(GetEntProp(train, Prop_Data, "m_spawnflags") & 2)) {
		SetEntProp(train, Prop_Data, "m_spawnflags", GetEntProp(train, Prop_Data, "m_spawnflags") | 2);
	}
	#if defined DEBUG
	PrintToServer("DTK Train Control -- Turned off user control for train with entindex %d", train);
	#endif
	SDKUnhook(train, SDKHook_SpawnPost, OnTrainPostSpawn);
}