--------------------------------------------------------------------------------
--- # Entity preview "window" in the combinator GUI
--------------------------------------------------------------------------------

local GuiPreview = {}

function GuiPreview:create(sc, parent)
    local ep_frame = parent.add {
        type = 'frame',
        style = 'deep_frame_in_shallow_frame',
    }
    ep_frame.style.minimal_width = 0
    ep_frame.style.horizontally_stretchable = true
    ep_frame.style.padding = 0

    local ep = ep_frame.add {
        type = 'entity-preview',
        style = 'wide_entity_button'
    }
    ep.entity = sc.input
end

return GuiPreview
