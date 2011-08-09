// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TargetCache.lua
//
//    Created by:   Mats Olsson (mats.olsson@matsotech.se)
//
Script.Load("lua/NS2Gamerules.lua") 
Script.Load("lua/TargetCache_Commands.lua")

//
// TargetFilters are used to check targets before presenting them to the prioritizers
// 

//
// Removes targets that are not inside the maxPitch
//
function PitchTargetFilter(attacker, minPitchDegree, maxPitchDegree)
    local lastPitch = 0
    return function(target, targetPoint)
        local origin = GetEntityEyePos(attacker)
        local viewCoords = GetEntityViewAngles(attacker):GetCoords()
        local v = targetPoint - origin
        local distY = Math.DotProduct(viewCoords.yAxis, v)
        local distZ = Math.DotProduct(viewCoords.zAxis, v)
        local pitch = 180 * math.atan2(distY,distZ) / math.pi
        result = pitch >= minPitchDegree and pitch <= maxPitchDegree
        // Log("filter %s for %s, v %s, pitch %s, result %s (%s,%s)", target, attacker, v, pitch, result, minPitchDegree, maxPitchDegree)
        return result
    end    
end

function CloakCamoTargetFilter()
    return  function(target, targetPoint)
                local hidden = (HasMixin(target, "Cloakable") and target:GetIsCloaked()) or (HasMixin(target, "Camouflage") and target:GetIsCamouflaged())
                return not hidden
            end
end 

//
// Only lets through damaged targets
//
function HealableTargetFilter(healer)
    return function(target, targetPoint) return target:AmountDamaged() > 0 end
end

//
function RangeTargetFilter(origin, sqRange)
    return function(target, targetPoint) return (targetPoint - origin):GetLengthSquared() end
end

//
// Prioritizers are used to prioritize one kind of target over others
// When selecting targets, the range-sorted list of targets are run against each supplied prioritizer in turn
// before checking if the target is visible. If the prioritizer returns true for the target, the target will
// be selected if it is visible. If not visible, the selection process continues.
// 
// Once all user-supplied prioritizers have run, a final run through will select the closest visible target.
// 

//
// Selects target based on class
//
function IsaPrioritizer(className)
    return function(target) return target:isa(className) end
end

//
// Selects targets based on if they can hurt us
//
function HarmfulPrioritizer()
    return function(target) return target:GetCanDoDamage() end
end

//
// Selects everything 
//
function AllPrioritizer()
    return function(target) return true end
end




class 'TargetCache'

TargetCache.kMstl = 1 // marine static target list index
TargetCache.kMmtl = 2 // marine mobile target list index
TargetCache.kAstl = 3 // alien static target list index
TargetCache.kAmtl = 4 // alien mobile target list index
TargetCache.kAshtl = 5 // alien static heal target list. Adds infestation to marine static target list, used by Crags when healing

TargetCache.kTargetListNames = { 
    "MarineStaticTargets",
    "MarineMobileTargets",
    "AlienStaticTargets",
    "AlienMobileTargets",
    "AlienStaticHealTargets"
}

TargetCache.kTargetListNamesShort = { 
    "MarineStat",
    "MarineMob",
    "AlienStat",
    "AlienMob",
    "AlienStatHeal"
}

// Used as final step if all other prioritizers fail
TargetCache.allPrioritizer = AllPrioritizer()

// called from NS2GameRules. This is not an Entity, so OnCreate doesn't exists. 

function TargetCache:Init() 
    self.targetListCache = {}
    self.tlcVersions = {}
    self.zombieList = {}
    for i,_ in ipairs(TargetCache.kTargetListNames) do
        self.targetListCache[i] = {}
        self.tlcVersions[i] = 0
    end
    self.salVersion = 0
    self.tlcSalVersion = -1   
    
    self.logTable = { }
    self.log = Logger("log", self.logTable)
    self.logDetail = Logger("detail", self.logTable)
    self.logTarget = Logger("target", self.logTable)
    self.logStats = Logger("stats", self.logTable)
    
    self.log("TargetCache initialized")

    self.stats = TcStats()
    self.stats:Init(self.logStats, 60)
    return self
