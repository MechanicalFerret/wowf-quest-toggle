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

-- Quest IDs under one zone header, matched by log index or header title
local function CategoryQuestIDs(headerIndex, headerTitle)
	local ids = {}
	local start
	local num = C_QuestLog.GetNumQuestLogEntries()
	if headerIndex then
		local info = C_QuestLog.GetInfo(headerIndex)
		if info and info.isHeader then start = headerIndex end
	end
	if not start then
		for i = 1, num do
			local info = C_QuestLog.GetInfo(i)
			if info and info.isHeader and info.title == headerTitle then start = i break end
		end
	end
	if not start then return ids end
	for i = start + 1, num do
		local info = C_QuestLog.GetInfo(i)
		if not info or info.isHeader then break end
		if not info.isHidden and info.questID then ids[#ids + 1] = info.questID end
	end
	return ids
end

-- Any watched quest in the list turns them all off; none watched turns them all on
local function ToggleIDs(ids, label)
	local watched = false
	for _, id in ipairs(ids) do
		if C_QuestLog.GetQuestWatchType(id) ~= nil then watched = true break end
	end
	if watched then
		for _, id in ipairs(ids) do
			if C_QuestLog.GetQuestWatchType(id) ~= nil then
				C_QuestLog.RemoveQuestWatch(id)
			end
		end
		Print(label .. " untracked.")
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
			Print(label .. " tracked.")
		end
	end
end

function QuestToggle_Toggle()
	ToggleIDs(LoggedQuestIDs(), "all quests")
end

local function AttachHeaderButton(header)
	local b = header.QuestToggleT
	if not b then
		b = CreateFrame("Button", nil, header, "UIPanelButtonTemplate")
		b:SetSize(18, 18)
		b:SetText("T")
		b:SetPoint("RIGHT", header, "RIGHT", -28, 0)
		b:SetFrameLevel(header:GetFrameLevel() + 5)
		b:SetScript("OnClick", function(self)
			local h = self:GetParent()
			local title = h.ButtonText and h.ButtonText:GetText() or h.Text and h.Text:GetText()
			ToggleIDs(CategoryQuestIDs(h.questLogIndex, title), title or "category")
		end)
		b:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText("Quest Toggle")
			GameTooltip:AddLine("Track or untrack quests in this category.", 1, 1, 1)
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", GameTooltip_Hide)
		header.QuestToggleT = b
	end
	b:Show()
end

local function UpdateHeaderButtons()
	local scroll = QuestScrollFrame
	local pool = scroll and scroll.headerFramePool
	if not pool or not pool.EnumerateActive then return end
	for header in pool:EnumerateActive() do
		AttachHeaderButton(header)
	end
end

local function CreateButton(name, parent)
	local b = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
	b:SetSize(80, 22)
	b:SetText("Toggle All")
	b:SetFrameStrata("HIGH")
	b:SetFrameLevel(parent:GetFrameLevel() + 50)
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
	if QuestLogQuests_Update then hooksecurefunc("QuestLogQuests_Update", UpdateHeaderButtons) end
	local b = CreateButton("QuestToggleMapButton", frame)
	b:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 12)
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
