local PlayerManager = class("PlayerManager")

function PlayerManager:ctor()
	self._modelDic = {}
	self:initModels()
end

function PlayerManager:initModels()
	for modelName, cnf in pairs(ModelDefine) do
		self._modelDic[modelName] = require(cnf.url).new()
	end
end

function PlayerManager:reset()
	-- for modelName, model in pairs(self._modelDic) do
	-- 	if modelName ~= "BullFight" and modelName ~= "PlayBack" then
	-- 		model:reset()
	-- 	end
	-- end
end

function PlayerManager:dailyReset()
	for __, model in pairs(self._modelDic) do
		model:dailyReset()
	end
end

function PlayerManager:getModel(modelName)
	assert(self._modelDic[modelName], "not exist this model")
	return self._modelDic[modelName]
end

cc.exports.PlayerManager = PlayerManager.new()