//=============================================================================
//
// lua/Notifications.lua
// 
// Created by Henry Kropf
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

// color, playername, color, message
local notificationMessages = { }

function NotificationsUI_GetNotifications()

    local uiNotificationMessages = {}
    
    if(table.maxn(notificationMessages) > 0) then
    
        table.copy(notificationMessages, uiNotificationMessages)
        notificationMessages = {}
        
    end
        
    return uiNotificationMessages

end



