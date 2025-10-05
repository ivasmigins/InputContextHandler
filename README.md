# (IAS but made for scripters) InputContextHandler 

**A Fluent and Robust Wrapper for Roblox's New Input Action System with Complete Type Definitions for All Exposed Objects and Methods**

---

## Purpose

This system was primarily created to **decouple input logic from the Roblox Explorer hierarchy**, solving a major workflow bottleneck for developers using Rojo, external editors, and structured project layouts. Since the native IAS requires managing `InputContext`, `InputAction`, and `InputBinding` instances within the Studio tree, this module provides an **entirely code-based, fluent API** to construct, configure, and manage the full input graph at runtime. This allows developers to define complex input schemes entirely in Luau files, promoting clean separation of concerns and eliminating the need to manually track and version input instances inside of a place file.

---

## Key Features

Unlike other IAS wrapper modules, this does not seek to **re-implement or abstract the underlying Input Action System's core logic**, but rather to **provide a fluent, code-centric wrapper that enhances accessibility and workflow for programmers**. 

* **Fluent API:** Configure actions and bindings with easy method chaining (e.g., `Context:CreateAction("Jump"):AddBinding("SpaceKey", Enum.KeyCode.Space)`).
* **Typed:** Type definitions for all exposed objects and methods, allowing for all the benefits of typed luau.
* **Automatic Cleanup:** Full lifecycle management using **Trove** to ensure all created instances and event connections are destroyed when the handler is destroyed.
* **Property Accessors:** Use dot-syntax to read or write properties on the underlying Roblox objects (e.g., `action.Enabled = false`) thanks to smart metatable handling.
* **Safe:** Error when accessing private (or nil) properties.
* **Built-in Presets:** Simple methods to configure common directional inputs like **WASD** and **Arrow Keys** with a single call.

---

## Basic Usage
This is not an example of recommended architecture or best practices!

```lua
--// Modules
local InputContextHandler = require(path.to.InputContextHandler)
local RunService = game:GetService("RunService")

--// Create a new context for gameplay
local GameplayContext = InputContextHandler.new("GameplayContext") -- Optional parent as 2nd argument
GameplayContext.Priority = 1000 -- Set properties via dot-syntax
GameplayContext.Parent = player.PlayerGui
--or via methods like :SetPriority(), up to you!

--// 1. Define an Action for a simple button press
local JumpAction = GameplayContext:CreateAction("Jump")
	-- Add the bindings
	:AddBinding("Keyboard", Enum.KeyCode.Space)
	:AddBinding("Gamepad", Enum.KeyCode.ButtonA)

--// 2. Connect to the handler's events
-- Connections are automatically cleaned up when JumpAction:Destroy() is called
JumpAction:OnPressed(function(state)
	print("Jump Pressed! State:", state)
end):OnReleased(function(state)
	print("Jump released! State:", state)
end):OnStateChanged(function(state)
	print("Jump state changed! State:", state)
end)

--// 3. Define Directional Actions (e.g., for movement)
local MoveAction = GameplayContext:CreateAction("Move", Enum.InputActionType.Direction2D)

-- Set up bindings using presets
MoveAction:AddWASDBinding("NameOfTheBind")
-- Or by creating your own and configuring them
MoveAction:CreateBinding("Thumbstick"):SetKeyCode(Enum.KeyCode.Thumbstick1)

-- Other types of directional actions
local flightAction = playContext:CreateAction("Flight", Enum.InputActionType.Direction3D)
	:SetEnabled(true) -- Enabled by default

flightAction:CreateBinding("3DKeys")
	:SetDirections({
		Forward = Enum.KeyCode.I, -- Be careful of using the same key as some of the core roblox scripts!
		Backward = Enum.KeyCode.K,
		Up = Enum.KeyCode.U,
		Down = Enum.KeyCode.J,
		Left = Enum.KeyCode.H,
		Right = Enum.KeyCode.L,
	})

local zoomAction = playContext:CreateAction("Zoom", Enum.InputActionType.Direction1D)

zoomAction:CreateBinding("ZoomKeys")
	:SetUp(Enum.KeyCode.Equals)
	:SetDown(Enum.KeyCode.Minus)

--// Example of using the Directional Action on a per-frame basis
RunService.Heartbeat:Connect(function()
	local moveState = MoveAction:GetState()
	if moveState and moveState.Magnitude > 0 then
		-- moveState will be a Vector2 from 2D directional actions
	end
end)
```
Note: Keep track of what your InputAction type is, because depending on it some properties in InputBindings might be writeable or not

Cleanup Example:
```lua
-- To disable the whole context (e.g., opening a menu):
GameplayContext.Enabled = false

-- To destroy all actions, connections, and the context itself:
GameplayContext:Destroy()
-- Individual actions and binds can also be destroyed! but preferably use the parent 
-- handler's method to manage child lifecycles.
-- e.g actionHandler:RemoveBinding(name) & ContextHandler:RemoveAction(name)
```

---

