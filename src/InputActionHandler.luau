-- Authors: 1VASM1G1NS
--[[
    Wrapper for Roblox InputAction objects.

    Responsibilities:
    - Manages the full lifecycle of an InputAction and its associated InputBindingHandlers.
    - Provides methods to configure properties but also exposes them via index and newindex.
    - Simplifies InputBindingHandler creation, retrieval, and removal.
    - Handles cleanup automatically via Trove.

    For advanced scenarios, you can access the underlying InputAction instance with GetInstance().
--]]

--// Imports //--
local Trove = require(script.Parent.Parent.Trove)
local InputBindingHandler = require("./InputBindingHandler")
local TypesDefinition = require("./Types.d")

--// Types //--
type InputActionHandler = TypesDefinition.InputActionHandler

--// Constants //--
-- Whitelisted properties from the underlying InputAction instance that can be safely accessed or modified.
local PROPERTY_WHITELIST = {
	Type = true,
	Enabled = true,
	DisplayName = true,
	PreferredBinding = true,
}

-- Whitelisted properties the engine exposes as read-only: readable, but not assignable.
local READ_ONLY_PROPERTIES = {
	PreferredBinding = true,
}

-- Explicitly whitelisted custom properties
local CUSTOM_PROPERTIES = {
	_bindings = true,
	_fireBinding = true,
}

-- Name of the internal Scriptable InputBinding that backs Fire.
-- Roblox deprecated InputAction:Fire in favour of InputBinding:Fire on a Scriptable binding.
local FIRE_BINDING_NAME = "__InputContextHandlerFire"

--// Class //--

local InputActionHandler = {}
InputActionHandler.__index = function(self, key)
	local classValue = rawget(InputActionHandler, key)
	if classValue ~= nil then
		return classValue
	end

	local action = rawget(self, "_action")
	if action and PROPERTY_WHITELIST[key] then
		return action[key]
	end

	if CUSTOM_PROPERTIES[key] then
		return rawget(self, key)
	end

	error(`Unknown or private property '{key}'`, 2)
end

InputActionHandler.__newindex = function(self, key, value)
	if READ_ONLY_PROPERTIES[key] then
		error(`Property '{key}' is read-only`, 2)
	end

	local action = rawget(self, "_action")
	if action and PROPERTY_WHITELIST[key] then
		action[key] = value
		return
	end

	if CUSTOM_PROPERTIES[key] then
		rawset(self, key, value)
		return
	end

	error(`Cannot set unknown property '{key}'`, 2)
end

--[[
	Creates a new InputActionHandler.
	@param inputAction - The InputAction instance to track
]]
function InputActionHandler.new(inputAction: InputAction): InputActionHandler
	local self = {
		_trove = Trove.new(),
		_action = inputAction,
		_bindings = {},
	}

	self = setmetatable(self, InputActionHandler)
	self:_cacheBindings()

	return self
end

--// Configuration Methods //--

function InputActionHandler:SetType(actionType: Enum.InputActionType)
	self._action.Type = actionType
	return self
end

function InputActionHandler:SetEnabled(enabled: boolean)
	self._action.Enabled = enabled
	return self
end

--[[
	Sets the human-readable name used when this action is surfaced in UI.
	@param displayName - Name to display
]]
function InputActionHandler:SetDisplayName(displayName: string)
	self._action.DisplayName = displayName
	return self
end

--// Binding Management Methods //--

--[[
	Creates and adds a new binding, returns its handler for further configuration. Deletes any existing binding with the same name.
	@param name - Unique name for this binding
	@return InputBindingHandler
]]
function InputActionHandler:CreateBinding(name: string)
	local existingHandler = self._bindings[name]
	if existingHandler then
		existingHandler:Destroy()
	end

	local binding = Instance.new("InputBinding")
	binding.Name = name
	binding.Parent = self._action

	local handler = InputBindingHandler.new(binding)
	self._bindings[name] = handler
	self._trove:Add(handler)

	return handler
end

--[[
	Wraps an existing InputBinding in a handler. Deletes any existing binding with the same name.
	@param inputBinding - Existing InputBinding instance
	@return InputBindingHandler
]]
function InputActionHandler:WrapBinding(inputBinding: InputBinding)
	if inputBinding.Parent ~= self._action then
		inputBinding.Parent = self._action
	end
	local existingHandler = self._bindings[inputBinding.Name]
	if existingHandler then
		existingHandler:Destroy()
	end

	local handler = InputBindingHandler.new(inputBinding)
	self._bindings[inputBinding.Name] = handler
	self._trove:Add(handler)

	return handler
