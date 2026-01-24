#include <sourcemod>
#include <sdkhooks>

bool   g_bEnabled;
ConVar cv_RedBits;
ConVar cv_BlueBits;
ConVar cv_Debug;

public Plugin myinfo =
{
	name		= "[DTK] QoL - Damage Filter",
	author		= "worMatty",
	description = "A QoL plugin that filters damage between red and blue. Useful on old ported maps",
	version		= "0.2",
	url			= ""
};

public void OnPluginStart() {
	cv_RedBits	= CreateConVar("sm_red_damage_filter_bits", "0", "Integer representation of a bitfield of damage types. Any red damage to blue players that contains any of these bits will be zeroed");
	cv_BlueBits = CreateConVar("sm_blue_damage_filter_bits", "0", "Integer representation of a bitfield of damage types. Any blue damage to red players that contains any of these bits will be zeroed");
	cv_Debug	= CreateConVar("sm_debug_damage_bits", "0", "Print damage type bitfield of damage dealt to opponents to client chat");
	cv_RedBits.AddChangeHook(Cvar_Hook);
	cv_BlueBits.AddChangeHook(Cvar_Hook);
	cv_Debug.AddChangeHook(Cvar_Hook);
}

void Cvar_Hook(ConVar convar, const char[] oldValue, const char[] newValue) {
	// enable plugin features
	if (!g_bEnabled && convar.BoolValue) {
		g_bEnabled = true;
		PrintToServer("Hooking damage on clients");

		for (int i = 1; i <= MaxClients; i++) {
			int client = i;

			if (IsValidEdict(client) && IsClientInGame(client)) {
				SDKHook(client, SDKHook_OnTakeDamageAlive, DamageHook);
			}
		}
	}
	// disable plugin features
	else if (!cv_BlueBits.BoolValue && !cv_RedBits.BoolValue && !cv_Debug.BoolValue) {
		g_bEnabled = false;
		PrintToServer("Unhooking damage on clients");

		for (int i = 1; i <= MaxClients; i++) {
			int client = i;

			if (IsValidEdict(client) && IsClientInGame(client)) {
				SDKUnhook(client, SDKHook_OnTakeDamageAlive, DamageHook);
			}
		}
	}
}

// hook player damage on joining the server
public void OnClientPutInServer(int client) {
	if (g_bEnabled) {
		SDKHook(client, SDKHook_OnTakeDamageAlive, DamageHook);
	}
}

// damage hook
Action DamageHook(int victim, int& attacker, int& inflictor, float& damage, int& damagetype) {
	// spew damage bits if debug mode is enabled
	if (cv_Debug.BoolValue) {
		PrintToChat(attacker, "Damage to %N: %b (%d)", victim, damagetype, damagetype);
	}

	bool changed;
	int	 attacker_team = GetClientTeam(attacker);
	int	 victim_team   = GetClientTeam(victim);

	// cross-team damage
	if (attacker_team != victim_team) {
		// attacker is on red team
		if (GetClientTeam(attacker) == 2) {
			if (damagetype & cv_RedBits.IntValue) {	   // bitwise AND filter flags
				damage	= 0.0;
				changed = true;
			}
		}
		// on other team i.e. blue
		else {
			if (damagetype & cv_BlueBits.IntValue) {
				damage	= 0.0;
				changed = true;
			}
		}
	}

	if (changed) {
		return Plugin_Changed;
	} else {
		return Plugin_Continue;
	}
}
