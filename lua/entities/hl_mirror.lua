AddCSLuaFile()

ENT.Category = "HeavyLight"
ENT.Spawnable = true
ENT.PrintName = "Mirror"

ENT.Base = "base_anim"
DEFINE_BASECLASS(ENT.Base)
ENT.RenderGroup = RENDERGROUP_OPAQUE

function ENT:Initialize()
	self:SetModel("models/hunter/plates/plate2x2.mdl")

	if SERVER then self:PhysicsInit(SOLID_VPHYSICS) end
end

-- function ENT:GetRT()
-- 	return GetRenderTarget("hl_camera_" .. ScrW() .. "_" .. ScrH() .. "_" .. self:EntIndex(), ScrW(), ScrH(), false)
-- end

function ENT:DrawMonitors(...)
	-- find out if we should even render
	local w, h = ScrW(), ScrH()

	local tl, br = self:GetRenderBounds()
	local tr = Vector(0, tl.y, br.z)
	local bl = Vector(0, br.y, tl.z)

	tl.x = 0
	br.x = 0

	tl = self:LocalToWorld(tl):ToScreen()
	br = self:LocalToWorld(br):ToScreen()
	tr = self:LocalToWorld(tr):ToScreen()
	bl = self:LocalToWorld(bl):ToScreen()

	if not tl.visible and not tr.visible and not bl.visible and not br.visible -- all 4 corners are behind the player, no chance this gets drawn
	then return	end

	if (tl.x < 0 and tr.x < 0 and bl.x < 0 and br.x < 0) -- all left of the screen
	or (tl.y < 0 and tr.y < 0 and bl.y < 0 and br.y < 0) -- all above the screen
	or (tl.x > w and tr.x > w and bl.x > w and br.x > w) -- all right of the screen
	or (tl.y > h and tr.y > h and bl.y > h and br.y > h) -- all below the screen
	then return end
end

if CLIENT then
	function ENT:Draw(studioflags)
		if studioflags ~= STUDIO_RENDER	-- if there's anything other than a STUDIO_RENDER flag in the flags, then this probably isn't being rendered for display.
		or halo.RenderedEntity() == self	-- this is only being rendered for a stencil
		or render.GetRenderViewDepth() >= cvars.Number("hl_mirrordepth", 1)	-- we've hit the maximum iterations allowed for mirrors to reflect
		then
			-- don't render mirrors, just make a plain render
			self:DrawModel()
			return
		end

		-- in other cases, actually render the mirror!
		-- find out if we should even render
		local w, h = ScrW(), ScrH()

		local tl, br = self:GetRenderBounds()
		local tr = Vector(0, tl.y, br.z)
		local bl = Vector(0, br.y, tl.z)

		tl.x = 0
		br.x = 0

		tl = self:LocalToWorld(tl):ToScreen()
		br = self:LocalToWorld(br):ToScreen()
		tr = self:LocalToWorld(tr):ToScreen()
		bl = self:LocalToWorld(bl):ToScreen()

		if not tl.visible and not tr.visible and not bl.visible and not br.visible -- all 4 corners are behind the player, no chance this gets drawn
		then return	end

		if (tl.x < 0 and tr.x < 0 and bl.x < 0 and br.x < 0) -- all left of the screen
		or (tl.y < 0 and tr.y < 0 and bl.y < 0 and br.y < 0) -- all above the screen
		or (tl.x > w and tr.x > w and bl.x > w and br.x > w) -- all right of the screen
		or (tl.y > h and tr.y > h and bl.y > h and br.y > h) -- all below the screen
		then return end

		local x, y
		x = math.min(tl.x, tr.x, bl.x, br.x)
		y = math.min(tl.y, tr.y, bl.y, br.y)
		w = math.max(tl.x, tr.x, bl.x, br.x) - x
		h = math.max(tl.y, tr.y, bl.y, br.y) - y

		local oldstencilenabled = render.GetStencilEnable()
		local oldstenciltestmask = render.GetStencilTestMask()
		local oldstencilwritemask = render.GetStencilWriteMask()
		local oldstencilpassop = render.GetStencilPassOperation()
		local oldstencilfailop = render.GetStencilFailOperation()
		local oldstencilzfailop = render.GetStencilZFailOperation()
		local oldstencilcomparefunc = render.GetStencilCompareFunction()
		render.SetStencilEnable(true)
		self:DrawModel()
		render.SetStencilEnable(oldstencilenabled)
	end

	-- Render library detours
	-- I need to get information from the render library that isn't available by default

	-- GetStencilEnable
	local render_SetStencilEnable = render.SetStencilEnable
	local stencilon = false
	function render.SetStencilEnable(...)
		render_SetStencilEnable(...)
		stencilon = ...
	end
	function render.GetStencilEnable()
		return stencilon
	end

	-- GetRenderViewDepth - how deep is our iteration of RenderView
	local render_RenderView = render.RenderView
	local viewdepth = 0
	function render.RenderView(...)
		viewdepth = viewdepth + 1
		render_RenderView(...)
		viewdepth = viewdepth - 1
	end
	function render.GetRenderViewDepth()
		return viewdepth
	end

	-- GetStencilReferenceValue
	local render_SetStencilReferenceValue = render.SetStencilReferenceValue
	local stencilrefval = 0
	function render.SetStencilReferenceValue(...)
		render_SetStencilReferenceValue(...)
		stencilrefval = ...
	end
	function render.GetStencilReferenceValue()
		return stencilrefval
	end

	-- GetStencilCompareFunction
	local render_SetStencilCompareFunction = render.SetStencilCompareFunction
	local stencilcompfunc = 0
	function render.SetStencilCompareFunction(...)
		render_SetStencilCompareFunction(...)
		stencilcompfunc = ...
	end
	function render.GetStencilCompareFunction()
		return stencilcompfunc
	end

	-- GetStencilPassOperation
	local render_SetStencilPassOperation = render.SetStencilPassOperation
	local stencilpassop = 0
	function render.SetStencilPassOperation(...)
		render_SetStencilPassOperation(...)
		stencilpassop = ...
	end
	function render.GetStencilPassOperation()
		return stencilpassop
	end

	-- GetStencilFailOperation
	local render_SetStencilFailOperation = render.SetStencilFailOperation
	local stencilfailop = 0
	function render.SetStencilFailOperation(...)
		render_SetStencilFailOperation(...)
		stencilfailop = ...
	end
	function render.GetStencilFailOperation()
		return stencilfailop
	end

	-- GetStencilZFailOperation
	local render_SetStencilZFailOperation = render.SetStencilZFailOperation
	local stencilzfailop = 0
	function render.SetStencilZFailOperation(...)
		render_SetStencilZFailOperation(...)
		stencilzfailop = ...
	end
	function render.GetStencilZFailOperation()
		return stencilzfailop
	end

	-- GetStencilTestMask
	local render_SetStencilTestMask = render.SetStencilTestMask
	local stenciltestmask = 0
	function render.SetStencilTestMask(...)
		render_SetStencilTestMask(...)
		stenciltestmask = ...
	end
	function render.GetStencilTestMask()
		return stenciltestmask
	end

	-- GetStencilWriteMask
	local render_SetStencilWriteMask = render.SetStencilWriteMask
	local stencilwritemask = 0
	function render.SetStencilWriteMask(...)
		render_SetStencilWriteMask(...)
		stencilwritemask = ...
	end
	function render.GetStencilWriteMask()
		return stencilwritemask
	end
end
