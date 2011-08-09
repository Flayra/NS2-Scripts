// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TechTree_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function GetTechSupported(callingEntity, techId, silentError)

    local techTree = GetTechTree()
    if(techTree ~= nil) then
    
        return techTree:GetTechSupported(techId, silentError)
    
    else
        Shared.Message("GetTechSupported (Client) returned nil tech tree.")
    end
    
    return false
    
end

function GetTechNode(techId)

    local techTree = GetTechTree()
    
    if(techTree) then
    
        return techTree:GetTechNode(techId)
        
    end
    
    return nil
    
end

function TechTree:CreateTechNodeFromNetwork(techNodeBaseTable)
    
    local techNode = TechNode()
    
    techNode:InitializeFromNetwork(techNodeBaseTable)
    
    self:AddNode(techNode)
    
end

function TechTree:UpdateTechNodeFromNetwork(techNodeUpdateTable)

    local techId = techNodeUpdateTable.techId
    local techNode = self:GetTechNode(techId)
    
    if techNode ~= nil then
        techNode:UpdateFromNetwork(techNodeUpdateTable)
    else
        Print("UpdateTechNodeFromNetwork(): Couldn't find technode with id %s, skipping update.", ToString(techId))
    end
    
    
end
