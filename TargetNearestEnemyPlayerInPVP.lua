local frame = CreateFrame("Frame")
local events = {}

local epicBattlegrounds = {} -- this is used as a 'Set' data structure. built when addon is loaded
local activeReboundedKey = nil
local isInCombat = false
local tryToTargetNearestEnemyAfterExistingCombat = false
local tryToTargetNearestEnemyPlayerAfterExistingCombat = false

local function log(string)

	if TTK_PrintActionsToChat then
	
		print(string)
	
	end

end


local OverrideZonePVP = false
--[[
local function KeyDown(self, key)

	if key == "O" then
		OverrideZonePVP = true
		log("\'O\' - simulating entering battleground")
		frame:GetScript("OnEvent")(f, "ZONE_CHANGED_NEW_AREA");
	end
	
	if key == "P" then
		OverrideZonePVP = false
		log("\'P\' - simulating leaving battleground")
		frame:GetScript("OnEvent")(f, "ZONE_CHANGED_NEW_AREA");
	end
	
   --frame:GetScript("OnEvent")(f, "CHAT_MSG_ADDON", allTheParamsRightHere);
end
frame:SetScript("OnKeyDown", KeyDown)
frame:SetPropagateKeyboardInput(true)
--]]

-- interface options
TTK_GlobalSettings = {}

TTK_GlobalSettings.OptMenu = CreateFrame("Frame", "TTK_options", UIParent)
TTK_GlobalSettings.OptMenu:Hide()
TTK_GlobalSettings.OptMenu.name = "Target Enemy Player"  

local options_title = TTK_GlobalSettings.OptMenu:CreateFontString("TTK_options_title", "OVERLAY", "GameFontNormalLarge")
options_title:SetPoint("TOPLEFT", "TTK_options", "TOPLEFT", 15, -15)
options_title:SetText("Target Nearest Enemy Player in PVP")

local addon_description = TTK_GlobalSettings.OptMenu:CreateFontString("TTK_addon_description", "OVERLAY", "GameFontNormal")
addon_description:SetPoint("TOPLEFT", "TTK_options", "TOPLEFT", 15, -25)
addon_description:SetPoint("TOPRIGHT", "TTK_options", "TOPRIGHT", -15, -25)
addon_description:SetText("When enabled, and the player enters a battleground or arena, this will change your keybinding for \"Target Nearest Enemy\" to instead be bound to \"Target Nearest Enemy Player\". After exiting the battleground or arena, the binding will revert back to \"Target Nearest Enemy\"")
addon_description:SetJustifyH("LEFT")
addon_description:SetHeight(85)

--toggle enabled for arena
local optionButton_enableForArena = CreateFrame("CheckButton", "TTK_optionButton_enableForArena", TTK_GlobalSettings.OptMenu, "InterfaceOptionsCheckButtonTemplate")
optionButton_enableForArena:SetPoint("TOPLEFT", "TTK_addon_description", "BOTTOMLEFT", 0, -10)

local optionTitle_enableForArena = TTK_GlobalSettings.OptMenu:CreateFontString("TTK_optionTitle_enableForArena", "OVERLAY", "GameFontNormal")
optionTitle_enableForArena:SetPoint("LEFT", "TTK_optionButton_enableForArena", "RIGHT", 5, 0)
optionTitle_enableForArena:SetText("Arena")

--toggle enabled for battlegrounds
local optionButton_enableForBattlegrounds = CreateFrame("CheckButton", "TTK_optionButton_enableForBattlegrounds", TTK_GlobalSettings.OptMenu, "InterfaceOptionsCheckButtonTemplate")
optionButton_enableForBattlegrounds:SetPoint("TOPLEFT", "TTK_optionButton_enableForArena", "BOTTOMLEFT", 0, -10)

local optionTitle_enableForBattlegrounds = TTK_GlobalSettings.OptMenu:CreateFontString("TTK_optionTitle_enableForBattlegrounds", "OVERLAY", "GameFontNormal")
optionTitle_enableForBattlegrounds:SetPoint("LEFT", "TTK_optionButton_enableForBattlegrounds", "RIGHT", 5, 0)
optionTitle_enableForBattlegrounds:SetText("Battlegrounds")

--toggle enabled for epic battlegrounds
local optionButton_enableForEpicBattlegrounds = CreateFrame("CheckButton", "TTK_optionButton_enableForEpicBattlegrounds", TTK_GlobalSettings.OptMenu, "InterfaceOptionsCheckButtonTemplate")
optionButton_enableForEpicBattlegrounds:SetPoint("TOPLEFT", "TTK_optionButton_enableForBattlegrounds", "BOTTOMLEFT", 0, -10)