end

    
//
// called by NS2Gamerules when it entities change
//
function TargetCache:OnEntityChange(oldId, newId)
    if oldId ~= nil then 
        self:_RemoveEntity(Shared.GetEntity(oldId))
        self.stats.entityCount = self.stats.entityCount - 1;
    end
    if newId ~= nil then
        self:_InsertEntity(Shared.GetEntity(newId))
        self.stats.entityCount = self.stats.entityCount + 1;
    end
end

//
// Some entities goes into a zombie stage when killed (power nodes)
// 
function TargetCache:OnKill(entity)
    // On kill we could handle by simply removing the entity. The problem is
    // that powernodes may become alive again, and there is no OnAlive() call made
    // So we add them to the zombieList. Once per tick, we check the zombielist to see
    // if they are alive. 
    self:_RemoveEntity(entity)
    // note ordering - remove entity will remove from zombie list.
    table.insert(self.zombieList,entity)
end

//
// Check if any zombies are up and running again

function TargetCache:_VerifyZombieList()
    local now = Shared.GetTime()
    if now ~= self.lastZombieCheckTime and #self.zombieList > 0 then
        self.lastZombieCheckTime = now
        // check zombielist for going alives. Iterate in reverse order to allow removals to work
        for i = #self.zombieList, 1, -1 do
            local zombie = self.zombieList[i]
            if self:_IsPossibleTarget(zombie, self:_IsMobile(zombie)) then
                self.logDetail("It's ALIVE! (%s)", zombie)
                table.remove(self.zombieList, i)
                self:_InsertEntity(zombie)
            end
        end
    end
end


//
// insert the given entity into the given list and increment its version
//
function TargetCache:_InsertInTargetList(listIndex, entity)
    local list = self.targetListCache[listIndex]
    table.insertunique(list,  entity)
    self.tlcVersions[listIndex] = self.tlcVersions[listIndex] + 1
    self.log("Insert %s, added to %s, vers %d, len %d", entity,TargetCache.kTargetListNames[listIndex],self.tlcVersions[listIndex],table.maxn(list))
    if self.logTable.detail then
        for i,target in ipairs(list) do  
            self.logDetail("%d : %s", i, target)
        end
    end
end
//
// Call when the insertEntity has been added to the newScriptActorList
//
function TargetCache:_InsertEntity(insertedEntity)
    if self:_IsCacheInvalid() then
        // cache is already invalid, so just return
        return 
    end
    local listIndex = self:_ClassifyEntity(insertedEntity)
    if listIndex ~= 0 then
        self:_InsertInTargetList(listIndex, insertedEntity)
        // special case: alien static heal list is the marine static target list + infestations
        if listIndex == TargetCache.kMstl then
            self:_InsertInTargetList(TargetCache.kAshtl, insertedEntity)
        end
    else
        self.logDetail("Insert ignoring %s", insertedEntity)
    end
end

//
// Call when the scriptActorList has changed due to deletion of the given entity.
//
function TargetCache:_RemoveEntity(deletedEntity)
    // always clear the zombie list
    table.removevalue(self.zombieList, deletedEntity)

    if self:_IsCacheInvalid() then
        // cache is already invalid, so just return
        return 
    end

    // a deleted entity may not maintain a status as a valid target, so the classification
    // may not work for it any longer. Go through all the lists and see if the entity was in it
    local found = false
    for i,list in ipairs(self.targetListCache) do
        local index = table.find(list,deletedEntity)
        if index then
            table.remove(list,index)
            self.stats:ChangeMainList(i)
            self.tlcVersions[i] = self.tlcVersions[i] + 1
            self.log("Remove %s from %s, vers %d, len %d", deletedEntity, TargetCache.kTargetListNames[i], self.tlcVersions[i], table.maxn(list))
            if self.logTable.detail then
                for i,target in ipairs(list) do  
                    self.logDetail("%d : %s",i,target)
                end
            end
            found = true
        end
    end
    if not found then
        self.logDetail("Remove ignored %s", deletedEntity)
    end
