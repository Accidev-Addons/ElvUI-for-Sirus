-- Pools.lua - Adapted from WeakAuras-WotLK for ElvUI
-- Provides CreateFramePool, CreateTexturePool, CreateFontStringPool globals
-- No Private namespace dependency

local Mixin = function(obj, ...)
	for i = 1, select("#", ...) do
		local mixin = select(i, ...)
		for k, v in pairs(mixin) do obj[k] = v end
	end
	return obj
end

local CreateFromMixins = function(...) return Mixin({}, ...) end

--- @class ObjectPoolMixin
local ObjectPoolMixin = {}
function ObjectPoolMixin:OnLoad(creationFunc, resetterFunc)
	self.creationFunc = creationFunc
	self.resetterFunc = resetterFunc
	self.activeObjects = {}
	self.inactiveObjects = {}
	self.numActiveObjects = 0
end
function ObjectPoolMixin:Acquire()
	local numInactiveObjects = #self.inactiveObjects
	if numInactiveObjects > 0 then
		local obj = self.inactiveObjects[numInactiveObjects]
		self.activeObjects[obj] = true
		self.numActiveObjects = self.numActiveObjects + 1
		self.inactiveObjects[numInactiveObjects] = nil
		return obj, false
	end
	local newObj = self.creationFunc(self)
	if self.resetterFunc and not self.disallowResetIfNew then
		self.resetterFunc(self, newObj)
	end
	self.activeObjects[newObj] = true
	self.numActiveObjects = self.numActiveObjects + 1
	return newObj, true
end
function ObjectPoolMixin:Release(obj)
	if self:IsActive(obj) then
		self.inactiveObjects[#self.inactiveObjects + 1] = obj
		self.activeObjects[obj] = nil
		self.numActiveObjects = self.numActiveObjects - 1
		if self.resetterFunc then self.resetterFunc(self, obj) end
		return true
	end
	return false
end
function ObjectPoolMixin:ReleaseAll()
	for obj in pairs(self.activeObjects) do self:Release(obj) end
end
function ObjectPoolMixin:SetResetDisallowedIfNew(disallowed) self.disallowResetIfNew = disallowed end
function ObjectPoolMixin:EnumerateActive() return pairs(self.activeObjects) end
function ObjectPoolMixin:GetNextActive(current) return (next(self.activeObjects, current)) end
function ObjectPoolMixin:IsActive(object) return (self.activeObjects[object] ~= nil) end
function ObjectPoolMixin:GetNumActive() return self.numActiveObjects end
function ObjectPoolMixin:EnumerateInactive() return ipairs(self.inactiveObjects) end

--- @class FramePoolMixin : ObjectPoolMixin
local FramePoolMixin = CreateFromMixins(ObjectPoolMixin)
local function FramePoolFactory(framePool)
	return CreateFrame(framePool.frameType, nil, framePool.parent, framePool.frameTemplate)
end
function FramePoolMixin:OnLoad(frameType, parent, frameTemplate, resetterFunc)
	ObjectPoolMixin.OnLoad(self, FramePoolFactory, resetterFunc)
	self.frameType = frameType
	self.parent = parent
	self.frameTemplate = frameTemplate
end
function FramePoolMixin:GetTemplate() return self.frameTemplate end
local function FramePool_HideAndClearAnchors(_, frame) frame:Hide(); frame:ClearAllPoints() end
local function CreateFramePool(frameType, parent, frameTemplate, resetterFunc)
	local framePool = CreateFromMixins(FramePoolMixin)
	framePool:OnLoad(frameType, parent, frameTemplate, resetterFunc or FramePool_HideAndClearAnchors)
	return framePool
end

--- @class TexturePoolMixin : ObjectPoolMixin
local TexturePoolMixin = CreateFromMixins(ObjectPoolMixin)
local function TexturePoolFactory(texturePool)
	return texturePool.parent:CreateTexture(nil, texturePool.layer, texturePool.textureTemplate, texturePool.subLayer)
end
function TexturePoolMixin:OnLoad(parent, layer, subLayer, textureTemplate, resetterFunc)
	ObjectPoolMixin.OnLoad(self, TexturePoolFactory, resetterFunc)
	self.parent = parent
	self.layer = layer
	self.subLayer = subLayer
	self.textureTemplate = textureTemplate
end
local function _AdjustRegionPoolParameters(subLayer, regionTemplate, resetterFunc)
	if resetterFunc == nil then
		if type(regionTemplate) == "function" then
			resetterFunc = regionTemplate; regionTemplate = subLayer; subLayer = nil
		elseif regionTemplate == nil and type(subLayer) ~= "number" then
			regionTemplate = subLayer; subLayer = nil
		end
	end
	return subLayer, regionTemplate, resetterFunc
end
local function CreateTexturePool(parent, layer, subLayer, textureTemplate, resetterFunc)
	subLayer, textureTemplate, resetterFunc = _AdjustRegionPoolParameters(subLayer, textureTemplate, resetterFunc)
	local texturePool = CreateFromMixins(TexturePoolMixin)
	texturePool:OnLoad(parent, layer, subLayer, textureTemplate, resetterFunc or FramePool_HideAndClearAnchors)
	return texturePool
end

if not _G.CreateFramePool then
	_G.CreateFramePool = CreateFramePool
end

if not _G.CreateTexturePool then
	_G.CreateTexturePool = CreateTexturePool
end

-- luacheck: globals CreateFromMixins ObjectPoolMixin CreateTexturePool CreateFramePool CreateFontStringPool