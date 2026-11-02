--- Sign-in screen: the QR code together with the code NetBird asks you to compare.
--
-- KOReader's QRMessage can't show both. Stable builds draw only the QR code, and
-- the title in newer ones doesn't exist on the devices still running stable.
local Blitbuffer = require("ffi/blitbuffer")
local CenterContainer = require("ui/widget/container/centercontainer")
local Device = require("device")
local Font = require("ui/font")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local InputContainer = require("ui/widget/container/inputcontainer")
local QRWidget = require("ui/widget/qrwidget")
local Size = require("ui/size")
local TextBoxWidget = require("ui/widget/textboxwidget")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local _ = require("gettext")

local NetBirdQR = InputContainer:extend{
    modal = true,
    url = nil,
    code = nil, -- may be nil: not every sign-in has one
    dismiss_callback = nil,
}

function NetBirdQR:init()
    local screen = Device.screen
    local width, height = screen:getWidth(), screen:getHeight()

    if Device:hasKeys() then
        self.key_events.AnyKeyPressed = { { Device.input.group.Any } }
    end
    if Device:isTouchDevice() then
        self.ges_events.TapClose = {
            GestureRange:new{
                ges = "tap",
                range = Geom:new{ x = 0, y = 0, w = width, h = height },
            },
        }
    end

    local qr = QRWidget:new{
        text = self.url,
        width = math.floor(math.min(width * 0.8, height * 0.6)),
        height = math.floor(math.min(width * 0.8, height * 0.6)),
    }
    -- QRWidget has no image if encoding failed, and painting that would crash.
    -- The caller falls back to showing the URL as text.
    assert(qr.image, "NetBird: could not encode the QR code")

    local text_width = width - 2 * Size.padding.fullscreen
    local function line(text, face)
        return TextBoxWidget:new{
            text = text,
            face = face,
            width = text_width,
            alignment = "center",
        }
    end
    local gap = VerticalSpan:new{ width = Size.span.vertical_large * 2 }

    local content = VerticalGroup:new{
        align = "center",
        line(_("Scan with your phone to sign in to NetBird"), Font:getFace("infofont")),
        gap,
        qr,
        gap,
    }
    if self.code then
        table.insert(content, line(self.code, Font:getFace("tfont", 32)))
        table.insert(content, line(_("Your phone should show this same code."), Font:getFace("infofont")))
        table.insert(content, gap)
    end
    table.insert(content, line(_("Tap to close."), Font:getFace("smallinfofont")))

    self[1] = FrameContainer:new{
        background = Blitbuffer.COLOR_WHITE,
        bordersize = 0,
        padding = 0,
        CenterContainer:new{
            dimen = Geom:new{ w = width, h = height },
            content,
        },
    }
end

function NetBirdQR:onShow()
    UIManager:setDirty(self, "ui")
    return true
end

function NetBirdQR:onCloseWidget()
    UIManager:setDirty(nil, "ui")
    if self.dismiss_callback then
        self.dismiss_callback()
        self.dismiss_callback = nil
    end
end

function NetBirdQR:onTapClose()
    UIManager:close(self)
    return true
end
NetBirdQR.onAnyKeyPressed = NetBirdQR.onTapClose

return NetBirdQR