end

//
// return to which list the given target belongs, or zero if it belongs to none
//
function TargetCache:_ClassifyEntity(target)
    // infestations are healed by Crags
    if target:isa("Infestation") then
        return TargetCache.kAshtl
    end
    local mobile = self:_IsMobile(target)
    if self:_ValidTarget(kAlienTeamType, target, mobile) then
        if mobile then    
            return TargetCache.kMmtl
        else
            return TargetCache.kMstl
        end
    elseif self:_ValidTarget(kMarineTeamType, target, mobile) then
        if mobile then    
            return TargetCache.kAmtl
        else
            return TargetCache.kAstl
        end        
    end
    return 0
end

function TargetCache:_IsPossibleTarget(target, mobile) 
    if target == nil then
        return false
    end
    local isStruct = target:isa("Structure")
    local validType = isStruct or mobile
    local validAndAlive = validType and (isStruct or target:GetIsAlive())
    return validAndAlive and target:GetCanTakeDamage()
end


// true if the target belongs to the given team and is valid
function TargetCache:_ValidTarget(enemyTeamType, target, mobile)
    return self:_IsPossibleTarget(target, mobile) and enemyTeamType == target:GetTeamType()
end
    

// players can move, and drifters, and MACs, and whips
// should really ask the entities instead...
TargetCache.kMobileClasses = { "Player", "Drifter", "MAC", "Whip", "ARC" }

// true if the target is able to move. Should really be a method on the object instead, but
// I don't want to mess around with changes in multiple files.
function TargetCache:_IsMobile(target)
     for i,mobileCls in ipairs(TargetCache.kMobileClasses) do
         if target:isa(mobileCls) then 
            return true
         end
     end
     return false
end


function TargetCache:_UpdateTargetListCaches() 
    local newLists = {}
    for i,_ in ipairs(TargetCache.kTargetListNames) do
        newLists[i] = {}
    end 

    // insert the possible targets into the correct list
    // static targets are those that don't move, mobile targets are those that can move
    // valid targets are those that can be damaged (enemies that can be hurt)
    for i,target in ientitylist(Shared.GetEntitiesWithClassname("ScriptActor")) do
        local listIndex = self:_ClassifyEntity(target)
        if listIndex ~= 0 then
            table.insert(newLists[listIndex], target)
            // kAshtl is a superset of kMstl
            if listIndex == TargetCache.kMstl then
                table.insert(newLists[TargetCache.kAshtl], target)    
            end
        end 
    end

    // make sure we get a consistent ordering
    function idSort(ent1, ent2)
        return ent1:GetId() < ent2:GetId()
    end
    
    // simpler cmpTable, as we know that neither t1 nor t2 is nil or contains holes, and that they are both sorted
    function cmpTable(t1, t2)
        if #t1 ~= #t2 then
            return false
        end
        for i,e1 in ipairs(t1) do
            if e1 ~= t2[i] then
                 return false
            end
        end   
        return true  
    end 
   
    // check if the new versions of each list changes, and change the version number if they do
    for i,newTable in ipairs(newLists) do
        table.sort(newTable,idSort)
        if not cmpTable(newTable, self.targetListCache[i]) then
            self.targetListCache[i] = newTable
            self.tlcVersions[i] = self.tlcVersions[i] + 1
            self.log("Updating %s, vers %d, len %d",TargetCache.kTargetListNames[i], self.tlcVersions[i],table.maxn(newTable))
            if self.logTable.detail then
                for i,t in ipairs(newTable) do
                    self.logDetail("%d : %s ", i, t)
                end
            end 
       end
    end
    // mark as uptodate
    self.tlcSalVersion = self.salVersion
end

function TargetCache:_IsCacheInvalid() 
    return self.tlcSalVersion ~= self.salVersion
end

function TargetCache:VerifyTargetingListCache()
    self:_VerifyZombieList()
    if self:_IsCacheInvalid() then
        self:_UpdateTargetListCaches()
    end
end

function TargetCache:GetTargetList(listType)
    self:VerifyTargetingListCache()
    return self.targetListCache[listType]
