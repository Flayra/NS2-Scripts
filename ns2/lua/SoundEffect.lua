// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\SoundEffect.lua
//
//    Created by:   Brain Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kDefaultMaxAudibleDistance = 50

class 'SoundEffect' (Entity)

SoundEffect.kMapName = "soundeffect"

SoundEffect.networkVars =
{
    playing = "boolean",
    assetIndex = "integer"
}

function SoundEffect:OnCreate()

    Entity.OnCreate(self)
    
    self.playing = false
    self.assetIndex = -1
    
    self:SetPropagate(Entity.Propagate_Mask)
    self:SetRelevancyDistance(kDefaultMaxAudibleDistance)
    
    if Server then
        self.assetLength = 0
        self.startTime = 0
        self:SetUpdates(true)
    end
    
    if Client then
    
        self.clientPlaying = false
        self.clientAssetIndex = -1
        self.soundEffectInstance = nil
        
    end

end

function SoundEffect:OnDestroy()

    if Client then
        self:_DestroySoundEffect()
    end
    
end

if Server then

    function SoundEffect:SetAsset(assetPath)
    
        self.assetIndex = Shared.GetSoundIndex(assetPath)
        local fevStart, fevEnd = string.find(assetPath, ".fev")
        local fixedAssetPath = string.sub(assetPath, fevEnd + 1)
        self.assetLength = Server.GetSoundLength(fixedAssetPath)
        
    end

    function SoundEffect:Start()
    
        // Asset must be assigned before playing.
        assert(self.assetIndex ~= -1)
        
        self.playing = true
        self.startTime = Shared.GetTime()
        
    end

    function SoundEffect:Stop()
    
        self.playing = false
        self.startTime = 0
        
    end

    function SoundEffect:OnUpdate(deltaTime)
    
        // If the assetLength is < 0, it is a looping sound and needs to be manually destroyed.
        if self.playing and self.assetLength >= 0 and self.startTime + self.assetLength > Shared.GetTime() then
            Server.DestroyEntity(self)
        end
    
    end
    
end

if Client then

    function SoundEffect:_DestroySoundEffect()
    
        if self.soundEffectInstance then
        
            Client.DestroySoundEffect(self.soundEffectInstance)
            self.soundEffectInstance = nil
            
        end
        
    end
    
    function SoundEffect:OnSynchronized()
    
        if not Shared.GetIsRunningPrediction() then
        
            if self.clientAssetIndex ~= self.assetIndex then
            
                self:_DestroySoundEffect()
                
                self.clientAssetIndex = self.assetIndex
                
                if self.assetIndex ~= -1 then
                
                    self.soundEffectInstance = Client.CreateSoundEffect(self.assetIndex)
                    local parentId = (self:GetParent() and self:GetParent():GetId()) or Entity.invalidId
                    self.soundEffectInstance:SetParent(parentId)
                    
                end
            
            end
            
            // Only attempt to play if the index seems valid.
            if self.assetIndex ~= -1 then
            
                if self.clientPlaying ~= self.playing then
                
                    self.clientPlaying = self.playing
                    
                    if self.playing then
                        self.soundEffectInstance:Start()
                    else
                        self.soundEffectInstance:Stop()
                    end
                    
                end
                
            end
            
        end
    
    end

end

Shared.LinkClassToMap("SoundEffect", SoundEffect.kMapName, SoundEffect.networkVars)