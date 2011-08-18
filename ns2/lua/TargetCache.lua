// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TargetCache.lua
//
//    Created by:   Mats Olsson (mats.olsson@matsotech.se)
//
// Allows for fast target selection for AI units such as hydras and sentries. 
// 
// Gains most of its speed by using the fact that the majority of potential targets don't move
// (static) while a minority is mobile. 
//
// To speed things up even further, the concept of TargetType is used. Each TargetType maintains a
// dictionary of created entities that match its own type. This allows for a quick filtering away of
// uninterresting targets, without having to check their type or team.
//
// The static targets are kept in a per-attacker cache. Usually, this table is empty, meaning that
// 90% of all potential targets are ignored at zero cpu cost. The remaining targets are found by
// using the fast ranged lookup (Shared.GetEntitiesWithinRadius()) and then using the per type list
// to quickly ignore any non-valid targets, only then checking validity, range and visibility. 
//
// The TargetSelector is the main interface. It is configured, one per attacker, with the targeting
// requriements (max range, if targets must be visible, what targetTypes, filters and prioritizers).
//
// Once configured, new targets may be acquired using AcquireTarget or AcquireTargets, and the validity
// of a current target can be check by ValidateTarget().
//
// Filters are used to reject targets that are not to valid. 
//
// Prioritizers are used to prioritize among targets. The default prioritizer chooses targets that
// can damage the attacker before other targets.
// 
Script.Load("lua/NS2Gamerules.lua") 

//
// TargetFilters are used to remove targets before presenting them to the prioritizers
// 

//
// Removes targets that are not inside the maxPitch
//
function PitchTargetFilter(attacker, minPitchDegree, maxPitchDegree)
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

function CloakTargetFilter()
    return  function(target, targetPoint)
                return not HasMixin(target, "Cloakable") or not target:GetIsCloaked()
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
// be selected if it is visible (if required). If not visible, the selection process continues.
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



class 'TargetType'

function TargetType:Init(name, classList)
    self.name = name
    self.classMap = {}
    for _,className in ipairs(classList) do
        self.classMap[className] = true
    end

    // the entities that have been selected by their TargetType. A proper hashtable, not a list.
    self.entityIdMap = {}
        
    return self
end


/**
 * Notification that a new entity id has been added
 */
function TargetType:EntityAdded(entity)
    if self:ContainsType(entity) and not self.entityIdMap[entity:GetId()] then
//        Log("%s: added %s", self.name, entity) 
        self.entityIdMap[entity:GetId()] = true
        self:OnEntityAdded(entity)
    end
end

/**
 * True if we contain the type of the given entity
 */
function TargetType:ContainsType(entity)
    return self.classMap[entity:GetClassName()]
end

/**
 * Notification that an entity id has been removed. 
 */
function TargetType:EntityRemoved(entity)
    if entity and self.entityIdMap[entity:GetId()] then
        self.entityIdMap[entity:GetId()] = nil
  //      Log("%s: removed %s", self.name, entity) 
        self:OnEntityRemoved(entity)    
    end
end


/**
 * Attach a target selector to this TargetType. 
 * 
 * The returned object must be supplied whenever an acquire target is made 
 */
function TargetType:AttachSelector(selector)
    assert(false, "Attach must be overridden")
end

/**
 * Allow subclasses to react to the adding of a new entity id
 */
function TargetType:OnEntityAdded(id)
end

/**
 * Allow subclasses to react to the adding of a new entity id. 
 */
function TargetType:OnEntityRemoved(id)
end

/**
 * Handle static targets
 */
class 'StaticTargetType' (TargetType)

function StaticTargetType:Init(name, classList)
    self.cacheMap = {}
    return TargetType.Init(self, name, classList)
end

function StaticTargetType:AttachSelector(selector)
    // key in cacheMap is the attackers entityId. This allows us to detect when the entity is gone.
    self.cacheMap[selector.attacker:GetId()] = StaticTargetCache():Init(self, selector)
    return self.cacheMap[selector.attacker:GetId()]
end

function StaticTargetType:VisitCaches(fun)
    // go through whole cache and add the entity id to all of them
    local toBeRemoved = {}
    for id,cache in pairs(self.cacheMap) do
        if Shared.GetEntity(id) then
            fun(cache)
        else
            toBeRemoved[id] = true
        end
    end
 
    // remove caches that belongs to no-longer valid entities
    for id,_ in pairs(toBeRemoved) do
        self.cacheMap[id] = nil
    end
end

function StaticTargetType:OnEntityAdded(entity)
    self:VisitCaches(function (cache) cache:OnEntityAdded(entity) end)