end

//
// filter the targetList, returning a list of (target,sqRange) tuples inside the given range.
//  
// If visibilityRequired is true, each target is also traced to to verify if it is visible.
//
function TargetCache:RebuildStaticTargetList(attacker, range, visibilityRequired, targetList)
     // static target list has changed. Rebuild it for the given entity
    local result = {}
    local sqRange = range * range
    local origin = GetEntityEyePos(attacker)
    local traceCount = 0

    for i,target in ipairs(targetList) do
        local targetPoint = target:GetEngagementPoint()
        local sqR = (origin - targetPoint):GetLengthSquared()
        if (sqR <= sqRange) then
            if (visibilityRequired) then
                traceCount = traceCount + 1
                // trace as a bullet, but only register hits on target
               local trace = Shared.TraceRay(origin, targetPoint, PhysicsMask.Bullets, EntityFilterOnly(target))
                if trace.entity ~= target then
                    target = nil
                end
            end
            if target then 
                table.insert(result, { target, sqR })
            end
        end
    end
    self.stats:RebuiltStatic(attacker, traceCount, result)
    return result
end


function TargetCache:_logRebuild(attacker, list, listType, version)
    self.logDetail("Rebuilt %s for %s, vers %d, len %d",TargetCache.kTargetListNames[listType], attacker, version , table.maxn(list))
    if self.logTable.detail then
        for i,targetAndSqRange in ipairs(list) do 
            local target, sqRange = unpack(targetAndSqRange)      
            self.logDetail("%d : %s at range %.2f", i, target, math.sqrt(sqRange))
        end
    end
end
//
// Check and recalculate a static target list of the given type.
//
function TargetCache:_GetStaticTargets(listType, attacker, range, visibilityRequired, list, version)
    self:VerifyTargetingListCache()
    local newVersion = self.tlcVersions[listType]
    if version ~= newVersion then        
        list = self:RebuildStaticTargetList(attacker, range, visibilityRequired, self.targetListCache[listType])
        version = newVersion
        self:_logRebuild(attacker, list, listType, version)
    end
    return list,version
end


//
// Return true if the target is acceptable to all filters
//
function TargetCache:_ApplyFilters(target, targetPoint, attacker, filters)
    if filters then
        for _, filter in ipairs(filters) do
            if not filter(target, targetPoint, attacker) then
                return false
            end
        end
    end
    return true
end

//
// Check if the given targets fultills the demands to be a possible target. 
// The standard criteria for a target to be valid is that it isn't the attacker, that it is alive, 
// can take damage and are inside range. 
// If these criteria is fulfilled, then the filters are applied to see if they accept the target as well.
// 
// if range to target is unknown, sqRange may be nil 
function TargetCache:PossibleTarget(attacker, origin, sqMaxRange, target, sqRange, filters)
    // use true for mobile; we know its either a mobile/struct because that hasn't changed since it was targeted
    if target ~= nil and attacker ~= target and self:_IsPossibleTarget(target, self:_IsMobile(target)) then 
        local targetPoint = target:GetEngagementPoint()
        sqRange = sqRange or (origin - targetPoint):GetLengthSquared()     
        if sqRange < sqMaxRange and self:_ApplyFilters(target, targetPoint, attacker, filters) then
            return true, sqRange
        end
    end            
    return false, -1
end

function TargetCache:ValidateTarget(attacker, origin, sqMaxRange, target, sqRange, filters)
    local result = false
    if self:PossibleTarget(attacker, origin, sqMaxRange, target, sqRange, filters) then
        Server.dbgTracer.seeEntityTraceEnabled = true
        result = attacker:GetCanSeeEntity(target)
        Server.dbgTracer.seeEntityTraceEnabled = true
        self.stats:ValidateTarget(attacker, target)
    end
    return result       
end

        

