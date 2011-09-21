// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TechTree_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function GetHasTech(callingEntity, techId, silentError)

    local techTree = GetTechTree()
    if(techTree ~= nil) then
    
        return techTree:GetHasTech(techId, silentError)
    
    else
        Shared.Message("GetHasTech (Client) returned nil tech tree.")
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
    
    ParseTechNodeBaseMessage(techNode, techNodeBaseTable)
    
    self:AddNode(techNode)
    
end

function TechTree:UpdateTechNodeFromNetwork(techNodeUpdateTable)

    local techId = techNodeUpdateTable.techId
    local techNode = self:GetTechNode(techId)
    
    if techNode ~= nil then
        ParseTechNodeUpdateMessage(techNode, techNodeUpdateTable)
    else
        Print("UpdateTechNodeFromNetwork(): Couldn't find technode with id %s, skipping update.", ToString(techId))
    end
    
    
end
