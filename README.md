# InputContextHandler

A code-first wrapper around Roblox's Input Action System.

The native IAS wants you to manage `InputContext`, `InputAction` and `InputBinding`
instances in the Explorer. That does not survive Rojo, external editors or code
review. This builds the whole input graph at runtime from Luau instead, with types
for everything it exposes and automatic cleanup through Trove.

## Install

```toml
# wally.toml
[dependencies]
InputContextHandler = "ivasmigins/inputcontexthandler@0.2.0"
```

## Usage

```lua
local InputContextHandler = require(ReplicatedStorage.Packages.InputContextHandler)

local gameplay = InputContextHandler.new("Gameplay")
gameplay.Parent = player.PlayerGui
gameplay.Priority = 1000

-- A button press. Bindings and callbacks both chain.
gameplay:CreateAction("Jump")
	:AddBinding("Keyboard", Enum.KeyCode.Space)
	:AddBinding("Gamepad", Enum.KeyCode.ButtonA)
	:OnPressed(function()
		print("jump")
	end)

-- A directional action, read per frame.
local move = gameplay:CreateAction("Move", Enum.InputActionType.Direction2D)
move:AddWASDBinding("WASD")
move:CreateBinding("Thumbstick"):SetKeyCode(Enum.KeyCode.Thumbstick1)

RunService.Heartbeat:Connect(function()
	local dir = move:GetState() -- Vector2 for Direction2D
	if dir and dir.Magnitude > 0 then
		-- ...
	end
end)

-- Destroying the context destroys its actions, bindings and connections.
gameplay.Enabled = false
gameplay:Destroy()
```

`OnPressed` and `OnReleased` receive no arguments, matching the engine. Use
`OnStateChanged(function(value) ... end)` when you need the value.

Which binding properties are writable depends on the action's `InputActionType`,
so keep track of which type you created.

## API

Properties can be set with dot-syntax (`action.Enabled = false`) or chainable
setters (`:SetEnabled(false)`). Three handler types mirror the three instances:

| | Wraps | Key methods |
| --- | --- | --- |
| `InputContextHandler` | `InputContext` | `CreateAction`, `WrapAction`, `GetAction`, `RemoveAction` |
| `InputActionHandler` | `InputAction` | `CreateBinding`, `AddBinding`, `AddWASDBinding`, `GetState`, `Fire`, `OnPressed`, `OnReleased`, `OnStateChanged` |
| `InputBindingHandler` | `InputBinding` | `SetKeyCode`, `SetUIButton`, `SetDirections`, `SetScale`, `SetWASD`, `SetArrowKeys`, `Fire` |

Full type definitions live in [`src/Types.d.luau`](src/Types.d.luau).

## License

MIT
