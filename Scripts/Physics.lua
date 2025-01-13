dofile("MathExtension.lua")

---@class Physics
Physics = class()

---@param this Shape
---@param other Shape
---@param gimbleOffset Vec3
---@param rodLength number
function Physics:solveRodConstraint(this, other, gimbleOffset, rodLength)
    local consts = {
        maxError                             = 1.0,
        cancelVelocityFactor                 = 0.5,
        rodForceFactor                       = 8.0,
        cancelVelocityCorrectionTorqueFactor = 0.5,
        inducedTorqueFactor                  = 0.25,
    }

    local diff = other:transformLocalPoint(gimbleOffset) - this:transformLocalPoint(gimbleOffset)
    local distance = diff:length()
    local direction = diff:normalize()

    --Cancel orbiting effects by canceling the force component that is
    --perpendicular to the rod, one tick later.
    if self.rodForce then
        local forceInDir = direction * self.rodForce:dot(direction)
        local forcePerpendicular = self.rodForce - forceInDir

        sm.physics.applyImpulse(this, -forcePerpendicular, true, gimbleOffset)

        self.rodForce = nil
    end

    local error = distance - rodLength

    --Bound the error to prevent extreme forces, leading to instability.
    error = math.clamp(error, -consts.maxError, consts.maxError)

    local smallestMass = math.min(this.body.mass, other.body.mass)

    local rodForce = math.sign(error) * error ^ 2 * smallestMass * consts.rodForceFactor

    self.rodForce = direction * rodForce

    local cancelVelForce = self.cancelVelocityAcceleration(this, other, direction) * this.body.mass
        * consts.cancelVelocityFactor

    local totalForce = cancelVelForce + self.rodForce

    local cOMOffset = this.body.centerOfMassPosition - this.worldPosition

    local correctionTorque = cOMOffset:cross(cancelVelForce) * consts.cancelVelocityCorrectionTorqueFactor
    -- - self.inducedTorque(this, cancelVelAcc, massOffset) * consts.inducedTorqueFactor

    sm.physics.applyImpulse(this, totalForce, true, gimbleOffset)
    sm.physics.applyTorque(this.body, correctionTorque, true)
end

---@param this Shape
---@param other Shape
---@param direction Vec3
---@return Vec3
function Physics.cancelVelocityAcceleration(this, other, direction)
    local totalMass = this.body.mass + other.body.mass

    --The velocity difference between the two shapes that should be canceled
    --out. Only in the direction of the coupling.
    local deltaVelocity = other.velocity - this.velocity
    deltaVelocity = direction * deltaVelocity:dot(direction)

    --The smaller the mass of this shapes body, the more it should be
    --influenced. The total influence of both sides should be 1.
    local influence = other.body.mass / totalMass

    return deltaVelocity * influence
end

---The torque that is induced by the acceleration of a point with offset to the
---center of mass.
---
---Has high complexity overhead with little effect. Correctness not verified.
---May lead to unstable behavior.
---@param shape Shape
---@param pointAcc Vec3
---@param pointOffset Vec3
---@return Vec3
function Physics.inducedTorque(shape, pointAcc, pointOffset)
    local inertia = Physics.computeBodyInertia(shape.body)

    local bodyAngularAcc = (pointOffset:cross(pointAcc)) / inertia

    local bodyAcc = pointAcc - bodyAngularAcc:cross(pointOffset) +
        pointOffset * shape.body.angularVelocity:length2()

    return pointOffset:cross(bodyAcc * shape.body.mass)
end

---Approximates the moment of inertia of a body.
---
---Correctness to the game not verified.
---@param body Body
---@return number
function Physics.computeBodyInertia(body)
    local inertia = 0.0

    local centerOfMass = body:getCenterOfMassPosition()

    for _, shape in ipairs(body:getShapes()) do
        inertia = inertia + Physics.computeShapeInertia(shape, centerOfMass)
    end

    return math.max(inertia, 1.0)
end

---Approximates the moment of inertia added by a shape onto a specified center of mass.
---@param shape Shape
---@param centerOfMass Vec3
---@return number
function Physics.computeShapeInertia(shape, centerOfMass)
    local inertia = 0.0

    local bb = shape:getBoundingBox()
    local iBB = bb * 4.0
    local hBB = bb * 0.5

    local mass = shape:getMass() / (iBB.x * iBB.y * iBB.z)

    for i = -hBB.x + 0.0, hBB.x - 0.25, 0.25 do
        for j = -hBB.y + 0.0, hBB.y - 0.25, 0.25 do
            for k = -hBB.z + 0.0, hBB.z - 0.25, 0.25 do
                local point = sm.vec3.new(i + 0.125, j + 0.125, k + 0.125)

                inertia = inertia + mass * (shape:transformLocalPoint(point) - centerOfMass):length2()
            end
        end
    end

    return inertia
end
