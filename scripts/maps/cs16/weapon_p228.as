enum P228Animation
{
	P228_IDLE = 0,
	P228_SHOOT1,
	P228_SHOOT2,
	P228_SHOOT3,
	P228_EMPTY,
	P228_RELOAD,
	P228_DRAW
};

const int P228_DEFAULT_GIVE 	= 65;
const int P228_MAX_CARRY    	= 52;
const int P228_MAX_CLIP     	= 13;
const int P228_WEIGHT       	= 5;

class weapon_p228 : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	int m_iShotsFired;
	int m_iShell;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/cs16/p228/w_p228.mdl" );
		
		self.m_iDefaultAmmo = P228_DEFAULT_GIVE;
		m_iShotsFired = 0;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/cs16/p228/v_p228.mdl" );
		g_Game.PrecacheModel( "models/cs16/p228/w_p228.mdl" );
		g_Game.PrecacheModel( "models/cs16/p228/p_p228.mdl" );

		//Precache the Sprites as well
		g_Game.PrecacheModel( "sprites/cs16/640hud7.spr" );
		g_Game.PrecacheModel( "sprites/cs16/640hud12.spr" );
		g_Game.PrecacheModel( "sprites/cs16/640hud13.spr" );
		
		m_iShell = g_Game.PrecacheModel( "models/cs16/shells/pshell.mdl" );
		
		g_Game.PrecacheGeneric( "sound/" + "weapons/cs16/dryfire_pistol.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/cs16/p228-1.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/cs16/p228_sliderelease.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/cs16/p228_slidepull.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/cs16/p228_clipout.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/cs16/p228_clipin.wav" );
		
		g_SoundSystem.PrecacheSound( "weapons/cs16/dryfire_pistol.wav" );
		g_SoundSystem.PrecacheSound( "weapons/cs16/p228-1.wav" );
		g_SoundSystem.PrecacheSound( "weapons/cs16/p228_sliderelease.wav" );
		g_SoundSystem.PrecacheSound( "weapons/cs16/p228_slidepull.wav" );
		g_SoundSystem.PrecacheSound( "weapons/cs16/p228_clipin.wav" );
		g_SoundSystem.PrecacheSound( "weapons/cs16/p228_clipout.wav" );
		
		g_Game.PrecacheGeneric( "sprites/" + "cs16/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cs16/640hud12.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cs16/640hud13.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cs16/crosshairs.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cs16/weapon_p228.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= P228_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= P228_MAX_CLIP;
		info.iSlot 		= 1;
		info.iPosition 	= 8;
		info.iFlags 	= 0;
		info.iWeight 	= P228_WEIGHT;

		return true;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( BaseClass.AddToPlayer( pPlayer ) == true )
		{
			@m_pPlayer = pPlayer;
			NetworkMessage csp228( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				csp228.WriteLong( g_ItemRegistry.GetIdForName("weapon_p228") );
			csp228.End();
			return true;
		}
		
		return false;
	}
	
	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_AUTO, "weapons/cs16/dryfire_pistol.wav", 0.9, ATTN_NORM, 0, PITCH_NORM );
		}
		
		return false;
	}
	
	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( "models/cs16/p228/v_p228.mdl" ), self.GetP_Model( "models/cs16/p228/p_p228.mdl" ), P228_DRAW, "onehanded" );
		
			float deployTime = 1;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time;
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;
		BaseClass.Holster( skipLocal );
	}
	
	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;
			return;
		}
		
		m_iShotsFired++;
		if( m_iShotsFired > 1 )
		{
			return;
		}
		
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.12;
		
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		--self.m_iClip;
		
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		if ( self.m_iClip <= 0 )
		{
			self.SendWeaponAnim( P228_EMPTY, 0, 0 );
		}
		else
		{
			switch ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
			{
				case 0: self.SendWeaponAnim( P228_SHOOT1, 0, 0 ); break;
				case 1: self.SendWeaponAnim( P228_SHOOT2, 0, 0 ); break;
				case 2: self.SendWeaponAnim( P228_SHOOT3, 0, 0 ); break;
			}
		}
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/cs16/p228-1.wav", 0.9, ATTN_NORM, 0, PITCH_NORM );
		
		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		int m_iBulletDamage = 19;
		
		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_1DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
			
		m_pPlayer.pev.punchangle.x = Math.RandomLong( -2, -1 );

		//self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.15f;
		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
		
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming + x * VECTOR_CONE_2DEGREES.x * g_Engine.v_right + y * VECTOR_CONE_2DEGREES.y * g_Engine.v_up;

		Vector vecEnd	= vecSrc + vecDir * 4096;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_MP5 );
			}
		}
		Vector vecShellVelocity, vecShellOrigin;
       
		//The last 3 parameters are unique for each weapon (this should be using an attachment in the model to get the correct position, but most models don't have that).
		CS16GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 17, 10, -6, true, false );
       
		//Lefthanded weapon, so invert the Y axis velocity to match.
		vecShellVelocity.y *= 1;
       
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
	}
	
	void Reload()
	{
		if( self.m_iClip == P228_MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 )
			return;

		self.DefaultReload( P228_MAX_CLIP, P228_RELOAD, 2.74, 0 );
		BaseClass.Reload();
	}
	
	void WeaponIdle()
	{
		// Can we fire?
		if ( self.m_flNextPrimaryAttack < WeaponTimeBase() )
		{
		// If the player is still holding the attack button, m_iShotsFired won't reset to 0
		// Preventing the automatic firing of the weapon
			if ( !( ( m_pPlayer.pev.button & IN_ATTACK ) != 0 ) )
			{
				// Player released the button, reset now
				m_iShotsFired = 0;
			}
		}

		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		self.SendWeaponAnim( P228_IDLE );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
	}
}

string GetP228Name()
{
	return "weapon_p228";
}

void RegisterP228()
{
	g_CustomEntityFuncs.RegisterCustomEntity( GetP228Name(), GetP228Name() );
	g_ItemRegistry.RegisterWeapon( GetP228Name(), "cs16", "ammo_cs_357sig" );
}