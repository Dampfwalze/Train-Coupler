dofile("Physics.lua")
dofile("MathExtension.lua")

local mod_interactive_train_coupler = sm.uuid.new("bce3e28c-fbf9-459c-b32e-588d04f60331")

---@class ShapeClass
TrainCoupler = class()

TrainCoupler.connectionInput = sm.interactable.connectionType.logic
TrainCoupler.connectionOutput = sm.interactable.connectionType.logic
TrainCoupler.maxParentCount = -1
TrainCoupler.maxChildCount = -1

---@type Physics
TrainCoupler.physics = nil

local gimbleOffset = sm.vec3.new(0, 0, 0)

---@class SaveData
local SaveData = {
    ---@type Shape
    coupledWith = nil
}

--MARK: Server events

function TrainCoupler:server_onCreate()
    self:server_init()
end

function TrainCoupler:server_onRefresh()
    self:server_init()
end

function TrainCoupler:server_init()
    ---@type SaveData?
    local data = self.storage:load()

    if data and data.coupledWith then
        self:sv_setCoupledState(data.coupledWith)
    end

    self.physics = Physics()
end

function TrainCoupler:server_onDestroy()
    sm.debugDraw.clear("Connection" .. self.shape.id)
    if self:isCoupled() then
        sm.event.sendToInteractable(self.coupledWith.interactable, "sv_setCoupledState", nil)
    end
end

