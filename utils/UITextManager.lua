local UITextManager = {
    font = nil,
    UIElements = {}
}

function UITextManager.initialize(fontPath)
    UITextManager.font = intraFont.load(fontPath)
end

function UITextManager.createText(text, x, y)
    local newText = {
        text = text,
        x = x,
        y = y,
        setText = function(self, newText)
            self.text = newText
        end,
        setPosition = function(self, newX, newY)
            self.x = newX
            self.y = newY
        end
    }
    table.insert(UITextManager.UIElements, newText)
    return newText
end

function UITextManager.Update()
    if not UITextManager.font then
        error("Font not initialized! Call UITextManager.initialize() first")
    end
    
    for _, element in ipairs(UITextManager.UIElements) do
        intraFont.print(UITextManager.font, element.x, element.y, element.text)
    end
end

return UITextManager