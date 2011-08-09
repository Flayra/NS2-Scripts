// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Vector.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

/////////////////////
// Class functions //
/////////////////////
Vector.kEpsilon = 0.0001

/*
function Vector:GetLength()
    return InternalVectorLength(self)
end

function Vector:GetLengthSquared()

    // Pull into local variables to avoid extra access costs
    local x = self.x
    local y = self.y
    local z = self.z
    
    return x*x + y*y + z*z
    
end

function Vector:GetLengthXZ()

    // Pull into local variables to avoid extra access costs
    local x = self.x
    local z = self.z    
    
    return math.sqrt( x*x + z*z )
    
end

function Vector:GetDistanceTo(dest)

    local x = self.x - dest.x
    local y = self.y - dest.y
    local z = self.z - dest.z
 
    local length = math.sqrt( x*x + y*y + z*z )

    if(length < Vector.kEpsilon) then

        length = 0

    end

    return length

end

function Vector:GetUnit()
    local l = 1.0 / self:GetLength()
    return Vector(self.x * l, self.y * l, self.z * l)
end

function Vector:Scale(value)
    self.x = self.x * value
    self.y = self.y * value
    self.z = self.z * value
end

function Vector:SetLength(newLength)

    local length = InternalVectorLength(self)    
    self.x = (self.x / length) * newLength
    self.y = (self.y / length) * newLength
    self.z = (self.z / length) * newLength

end

function Vector:GetPerpendicular()

    // Pull into local variables to avoid extra access costs
    local x = self.x
    local y = self.y
    local z = self.z
    
    if(math.abs(y) > (1.0 - Vector.kEpsilon)) then
        local normalizer = 1.0 / math.sqrt(z*z + y*y)
        return Vector(0, z*normalizer, -y*normalizer)
    else
        local normalizer = 1.0 / math.sqrt(z*z + x*x)
        return Vector(-z*normalizer, 0, x*normalizer)
    end

end

function Vector:GetProjection(axis)
    local scale = self:DotProduct(axis)
    return Vector(axis.x * scale, axis.y * scale, axis.z * scale)
end

function Vector:GetReflection(axis)
    local scale = 2 * axis:DotProduct(self)
    return Vector((axis.x - self.x)*scale, (axis.y - self.y)*scale, (axis.z - self.z)*scale)
end

function Vector:DotProduct(vec)
    return self.x*vec.x + self.y*vec.y + self.z*vec.z
end

function Vector:CrossProduct(vec)
    
    // Pull into local variables to avoid extra access costs
    local x = self.x
    local y = self.y
    local z = self.z
    
    return Vector(y*vec.z - z*vec.y, z*vec.x - x*vec.z, x*vec.y - y*vec.x)
end

function Vector:GetIsEqual(vec)
    return self.x == vec.x and self.y == vec.y and self.z == vec.z
end

function Vector:tostring()
    return string.format("<%.2f, %.2f, %.2f>", self.x, self.y, self.z)
end
*/

////////////////////////
// Internal functions //
////////////////////////
function InternalVectorLength(vec)

    // Pull into local variables to avoid extra access costs
    local x = vec.x
    local y = vec.y
    local z = vec.z 
    
    local length = math.sqrt( x*x + y*y + z*z )
    
    if(length < Vector.kEpsilon) then
        length = 0
    end
    
    return length
    
end

///////////////////////
// Utility functions //
///////////////////////
function GetNormalizedVector(inputVec)

    local normVec = Vector()
    
    VectorCopy(inputVec, normVec)
    normVec:Normalize()
    
    return normVec
    
end

function GetNormalizedVectorXZ(inputVec)

    local normVec = Vector()
    
    VectorCopy(inputVec, normVec)
    normVec.y = 0
    normVec:Normalize()
    
    return normVec
    
end

function GetNormalizedVectorXY(inputVec)

    local normVec = Vector()
    
    VectorCopy(inputVec, normVec)
    normVec.z = 0
    normVec:Normalize()
    
    return normVec
    
end

function GetNormalizedVectorYZ(inputVec)

    local normVec = Vector()
    
    VectorCopy(inputVec, normVec)
    normVec.x = 0
    normVec:Normalize()
    
    return normVec
    
end

function ReflectVector(inputVector, normal)

    local bounceDirection = inputVector:GetUnit() * -1
    local inputVectorLength = InternalVectorLength(inputVector)
    
    local bounceReflection = bounceDirection:GetReflection(normal)
    bounceReflection = bounceReflection:GetUnit()
    
    return bounceReflection * inputVectorLength

end

function VectorCopy(src, dest)
    dest.x = src.x
    dest.y = src.y
    dest.z = src.z
end

function VectorAbs(src)
    local v = Vector()
    v.x = math.abs(src.x)
    v.y = math.abs(src.y)
    v.z = math.abs(src.z)
    
    return v
end

