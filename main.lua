local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")

local KoboSync = WidgetContainer:extend{
    name = "kobosync",
    is_doc_only = false,
}

function KoboSync:init()
    self.ui.menu:registerToMainMenu(self)
end

function KoboSync:addToMainMenu(menu_items)
    menu_items.kobosync = {
        text = _("Kobo Sync"),
        sorting_hint = "tools",
        sub_item_table = {
            {
                text = _("About"),
                keep_menu_open = true,
                callback = function()
                    UIManager:show(InfoMessage:new{
                        text = _("Kobo Sync client for self-hosted servers (calibre-web and compatible).")
                            .. "\n\n" .. _("Not yet configured."),
                    })
                end,
            },
        },
    }
end

return KoboSync
