local AccountModel = class("AccountModel", BaseModel)

function AccountModel:ctor()
	self:reset()
end

function AccountModel:reset()
	self._data = {}
end

function AccountModel:setAccountInfo(netData)
	for k,v in pairs(netData) do
		self._data[k] = v
	end
end

function AccountModel:getId()
	return tonumber(self._data["uid"]) or 0
end

function AccountModel:getUnionid()
	return self._data["account"]
end

return AccountModel