end

function StaticTargetType:OnEntityRemoved(entity)
    self:VisitCaches(function (cache) cache:OnEntityRemoved(entity) end)
end

class 'StaticTargetCache'

function StaticTargetCache:Init(targetType, selector)
    self.targetType = targetType
    self.selector = selector
    self.targetIdToRangeMap = nil 
    self.addedEntityIds = {}

    return self
end

function StaticTargetCache:Log(formatString, ...)
    if self.selector.debug then
        formatString = "%s[%s]: " .. formatString
        Log(formatString, self.selector.attacker, self.targetType.name, ...)
    end
end

function StaticTargetCache:OnEntityAdded(entity)
    if self.targetIdToRangeMap then
        table.insert(self.addedEntityIds, entity:GetId())
    end
end

function StaticTargetCache:OnEntityRemoved(entity)
    if self.targetIdToRangeMap then
        // just clear any info we might have had on that id
        self.targetIdToRangeMap[entity:GetId()] = nil
        table.removevalue(self.addedEntityIds, entity:GetId())
    end
end

function StaticTargetCache:ValidateCache()
    if not self.targetIdToRangeMap then 
        self.targetIdToRangeMap = {}
        local origin = self.selector.attacker:GetEyePos()
        entityIds = {}
        Shared.GetEntitiesWithinRadius(origin, self.selector.range, entityIds)
        self:MaybeAddTargets(origin, entityIds)
    end
    // add in any added entities. Need to do it with a delay
    // because when an entity is added, it isn't fully initialized
    if #self.addedEntityIds > 0 then
        self:MaybeAddTargets(self.selector.attacker:GetEyePos(), self.addedEntityIds)
        self.addedEntityIds = {}
    end
end

/**
 * Append possible targets, range pairs to the targetList
 */
function StaticTargetCache:AddTargetsWithRange(selector, targets)
    self:ValidateCache(selector)
    
    for targetId, range in pairs(self.targetIdToRangeMap) do
        local target = Shared.GetEntity(targetId)
        
        if target:GetIsAlive() and target:GetCanTakeDamage() and selector:_ApplyFilters(target, target:GetEngagementPoint()) then
            table.insert(targets, {target, range})
            //Log("%s: static target %s at range %s", selector.attacker, target, range)
        end
    end
end

/**
 * If the attacker moves, the cache has to be invalidated. 
 */
function StaticTargetCache:AttackerMoved()
    self.targetIdToRangeMap = nil    
end

/**
 * Check if the target is a possible target for us
 *
 * Make sure its id is in our map, and that its inside range
 */
function StaticTargetCache:PossibleTarget(target, origin, range)
    self:ValidateCache()
    local r = self.targetIdToRangeMap[target:GetId()]
    return r and r <= range
end

function StaticTargetCache:MaybeAddTarget(target, origin)
    local inRange = false
    local visible = false
    local range = -1
    local rightType = self.targetType.entityIdMap[target:GetId()]
    if rightType then
        local targetPoint = target:GetEngagementPoint()
        range = (origin - targetPoint):GetLength()
        inRange = range <= self.selector.range
        if inRange then
            visible = true
            if (self.selector.visibilityRequired) then
                // trace as a bullet, but ignore everything but the target.
                local trace = Shared.TraceRay(origin, targetPoint, PhysicsMask.Bullets, EntityFilterOnly(target))
//                self:Log("f %s, e %s", trace.fraction, trace.entity)       
                visible = trace.entity == target or trace.fraction == 1
                if visible and trace.entity == target then
                    range = range * trace.fraction
                end
                Server.dbgTracer:TraceTargeting(self.selector.attacker, target, origin, trace)
            end
        end          
    end
    if inRange and visible then 
        // save the target and the range to it
        self.targetIdToRangeMap[target:GetId()] = range
//        self:Log("%s added at range %s", target, range)
    else
        if not rightType then
  //          self:Log("%s rejected, wrong type", target) 
        else
    //        self:Log("%s rejected, range %s, inRange %s, visible %s", target, range, inRange, visible)
        end
    end  
end

function StaticTargetCache:MaybeAddTargets(origin, targetList)
    for i,targetId in ipairs(targetList) do
        // the targetlist may contains newly created/updated items that have gotten killed before we 
        // validate our cache.
        local target = Shared.GetEntity(targetId)
        if target then
            self:MaybeAddTarget(target, origin)
        end
    end
end

