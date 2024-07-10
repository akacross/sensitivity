script_name("sensitivity")
script_author("akacross")
script_version("0.4.01")
script_url("https://akacross.net/")

local scriptName = thisScript().name
local scriptVersion = thisScript().version

-- Requirements
require"lib.moonloader"
local imgui = require 'mimgui'
local ffi = require 'ffi'
local mem = require 'memory'
local encoding = require 'encoding'
local fa = require 'fAwesome6'

-- Encoding
encoding.default = 'CP1251'
local u8 = encoding.UTF8

-- Paths
local workingDir = getWorkingDirectory()

local configDir = workingDir .. '\\config\\'
local cfgFile = configDir .. scriptName .. '.ini'

-- Libs
local ped, h = playerPed, playerHandle

local sens = {}
local sens_defaultSettings = {
	autosave = false,
	values = {
		0.002500,
		0.000845,
		0.000270
	}
}

local current_sensitivity = nil
local thirdperson_ids = {[5] = true, [53] = true, [55] = true, [65] = true}
local firstperson_ids = {[7] = true, [8] = true, [16] = true, [34] = true, [39] = true, [40] = true, [41] = true, [42] = true, [45] = true, [46] = true, [51] = true, [52] = true}

local new, str = imgui.new, ffi.string
local menu = new.bool(false)
local mainc = imgui.ImVec4(0.92, 0.27, 0.92, 1.0)

local function handleConfigFile(path, defaults, configVar, ignoreKeys)
	ignoreKeys = ignoreKeys or {}
    if doesFileExist(path) then
        local config, err = loadConfig(path)
        if not config then
            print("Error loading config: " .. err)

            local newpath = path:gsub("%.[^%.]+$", ".bak")
            local success, err2 = os.rename(path, newpath)
            if not success then
                print("Error renaming config: " .. err2)
                os.remove(path)
            end
            handleConfigFile(path, defaults, configVar)
        else
            local result = ensureDefaults(config, defaults, false, ignoreKeys)
            if result then
                local success, err3 = saveConfig(path, config)
                if not success then
                    print("Error saving config: " .. err3)
                end
            end
            return config
        end
    else
        local result = ensureDefaults(configVar, defaults, true)
        if result then
            local success, err = saveConfig(path, configVar)
            if not success then
                print("Error saving config: " .. err)
            end
        end
    end
    return configVar
end

function main()
	createDirectory(configDir)

	sens = handleConfigFile(cfgFile, sens_defaultSettings, sens)

	repeat wait(0) until isSampAvailable()
	sampRegisterChatCommand("sens", function() menu[0] = not menu[0] end)

	while true do wait(0)
		setMouseSensitivity(isPlayerAiming(true, true) and (getCurrentCharWeapon(ped) == 34 and sens.values[3] or sens.values[2]) or sens.values[1])
	end
end

function onScriptTerminate(scr, quitGame)
	if scr == script.this then
		if sens.autosave then
            local success, err = saveConfig(cfgFile, sens)
            if not success then
                print("Error saving config: " .. err)
            end
		end
	end
end

imgui.OnInitialize(function()
	apply_custom_style() -- apply custom style

	local config = imgui.ImFontConfig()
	config.MergeMode = true
    config.PixelSnapH = true
    config.GlyphMinAdvanceX = 14
    local builder = imgui.ImFontGlyphRangesBuilder()
    local list = {
		"GEAR",
		"FLOPPY_DISK",
		"UPLOAD",
		"ERASER",
		"GLOBE",
		"ERASER",
		"CROSSHAIRS"
	}
	for _, b in ipairs(list) do
		builder:AddText(fa(b))
	end
	defaultGlyphRanges1 = imgui.ImVector_ImWchar()
	builder:BuildRanges(defaultGlyphRanges1)
	imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(fa.get_font_data_base85("regular"), 14, config, defaultGlyphRanges1[0].Data)

	imgui.GetIO().IniFilename = nil
end)

