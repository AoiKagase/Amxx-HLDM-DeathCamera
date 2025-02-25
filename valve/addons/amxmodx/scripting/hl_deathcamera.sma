#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <xs>
#include <fakemeta_util>

new g_bInCamera;
#define ClearUserInCamera(%0)		g_bInCamera &= ~(1<<(%0&31))
#define IsUserInCamera(%0)			( g_bInCamera & 1<<(%0&31) )
#define ToggleUserCameraState(%0)	g_bInCamera ^= 1<<(%0&31)
#define TRIPMINE_TASK 119292

new gEntCamera;
new g_iPlayerCamera[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin("Death Camera", "0.1", "Aoi.Kagase");

	RegisterHamPlayer(Ham_TakeDamage, "OnTakeDamagePre", 0);
	RegisterHamPlayer(Ham_Spawn, "OnSpawned", 1);
	RegisterHam(Ham_Think, "trigger_camera", "CameraThink", 1);

	RegisterHam(Ham_Think, "monster_tripmine", "OnTripmineThink", 1);
	// registered func_breakable
	gEntCamera = engfunc(EngFunc_AllocString, "trigger_camera");
}

public client_disconnected(client)
{
	if (pev_valid(g_iPlayerCamera[client]))
	{
		set_pev(g_iPlayerCamera[client], pev_flags, pev(g_iPlayerCamera[client], pev_flags) | FL_KILLME);
		engfunc(EngFunc_RemoveEntity, g_iPlayerCamera[client]);
	}

}

public OnTripmineThink(iEnt)
{
	if (pev_valid(iEnt))
	{
		if (pev(iEnt, pev_iuser4) != 1)
		{
			new beam = get_ent_data_entity(iEnt, "CTripmineGrenade", "m_pBeam");
			if (pev_valid(beam))
			{
				set_pev(beam, pev_renderamt, 255.0);
				set_pev(iEnt, pev_iuser4, 1);
			}
		}
	}
}

public OnTakeDamagePre(client, idinflictor, idattacker, Float:damage, damagebits)
{
	if (!(1 <= client <= 32))
		return HAM_IGNORED;
	
	if (is_user_bot(client))
		return HAM_IGNORED;

	static Float:health; 
	pev(client, pev_health, health);
	health -= damage;

	// Die.
	if (health <= 0.0)
	{
		if (!pev_valid(g_iPlayerCamera[client]))
		{
			new iEnt = g_iPlayerCamera[client] = engfunc(EngFunc_CreateNamedEntity, gEntCamera);
			if (pev_valid(iEnt))
			{
				set_pev(iEnt, pev_classname, 	"DeathCamera");
				set_pev(iEnt, pev_spawnflags,	SF_CAMERA_PLAYER_TARGET);
				set_pev(iEnt, pev_flags, 		pev(iEnt, pev_flags) | FL_ALWAYSTHINK);
				set_pev(iEnt, pev_owner, 		client);

				static Float:vCamOrigin[3];
				static Float:vPlayerOrigin[3];
				static Float:vAngle[3];
				pev(client, pev_origin, vPlayerOrigin);
				pev(client, pev_v_angle, vAngle);
				xs_vec_copy(vPlayerOrigin, vCamOrigin);
				vCamOrigin[2] += 120.0;

				xs_vec_sub(vCamOrigin, vPlayerOrigin, vAngle);
				vector_to_angle(vAngle, vAngle);

				set_pev(iEnt, pev_angles, vAngle);
				set_pev(iEnt, pev_v_angle, vAngle);
				set_pev(iEnt, pev_vuser1, vCamOrigin);
				set_pev(iEnt, pev_vuser2, vAngle);
				set_pev(iEnt, pev_solid, SOLID_TRIGGER);
				set_pev(iEnt, pev_movetype, MOVETYPE_FLY);
				set_pev(iEnt, pev_owner, client);

				set_pev(iEnt, pev_rendermode, kRenderTransTexture );
				set_pev(iEnt, pev_renderamt, 0.0 );					
				engfunc(EngFunc_SetOrigin, iEnt, vCamOrigin);
					// set entity position.
				dllfunc(DLLFunc_Spawn, iEnt);
				// set_pev(iEnt, pev_v_angle, vAngle);
				set_ent_data_float(iEnt, "CTriggerCamera", "m_flWait", 999999.0);
				ExecuteHam(Ham_Use, iEnt, client, client, USE_TOGGLE, 1.0);
//				engfunc(EngFunc_SetView, client, iEnt); // shouldn't be always needed
				// attach_view(iEnt, id)
			}
		}
	}
	return HAM_IGNORED;
}

public OnSpawned(client)
{
	if (pev_valid(g_iPlayerCamera[client]))
	{
		set_pev(g_iPlayerCamera[client], pev_flags, pev(g_iPlayerCamera[client], pev_flags) | FL_KILLME);
		engfunc(EngFunc_RemoveEntity, g_iPlayerCamera[client]);
	}

	if (!is_user_bot(client))
	{
		if (is_user_alive(client))
			set_view(client, CAMERA_NONE);
	}
	g_iPlayerCamera[client] = -1;
}

public CameraThink(iEnt)
{
	if (pev_valid(iEnt))
	{
		static classname[16];
		pev(iEnt, pev_classname, classname, charsmax(classname));
		if (equali(classname, "DeathCamera"))
		{
			if (pev(iEnt, pev_iuser4) == 1)
			{
				static Float:cPos[3];
				static Float:pAngle[3]
				pev(iEnt, pev_vuser1, cPos);
				pev(iEnt, pev_vuser2, pAngle);
				engfunc(EngFunc_SetOrigin, iEnt, cPos);
				set_pev(iEnt, pev_angles, pAngle);
				set_pev(iEnt, pev_iuser4, 1);
			}
		}
	}
}