## API
```lua
export type InputContextHandler = {
	GetInstance: (self: InputContextHandler) -> InputContext,
	Destroy: (self: InputContextHandler) -> (),

	-- Config
	SetEnabled: (self: InputContextHandler, enabled: boolean) -> InputContextHandler,
	SetPriority: (self: InputContextHandler, priority: number) -> InputContextHandler,
	SetSink: (self: InputContextHandler, sink: boolean) -> InputContextHandler,
	SetParent: (self: InputContextHandler, parent: Instance) -> InputContextHandler,

	-- Dynamic properties
	Enabled: boolean?,
	Priority: number?,
	Sink: boolean?,
	Parent: Instance?,

	-- Custom properties
	_actions: { [string]: InputActionHandler },

	-- Action management
	CreateAction: (self: InputContextHandler, name: string, actionType: Enum.InputActionType?) -> InputActionHandler,
	WrapAction: (self: InputContextHandler, inputAction: InputAction) -> InputActionHandler,
	GetAction: (self: InputContextHandler, name: string) -> InputActionHandler?,
	GetAllActions: (self: InputContextHandler) -> { [string]: InputActionHandler },
	RemoveAction: (self: InputContextHandler, name: string) -> InputContextHandler,
}

export type InputActionHandler = {
	GetInstance: (self: InputActionHandler) -> InputAction,
	Destroy: (self: InputActionHandler) -> (),

	-- Config
	SetType: (self: InputActionHandler, actionType: Enum.InputActionType) -> InputActionHandler,
	SetEnabled: (self: InputActionHandler, enabled: boolean) -> InputActionHandler,

	-- Dynamic properties
	Type: Enum.InputActionType?,
	Enabled: boolean?,

	-- Custom properties
	_bindings: { [string]: InputBindingHandler },
	
	-- Action Methods
	Fire: (self: InputActionHandler, state: any) -> (),
	GetState: (self: InputActionHandler) -> any,

	-- Binding management
	CreateBinding: (self: InputActionHandler, name: string) -> InputBindingHandler,
	WrapBinding: (self: InputActionHandler, inputBinding: InputBinding) -> InputBindingHandler,
	GetBinding: (self: InputActionHandler, name: string) -> InputBindingHandler?,
	GetAllBindings: (self: InputActionHandler) -> { [string]: InputBindingHandler },
	RemoveBinding: (self: InputActionHandler, name: string) -> InputActionHandler,

	-- Convenience Binding Methods
	AddBinding: (self: InputActionHandler, name: string, keyCode: Enum.KeyCode) -> InputActionHandler,
	AddTouchBinding: (self: InputActionHandler, name: string, uiButton: GuiButton) -> InputActionHandler,
	AddWASDBinding: (self: InputActionHandler, name: string) -> InputActionHandler,
	AddArrowKeysBinding: (self: InputActionHandler, name: string) -> InputActionHandler,

	-- Events
	OnPressed: (self: InputActionHandler, callback: (state: any) -> ()) -> InputActionHandler,
	OnReleased: (self: InputActionHandler, callback: (state: any) -> ()) -> InputActionHandler,
	OnStateChanged: (self: InputActionHandler, callback: (state: any) -> ()) -> InputActionHandler,
}

export type InputBindingHandler = {
	GetInstance: (self: InputBindingHandler) -> InputBinding,
	Destroy: (self: InputBindingHandler) -> (),

	-- Dynamic properties
	KeyCode: Enum.KeyCode?,
	UIButton: GuiButton?,
	PressedThreshold: number?,
	ReleasedThreshold: number?,
	Scale: number?,
	Vector2Scale: Vector2?,
	Forward: Enum.KeyCode?,
	Backward: Enum.KeyCode?,
	Up: Enum.KeyCode?,
	Down: Enum.KeyCode?,
	Left: Enum.KeyCode?,
	Right: Enum.KeyCode?,

	-- Configuration methods
	SetKeyCode: (self: InputBindingHandler, keyCode: Enum.KeyCode) -> InputBindingHandler,
	SetUIButton: (self: InputBindingHandler, uiButton: GuiButton) -> InputBindingHandler,
	SetPressedThreshold: (self: InputBindingHandler, threshold: number) -> InputBindingHandler,
	SetReleasedThreshold: (self: InputBindingHandler, threshold: number) -> InputBindingHandler,
	SetScale: (self: InputBindingHandler, scale: number) -> InputBindingHandler,
	SetVector2Scale: (self: InputBindingHandler, scale: Vector2) -> InputBindingHandler,

	-- Directional
	SetDirections: (self: InputBindingHandler, directions: {
		Forward: Enum.KeyCode?,
		Backward: Enum.KeyCode?,
		Up: Enum.KeyCode?,
		Down: Enum.KeyCode?,
		Left: Enum.KeyCode?,
		Right: Enum.KeyCode?,
	}) -> InputBindingHandler,
	SetForward: (self: InputBindingHandler, keyCode: Enum.KeyCode) -> InputBindingHandler,
	SetBackward: (self: InputBindingHandler, keyCode: Enum.KeyCode) -> InputBindingHandler,
	SetUp: (self: InputBindingHandler, keyCode: Enum.KeyCode) -> InputBindingHandler,
	SetDown: (self: InputBindingHandler, keyCode: Enum.KeyCode) -> InputBindingHandler,
	SetLeft: (self: InputBindingHandler, keyCode: Enum.KeyCode) -> InputBindingHandler,
	SetRight: (self: InputBindingHandler, keyCode: Enum.KeyCode) -> InputBindingHandler,

	-- Presets
	SetWASD: (self: InputBindingHandler) -> InputBindingHandler,
	SetArrowKeys: (self: InputBindingHandler) -> InputBindingHandler,
}
```

---

### Installation


#### 1. [Wally (Recommended)](https://wally.run/package/ivasmigins/inputcontexthandler)

#### 2. [GitHub / Manual](https://github.com/ivasmigins/InputContextHandler)

---

## Contributing

Found a bug or have improvements? Please open an issue or submit a pull request on the GitHub repository.