imgui.OnFrame(function() return menu[0] end,
function()
	local width, height = getScreenResolution()
	local title = string.format("%s %s Settings - Version: %s", fa.GEAR, firstToUpper(scriptName), scriptVersion)
	imgui.SetNextWindowPos(imgui.ImVec2(width / 2, height / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	imgui.Begin(title, menu, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
		if imgui.Button(fa.FLOPPY_DISK.. ' Save') then
            local success, err = saveConfig(cfgFile, sens)
            if not success then
                print("Error saving config: " .. err)
            end
		end 
		imgui.SameLine()
		if imgui.Button(fa.UPLOAD.. ' Load') then
			sens = handleConfigFile(cfgFile, sens_defaultSettings, sens)
		end 
		imgui.SameLine()
		if imgui.Button(fa.ERASER .. ' Reset') then
			ensureDefaults(sens, sens_defaultSettings, true)
		end 
		imgui.SameLine()
		if imgui.Checkbox('Autosave', new.bool(sens.autosave)) then
			sens.autosave = not sens.autosave
		end

		local global_sense = new.float(sens.values[1])
		imgui.PushItemWidth(170)
		if imgui.InputFloat(fa.GLOBE .. ' Global', global_sense, 0.00001, 1.000, "%.6f") then
			sens.values[1] = global_sense[0]
		end 

		local aiming_sense = new.float(sens.values[2])
		if imgui.InputFloat(fa.CROSSHAIRS .. ' Aiming', aiming_sense, 0.00001, 1.000, "%.6f") then
			sens.values[2] = aiming_sense[0]
		end 

		local sniper_sense = new.float(sens.values[3])
		if imgui.InputFloat(fa.CROSSHAIRS .. ' Sniper', sniper_sense, 0.00001, 1.000, "%.6f") then
			sens.values[3] = sniper_sense[0]
		end 
		imgui.PopItemWidth()

		if imgui.Button(fa.UPLOAD .. ' Transfer from sensfix.asi') then
			import_sensfix_asi()
		end
	imgui.End()
end)

function setMouseSensitivity(value)
    local new_sensitivity = value / 4
    if current_sensitivity ~= new_sensitivity then
        for _, addr in ipairs({0xB6EC1C, 0xB6EC18}) do
            mem.setfloat(addr, new_sensitivity, false)
        end
        current_sensitivity = new_sensitivity
    end
end

function isPlayerAiming(thirdperson, firstperson)
    local id = mem.read(11989416, 2, false)
    if thirdperson and thirdperson_ids[id] then return true end
    if firstperson and firstperson_ids[id] then return true end
    return false
end

function import_sensfix_asi()
    if getModuleHandle("sensfix.asi") ~= 0 or getModuleHandle("sensfix") ~= 0 then formattedAddChatMessage("Error: Cannot copy configuration from 'sensfix.asi' while it is actively running!", -1) return end

    local table, res = lines_from("sensfix.ini")
    if not res then formattedAddChatMessage("Error: 'sensfix.ini' not found. Please ensure it is located in the root directory.", -1) return end
    if table[1]:match("%s*%[sensfix%]") then
        for k, v in pairs(table) do
            if v:find("^%s*global=") then
                local value = v:gsub("%s*global=", "")
                sens.values[1] = tonumber(value)
                if not sens.values[1] then
                    formattedAddChatMessage("Error: While converting global value to number: " .. value, -1)
                end
            elseif v:find("^%s*aiming=") then
                local value = v:gsub("%s*aiming=", "")
                sens.values[2] = tonumber(value)
                if not sens.values[2] then
					formattedAddChatMessage("Error: While converting aiming value to number: " .. value, -1)
                end
            elseif v:find("^%s*aiming_sniper=") then
                local value = v:gsub("%s*aiming_sniper=", "")
                sens.values[3] = tonumber(value)
                if not sens.values[3] then
                    formattedAddChatMessage("Error: While converting aiming_sniper value to number: " .. value, -1)
                end
            end
        end
        formattedAddChatMessage("Transfer completed successfully!", -1)
    else
        formattedAddChatMessage("Error: Invalid 'sensfix.asi' configuration detected!", -1)
    end
end

function lines_from(file)
    if not doesFileExist(file) then return {}, false end
    local lines = {}
    for line in io.lines(file) do
        table.insert(lines, line)
    end
    return lines, true
end

function formattedAddChatMessage(string, color)
    sampAddChatMessage(string.format("{ABB2B9}[%s]{FFFFFF} %s", firstToUpper(scriptName), string), color)
end

function firstToUpper(string)
    return (string:gsub("^%l", string.upper))
end

function loadConfig(filePath)
    local file = io.open(filePath, "r")
    if not file then
        return nil, "Could not open file."
    end

    local content = file:read("*a")
    file:close()

    if not content or content == "" then
        return nil, "Config file is empty."
    end

    local success, decoded = pcall(decodeJson, content)
    if success then
        if next(decoded) == nil then
            return nil, "JSON format is empty."
        else
            return decoded, nil
        end
    else
        return nil, "Failed to decode JSON: " .. decoded
    end
end

function saveConfig(filePath, config)
    local file = io.open(filePath, "w")
    if not file then
        return false, "Could not save file."
    end
    file:write(encodeJson(config, true))
    file:close()
    return true
end

function ensureDefaults(config, defaults, reset, ignoreKeys)
    ignoreKeys = ignoreKeys or {}
    local status = false

    local function isIgnored(key)
        for _, ignoreKey in ipairs(ignoreKeys) do
            if key == ignoreKey then
                return true
            end
        end
        return false
    end

    local function cleanupConfig(conf, def)
        local localStatus = false
        for k, v in pairs(conf) do
            if isIgnored(k) then
                return
            elseif def[k] == nil then
                conf[k] = nil
                localStatus = true
            elseif type(conf[k]) == "table" and type(def[k]) == "table" then
                localStatus = cleanupConfig(conf[k], def[k]) or localStatus
            end
        end
        return localStatus
    end

    local function applyDefaults(conf, def)
        local localStatus = false
        for k, v in pairs(def) do
            if isIgnored(k) then
                return
            elseif conf[k] == nil or reset then
                if type(v) == "table" then
                    conf[k] = {}
                    localStatus = applyDefaults(conf[k], v) or localStatus
                else
                    conf[k] = v
                    localStatus = true
                end
            elseif type(v) == "table" and type(conf[k]) == "table" then
                localStatus = applyDefaults(conf[k], v) or localStatus
            end
        end
        return localStatus
    end

    status = applyDefaults(config, defaults)
    status = cleanupConfig(config, defaults) or status
    return status
end

function apply_custom_style()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4
	style.WindowRounding = 1.5
	style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
	style.FrameRounding = 1.0
	style.ItemSpacing = imgui.ImVec2(4.0, 4.0)
	style.ScrollbarSize = 13.0
	style.ScrollbarRounding = 0
	style.GrabMinSize = 8.0
	style.GrabRounding = 1.0
	style.WindowBorderSize = 0.0
	style.WindowPadding = imgui.ImVec2(4.0, 4.0)
	style.FramePadding = imgui.ImVec2(2.5, 3.5)
	style.ButtonTextAlign = imgui.ImVec2(0.5, 0.35)

	colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.TextDisabled]           = ImVec4(0.7, 0.7, 0.7, 1.0)
	colors[clr.WindowBg]               = ImVec4(0.07, 0.07, 0.07, 1.0)
	colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
	colors[clr.Border]                 = ImVec4(mainc.x, mainc.y, mainc.z, 0.4)
	colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.FrameBg]                = ImVec4(mainc.x, mainc.y, mainc.z, 0.7)
	colors[clr.FrameBgHovered]         = ImVec4(mainc.x, mainc.y, mainc.z, 0.4)
	colors[clr.FrameBgActive]          = ImVec4(mainc.x, mainc.y, mainc.z, 0.9)
	colors[clr.TitleBg]                = ImVec4(mainc.x, mainc.y, mainc.z, 1.0)
	colors[clr.TitleBgActive]          = ImVec4(mainc.x, mainc.y, mainc.z, 1.0)
	colors[clr.TitleBgCollapsed]       = ImVec4(mainc.x, mainc.y, mainc.z, 0.79)
	colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
	colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
	colors[clr.ScrollbarGrab]          = ImVec4(mainc.x, mainc.y, mainc.z, 0.8)
	colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
	colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
	colors[clr.CheckMark]              = ImVec4(mainc.x + 0.13, mainc.y + 0.13, mainc.z + 0.13, 1.00)
	colors[clr.SliderGrab]             = ImVec4(0.28, 0.28, 0.28, 1.00)
	colors[clr.SliderGrabActive]       = ImVec4(0.35, 0.35, 0.35, 1.00)
	colors[clr.Button]                 = ImVec4(mainc.x, mainc.y, mainc.z, 0.8)
	colors[clr.ButtonHovered]          = ImVec4(mainc.x, mainc.y, mainc.z, 0.63)
	colors[clr.ButtonActive]           = ImVec4(mainc.x, mainc.y, mainc.z, 1.0)
	colors[clr.Header]                 = ImVec4(mainc.x, mainc.y, mainc.z, 0.6)
	colors[clr.HeaderHovered]          = ImVec4(mainc.x, mainc.y, mainc.z, 0.43)
	colors[clr.HeaderActive]           = ImVec4(mainc.x, mainc.y, mainc.z, 0.8)
	colors[clr.Separator]              = colors[clr.Border]
	colors[clr.SeparatorHovered]       = ImVec4(0.26, 0.59, 0.98, 0.78)
	colors[clr.SeparatorActive]        = ImVec4(0.26, 0.59, 0.98, 1.00)
	colors[clr.ResizeGrip]             = ImVec4(mainc.x, mainc.y, mainc.z, 0.8)
	colors[clr.ResizeGripHovered]      = ImVec4(mainc.x, mainc.y, mainc.z, 0.63)
	colors[clr.ResizeGripActive]       = ImVec4(mainc.x, mainc.y, mainc.z, 1.0)
	colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
	colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
	colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
	colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
	colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.35)
end
