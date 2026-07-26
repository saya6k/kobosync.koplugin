-- A message pinned to the bottom left corner while a sync runs.
--
-- KOReader's TrapWidget draws exactly this, but it is an InputContainer that
-- claims every tap, hold and swipe on the screen so it can interrupt whatever
-- it is guarding. A background sync must not do that -- the reader underneath
-- has to keep turning pages -- so this borrows the layout and registers no
-- gestures at all: events fall straight through to the widget below.

local Blitbuffer = require("ffi/blitbuffer")
local BottomContainer = require("ui/widget/container/bottomcontainer")
local CenterContainer = require("ui/widget/container/centercontainer")
local Device = require("device")
local Font = require("ui/font")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local LeftContainer = require("ui/widget/container/leftcontainer")
local Size = require("ui/size")
local TextBoxWidget = require("ui/widget/textboxwidget")
local TextWidget = require("ui/widget/textwidget")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local Screen = Device.screen

local SyncIndicator = WidgetContainer:extend{
    text = "",
    face = Font:getFace("infofont"),
}

function SyncIndicator:init()
    local full_screen = Geom:new{
        x = 0, y = 0,
        w = Screen:getWidth(),
        h = Screen:getHeight(),
    }
    local textw = TextWidget:new{ text = self.text, face = self.face }
    -- Keep the message off the full width so it reads as popping out of the
    -- corner; wrap it when it would not fit.
    if textw:getWidth() > Screen:getWidth() * 0.9 then
        textw = TextBoxWidget:new{
            text = self.text,
            face = self.face,
            width = math.floor(Screen:getWidth() * 0.9),
        }
    end
    local border_size = Size.border.default
    self.frame = FrameContainer:new{
        background = Blitbuffer.COLOR_WHITE,
        bordersize = border_size,
        margin = 0,
        padding = 0,
        padding_left = Size.padding.default,
        padding_right = Size.padding.default,
        textw,
    }
    -- Nested containers push the left and bottom borders off-screen, which is
    -- what makes the frame look attached to the corner.
    self[1] = CenterContainer:new{
        dimen = full_screen:copy(),
        BottomContainer:new{
            dimen = Geom:new{
                w = full_screen.w,
                h = full_screen.h + 2 * border_size,
            },
            LeftContainer:new{
                dimen = Geom:new{
                    w = full_screen.w + 2 * border_size,
                    h = self.frame:getSize().h,
                },
                self.frame,
            },
        },
    }
end

function SyncIndicator:onShow()
    UIManager:setDirty(self, function()
        return "ui", self.frame.dimen
    end)
    return true
end

function SyncIndicator:onCloseWidget()
    UIManager:setDirty(nil, function()
        return "ui", self.frame.dimen
    end)
end

return SyncIndicator
