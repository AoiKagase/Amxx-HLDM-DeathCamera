#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <xs>

new const PLUGIN_NAME	[] 	= "Death Camera";
new const PLUGIN_VERSION[] 	= "0.2";
new const PLUGIN_AUTHOR	[] 	= "Aoi.Kagase";

new const gClassName	[] 	= "DeathCamera";

new gEntCamera;
new g_iPlayerCamera		[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

	RegisterHamPlayer(Ham_TakeDamage, 	"OnTakeDamagePre", 0);
	RegisterHamPlayer(Ham_Spawn, 		"OnSpawned", 1);

	RegisterHam(Ham_Think, "trigger_camera", "CameraThink", 1);

	gEntCamera = engfunc(EngFunc_AllocString, "trigger_camera");
}


// 
// Player Disconnected.
//
public client_disconnected(client)
{
	if (pev_valid(g_iPlayerCamera[client]))
	{
		set_pev(g_iPlayerCamera[client], pev_flags, pev(g_iPlayerCamera[client], pev_flags) | FL_KILLME);
		dllfunc(DLLFunc_Think, g_iPlayerCamera[client]);
		g_iPlayerCamera[client] = -1;
	}
}

// 
// Processing just before player damage is done.
//
public OnTakeDamagePre(client, idinflictor, idattacker, Float:damage, damagebits)
{
	// Is Player?
	if (!(1 <= client <= 32))
		return HAM_IGNORED;

	// Is Bot? Nah...	
	if (is_user_bot(client))
		return HAM_IGNORED;

	// Get Player health, and calculate damaged.
	static Float:health; 
	pev(client, pev_health, health);
	health -= damage;

	// Is Die.
	if (health <= 0.0)
	{
		// Invalid Camera Entity.
		if (!pev_valid(g_iPlayerCamera[client]))
		{
			// Create Camera Entity.
			new iEnt = g_iPlayerCamera[client] = engfunc(EngFunc_CreateNamedEntity, gEntCamera);
			if (pev_valid(iEnt))
			{
				static Float:vCamOrigin[3];
				static Float:vPlayerOrigin[3];
				static Float:vAngle[3];

				// Set camera info.
				set_pev(iEnt, pev_classname, 	gClassName);
				set_pev(iEnt, pev_spawnflags,	SF_CAMERA_PLAYER_TARGET);
				set_pev(iEnt, pev_flags, 		pev(iEnt, pev_flags) | FL_ALWAYSTHINK);
				set_pev(iEnt, pev_owner, 		client);

				// Get Player position for set Camera position.
				pev(client, pev_origin, 		vPlayerOrigin);
				pev(client, pev_v_angle,		vAngle);
				xs_vec_copy(vPlayerOrigin, 		vCamOrigin);
				vPlayerOrigin[2] += 1.0;
				vCamOrigin[2] += 120.0;
				// Check over wall.
			    // create the trace handle.
				static trace; trace = create_tr2();
				// get wall position to vNewOrigin.
				engfunc(EngFunc_TraceLine, vPlayerOrigin, vCamOrigin, (IGNORE_MISSILE | IGNORE_MONSTERS | IGNORE_GLASS), client, trace);
				{
					static Float:fFraction;
					get_tr2(trace, TR_flFraction, fFraction);
			
					// -- We hit something!
					if (fFraction < 1.0)
					{
						// -- Save results to be used later.
						get_tr2(trace, TR_vecEndPos, vCamOrigin);
					}
				}
				// free the trace handle.
				free_tr2(trace);

				// Calculate Top/Down Angle.
				xs_vec_sub(vCamOrigin, vPlayerOrigin, vAngle);
				vector_to_angle(vAngle, vAngle);

				// Angle Set (It probably won't work.)
				set_pev(iEnt, pev_angles, 		vAngle);
				set_pev(iEnt, pev_v_angle, 		vAngle);
				// (Keep for use think logic.)
				set_pev(iEnt, pev_vuser1, 		vCamOrigin);
				set_pev(iEnt, pev_vuser2, 		vAngle);

				// Set transparent for looks.
				set_pev(iEnt, pev_solid, 		SOLID_TRIGGER);
				set_pev(iEnt, pev_movetype, 	MOVETYPE_FLY);
				set_pev(iEnt, pev_owner, 		client);
				set_pev(iEnt, pev_rendermode, 	kRenderTransTexture);
				set_pev(iEnt, pev_renderamt, 	0.0);					

				// Set Position.
				engfunc(EngFunc_SetOrigin, iEnt, vCamOrigin);
				dllfunc(DLLFunc_Spawn, iEnt);

				// I don't know this.
				set_ent_data_float(iEnt, "CTriggerCamera", "m_flWait", 999999.0);
				// Camera Viewing.
				ExecuteHam(Ham_Use, iEnt, client, client, USE_TOGGLE, 1.0);
			}
		}
	}
	return HAM_IGNORED;
}

// 
// Player spawned.
//
public OnSpawned(client)
{
	// if already exist camera remove it.
	if (pev_valid(g_iPlayerCamera[client]))
	{
		set_pev(g_iPlayerCamera[client], pev_flags, pev(g_iPlayerCamera[client], pev_flags) | FL_KILLME);
		engfunc(EngFunc_RemoveEntity, g_iPlayerCamera[client]);
	}

	// Is Player?
	if (!is_user_bot(client))
	{
		// Reset camera view.
		if (is_user_alive(client))
			set_view(client, CAMERA_NONE);
	}
	// Reset Camera Entity ID.
	g_iPlayerCamera[client] = -1;
}

// 
// Camera Think logic.
//
public CameraThink(iEnt)
{
	if (pev_valid(iEnt))
	{
		static classname[16];
		pev(iEnt, pev_classname, classname, charsmax(classname));

		// Death Camera?
		if (equali(classname, gClassName))
		{
			// One execute.
			if (pev(iEnt, pev_iuser4) == 1)
			{
				static Float:cPos[3];
				static Float:pAngle[3]

				// Get keep position/Angle.
				pev(iEnt, pev_vuser1, cPos);
				pev(iEnt, pev_vuser2, pAngle);

				// ReSet keep position/Angle
				engfunc(EngFunc_SetOrigin, iEnt, cPos);
				set_pev(iEnt, pev_angles, pAngle);

				// Executed.
				set_pev(iEnt, pev_iuser4, 1);
				client_print(pev(iEnt, pev_owner), print_chat, "CameraThink");
			}
		}
	}
}
