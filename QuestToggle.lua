local ADDON = ...

local MAX_WATCHES = (Constants and Constants.QuestWatchConsts and Constants.QuestWatchConsts.MAX_QUEST_WATCHES) or 25
local buttons = {}

local function Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Quest Toggle:|r " .. msg)
end

-- Every real quest in the log (no zone headers, no hidden entries)
local function LoggedQuestIDs()
	local ids = {}
	for i = 1, C_QuestLog.GetNumQuestLogEntries() do
		local info = C_QuestLog.GetInfo(i)
		if info and not info.isHeader and not info.isHidden and info.questID then
			ids[#ids + 1] = info.questID
		end
	end
	return ids
end

-- Any watched quest turns everything off; none watched turns everything on
function QuestToggle_Toggle()
	local ids = LoggedQuestIDs()
	if C_QuestLog.GetNumQuestWatches() > 0 then
		for _, id in ipairs(ids) do
			if C_QuestLog.GetQuestWatchType(id) ~= nil then
				C_QuestLog.RemoveQuestWatch(id)
			end
		end
		Print("all quests untracked.")
	else
		local added = 0
		for _, id in ipairs(ids) do
			if C_QuestLog.GetNumQuestWatches() >= MAX_WATCHES then break end
			C_QuestLog.AddQuestWatch(id)
			added = added + 1
		end
		if added < #ids then
			Print(("tracking %d of %d quests (limit %d)."):format(added, #ids, MAX_WATCHES))
		else
			Print("all quests tracked.")
		end
	end
end

local function CreateButton(name, parent)
	local b = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
	b:SetSize(70, 20)
	b:SetText("Toggle")
	b:SetFrameLevel(parent:GetFrameLevel() + 5)
	b:SetScript("OnClick", QuestToggle_Toggle)
	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:SetText("Quest Toggle")
		GameTooltip:AddLine("Track or untrack all quests.", 1, 1, 1)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", GameTooltip_Hide)
	buttons[#buttons + 1] = b
	return b
end

local function AttachMap()
	if QuestToggleMapButton then return end
	local frame = QuestMapFrame
	if not frame then return end
	local b = CreateButton("QuestToggleMapButton", frame)
	b:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -26, -30)
end

local function TryAttach()
	AttachMap()
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", TryAttach)

SLASH_QUESTTOGGLE1 = "/questtoggle"
SLASH_QUESTTOGGLE2 = "/qt"
SlashCmdList["QUESTTOGGLE"] = QuestToggle_Toggle