function TargetCache:_GetRawTargetList(attacker, range, visibilityRequired, mobileListType, staticListType, staticList, staticListVersion, filters) 
    self:VerifyTargetingListCache() 
    local result = {}
    local sqMaxRange = range * range
    local origin = GetEntityEyePos(attacker)

    // filter the mobile targets
    if mobileListType then
        for i,target in ipairs(self.targetListCache[mobileListType]) do
            local valid, sqRange = self:PossibleTarget(attacker, origin, sqMaxRange, target, nil, filters)
            if valid then
                table.insert(result, {target, sqRange })
            end
        end
    end
    
    if staticListType then
        // make sure the the list of static targets are uptodate
        staticList, staticListVersion = self:_GetStaticTargets(staticListType, attacker, range, visibilityRequired, staticList, staticListVersion)
        self.stats:UseStatic(attacker, staticList)
        
        // add in the static targets
        for i,targetAndSqRange in ipairs(staticList) do
            local target, sqRange = unpack(targetAndSqRange)
            local valid, sqRange = self:PossibleTarget(attacker, origin, sqMaxRange, target, sqRange, filters)
            if valid then
                table.insert(result, targetAndSqRange)
            end
        end
    end
 
    function sortTargets(eR1, eR2)
        local ent1, r1 = unpack(eR1)
        local ent2, r2 = unpack(eR2)
        if r1 ~= r2 then
            return r1 < r2
        end
        // Make deterministic in case that distances are equal
        return ent1:GetId() < ent2:GetId()
    end
    // sort them closest first
    table.sort(result,sortTargets)
    
    return result,staticList,staticListVersion
end 


//
// Insert valid target into the resultTable until it is full.
// 
// Let a selector work on a target list. If a selector selects a target, a trace is made 
// and if successful, that target and range is inserted in the resultsTable.
// 
// Once the resultTable size reaches maxTargets, the method returns. 
// 
// If the trace fails, the sqRange of that entry in the targets list is set to -1 to mark
// is as ineligible for further selectors. 
//
function TargetCache:_InsertTargets(resultTable, checkedTable, attacker, prioritizer, targets, maxTargets, visibilityRequired)
    local resultTarget, resultRange
    local traceCount = 0
    for index, targetAndSqRange in ipairs(targets) do
        local target, sqRange = unpack(targetAndSqRange)
        local include = false
        if not checkedTable[target] and prioritizer(target, sqRange) then
            if visibilityRequired then 
                traceCount = traceCount + 1
                include = attacker:GetCanSeeEntity(target) 
            else
                include = true
            end
            checkedTable[target] = true
        end            
        if include then
            table.insert(resultTable, target)
            if #resultTable >= maxTargets then
                break
            end
        end                       
    end
    return traceCount
end

//
// AcquireTargets with maxTarget set to 1, and returning the selected target
//
function TargetCache:AcquireTarget(attacker, range, visibilityRequired, mobileListType, staticListType, staticList, staticListVersion, filters, prioritizers)

    local result, staticList, staticListVersion = self:AcquireTargets(attacker, 1, range, visibilityRequired, mobileListType, staticListType, staticList, staticListVersion, filters, prioritizers)

    if #result > 0 then  
        return result[1], staticList, staticListVersion
    end

    return nil, staticList, staticListVersion

end