function TrainCoupler:server_onFixedUpdate(dt)
    local isOnLift = self.shape.body:isOnLift()

    if self.coupledWith then
        sm.debugDraw.addArrow("Connection" .. self.shape.id, CouplerWorldPosition(self.shape),
            CouplerWorldPosition(self.coupledWith), sm.color.new(1, 0, 0))

        local otherIsOnLift = self.coupledWith.body:isOnLift()

        if isOnLift ~= self.prevIsOnLift and isOnLift then
            --Creation has been lifted just now
            self:trySetCoupleState(false)
        else
            if not otherIsOnLift or otherIsOnLift == self.prevOtherIsOnLift then
                --Other creation has not been lifted just now
                self.physics:solveRodConstraint(self.shape, self.coupledWith, gimbleOffset, 4 / 4)
            end
        end
        self.prevOtherIsOnLift = otherIsOnLift
    else
        self:sv_lookForCouplers()
    end

    self.prevIsOnLift = isOnLift

    local parents = self.interactable:getParents(sm.interactable.connectionType.logic)
    if #parents > 0 then
        assert(#parents == 1, "TrainCoupler should only have one logic parent")

        if parents[1]:isActive() then
            if not self.coupledStateChanged then
                self:trySetCoupleState(not self:isCoupled())
            end
        else
            self.coupledStateChanged = false
        end
    end
end

--MARK: Server methods

---@param coupler Shape
function TrainCoupler:sv_setCoupledState(coupler)
    self.coupledWith = coupler

    self:sv_store()

    self.interactable:setActive(coupler ~= nil)

    if not coupler then
        self.coupleCandidate = self:findCouplingCandidate()
    end

    self.network:sendToClients("cl_setCoupleState",
        { coupler = coupler or self.coupleCandidate, state = coupler ~= nil })

    if not coupler then
        sm.debugDraw.clear("Connection" .. self.shape.id)
    end
end

function TrainCoupler:sv_lookForCouplers()
    local candidate = self:findCouplingCandidate()

    if candidate ~= self.coupleCandidate then
        self.coupleCandidate = candidate
        self.network:sendToClients("cl_setCoupleState", { coupler = candidate, state = false })
    end
end

function TrainCoupler:sv_store()
    ---@type SaveData
    local data = {
        coupledWith = self.coupledWith
    }

    self.storage:save(data)
end

--MARK: Common methods

---@param state boolean
function TrainCoupler:trySetCoupleState(state)
    if not sm.isServerMode() then
        self.network:sendToServer("trySetCoupleState", state)
        return
    end

    if state then
        if self.coupleCandidate then
            sm.event.sendToInteractable(self.coupleCandidate.interactable, "sv_setCoupledState", self.shape)
            sm.event.sendToInteractable(self.interactable, "sv_setCoupledState", self.coupleCandidate)
            self.coupledStateChanged = true
        end
    elseif self:isCoupled() then
        sm.event.sendToInteractable(self.coupledWith.interactable, "sv_setCoupledState", nil)
        sm.event.sendToInteractable(self.interactable, "sv_setCoupledState", nil)
        self.coupledStateChanged = true
    end
end

---@return boolean
function TrainCoupler:isCoupled()
    if sm.isServerMode() then
        return self.coupledWith ~= nil
    else
        return self.cl_coupledWith ~= nil
    end
end

---@return Shape?
function TrainCoupler:findCouplingCandidate()
    local shapes = self.shape.shapesInSphere(self.shape.worldPosition, 1.5)

    local couplers = {}

    for _, shape in ipairs(shapes) do
        if shape.uuid == mod_interactive_train_coupler
            and shape.id ~= self.shape.id
            and shape.body.id ~= self.shape.body.id
        then
            couplers[#couplers + 1] = shape
        end
    end

    if #couplers > 0 then
        table.sort(couplers, function(a, b)
            return (a.worldPosition - self.shape.worldPosition):length2() <
                (b.worldPosition - self.shape.worldPosition):length2()
        end)
        return couplers[1]
    end

    return nil
end

--MARK: Client events

function TrainCoupler:client_getAvailableParentConnectionCount(connectionType)
    if connectionType == sm.interactable.connectionType.logic then
        return 1 - #self.interactable:getParents(connectionType)
    else
        return 0
    end
end

function TrainCoupler:client_getAvailableChildConnectionCount(connectionType)
    if connectionType == sm.interactable.connectionType.logic then
        return 1
    else
        return 0
    end
end

function TrainCoupler:client_onCreate()
    self:client_init()
end

function TrainCoupler:client_onRefresh()
    self:client_init()
end

function TrainCoupler:client_init()
    self.interactable:setAnimEnabled("lock", true)
    self.interactable:setAnimEnabled("gimble_yaw", true)
    self.interactable:setAnimEnabled("gimble_pitch", true)
    self.interactable:setAnimEnabled("stretch", true)

    self.cl_animProgress = { pitch = 0.5, yaw = 0.5, stretch = 0.5 }
    self.cl_lockAnimProgress = 0.0
end

function TrainCoupler:client_onDestroy()
    if self.cl_previewCoupler then
        sm.event.sendToInteractable(self.cl_previewCoupler.interactable, "cl_setCoupleState",
            { coupler = nil, state = false })
    end
end

function TrainCoupler:client_onUpdate(dt)
    self:cl_pointToOther(dt);

    self:cl_closeAnimation(dt);
end

function TrainCoupler:client_onInteract(character, state)
    if state then
        self:trySetCoupleState(not self:isCoupled())
    end
end

function TrainCoupler:client_canInteract(character)
    if self.cl_previewCoupler then
        sm.gui.setInteractionText((self:isCoupled() and "Uncouple" or "Couple"))
    else
        sm.gui.setInteractionText("Bring it close to another coupler")
    end
    return self.cl_previewCoupler ~= nil
end

-- MARK: Client methods

---@param dt number
function TrainCoupler:cl_pointToOther(dt)
    if self.cl_previewCoupler then
        local function toAnimProgress(angle)
            local maxAngle = math.pi / 3
            local mapped = math.map(angle, -maxAngle, maxAngle, 0.0, 1.0)
            return math.clamp(mapped, 0.0, 1.0)
        end

        local direction = self.shape:transformDirection(
            CouplerWorldPosition(self.cl_previewCoupler) - CouplerWorldPosition(self.shape))

        local pitch = math.asin(direction.y / math.max(0.001, direction:length()))
        local yaw = math.atan(direction.x / direction.z)
        local length = math.clamp(direction:length() * 4.0 / 2.0, 0.5, 5.0)

        local stretchAnim
        if length > 2.0 then
            stretchAnim = math.map(length, 2.0, 12.0, 0.5, 1.0)
        else
            stretchAnim = math.map(length, 1.0, 2.0, 0.0, 0.5)
        end

        local target = {
            pitch = toAnimProgress(pitch),
            yaw = toAnimProgress(yaw ~= yaw and 0.0 or yaw),
            stretch = 1.0 - stretchAnim
        }

        if self.cl_didApproach then
            self.cl_animProgress = target
        else
            self.cl_animProgress = {
                pitch = ApproachTarget(self.cl_animProgress.pitch, target.pitch, 0.9, dt),
                yaw = ApproachTarget(self.cl_animProgress.yaw, target.yaw, 0.9, dt),
                stretch = ApproachTarget(self.cl_animProgress.stretch, target.stretch, 0.9, dt)
            }

            if math.abs(self.cl_animProgress.pitch - target.pitch) < 0.03
                and math.abs(self.cl_animProgress.yaw - target.yaw) < 0.03
                and math.abs(self.cl_animProgress.stretch - target.stretch) < 0.05
            then
                self.cl_didApproach = true
            end
        end
    else
        self.cl_didApproach = false

        self.cl_animProgress = {
            pitch = ApproachTarget(self.cl_animProgress.pitch, 0.5, 0.9, dt),
            yaw = ApproachTarget(self.cl_animProgress.yaw, 0.5, 0.9, dt),
            stretch = ApproachTarget(self.cl_animProgress.stretch, 0.5, 0.9, dt)
        }
    end

    self.interactable:setAnimProgress("gimble_yaw", self.cl_animProgress.yaw)
    self.interactable:setAnimProgress("gimble_pitch", self.cl_animProgress.pitch)
    self.interactable:setAnimProgress("stretch", self.cl_animProgress.stretch)
end

---@param dt number
function TrainCoupler:cl_closeAnimation(dt)
    local target = self:isCoupled() and 1.0 or 0.0

    self.cl_lockAnimProgress = ApproachTarget(self.cl_lockAnimProgress, target, 0.9, dt)

    self.interactable:setAnimProgress("lock", self.cl_lockAnimProgress)
end

---@param args {coupler: Shape, state: boolean}
function TrainCoupler:cl_setCoupleState(args)
    self.cl_previewCoupler = args.coupler

    if args.state then
        self.cl_coupledWith = args.coupler
    else
        self.cl_coupledWith = nil
    end
end

--MARK: Utility

---@param value number
---@param target number
---@param speed number
---@param dt number
---@return number
function ApproachTarget(value, target, speed, dt)
    return math.lerp(value, target, math.clamp(1.0 - speed ^ (1.0 - dt), 0.0, 1.0))
end

---@param coupler Shape
---@return Vec3
function CouplerWorldPosition(coupler)
    return coupler:transformLocalPoint(gimbleOffset)
end
