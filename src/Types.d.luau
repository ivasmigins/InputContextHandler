--!strict

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
	SetDisplayName: (self: InputActionHandler, displayName: string) -> InputActionHandler,

	-- Dynamic properties
	Type: Enum.InputActionType?,
	Enabled: boolean?,
	DisplayName: string?,
	-- Read-only on the engine instance; assigning throws.
	PreferredBinding: InputBinding?,

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
	-- Pressed and Released are fired by the engine with no arguments.
	OnPressed: (self: InputActionHandler, callback: () -> ()) -> InputActionHandler,
	OnReleased: (self: InputActionHandler, callback: () -> ()) -> InputActionHandler,
	OnStateChanged: (self: InputActionHandler, callback: (state: any) -> ()) -> InputActionHandler,
}

export type InputBindingHandler = {
	GetInstance: (self: InputBindingHandler) -> InputBinding,
	Destroy: (self: InputBindingHandler) -> (),

	-- Action Methods
	Fire: (self: InputBindingHandler, state: any) -> (),

	-- Dynamic properties
	KeyCode: Enum.KeyCode?,
	UIButton: GuiButton?,
	PressedThreshold: number?,
	ReleasedThreshold: number?,
	Scale: number?,
	Vector2Scale: Vector2?,
	Vector3Scale: Vector3?,
	Type: Enum.InputBindingType?,
	PrimaryModifier: Enum.KeyCode?,
	SecondaryModifier: Enum.KeyCode?,
	UIModifier: GuiButton?,
	PointerIndex: number?,
	ResponseCurve: number?,
	ClampMagnitudeToOne: boolean?,
	DisplayName: string?,
	DisplayImage: Content?,
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
	SetVector3Scale: (self: InputBindingHandler, scale: Vector3) -> InputBindingHandler,
	SetType: (self: InputBindingHandler, bindingType: Enum.InputBindingType) -> InputBindingHandler,
	SetPrimaryModifier: (self: InputBindingHandler, keyCode: Enum.KeyCode) -> InputBindingHandler,
	SetSecondaryModifier: (self: InputBindingHandler, keyCode: Enum.KeyCode) -> InputBindingHandler,
	SetUIModifier: (self: InputBindingHandler, uiButton: GuiButton) -> InputBindingHandler,
	SetPointerIndex: (self: InputBindingHandler, index: number) -> InputBindingHandler,
	SetResponseCurve: (self: InputBindingHandler, exponent: number) -> InputBindingHandler,
	SetClampMagnitudeToOne: (self: InputBindingHandler, clamp: boolean) -> InputBindingHandler,
	SetDisplayName: (self: InputBindingHandler, displayName: string) -> InputBindingHandler,
	SetDisplayImage: (self: InputBindingHandler, image: Content) -> InputBindingHandler,

	-- Directional
	SetDirections: (
		self: InputBindingHandler,
		directions: {
			Forward: Enum.KeyCode?,
			Backward: Enum.KeyCode?,
			Up: Enum.KeyCode?,
			Down: Enum.KeyCode?,
			Left: Enum.KeyCode?,
			Right: Enum.KeyCode?,
		}
	) -> InputBindingHandler,
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

return nil
