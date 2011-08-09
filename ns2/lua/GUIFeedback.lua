
// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIFeedback.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages the feedback text.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIFeedback' (GUIScript)

GUIFeedback.kFontSize = 15
GUIFeedback.kTextFontName = "MicrogrammaDMedExt"
GUIFeedback.kTextColor = Color(0.5, 0, 0, 0.75)
GUIFeedback.kTextOffset = Vector(20, 55, 0)

function GUIFeedback:Initialize()

    self.buildText = GUIManager:CreateTextItem()
    self.buildText:SetFontSize(GUIFeedback.kFontSize)
    self.buildText:SetFontName(GUIFeedback.kTextFontName)
    self.buildText:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.buildText:SetTextAlignmentX(GUIItem.Align_Min)
    self.buildText:SetTextAlignmentY(GUIItem.Align_Center)
    self.buildText:SetPosition(GUIFeedback.kTextOffset)
    self.buildText:SetColor(GUIFeedback.kTextColor)
    self.buildText:SetFontIsBold(true)
    self.buildText:SetText(Locale.ResolveString("BETA_MAINMENU") .. tostring(Shared.GetBuildNumber()))
    
    self.feedbackText = GUIManager:CreateTextItem()
    self.feedbackText:SetFontSize(GUIFeedback.kFontSize)
    self.feedbackText:SetFontName(GUIFeedback.kTextFontName)
    self.feedbackText:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.feedbackText:SetTextAlignmentX(GUIItem.Align_Min)
    self.feedbackText:SetTextAlignmentY(GUIItem.Align_Min)
    self.feedbackText:SetColor(GUIFeedback.kTextColor)
    self.feedbackText:SetFontIsBold(true)
    self.feedbackText:SetText(Locale.ResolveString("FEEDBACK_MAINMENU"))
    self.buildText:AddChild(self.feedbackText)

end

function GUIFeedback:Uninitialize()

    if self.buildText then
        GUI.DestroyItem(self.buildText)
        self.buildText = nil
        self.feedbackText = nil
    end
    
end

function GUIFeedback:SendKeyEvent(key, down)

    if down and key == InputKey.F1 then
        ShowFeedbackPage()
        return true
    end
    return false

end