end

--[[
	Adds a keyboard binding with the specified KeyCode.
	@param name - Unique name for this binding
	@param keyCode - Enum.KeyCode for the key
]]
function InputActionHandler:AddBinding(name: string, keyCode: Enum.KeyCode)
	self:CreateBinding(name):SetKeyCode(keyCode)
	return self
end

--[[
	Adds a touch binding linked to a GuiButton.
	@param name - Unique name for this binding
	@param uiButton - GuiButton instance that triggers this binding
]]
function InputActionHandler:AddTouchBinding(name: string, uiButton: GuiButton)
	self:CreateBinding(name):SetUIButton(uiButton)
	return self
end

--[[
	Adds a WASD directional binding (requires Direction2D or Direction3D action type).
	@param name - Unique name for this binding
]]
function InputActionHandler:AddWASDBinding(name: string)
	self:CreateBinding(name):SetWASD()
	return self
end

--[[
	Adds an arrow keys directional binding (requires Direction2D or Direction3D action type).
	@param name - Unique name for this binding
]]
function InputActionHandler:AddArrowKeysBinding(name: string)
	self:CreateBinding(name):SetArrowKeys()
	return self
end

--[[
	Removes a binding by name.
	@param name - Name of the binding to remove
]]
function InputActionHandler:RemoveBinding(name: string)
	local handler = self._bindings[name]
	if handler then
		handler:Destroy()
		self._bindings[name] = nil
	end
	return self
end

--[[
	Gets a binding handler by name.
	@param name - Name of the binding
	@return InputBindingHandler?
]]
function InputActionHandler:GetBinding(name: string)
	return self._bindings[name]
end

--[[
	Gets all binding handlers.
	@return Dictionary of binding handlers
]]
function InputActionHandler:GetAllBindings()
	return self._bindings
end

--// Event Connection Methods //--

--[[
	Connects to the action being pressed. Only fires for Bool actions, on the
	false -> true transition. Roblox passes no arguments to this event.
	@param callback - Called with no arguments
]]
function InputActionHandler:OnPressed(callback: () -> ())
	self._trove:Connect(self._action.Pressed, callback)
	return self
end

--[[
	Connects to the action being released. Only fires for Bool actions, on the
	true -> false transition. Roblox passes no arguments to this event.
	@param callback - Called with no arguments
]]
function InputActionHandler:OnReleased(callback: () -> ())
	self._trove:Connect(self._action.Released, callback)
	return self
end

--[[
	Connects to every state change, for all action types.

	For continuous analog input this fires only when the value changes, so a
	thumbstick held at a fixed angle fires once. Poll GetState() each frame for
	those cases instead.

	@param callback - Called with the new state
]]
function InputActionHandler:OnStateChanged(callback: (state: any) -> ())
	self._trove:Connect(self._action.StateChanged, callback)
	return self
end

--// Utility Methods //--

--[[
	Updates the underlying InputAction to the given state and fires the appropriate signals.

	Roblox deprecated InputAction:Fire in favour of InputBinding:Fire on a binding
	whose Type is Enum.InputBindingType.Scriptable, so this lazily creates and
	reuses one such binding on the action. The binding is internal: it is kept out
	of GetAllBindings and is cleaned up with the handler.

	@param state - The new state to fire (must match the action's Type).
]]
function InputActionHandler:Fire(state: any)
	local binding = self._fireBinding

	if not binding or binding.Parent ~= self._action then
		binding = Instance.new("InputBinding")
		binding.Name = FIRE_BINDING_NAME
		binding.Type = Enum.InputBindingType.Scriptable
		binding.Parent = self._action

		self._fireBinding = binding
		self._trove:Add(binding)
	end

	binding:Fire(state)
end

--[[
	Returns the current state of the underlying InputAction.
	@return The current state.
]]
function InputActionHandler:GetState(): any
	return self._action:GetState()
end

function InputActionHandler:GetInstance(): InputAction
	return self._action
end

function InputActionHandler:Destroy()
	if self._action then
		self._action:Destroy()
	end
	self._trove:Destroy()
	table.clear(self._bindings)
end

function InputActionHandler:_cacheBindings()
	for _, child in self._action:GetChildren() do
		if not child:IsA("InputBinding") then
			continue
		end

		-- Adopt, but do not expose, the internal Scriptable binding backing Fire.
		if child.Name == FIRE_BINDING_NAME then
			self._fireBinding = child
			continue
		end

		local handler = InputBindingHandler.new(child)
		self._bindings[child.Name] = handler
		self._trove:Add(handler)
	end
end

return InputActionHandler