local optionTitle_enableForEpicBattlegrounds = TTK_GlobalSettings.OptMenu:CreateFontString("TTK_optionTitle_enableForEpicBattlegrounds", "OVERLAY", "GameFontNormal")
optionTitle_enableForEpicBattlegrounds:SetPoint("LEFT", "TTK_optionButton_enableForEpicBattlegrounds", "RIGHT", 5, 0)
optionTitle_enableForEpicBattlegrounds:SetText("Epic Battlegrounds")

--toggle output to chat-
local optionButton_printActionsInChat = CreateFrame("CheckButton", "TTK_optionButton_printActionsInChat", TTK_GlobalSettings.OptMenu, "InterfaceOptionsCheckButtonTemplate")
optionButton_printActionsInChat:SetPoint("BOTTOMLEFT", "TTK_options", "BOTTOMLEFT", 15, 15)

local optionTitle_printActionsInChat = TTK_GlobalSettings.OptMenu:CreateFontString("TTK_optionTitle_printActionsInChat", "OVERLAY", "GameFontNormal")
optionTitle_printActionsInChat:SetPoint("LEFT", "TTK_optionButton_printActionsInChat", "RIGHT", 5, 0)
optionTitle_printActionsInChat:SetText("Display in chat when addon changes your keybinding")

-- interface events
--enable for arena
optionButton_enableForArena:SetScript("OnClick", function(self)
	
	local checked = self:GetChecked()
	TTK_EnabledForArena = checked
	
end)

--enable for battlegrounds
optionButton_enableForBattlegrounds:SetScript("OnClick", function(self)
	
	local checked = self:GetChecked()
	TTK_EnabledForBattlegrounds = checked
	
end)

--enable for epic battlegrounds
optionButton_enableForEpicBattlegrounds:SetScript("OnClick", function(self)
	
	local checked = self:GetChecked()
	TTK_EnabledForEpicBattlegrounds = checked
	
end)

--print in chat
optionButton_printActionsInChat:SetScript("OnClick", function(self)
	
	local checked = self:GetChecked()
	TTK_PrintActionsToChat = checked
	
end)

InterfaceOptions_AddCategory(TTK_GlobalSettings.OptMenu)

--build epic bg set
local function buildEpicBattlegroundSet()

	for i=1, GetNumBattlegroundTypes() do
	
		local name, _, _, _, _, _, _, teamSize = GetBattlegroundInfo(i)
		
		if teamSize and teamSize > 20 then
		
			epicBattlegrounds[name] = true
		
		end
	
	end

end

-- event handling
function events:ADDON_LOADED(name)
	
	if name == "TargetNearestEnemyPlayerInPVP" then
	
		if TTK_EnabledForArena == nil then
		
			TTK_EnabledForArena = true
		
		end
		
		if TTK_EnabledForBattlegrounds == nil then
		
			TTK_EnabledForBattlegrounds = true
		
		end
		
		if TTK_EnabledForEpicBattlegrounds == nil then
		
			TTK_EnabledForEpicBattlegrounds = true
		
		end
	
		buildEpicBattlegroundSet()
	
		optionButton_enableForArena:SetChecked(TTK_EnabledForArena)
		optionButton_enableForBattlegrounds:SetChecked(TTK_EnabledForBattlegrounds)
		optionButton_enableForEpicBattlegrounds:SetChecked(TTK_EnabledForEpicBattlegrounds)
		optionButton_printActionsInChat:SetChecked(TTK_PrintActionsToChat)
	
	end

end

-- actual work
local function setBindingToTargetNearestEnemyPlayer()
	
	local targetNearestEnemyBinding = GetBindingKey("TARGETNEARESTENEMY")
	
	if targetNearestEnemyBinding == nil then
	
		return
	
	end
	
	log("Target Nearest Enemy: attempting to set target-nearest-enemy-player to " .. targetNearestEnemyBinding)
	
	activeReboundedKey = targetNearestEnemyBinding
	local successfullyChangedBinding = SetBinding(targetNearestEnemyBinding, "TARGETNEARESTENEMYPLAYER")
	log("successfullyChangedBinding : " .. tostring(successfullyChangedBinding))
	
	if successfullyChangedBinding == false then
	
		if isInCombat then
		
			log("Target Nearest Enemy: in combat. cannot change bindings. will attempt again after exiting combat")
			tryToTargetNearestEnemyPlayerAfterExistingCombat = true
			return
		
		end
		
	end
	
	tryToTargetNearestEnemyPlayerAfterExistingCombat = false

