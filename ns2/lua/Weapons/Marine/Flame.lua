//=============================================================================
//
// lua\Weapons\Marine\Flame.lua
//
// Created by Andreas Urwalek (a_urwa@sbox.tugraz.at)
// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
//=============================================================================
Script.Load("lua/ScriptActor.lua")

class 'Flame' (ScriptActor)

Flame.kMapName            = "flame"
Flame.kFireEffect         = PrecacheAsset("cinematics/marine/flamethrower/burning_surface.cinematic")


Flame.kDamageRadius       = 1.8
Flame.kLifeTime           = 7
Flame.kThinkTime 		  = .3
Flame.kDamage             = 8

Flame.kClientThinkTime	= .01

function Flame:OnInit()

    ScriptActor.OnInit(self)
    
    if Server then  
    
	    // intervall of dealing damage
	    self.lifeTime = Flame.kLifeTime
	    self:SetNextThink(1)

    elseif Client then
    
        self.fireEffect = Client.CreateCinematic(RenderScene.Zone_Default)    
        self.fireEffect:SetCinematic(Flame.kFireEffect)    
        self.fireEffect:SetRepeatStyle(Cinematic.Repeat_Endless)

        local coords = Coords.GetIdentity()
        coords.origin = self:GetOrigin()
        self.fireEffect:SetCoords(coords)
    
    end
    
end

function Flame:OnDestroy()

	if Client then	
	
		 Client.DestroyCinematic(self.fireEffect)
         self.fireEffect = nil
	
	end
	
	ScriptActor.OnDestroy(self)

end

function Flame:GetDeathIconIndex()
    return kDeathMessageIcon.Flame
end

function Flame:GetDamageType()
    return kFlameLauncherDamageType
end
    
if Server then
    
    function Flame:GetDamageType()
    	return kFlameThrowerDamageType
    end
    
	function Flame:OnThink()
	
	    ScriptActor.OnThink(self)
	    
	    self.lifeTime = self.lifeTime - Flame.kThinkTime        
	    self:Detonate(nil)
	    
	    if self.lifeTime < 0 then
	    
	        if Server then
	           self:Detonate(nil)
	        end
	        
	        DestroyEntity(self)
	        
	    else
	    
	       self:SetNextThink(Flame.kThinkTime)
	       
	    end
	    
	end
	    
    function Flame:Detonate(targetHit)    	
    
    	local player = self:GetOwner()
	    local ents = GetEntitiesWithMixinWithinRange("Live", self:GetOrigin(), Flame.kDamageRadius)
	    
	    if targetHit ~= nil then
	    	table.insert(ents, targetHit)
	    end
	    
	    for index, ent in ipairs(ents) do

            if HasMixin(self, "GameEffects") and GetGameEffectMask(kGameEffect.InUmbra) then
                DestroyEntity(self)
                break
            end
        
            local toEnemy = GetNormalizedVector(ent:GetModelOrigin() - self:GetOrigin())
        
            if GetGamerules():CanEntityDoDamageTo(player, ent) then

                local health = ent:GetHealth()

                // Do damage to them and catch them on fire, ignore doors (if cheats are turned on)
                if not ent:isa("Door") then
                    ent:TakeDamage(Flame.kDamage, player, self, ent:GetModelOrigin(), toEnemy)
                end
                
            end
            
	    end
        
    end

end

Shared.LinkClassToMap("Flame", Flame.kMapName)