/*
	Possible bugs
		If you set the Useable spawnflag on a button that didn't have it previously,
		it will take one damage event to make it 'update' before it will respond to
		the next damage event. (is this still a problem? 2021.01.20)
*/
public Plugin myinfo =
{
	name		= "[DTK] QoL - +use",
	author		= "worMatty",
	description = "A QoL plugin that simulates +use functionality on maps with buttons that only have OnDamaged outputs",
	version		= "0.3",
	url			= ""
};

//#define DEBUG

#include <sourcemod>
#include <sdkhooks>	   // needed for hooking spawn and use

ConVar g_cvEnabled;

public void OnPluginStart() {
	g_cvEnabled = CreateConVar("dtk_qol_button_use", "0", "Causes players to damage a button they +use, in order to trigger its OnDamaged outputs. Automatically disabled on map end");
}

// disable plugin on map end
public void OnMapEnd() {
	g_cvEnabled.BoolValue = false;
}

// hook into the spawning and using of newly-created func_buttons
public void OnEntityCreated(int entity, const char[] classname) {
	if (!g_cvEnabled.BoolValue) {
		if (StrEqual(classname, "func_button")) {
			SDKHook(entity, SDKHook_UsePost, OnButtonUsePost);
			SDKHook(entity, SDKHook_Spawn, OnButtonSpawn);
		}
	}
}

// when a button spawns, give it the 'useable' spawnflag
Action OnButtonSpawn(int entity) {
	int spawnflags = GetEntProp(entity, Prop_Data, "m_spawnflags");

	// check if button does not already have this spawnflag
	if (!(spawnflags & 1024)) {
		SetEntProp(entity, Prop_Data, "m_spawnflags", spawnflags | 1024);
	}

	// unhook
	SDKUnhook(entity, SDKHook_Spawn, OnButtonSpawn);

	return Plugin_Continue;
}

// 'button pressed' hook
void OnButtonUsePost(int entity, int activator, int caller, UseType type, float value) {
	// make the button take damage of 0 value
	SDKHooks_TakeDamage(entity, activator, activator, 0.0, 0, -1, NULL_VECTOR, NULL_VECTOR);
}