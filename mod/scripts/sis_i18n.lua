local G = GLOBAL
local translations = modinfo.sis_i18n
local selected = SIS_CONFIG.language

local function resolve(choice)
    if choice == "zh" or choice == "en" then return choice end
    local code = G.LOC and G.LOC.GetLocaleCode and G.LOC.GetLocaleCode()
    if not code and G.LanguageTranslator then code = G.LanguageTranslator.defaultlang end
    code = string.lower(code or "en")
    return string.sub(code,1,2) == "zh" and "zh" or "en"
end

SIS_Text = function(key)
    local messages = translations[resolve(selected)].messages
    return messages[key] or translations.en.messages[key] or key
end

local function apply(info, settings)
    if not info or not info.sis_i18n then return end
    for _, option in ipairs(settings or info.configuration_options or {}) do
        if option.name == "language" and option.saved ~= nil then
            selected = option.saved
            break
        end
    end
    SIS_CONFIG.language = selected
    local text = info.sis_i18n[resolve(selected)]
    info.name, info.description = text.name, text.description
    for _, option in ipairs(info.configuration_options or {}) do
        -- The save callback pops the configuration screen before vanilla
        -- reloads the settings file. Keep GetModInfo from restoring the old
        -- language while the Mods screen is becoming active again.
        if option.name == "language" then option.saved = selected end
        local entry = text.config[option.name]
        if entry then
            option.label, option.hover = entry.label, entry.hover
            for i, value in ipairs(option.options or {}) do value.description = entry.options[i] end
        end
    end
end
apply(modinfo)

-- Frontend metadata loads before saved settings. UpdateConfigurationOptions
-- also covers asynchronous persistent-string loads. Only our mod is localized.
local index = G.KnownModIndex
if index then
    local get, load, update, save = index.GetModInfo, index.LoadModConfigurationOptions,
        index.UpdateConfigurationOptions, index.SaveConfigurationOptions
    index.GetModInfo = function(self, name, ...)
        local info = get(self, name, ...)
        if name == modname then apply(info) end
        return info
    end
    index.LoadModConfigurationOptions = function(self, name, ...)
        local settings = load(self, name, ...)
        if name == modname then apply(get(self, name), settings) end
        return settings
    end
    index.UpdateConfigurationOptions = function(self, settings, saved, ...)
        local result = update(self, settings, saved, ...)
        local info = get(self, modname)
        if info and settings == info.configuration_options then apply(info, settings) end
        return result
    end
    index.SaveConfigurationOptions = function(self, callback, name, settings, ...)
        if name ~= modname then return save(self, callback, name, settings, ...) end
        return save(self, function(...)
            apply(get(self, name), settings)
            return callback(...)
        end, name, settings, ...)
    end
end

-- Vanilla single-player DS ignores hover fields. Keep help below both option
-- columns so adding options never hides a spinner. Other mods are unchanged.
AddClassPostConstruct("screens/modconfigurationscreen", function(screen)
    if screen.modname ~= modname then return end
    local Text = G.require("widgets/text")
    local help = screen.root:AddChild(Text(G.DEFAULTFONT, 17, ""))
    help:SetPosition(0, -248, 0)
    help:SetRegionSize(880, 48)
    help:SetHAlign(G.ANCHOR_MIDDLE)
    help:EnableWordWrap(true)
    local refresh = screen.RefreshOptions
    local function bind(self)
        local info = index and index:GetModInfo(modname) or modinfo
        local settings = info.configuration_options
        local offset = self.option_offset or 0
        for column, spinners in ipairs({self.left_spinners or {}, self.right_spinners or {}}) do
            for i, spinner in ipairs(spinners) do
                local option = settings[offset+(column-1)*7+i]
                if option then
                    local gain = spinner.OnGainFocus
                    spinner.OnGainFocus = function(widget, ...)
                        if gain then gain(widget, ...) end
                        help:SetString(option.hover or "")
                    end
                end
            end
        end
        help:SetString(settings[1].hover or "")
    end
    screen.RefreshOptions = function(self, ...)
        local result = refresh(self, ...)
        bind(self)
        return result
    end
    bind(screen)
end)

AddClassPostConstruct("screens/modsscreen", function(screen)
    local active = screen.OnBecomeActive
    screen.OnBecomeActive = function(self, ...)
        local result
        if active then result = active(self, ...) end
        if self.modnames and self.modnames[self.currentmod] == modname then
            self:ShowModDetails(self.currentmod)
        end
        return result
    end
end)
