local AccountController = {}

function AccountController:getModel()
	return PlayerManager:getModel("Account")
end

cc.exports.AccountController = AccountController