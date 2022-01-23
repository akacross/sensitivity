script_name("sensitivity")
script_author("akacross", "Montri")
script_version("0.3.5.1")
script_url("https://akacross.net/")

if getMoonloaderVersion() >= 27 then
	require 'libstd.deps' {
	   'fyp:mimgui',
	   'fyp:fa-icons-4',
	   --'donhomka:mimgui-addons',
	   'donhomka:extensions-lite'
	}
end

require"lib.moonloader"
require"lib.sampfuncs"
require "extensions-lite"

local imgui, ffi = require 'mimgui', require 'ffi'
local new, str = imgui.new, ffi.string
local vk = require 'vkeys'
local sampev = require 'lib.samp.events'
local mem = require 'memory'
local ped, h = playerPed, playerHandle
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8
--local mimgui_addons = require 'mimgui_addons'
local faicons = require 'fa-icons'
local ti = require 'tabler_icons'

local function loadIconicFont(fontSize)
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
    local iconRanges = imgui.new.ImWchar[3](ti.min_range, ti.max_range, 0)
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(ti.get_font_data_base85(), fontSize, config, iconRanges)
end

local blank = {}
local sens = {
	autosave = false,
	values = {0.2345, 0.163, 0.165}
}

local main_window_state = new.bool(false)
local mainc = imgui.ImVec4(0.92, 0.27, 0.92, 1.0)

path = getWorkingDirectory() .. '\\config\\' 
cfg = path .. 'sensitivity.ini'

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

function main()
	blank = table.deepcopy(sens)
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	if not doesDirectoryExist(path) then createDirectory(path) end
	if doesFileExist(cfg) then loadIni() else blankIni() end
	while not isSampAvailable() do wait(100) end
	sampRegisterChatCommand("sens", function() main_window_state[0] = not main_window_state[0] end)
	sampfuncsLog("[Sensitivity] /sens")
	while true do wait(0)
		if isPlayerAiming(true, true) then 
			if getCurrentCharWeapon(ped) == 34 then 
				setsens(sens.values[3]) 
			else 
				setsens(sens.values[2]) 
			end 
		else 
			setsens(sens.values[1])
		end
		--imgui.Process = main_window_state.v
	end
end

-- imgui.OnInitialize() called only once, before the first render
imgui.OnInitialize(function()
	apply_custom_style() -- apply custom style
	local defGlyph = imgui.GetIO().Fonts.ConfigData.Data[0].GlyphRanges
	imgui.GetIO().Fonts:Clear() -- clear the fonts
	local font_config = imgui.ImFontConfig() -- each font has its own config
	font_config.SizePixels = 14.0;
	font_config.GlyphExtraSpacing.x = 0.1
	-- main font
	local def = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\arialbd.ttf', font_config.SizePixels, font_config, defGlyph)
   
	local config = imgui.ImFontConfig()
	config.MergeMode = true
	config.PixelSnapH = true
	config.FontDataOwnedByAtlas = false
	config.GlyphOffset.y = 1.0 -- offset 1 pixel from down
	local fa_glyph_ranges = new.ImWchar[3]({ faicons.min_range, faicons.max_range, 0 })
	-- icons
	local faicon = imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85(), font_config.SizePixels, config, fa_glyph_ranges)

	loadIconicFont(14)

	imgui.GetIO().ConfigWindowsMoveFromTitleBarOnly = true
	imgui.GetIO().IniFilename = nil
end)

