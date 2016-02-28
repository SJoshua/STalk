----------------------------------
-- STalk - InBox
-- By Joshua
-- At 2013-02-10 18:25:14
----------------------------------
local socket=require "socket"
----------------------------------
-- InBox - Start
-- By Joshua
-- At 2013-02-10 18:26:40
----------------------------------
os.execute"title STalk -  ‰»Î¥∞ø⁄ & mode con cols=82 lines=15 & cls"
local tmain=socket.tcp()
tmain:connect("localhost",8884)
tmain:settimeout(1)
while true do
	io.write("  Input\n=============================================\n\t")
	local str=io.read()
	local _,res=tmain:send(str.."\n")
	if res=="closed" or str:find("^%s*<[Ll][Oo][Gg][Oo][Uu][Tt]>%s*$") then
		os.exit()
	end
	os.execute("cls")
end