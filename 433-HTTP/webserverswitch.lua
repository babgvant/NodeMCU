-- Webserver to control several on / off switches.
-- HTML inspired by: https://github.com/mrkale/NodeMCU-WifiDoubleSwitch
-- webserver modifed from https://www.youtube.com/watch?v=5ElOFNiphGA

-- Config
switch1_pin = 1 -- Switch 1 On
switch2_pin = 2 -- Switch 1 Off
switch3_pin = 3 -- Switch 2 On
switch4_pin = 0 -- Switch 2 Off
switch5_pin = 5 -- Switch 3 On
switch6_pin = 6 -- Switch 3 Off
switch7_pin = 7 -- Switch 4 On
switch8_pin = 8 -- Switch 4 Off

HOLD_FOR = 750 -- How long to simulate a button press


-- Connect 
tmr.alarm(0, 1000, 1, function()
   if wifi.sta.getip() == nil then
      print("Connecting to AP...\n")
   else
      ip, nm, gw=wifi.sta.getip()
      print("IP address: ",ip)
      tmr.stop(0)

      gpio.mode(switch1_pin, gpio.OUTPUT)
      gpio.mode(switch2_pin, gpio.OUTPUT)
      gpio.mode(switch3_pin, gpio.OUTPUT)
      gpio.mode(switch4_pin, gpio.OUTPUT)
      gpio.mode(switch5_pin, gpio.OUTPUT)
      gpio.mode(switch6_pin, gpio.OUTPUT)
      gpio.mode(switch7_pin, gpio.OUTPUT)
      gpio.mode(switch8_pin, gpio.OUTPUT)
      tmr.start(1)
   end
end)

tmr.alarm(1, HOLD_FOR, 1, function()
    gpio.write(switch1_pin, gpio.LOW)
    gpio.write(switch2_pin, gpio.LOW)
    gpio.write(switch3_pin, gpio.LOW)
    gpio.write(switch4_pin, gpio.LOW)
    gpio.write(switch5_pin, gpio.LOW)
    gpio.write(switch6_pin, gpio.LOW)
    gpio.write(switch7_pin, gpio.LOW)
    gpio.write(switch8_pin, gpio.LOW)
    tmr.stop(1)
end)

local httpRequest={}
httpRequest["/"]="index.htm";
httpRequest["/index.htm"]="index.htm";
httpRequest["/style.css"]="style.css";

local getContentType={};
getContentType["/"]="text/html";
getContentType[".htm"]="text/html";
getContentType[".css"]="text/css";
local filePos=0;

if srv then srv:close() srv=nil end
srv=net.createServer(net.TCP)
srv:listen(80,function(conn)
    conn:on("receive", function(conn,request)
        print("[New Request]");
        local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
        if(method == nil)then
         _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
        end
        local formDATA = {}
        if (vars ~= nil)then
            for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
                print("["..k.."="..v.."]");
                formDATA[k] = v
            end   
        end
        print("path " .. path);
        local cleanpath = string.match(path, "/(.+)");
        if(cleanpath == nil or cleanpath == '') then
            cleanpath = "index.htm";
        end
        print("cleanpath " .. cleanpath);
        if file.open(cleanpath,r) then
            file.close();
            requestFile=cleanpath;
            print("[Sending file "..requestFile.."]");            
            filePos=0;
            local fileExt = string.match(cleanpath, "(%.%w+)");
            if (fileExt == nil or fileExt == '') then
                print("fileExt nil");
                fileExt = '.htm';
            end
            print("fileExt " .. fileExt);
            conn:send("HTTP/1.1 200 OK\r\nContent-Type: "..getContentType[fileExt].."\r\n\r\n");            
        else
            local command = string.match(path, "/(%d*)")
            if (command ~= nil and command ~= "") then
                print("Switch "..command.." click")
                gpio.write(tonumber(command), gpio.HIGH)
                tmr.start(1)
                conn:send("HTTP/1.1 200 OK\r\n\r\n\r\n");
            else
                print("[File "..path.." not found]");
                conn:send("HTTP/1.1 404 Not Found\r\n\r\n")
            end
            conn:close();
            collectgarbage();
        end
    end)
    conn:on("sent",function(conn)
        if requestFile then
            if file.open(requestFile,r) then
                file.seek("set",filePos);
                local partial_data=file.read(512);
                file.close();
                if partial_data then
                    filePos=filePos+#partial_data;
                    print("["..filePos.." bytes sent]");
                    conn:send(partial_data);
                    if (string.len(partial_data)==512) then
                        return;
                    end
                   
                end
            else
                print("[Error opening file"..requestFile.."]");
            end
        end
        print("[Connection closed]");
        conn:close();
        collectgarbage();
    end)
end)