imgui.OnFrame(function() return main_window_state[0] end,
function()
	local width, height = getScreenResolution()
	imgui.SetNextWindowPos(imgui.ImVec2(width / 2, height / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	imgui.Begin(ti.ICON_SETTINGS .. 'Sensitivity', main_window_state, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)	
		
		if imgui.Button(ti.ICON_DEVICE_FLOPPY.. 'Save') then
			saveIni()
		end 
		imgui.SameLine()
		if imgui.Button(ti.ICON_FILE_UPLOAD.. 'Load') then
			loadIni()
		end 
		imgui.SameLine()
		if imgui.Button(ti.ICON_ERASER .. 'Reset') then
			blankIni()
		end 
		imgui.SameLine()
		if imgui.Checkbox('Autosave', new.bool(sens.autosave)) then 
			sens.autosave = not sens.autosave 
			saveIni() 
		end  
			
		local global_sense = new.float(sens.values[1])
		imgui.PushItemWidth(170)
		if imgui.InputFloat(faicons.ICON_GLOBE .. ' Global Sense', global_sense, 0.001, 1.000, "%.6f") then
			sens.values[1] = global_sense[0]
		end 
		local aiming_sense = new.float(sens.values[2])
		if imgui.InputFloat(faicons.ICON_CROSSHAIRS .. ' Aiming Sense', aiming_sense, 0.001, 1.000, "%.6f") then
			sens.values[2] = aiming_sense[0]
		end 
		local sniper_sense = new.float(sens.values[3])
		if imgui.InputFloat(faicons.ICON_CROSSHAIRS .. ' Sniper Sense', sniper_sense, 0.001, 1.000, "%.6f") then
			sens.values[3] = sniper_sense[0]
		end 
		imgui.PopItemWidth()
		if imgui.Button(ti.ICON_UPLOAD .. "Transfer from sensfix.asi") then 
			if getModuleHandle("sensfix.asi") ~= 0 or getModuleHandle("sensfix") ~= 0 then
				sampAddChatMessage("{05D353}[Sensfix] {FFFFFF} Cannot copy config from sensfix.asi while its actively running!")
			else
				local table = lines_from("sensfix.ini")
				for k,v in pairs(table) do
					print('line[' .. k .. ']', v)
				end
				if table[1] == " [sensfix]" and string.find(table[2], " aiming_sniper=") and string.find(table[3], " aiming=") and string.find(table[4], " global=") then
					print("this is a legit file.")
					aiming_sniper = string.gsub(table[2], " aiming_sniper=", "")
					aiming_normal = string.gsub(table[3], " aiming=", "")
					aiming_global = string.gsub(table[4], " global=", "")
					
					print(aiming_sniper .. " | " .. aiming_normal .. " | " .. aiming_global)

					sens.values[1] = aiming_global*3.2
					sens.values[2] = aiming_normal*3.2
					sens.values[3] = aiming_sniper*3.2
						
					sampAddChatMessage("{05D353}[Sensfix] {FFFFFF} Transfer successful!")
					position_x = 0 
					position_y = 0 
					position_z = 0 
					sound = 1057 
					addOneOffSound(position_x,position_y,position_z,sound)
				else
					sampAddChatMessage("{05D353}[Sensfix] {FFFFFF} This is not a valid sensfix.asi Config!")
				end 
			end 
		end 
	imgui.End()
end)



function onScriptTerminate(scr, quitGame) 
	if scr == script.this then 
		if sens.autosave then 
			saveIni() 
		end 
	end
end

function setsens(value)
	mem.setfloat(0xB6EC1C, value / 1000, false)
	mem.setfloat(0xB6EC18, value / 1000, false)
end

function isPlayerAiming(thirdperson, firstperson)
	local id = mem.read(11989416, 2, false)
	if thirdperson and (id == 5 or id == 53 or id == 55 or id == 65) then return true end
	if firstperson and (id == 7 or id == 8 or id == 16 or id == 34 or id == 39 or id == 40 or id == 41 or id == 42 or id == 45 or id == 46 or id == 51 or id == 52) then return true end
end

function blankIni() 
	sens = table.deepcopy(blank)
	saveIni()
	loadIni()
end

function loadIni() 
	local f = io.open(cfg, "r") if f then sens = decodeJson(f:read("*all")) f:close() end
end

function saveIni()
	if type(sens) == "table" then local f = io.open(cfg, "w") f:close() if f then f = io.open(cfg, "r+") f:write(encodeJson(sens)) f:close() end end
end

function lines_from(file)
    if not file_exists(file) then return {} end
    lines = {}
    for line in io.lines(file) do 
      lines[#lines + 1] = line
    end
    return lines
end

function file_exists(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end