end

local function setBindingToTargetNearestEnemy()
	
	log("Target Nearest Enemy: attempting to set target-nearest-enemy back to " .. tostring(activeReboundedKey))
	
	--first get any alternate key if it exists. we need to repopulate the bindings the same way (key1 and key2). otherwise, the next time we toggle, we would be toggling using the user's alternate key
	local targetNearestEnemyBinding = GetBindingKey("TARGETNEARESTENEMY")
	
	if targetNearestEnemyBinding == nil then
	
		print("No alternate keys found")
		
	else
	
		local successfullyClearedBindings = SetBinding(targetNearestEnemyBinding) -- when only given the key argument, it removes all bindings for that key
		
		if successfullyClearedBindings == false then
		
			if isInCombat then
			
				log("Target Nearest Enemy: in combat. cannot change bindings. will attempt again after exiting combat")
				tryToTargetNearestEnemyAfterExistingCombat = true
				return
				
			end
		
		else
		
			tryToTargetNearestEnemyAfterExistingCombat = false
		
		end
		
	end
	
	
	
	
	--key 1
	local successfullyChangedBinding1 = SetBinding(activeReboundedKey, "TARGETNEARESTENEMY")
	
	if  targetNearestEnemyBinding ~= nil then
	
		--key 2
		successfullyChangedBinding2 = SetBinding(targetNearestEnemyBinding, "TARGETNEARESTENEMY")
	
	end
	
	local successString = "successfully reverted"

	
	if successfullyChangedBinding1 and (successfullyChangedBinding2 or targetNearestEnemyBinding == nil) then
	
		log("successfully reverted bindings")
		tryToTargetNearestEnemyAfterExistingCombat = false
	
	else
	
		log("error: did not successfully revert bindings")
		log("binding 1: " .. tostring(successfullyChangedBinding1))
		log("binding 2: " .. tostring(successfullyChangedBinding2))
		
		if isInCombat then
			
			log("Target Nearest Enemy: in combat. cannot change bindings. will attempt again after exiting combat")
			tryToTargetNearestEnemyAfterExistingCombat = true
			return
				
		end
		
	
	end
	
	activeReboundedKey = nil

end

function events:ZONE_CHANGED_NEW_AREA()

	log("ZONE_CHANGED_NEW_AREA")

	local _, instanceType = IsInInstance()
	local inPVP = (instanceType == "pvp" or instanceType == "arena") or OverrideZonePVP
	
	if inPVP ~= true then
	
		tryToTargetNearestEnemyPlayerAfterExistingCombat = false
		
		if activeReboundedKey == nil then
		
			return
			
		end
		
		setBindingToTargetNearestEnemy()
		return
		
	end
	
	tryToTargetNearestEnemyAfterExistingCombat = false
	
	local inArena = instanceType == "arena"
	local zoneText = GetZoneText()
	local inEpicBattleground = (epicBattlegrounds[zoneText] ~= nil)
	local inBattleground = (not inArena and not inEpicBattleground)
	
	local shouldToggleForArena = inArena and TTK_EnabledForArena
	local shouldToggleForBattleground = inBattleground and TTK_EnabledForBattlegrounds
	local shouldToggleForEpicBattleground = inEpicBattleground and TTK_EnabledForEpicBattlegrounds
	local shouldToggle = shouldToggleForArena or shouldToggleForBattleground or shouldToggleForEpicBattleground
	
	if shouldToggle then
	
		if activeReboundedKey ~= nil then
	
			return
	
		end
		
		setBindingToTargetNearestEnemyPlayer()
		
	end
	
end

function events:PLAYER_REGEN_DISABLED()

	isInCombat = true

end

function events:PLAYER_REGEN_ENABLED()

	isInCombat = false
	
	if tryToTargetNearestEnemyAfterExistingCombat then
	
		setBindingToTargetNearestEnemy()
	
	elseif tryToTargetNearestEnemyPlayerAfterExistingCombat then
	
		setBindingToTargetNearestEnemyPlayer()
	
	end
	
end

-- listening to events
frame:SetScript("OnEvent", function(self, event, ...)
 events[event](self, ...);
end);

for k, v in pairs(events) do
 frame:RegisterEvent(k);
end