function StaticTargetCache:Debug(selector, full)
//    Log("%s :", self.targetType.name)
    self:ValidateCache(selector)
    local origin = GetEntityEyePos(selector.attacker)
    // go through all static targets, showing range and curr
    for targetId, range in pairs(self.targetType.entityIdMap) do
        local target = Shared.GetEntity(targetId)
        local targetPoint = target:GetEngagementPoint()
        local range = (origin - targetPoint):GetLength()
        local inRange = range <= selector.range
        if full or inRange then
            local valid = target:GetIsAlive() and target:GetCanTakeDamage()
            local unfiltered = selector:_ApplyFilters(target, targetPoint)
            local visible = true
            if selector.visibilityRequired then
                local trace = Shared.TraceRay(origin, targetPoint, PhysicsMask.Bullets, EntityFilterOnly(target))
                visible = trace.entity == target or trace.fraction == 1
                Server.dbgTracer:TraceTargeting(selector.attacker,target,origin, trace)
            end
            local inCache = self.targetIdToRangeMap[targetId] ~= nil
            local shouldBeInCache = inRange and visible
            local cacheTxt = (inCache == shouldBeInCache and "") or (string.format(", CACHE %s != shouldBeInCache %s!", ToString(inCache), ToString(shouldBeInCache)))
//            Log("%s: in range %s, valid %s, unfiltered %s, visible %s%s", target, inRange, valid, unfiltered, visible, cacheTxt)
        end
    end
end

/**
 * Handle mobile targets
 */
class 'MobileTargetType' (TargetType)

function MobileTargetType:AttachSelector(selector)
    // we don't do any caching on a per-selector basis, so just return ourselves
    return self
end


function MobileTargetType:AddTargetsWithRange(selector, targets)
    local origin = GetEntityEyePos(selector.attacker)
    local entityIds = {}

    Shared.GetEntitiesWithinRadius(origin, selector.range, entityIds)
    for _, id in ipairs(entityIds) do
        if self.entityIdMap[id] then
            local target = Shared.GetEntity(id)
            local targetPoint = target:GetEngagementPoint()
            local range = (origin - targetPoint):GetLength()             
            if range <= selector.range and target:GetIsAlive() and target:GetCanTakeDamage() and selector:_ApplyFilters(target, targetPoint) then
                table.insert(targets, { target, range })
                // Log("%s: mobile target %s at range %s", selector.attacker, target, range)
            end
        end
    end
end

function MobileTargetType:AttackerMoved()  
    // ignore: notings cached here
end

function MobileTargetType:PossibleTarget(target, origin, range)
    local r = nil
    if self.entityIdMap[target:GetId()] then
        r = (origin - target:GetEngagementPoint()):GetLength()
    end
    return r and r <= range
end


