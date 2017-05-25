local concat = table.concat
local ipairs = ipairs
local type = type

local kit = require 'kit'

local append = kit.append
local flatten = kit.flatten
local setup = kit.setup

local content_key = require 'cheatsheet/content/key'
local content_mods = require 'cheatsheet/content/mods'

local mods_parse = content_mods.parse
local key_parse = content_key.parse

local _M = {}

_M.config = {
    show_disabled = true,
}

local show_disabled

function _M.init(config)
    setup(content_mods, config.mods)

    show_disabled = config.show_disabled
end

local function tag(name, class, enabled, text)
    local attr = class and not enabled and (class .. ' disabled')
            or not enabled and 'disabled'
            or class
    attr = attr and (' class="' .. attr .. '"') or ''

    return { '<', name, attr, '>', text, '</', name, '>' }
end

local function command(item)
    local key = key_parse(item.AXMenuItemCmdChar, item.AXMenuItemCmdGlyph)

    if key then
        return tag('tr', 'command', item.AXEnabled, {
            '<td class="mods">', mods_parse(item.AXMenuItemCmdModifiers), '</td>',
            '<td class="key">', key, '</td>',
            '<td class="title">', item.AXTitle, '</td>'
        })
    end
end

local role = {}

local function list(menu, path)
    local commands = {}
    local sections = {}

    for _, item in ipairs(menu) do
        if type(item) == 'table' then
            if item.AXEnabled or show_disabled then
                local children = item.AXChildren

                if children == nil then
                    commands[#commands + 1] = command(item)
                elseif type(children) == 'table' then
                    local role = role[item.AXRole]

                    if role ~= nil then
                        sections[#sections + 1] = role(item, path)
                    end
                end
            end
        end
    end

    return append(commands, sections)
end

local function cd(path, step)
    return path and (path .. ' → ' .. step) or step
end

function role.AXMenuItem(item, path)
    local path = cd(path, item.AXTitle)
    local children = list(item.AXChildren[1], path)

    if #children ~= 0 then
        return {
            tag('tr', 'section', item.AXEnabled, { '<th colspan="3">', path, '</th>' }),
            children,
        }
    end
end

function role.AXMenuBarItem(item, path)
    local children = list(item.AXChildren[1], path)

    if #children ~= 0 then
        return tag('div', 'block', item.AXEnabled, {
            '<h1>', item.AXTitle, '</h1>',
            '<table><tbody>', children, '</tbody></table>',
        })
    end
end

local function parse(menu)
    return concat(flatten(list(menu)))
end

_M.parse = parse

return _M
