--!strict

export type BouncyRay = {
	Origin: Vector3,
	InitialDirection: Vector3,
	Bounces: number,
	Params: RaycastParams,
	
	_CurrentPosition: Vector3,
	_CurrentDirection: Vector3,
	_CurrentBounces: number,
	_Callbacks: {(HitPosition: Vector3) -> nil},
	
	_HasShot: boolean
}

local BouncyRay_helper = {}

function BouncyRay_helper.new(Origin: Vector3, InitialDirection: Vector3, Params: RaycastParams?, Bounces: number?): BouncyRay
	local Object = {
		Origin = Origin,
		InitialDirection = InitialDirection,
		Bounces = (Bounces or math.huge),
		Params = Params or RaycastParams.new(),
		
		_CurrentPosition = Origin,
		_CurrentDirection = InitialDirection,
		_CurrentBounces = 0,
		_HasShot = false
	} :: BouncyRay
	
	return Object
end

function BouncyRay_helper.Destroy(BouncyRay: BouncyRay)
	table.clear(BouncyRay._Callbacks)
	table.freeze(BouncyRay._Callbacks)
	table.clear(BouncyRay)
	table.freeze(BouncyRay)
end

function BouncyRay_helper.AssignBounceCallback(BouncyRay: BouncyRay, Callback: (HitPosition: Vector3) -> nil)
	BouncyRay._Callbacks[#BouncyRay._Callbacks + 1] = Callback
end

function BouncyRay_helper.Shoot(BouncyRay: BouncyRay)
	assert(not BouncyRay._HasShot, "This ray has already been shot")
	BouncyRay._HasShot = true
	
	local Results = workspace:Raycast(BouncyRay._CurrentPosition, BouncyRay._CurrentDirection, BouncyRay.Params)
	local HitPosition = if Results then Results.Position else BouncyRay._CurrentPosition + BouncyRay._CurrentDirection
	for _, Callback in BouncyRay._Callbacks do
		task.spawn(Callback, HitPosition)
	end
	
	if Results and BouncyRay._CurrentBounces < BouncyRay.Bounces then
		BouncyRay._CurrentBounces += 1
		local Normal = Results.Normal
		local ReflectedVector = (BouncyRay._CurrentDirection - (2 * BouncyRay._CurrentDirection:Dot(Normal) * Normal))
		
		BouncyRay._CurrentDirection = ReflectedVector
		BouncyRay._CurrentPosition = Results.Position
	else
		BouncyRay_helper.Destroy(BouncyRay)
	end
end

return BouncyRay_helper