function MobileTargetType:Debug(selector, full)
    // go through all mobile targets, showing range and curr
    local origin = GetEntityEyePos(selector.attacker)
    local idsInRadius = { }
    Shared.GetEntitiesWithinRadius(origin, selector.range, idsInRadius)

    Log("%s : %s entities inside %s range (%s)", self.name, #idsInRadius, selector.range, idsInRadius)
    
    for id,_ in pairs(self.entityIdMap) do
        local target = Shared.GetEntity(id)
        local targetPoint = target:GetEngagementPoint()
        local range = (origin - targetPoint):GetLength()      
        local inRange = range <= selector.range 
        if full or inRange then
            local valid = target:GetIsAlive() and target:GetCanTakeDamage()
            local unfiltered = selector:_ApplyFilters(target, targetPoint)
            Server.dbgTracer.seeEntityTraceEnabled = true
            local visible = selector.attacker:GetCanSeeEntity(target)
            Server.dbgTracer.seeEntityTraceEnabled = false
            local inRadius = table.contains(idsInRadius, target:GetId())
            Log("%s, in range %s (%s), in radius %s, valid %s, unfiltered %s, visible %s", target, range, inRange, inRadius, valid, unfiltered, visible)
        end
    end
end

//
// Note that we enumerate each individual instantiated class here. Adding new structures means that these must be updated.
//
/** Static targets for marines */
kMarineStaticTargets = StaticTargetType():Init( "MarineStatic", { "Hydra", "Cyst", "MiniCyst", "Crag", "Shade", "Harvester", "Hive", "Embryo", "Egg" })
/** Arc targets are the same + the Whip */
kMarineARCTargets = StaticTargetType():Init( "MarineArc", { "Hydra", "Cyst", "MiniCyst", "Crag", "Shade", "Harvester", "Hive", "Embryo", "Egg", "Whip" })
/** Mobile targets for marines */
kMarineMobileTargets = MobileTargetType():Init( "MarineMobile", { "Skulk", "Lerk", "Fade", "Gorge", "Onos", "Drifter", "Whip" })
/** Static targets for aliens */
kAlienStaticTargets = StaticTargetType():Init( "AlienStatic", { "Sentry", "PowerPack", "PowerPoint", "CommandStation", "Extractor", "InfantryPortal", "PhaseGate", "RoboticsFactory", "Observatory", "AdvancedArmory", "ArmsLab", "Armory", })
/** Mobile targets for aliens */
kAlienMobileTargets = MobileTargetType():Init( "AlienMobile", { "Marine", "MAC", "ARC" } )
/** Alien static heal targets */
kAlienStaticHealTargets = kMarineStaticTargets
/** Alien mobile heal targets */
kAlienMobileHealTargets = kMarineMobileTargets

// Used as final step if all other prioritizers fail
TargetType.kAllPrioritizer = AllPrioritizer()

// List all target class
TargetType.kAllTargetTypees = {
    kMarineStaticTargets, 
    kMarineMobileTargets,
    kAlienStaticTargets, 
    kAlienMobileTargets
}

    
//
// called by TargetMixin when targetable units are created or destroyed
//
function TargetType.OnDestroyEntity(entity)
    for _,tc in ipairs(TargetType.kAllTargetTypees) do
        tc:EntityRemoved(entity)
    end
end

function TargetType.OnCreateEntity(entity)
    for _,tc in ipairs(TargetType.kAllTargetTypees) do
        tc:EntityAdded(entity)
    end
end


//
// ----- TargetSelector - simplifies using the TargetCache. --------------------
//
// It wraps the static list handling and remembers how targets are selected so you can acquire and validate
// targets using the same rules. 
//
// After creating a target selector in the initialization of the attacker, you only then need to call the AcquireTarget()
// to scan for a new target and ValidateTarget(target) to validate it.
// While the TargetSelector assumes that you don't move, if you do move, you must call AttackerMoved().
//

class "TargetSelector"

//
// Setup a target selector.
//
// A target selector allows one attacker to acquire and validate targets. 
//
// The attacker should stay in place. If the attacker moves, the AttackerMoved() method MUST be called.
//
// Arguments: 
// - attacker - the attacker.
//
// - range - the maximum range of the attack. 
//
// - visibilityRequired - true if the target must be visible to the attacker
//
// - targetTypeList - list of targetTypees to use
//
// - filters - a list of filter functions (nil ok), used to remove alive and in-range targets. Each filter will
//             be called with the target and the targeted point on that target. If any filter returns true, then the target is inadmissable.
//
// - prioritizers - a list of selector functions, used to prioritize targets. The range-sorted, filtered
//               list of targets is run through each selector in turn, and if a selector returns true the
//               target is then checked for visibility (if visibilityRequired), and if seen, that target is selected.
//               Finally, after all prioritizers have been run through, the closest visible target is choosen.
//               A nil prioritizers will default to a single HarmfulPrioritizer
//
function TargetSelector:Init(attacker, range, visibilityRequired, targetTypeList, filters, prioritizers)
    self.attacker = attacker
    self.range = range
    self.visibilityRequired = visibilityRequired
    self.filters = filters
    self.prioritizers = prioritizers or { HarmfulPrioritizer() }

    self.targetTypeMap = {}
    for _, tc in ipairs(targetTypeList) do
        self.targetTypeMap[tc] = tc:AttachSelector(self)
    end
    
    self.debug = false 
    // Log("created ts for %s, tcmap %s", attacker, self.targetTypeMap)
    
    return self
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
    local savedFilters = self.filters
    if rangeOverride then
        local filters = {}
        if self.filters then
            table.copy(self.filters, filters)
        end
        local origin = originOverride or GetEntityEyePos(self.attacker)
        table.insert(filters, RangeTargetFilter(origin, rangeOverride))
        self.filters = filters
    end

    // 1000 targets should be plenty ...
    maxTargets = maxTargets or 1000

    local targets = self:_AcquireTargets(maxTargets)
    return targets
end

//
// Return true if the target is acceptable to all filters
//
function TargetSelector:_ApplyFilters(target, targetPoint)
    //Log("%s: _ApplyFilters on %s, %s", self.attacker, target, targetPoint)
    if self.filters then
        for _, filter in ipairs(self.filters) do
            if not filter(target, targetPoint) then
                //Log("%s: Reject %s", self.attacker, target)
                return false
            end
            //Log("%s: Accept %s", self.attacker, target)
        end
    end
    return true
end

//
// Check if the target is possible. 
//
function TargetSelector:_PossibleTarget(target)
    if target and self.attacker ~= target and (target.GetIsAlive and target:GetIsAlive()) and target:GetCanTakeDamage() then
        local origin = self.attacker:GetEyePos()
        
        local possible = false
        for tc,tcCache in pairs(self.targetTypeMap) do
            possible = possible or tcCache:PossibleTarget(target, origin, self.range) 
        end
        if possible then
            local targetPoint = target:GetEngagementPoint()
            if self:_ApplyFilters(target, targetPoint) then
                return true
            end
        end
    end            
    return false
end

function TargetSelector:ValidateTarget(target)
    local result = false
    if target then
        result = self:_PossibleTarget(target)
        if result and self.visibilityRequired then
            Server.dbgTracer.seeEntityTraceEnabled = true
            result = self.attacker:GetCanSeeEntity(target)
            Server.dbgTracer.seeEntityTraceEnabled = true
        end
//        self:Log("validate %s -> %s", target, result)
    end
    return result       
end


//
// AcquireTargets with maxTarget set to 1, and returning the selected target
//
function TargetSelector:AcquireTarget()
    return self:_AcquireTargets(1)[1]
end

//
// Acquire a certain number of targets using filters to reject targets and prioritizers to prioritize them
//
// Arguments: See TargetCache:CreateSelector for missing argument descriptions
// - maxTarget - maximum number of targets to acquire
//
// Return:
// - the chosen targets
//
function TargetSelector:_AcquireTargets(maxTargets)
    PROFILE("TargetSelector:_AcquireTargets")
    local targets = self:_GetRawTargetList() 

    local result = {}
    local checkedTable = {} // already checked entities
    local finalRange = nil
    
    Server.dbgTracer.seeEntityTraceEnabled = true
    // go through the prioritizers until we have filled up on targets
    if self.prioritizers then 
        for _, prioritizer in ipairs(self.prioritizers) do
            self:_InsertTargets(result, checkedTable, prioritizer, targets, maxTargets)
            if #result >= maxTargets then
                break
            end
        end
    end
    
    // final run through with an all-selector
    if #result < maxTargets then
        self:_InsertTargets(result, checkedTable, TargetType.kAllPrioritizer, targets, maxTargets)
    end
    Server.dbgTracer.seeEntityTraceEnabled = false
  
    if self.debug and #result > 0 then
        Log("%s: found %s targets (%s)", self.attacker, #result, result[1])
    end
    return result
end


/**
 * Return a sorted list of alive and GetCanTakeDamage'able targets, sorted by range. 
 */
function TargetSelector:_GetRawTargetList()

    local result = {}

    // get potential targets from all targetTypees
    for tc,tcCache in pairs(self.targetTypeMap) do
        tcCache:AddTargetsWithRange(self, result)
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
    
    return result
end 

//
// Insert valid target into the resultTable until it is full.
// 
// Let a selector work on a target list. If a selector selects a target, a trace is made 
// and if successful, that target and range is inserted in the resultsTable.
// 
// Once the results size reaches maxTargets, the method returns. 
//
function TargetSelector:_InsertTargets(foundTargetsList, checkedTable, prioritizer, targets, maxTargets)
    for _, targetAndRange in ipairs(targets) do
        local target, range = unpack(targetAndRange)
        // Log("%s: check %s, range %s, ct %s, prio %s", self.attacker, target, range, checkedTable[target], prioritizer(target,range))
        local include = false
        if not checkedTable[target] and prioritizer(target, range) then
            if self.visibilityRequired then 
                include = self.attacker:GetCanSeeEntity(target) 
            else
                include = true
            end
            checkedTable[target] = true
        end            
        if include then
            //Log("%s targets %s", self.attacker, target)
            table.insert(foundTargetsList,target)
            if #foundTargetsList >= maxTargets then
                break
            end
        end                       
    end
end


//
// if the location of the unit doing the target selection changes, its static target list
// must be invalidated. 
//
function TargetSelector:AttackerMoved()
    for tc,tcCache in pairs(self.targetTypeMap) do
        tcCache:AttackerMoved()
    end
end

//
// Dump debugging info for this TargetSelector
//
function TargetSelector:Debug(cmd)
    local full = cmd == "full" // list all possible targets, even those out of range
    self.debug = cmd == "log" and not self.debug or self.debug // toggle logging for this selector only
    Log("%s : target debug (full=%s, log=%s)", self.attacker, full, self.debug)
    for tc,tcCache in pairs(self.targetTypeMap) do
        tcCache:Debug(self, full)
    end
end

function TargetSelector:Log(formatString, ...)
    if self.debug then
        formatString = "%s: " .. formatString
        Log(formatString, self.attacker, ...)
    end
end