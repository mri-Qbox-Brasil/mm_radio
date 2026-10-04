-- Registered at runtime so ox_inventory items.lua needs no client.event for the radio
for i = 1, #Shared.RadioItem do
    exports.qbx_core:CreateUseableItem(Shared.RadioItem[i], function(source, item)
        TriggerClientEvent('mm_radio:client:use', source, item)
    end)
end

if Shared.Jammer.state then
    exports.qbx_core:CreateUseableItem('jammer', function(source)
        TriggerClientEvent('mm_radio:client:usejammer', source)
    end)
end

if Shared.Battery.state then
    exports.qbx_core:CreateUseableItem('radiocell', function(source)
        TriggerClientEvent('mm_radio:client:recharge', source)
    end)
end
