if file.open("wifi.txt", "r") then
    ssid = string.gsub(file.readline(), "\n", "")
    pwd = string.gsub(file.readline(), "\n", "")
    client_ip = string.gsub(file.readline(), "\n", "")
    client_netmask = string.gsub(file.readline(), "\n", "")
    client_gateway = string.gsub(file.readline(), "\n", "")
    file.close()
    
    --ssid = string.gsub(ssid, "|", "")
    --pwd = string.gsub(pwd, "|", "")
    wifi.setmode(wifi.STATION)
    wifi.setphymode(wifi.PHYMODE_N)
    print("connect to: " .. ssid .. " " .. pwd)
    wifi.sta.config(ssid, pwd)
    wifi.sta.connect()
    if client_ip ~= "" then
        print("set ip: " .. client_ip .. " " .. client_netmask .. " " .. client_gateway)
        wifi.sta.setip({ip=client_ip,netmask=client_netmask,gateway=client_gateway})
    else
        print("use DHCP")        
    end

    --delay 5 seconds, then load web server
    tmr.alarm(0, 5000, 1, function()
        ip = wifi.sta.getip()    
        if ip then
            tmr.unregister(0)  
            print("start server") 
            dofile("webserverswitch.lua")
        else
            print ("couldn't connect to " .. ssid .. " try again")
            --wifi.sta.config(ssid, pwd)
            --node.restart()
        end
    end)
end