//
// Acquire a certain number of targets using filters to reject targets and prioritizers to prioritize them
//
// Arguments: See TargetCache:CreateSelector for missing argument descriptions
// - maxTarget - maximum number of targets to acquire
// - staticList - the current list of static targets used by the attacker
// - staticListVersion - the version of the base static target list the staticList is based on
//
// Return a tripple:
// - the chosen target
// - a list of static targets (the given staticList if version is unchanged, else a new one)
// - the version of the static list
//
function TargetCache:AcquireTargets(attacker, maxTargets, range, visibilityRequired, mobileListType, staticListType, staticList, staticListVersion, filters, prioritizers)
    PROFILE("TargetCache:AcquireTargets")
    local targets
    targets, staticList, staticListVersion = self:_GetRawTargetList(
            attacker,
            range, 
            visibilityRequired,
            mobileListType, 
            staticListType, 
            staticList, 
            staticListVersion,
            filters) 

    local traceCount = 0
    local result = {}
    local checkedTable = {} // already checked entities
    local finalRange = nil
    
    Server.dbgTracer.seeEntityTraceEnabled = true
    // go through the prioritizers until we have filled up on targets
    if prioritizers then 
        for _, selector in ipairs(prioritizers) do
            traceCount = traceCount + self:_InsertTargets(result, checkedTable, attacker, selector, targets, maxTargets,visibilityRequired)
            if #result >= maxTargets then
                break
            end
        end
    end
    
    // final run through with an all-selector
    if #result < maxTargets then
        traceCount = traceCount + self:_InsertTargets(result, checkedTable, attacker, TargetCache.allPrioritizer, targets, maxTargets,visibilityRequired)
    end
    Server.dbgTracer.seeEntityTraceEnabled = false
    
    if #result > 0 and self.logTable.detail then
        local msg = nil
        for _,target in ipairs(result) do
            msg = msg and (msg .. ", " .. ToString(target)) or ToString(target)
        end
        self.logTarget("%s targets %s", attacker, msg)
    end
    
    self.stats:AcqTarget(attacker, #targets, traceCount)
    
    return result,staticList,staticListVersion
end

//
// Setup a target selector.
//
// A target selector allows one attacker to acquire and validate targets. 
//
// Arguments: 
// - attacker - the attacker.
//
// - range - the maximum range of the attack. 
//
// - visibilityRequired - true if the target must be visible to the attacker
//
// - mobileListType - a TargetCache.kXxxx value indicating the kind of list used for mobile targets
//
// - staticListType - a TargetCache.kXxxx value indicating the kind of list used for static targets
//
// - filters - a list of filter functions (nil ok), used to remove alive and in-range targets. Each filter will
//             be called with the target and the targeted point on that target. If any filter returnstrue, then the target is inadmissable.
//
// - prioritizers - a list of selector functions, used to prioritize targets. The range-sorted, filtered
//               list of targets is run through each selector in turn, and if a selector returns true the
//               target is then checked for visibility, and if seen, that target is selected.
//               Finally, after all prioritizers have been run through, the closest visible target is choosen.
//               A nil prioritizers will default to a single HarmfulPrioritizer
//
function TargetCache:CreateSelector(attacker, range, visibilityRequired, mobileListType, staticListType, filters, prioritizers)
    return TargetSelector():Init(self, attacker, range, visibilityRequired, mobileListType, staticListType, filters, prioritizers)
end

//
// ----- TargetSelector - simplifies using the TargetCache. --------------------
//
// It wraps the static list handling and remembers how targets are selected so you can acquire and validate
// targets using the same rules. 
//
// After setting up a target selector (preferably using TargetCache:CreateSelector()) in the initialization of
// the attacker, you only then need to call the AcquireTarget() to scan for a new target and
// ValidateTarget(target) to validate it.
//

class "TargetSelector"

//
// Setup a target selector.AbortResearch
//
// A target selector allows one attacker to acquire and validate targets. It wraps the use of the
// targetCache.
//
// Arguments: See TargetCache:CreateSelector for missing argument descriptions
// - cache - the target cache
//
function TargetSelector:Init(cache, attacker, range, visibilityRequired, mobileListType, staticListType, filters, prioritizers)
    self.cache = cache
    self.attacker = attacker
    self.range = range
    self.visibilityRequired = visibilityRequired
    self.mobileListType = mobileListType
    self.staticListType = staticListType
    self.filters = filters
    self.prioritizers = prioritizers or { HarmfulPrioritizer() }
    self.staticList = {}
    self.staticListVersion = -1
    return self
end

function TargetSelector:AcquireTarget() 
    local target
    target, self.staticList, self.staticListVersion = self.cache:AcquireTarget(
            self.attacker,
            self.range,
            self.visibilityRequired, 
            self.mobileListType, 
            self.staticListType, 
            self.staticList, 
            self.staticListVersion,
            self.filters,
            self.prioritizers)
    return target
end


//
// Acquire maxTargets targets inside the given rangeOverride.
//
// both may be left out, in which case maxTargets defaults to 1000 and rangeOverride to standard range
//
// The rangeOverride, if given, must be <= the standard range for this selector
// If originOverride is set, the range filter will filter from this point
// Note that no targets can be selected outside the fixed target selector range.
//
function TargetSelector:AcquireTargets(maxTargets, rangeOverride, originOverride)
    local filters = self.filters
    if rangeOverride then
        filters = {}
        if self.filters then
            table.copy(self.filters, filters)
        end
        local origin = originOverride or GetEntityEyePos(self.attacker)
        table.insert(filters, RangeTargetFilter(origin, rangeOverride))
    end
    // 1000 targets should be plenty ...
    maxTargets = maxTargets or 1000

    local targets
    targets, self.staticList, self.staticListVersion = self.cache:AcquireTargets(
            self.attacker,
            maxTargets,
            self.range,
            self.visibilityRequired,
            self.mobileListType, 
            self.staticListType,
            self.staticList, 
            self.staticListVersion,
            filters,
            self.prioritizers)
    return targets
end

//
// Validate the target. 
// Returns { validflag, sqRange }
//
function TargetSelector:ValidateTarget(target)
    if target then
        self.cache:VerifyTargetingListCache()
        local sqMaxRange = self.range * self.range
        local origin = GetEntityEyePos(self.attacker)
        return self.cache:ValidateTarget(self.attacker, origin, sqMaxRange, target, nil, self.filters)
    end
    return false, -1
end

function TargetSelector:HasStaticTargets()
    self.staticList, self.staticListVersion = self.cache:_GetStaticTargets(
            self.staticListType, 
            self.attacker,
            self.range, 
            self.visibilityRequired, 
            self.staticList,
            self.staticListVersion)
    return #self.staticList > 0
end

//
// if the location of the unit doing the target selection changes, its static target list
// must be invalidated. 
//
function TargetSelector:InvalidateStaticCache()
    self.staticListVersion = -1
end

//
// ----- TcStats - statistics class section --------------------
//

class "TcStats"

function TcStats:Init(logger, windowSize)
    self.log = logger
    self.windowSize = windowSize
    self.entityCount = 0
    self:Reset()
end

function TcStats:Reset()
    self.time = Shared.GetTime()
    self.startTime = Shared.GetTime()

    self.mainListChangeCount = { 0, 0, 0, 0, 0 }
    self.localListStats = {}
    self.tickStats = {}
    self.tick = self:NewTick()
end

function TcStats:NewTick()
    return { acqCount = 0, validateCount = 0, rebuildTraceCount = 0,  targetTraceCount = 0, targetCount= 0 }
end

function TcStats:AcqTarget(attacker, targetCount, traceCount)
    self.tick.acqCount = self.tick.acqCount + 1
    self.tick.targetTraceCount = self.tick.targetTraceCount + traceCount
    self.tick.targetCount = self.tick.targetCount + targetCount
end

function TcStats:ValidateTarget(attacker, target)
    self.tick.validateCount = self.tick.validateCount + 1
    self.tick.targetTraceCount = self.tick.targetTraceCount + 1
    self.tick.targetCount = self.tick.targetCount + 1
end

function TcStats:RebuiltStatic(attacker, traceCount, list)
    self.tick.rebuildTraceCount = self.tick.rebuildTraceCount + 1
    local key = ToString(attacker)
    local llStat = self.localListStats[key]
    if not llStat then
        llStat ={ rebuildCount = 0, length = 0 }
        self.localListStats[key] = llStat
    end
    llStat.rebuildCount = llStat.rebuildCount + 1
    llStat.length = #list 
end

function TcStats:UseStatic(attacker, list)
    local key = ToString(attacker)
    local llStat = self.localListStats[key]
    if not llStat then
        llStat ={ rebuildCount = 0, length = 0 }
        self.localListStats[key] = llStat
    end
    llStat.length = #list     
end



function TcStats:ChangeMainList(listIndex)
     self.mainListChangeCount[listIndex] = self.mainListChangeCount[listIndex] + 1
end


//
// analyze statistics and dump them
// We show how much work we did per tick
//
function TcStats:LogStats()
    // first dump the total stats to the session
    // length of each main list
    // number of times each main list has changed 
    // number of local static lists
    // distribution of their lengths
    // how many times the local lists have been rebuilt
    // number of traces used to rebuild static lists
    // number of traces used to acquire targets
    // number of target acquistions made
    // 
    local tc = Server.targetCache
    local nameCount = nil
    for i,name in ipairs(TargetCache.kTargetListNamesShort) do
        local tmp = name .. ":" .. #tc.targetListCache[i] .. "[" .. self.mainListChangeCount[i] .. "]"
        nameCount = nameCount and nameCount .. ", " .. tmp or tmp 
    end
    self.log("TcStats %s:%s", string.format("%.2f(%.2f)", Shared.GetTime(), (Shared.GetTime() - self.startTime)), nameCount)
    
    local maxLen, totalLen, totalRebuilds, numLocals, counts = 0, 0, 0, 0, {}
    for id, llstat in pairs(self.localListStats) do
        totalLen = totalLen + llstat.length
        totalRebuilds = totalRebuilds + llstat.rebuildCount
        self:Inc(counts, "key-" .. llstat.length)     
        maxLen = math.max(maxLen, llstat.length)
        numLocals = numLocals + 1
    end
    local distrib = nil
    for i = 0, maxLen do
        local count = counts["key-" .. i]
        if count then 
            local tmp = i .. ":" .. count
            distrib = (distrib and (distrib .. ", " .. tmp)) or tmp
        end
    end
    self.log("    - Local: count %s, total len %s, rebuilds %s, distrib: %s" , numLocals, totalLen, totalRebuilds, distrib)
    
    // work distribution over ticks
    local bucketSize = 5
    local workTable = {}
    local maxSlot = 0
    local totalRebuildTraceCount, totalTargetTraceCount, totalTargetCount = 0,0,0
    for i, tick in ipairs(self.tickStats) do
        // slot 1 == 0, slot 2 == 1-5 etc
        local slot = 1 + math.floor((tick.acqCount + bucketSize -1)/ bucketSize)
        self:Inc(workTable, slot)
        //Shared.Message("inc " .. slot .. " to " .. workTable[slot] .. ", acq " .. tick.acqCount)
        maxSlot = math.max(maxSlot, slot)

        totalRebuildTraceCount = totalRebuildTraceCount + tick.rebuildTraceCount
        totalTargetTraceCount = totalTargetTraceCount + tick.targetTraceCount
        totalTargetCount = totalTargetCount + tick.targetCount
    end
    
    // total work
    self.log("    - Traces: %s rebuild, %s targeting. Total targets checked: %s", totalRebuildTraceCount, totalTargetTraceCount, totalTargetCount)

    // work distribution over ticks
    local workMsg = string.format("0:%d", workTable[1] or 0)
    for i = 2, maxSlot do
        local count = workTable[i]
        if count then
            local tmp = ( 1 + (i-2) * bucketSize) .. "-" .. ((i-1)*bucketSize) .. ":" .. count
            workMsg = (workMsg and (workMsg .. ", " .. tmp)) or tmp
        end
    end
    self.log("    - Work (target acq, bucketsize %d): %s", bucketSize, workMsg) 
end

function TcStats:CheckTickTime()
    if self.gameStarted then
        local now = Shared.GetTime()
        if now ~= self.time then
            if now - self.startTime > self.windowSize then
                self:LogStats()
                self:Reset()
            end
            table.insert(self.tickStats, self.tick)
            self.tick = self:NewTick()
            self.time = now
        end
    end
    if GetGamerules():GetGameStarted() ~= self.gameStarted then
        self.gameStarted = GetGamerules():GetGameStarted()
        self:Reset()
    end
end

function TcStats:Add(tab, key, amount)
    amount = amount or 1
    tab[key] = (tab[key] and tab[key] + amount) or amount
end

function TcStats:Inc(tab, key)
    self:Add(tab, key, 1)
end

function OnUpdateServer()
    Server.targetCache.stats:CheckTickTime()
end

Event.Hook("UpdateServer", OnUpdateServer)

