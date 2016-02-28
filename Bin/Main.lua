----------------------------------
-- STalk - Main
-- By Joshua
-- At 2013-02-10 15:08:19
----------------------------------
require("lcon")
local socket=require("socket")
local cjson=require("cjson")
local coding=require("coding")
----------------------------------
-- Main - GetKey
-- By Joshua
-- At 2013-02-12 17:21:11
----------------------------------
function GetKey(key)
	if type(key)~="table" then
		error("在合成密钥时检测到密钥数据类型不正确，为"..type(key).."类型")
	elseif #key~=16 then
		error("密钥需要16个元素，元素只有"..#key.."个")
	end
	local res={}
	for i=1,16 do
		res[i]=string.char(key[((i+5)%16)+1])
	end
	return table.concat(res)
end
----------------------------------
-- Main - DeJson
-- By Joshua
-- At 2013-02-12 17:27:31
----------------------------------
function DeJson(str)
	str=(str or ""):match("^({.+}).-$")
	if type(str)~="string" then
		return false
	end
	local a,b=pcall(cjson.decode,str)
	if a and b then
		return b
	else
		return false
	end
end
----------------------------------
-- Main - ToJson
-- By Joshua
-- At 2013-02-12 17:51:46
----------------------------------
function ToJson(t)
	if type(table)~="table" then
		return false
	end
	local a,b=pcall(cjson.encode,t)
	if a and b then
		return b
	else
		return false
	end
end
----------------------------------
-- Main - Tea
-- By Joshua
-- At 2013-02-10 20:43:21
----------------------------------
function Tea(str,key)
	str=str..(" "):rep((8-(#str%8))%8)
	local r={}
	for i=1,#str/8 do
		r[i]=coding.tea(str:sub(i*8-7,i*8),key)
	end
	return table.concat(r)
end
----------------------------------
-- Main - Teadec
-- By Joshua
-- At 2013-02-10 20:43:21
----------------------------------
function Teadec(str,key)
	str=str..(" "):rep((8-(#str%8)%8))
	local r={}
	for i=1,#str/8 do
		r[i]=coding.teadec(str:sub(i*8-7,i*8),key)
	end
	return table.concat(r)
end
----------------------------------
-- Main - Send
-- By Joshua
-- At 2013-02-13 13:35:49
----------------------------------
function Send(obj,t)
	obj:send(coding.base64(Tea(ToJson(t),StrKey)).."\n")
end
----------------------------------
-- Main - Get
-- By Joshua
-- At 2013-02-13 18:45:58
----------------------------------
function Get(obj)
	local data,sta=obj:receive("*l")
	if sta=="closed" then
		io.write("\tNetwork error: 与服务器的连接已断开。\n\n\t")
		os.execute("pause")
		return StartSTalk()
	elseif data then
		return DeJson(Teadec(coding.debase64(data),StrKey))
	end
end
----------------------------------
-- Main - SetColor
-- By Joshua
-- At 2013-01-28 18:01:24
----------------------------------
function SetColor(color)
	lcon.set_color(type(color)=="number" and color or Colors[color or "white"])
end
----------------------------------
-- Main - StartSTalk
-- By Joshua
-- At 2013-02-13 17:13:02
----------------------------------
function StartSTalk()
	os.execute("title STalk - 1.3.1.1 & cls")
	local box={
		"登录帐号",
		"注册帐号",
		"开发名单",
		"退出程序",
	}
	SetColor()
	io.write("\t    --- 欢迎使用STalk ---\n\n\t\t=== 菜单 ===\n\n")
	io.write("=============================================================\n")
	io.write("\t\t[lsgreen > 登录帐号]\n")
	io.write("\t\t  注册帐号\n")
	io.write("\t\t  开发名单\n")
	io.write("\t\t  退出程序\n")
	io.write("=============================================================\n")
	local m=4
	local x=16
	local y=lcon.cur_y()-5
	local point=1
	while true do
		local Key=lcon.getch()
		if Key==72 and point>1 then
			lcon.gotoXY(x,y)
			SetColor()
			io.write("  ",box[point])
			point=point-1
			y=y-1
			lcon.gotoXY(x,y)
			SetColor("lsgreen")
			io.write("> ",box[point])
		elseif Key==80 and point<m then
			lcon.gotoXY(x,y)
			SetColor()
			io.write("  ",box[point])
			point=point+1
			y=y+1
			lcon.gotoXY(x,y)
			SetColor("lsgreen")
			io.write("> ",box[point])
		elseif Key==13 then
			SetColor()
			if point==1 then
				os.execute("cls")
				io.write("\t\t\t       === 登录 ===\n")
				io.write("\t\t\t帐号: ")
				local x=lcon.cur_x()
				local y=lcon.cur_y()
				io.write("\n\t\t\t密码: ")
				local x2=lcon.cur_x()
				local y2=lcon.cur_y()
				lcon.gotoXY(x,y)
				ID=io.read(10)
				lcon.gotoXY(x2,y2)
				local pw=io.read(36,6)
				os.execute("cls")
				ID=tonumber(ID)
				if not ID then
					io.write("\n\n\tData error: 账号只能为数字。\n\t")
					os.execute("pause")
					return StartSTalk()
				end
				io.write("\tConnecting...\n")
				Link=socket.tcp()
				Link:settimeout(10)
				local res,tip=Link:connect(host,port)
				if not res then
					io.write("\tNetwork error: "..tip.."\n\n\t服务器可能已经关闭或者网络未连接，请重试。\n\t另外，请注意不支持同时打开两个和/或以上的客户端。\n\t")
					os.execute("pause")
					os.exit()
				else
					Send(Link,{
						type="system",
						text="Login",
						id=ID,
						pw=coding.md5(pw)
					})
					local res=Get(Link)
					if type(res)~="table" then
						io.write("\t抱歉，服务器无响应，请重试。\n\n\t")
						os.execute("pause")
						return StartSTalk()
					elseif res.text=="No data" then
						io.write("\t数据库中没有该帐号，请尝试注册。\n\n\t")
						os.execute("pause")
						return StartSTalk()
					elseif res.text=="Password error" then
						io.write("\t密码错误，请重试。\n\n\t")
						os.execute("pause")
						return StartSTalk()
					elseif res.text=="ok" then
						io.write("\t恭喜，登陆成功！马上进入主界面...")
						Nick=res.nick
						socket.sleep(0.5)
						break
					end
				end
			elseif point==2 then
				os.execute("cls")
				io.write("\t\t\t       === 注册 ===\n")
				io.write("\t\t\t昵称: ")
				local x=lcon.cur_x()
				local y=lcon.cur_y()
				io.write("\n\t\t\t密码: ")
				local x2=lcon.cur_x()
				local y2=lcon.cur_y()
				lcon.gotoXY(x,y)
				Nick=io.read(20)
				lcon.gotoXY(x2,y2)
				local pw=io.read(36,5)
				if #Nick<4 then
					io.write("\n\n\tData error: 昵称至少要4字节(两个文字)。\n\t")
					os.execute("pause")
					return StartSTalk()
				end
				os.execute("cls")
				io.write("\tConnecting...\n")
				Link=socket.tcp()
				Link:settimeout(10)
				local res,tip=Link:connect(host,port)
				if not res then
					io.write("\tNetwork error: "..tip.."\n\n\t服务器可能已经关闭或者网络未连接，请重试。\n\t另外，请注意不支持同时打开两个和/或以上的客户端。\n\t")
					os.execute("pause")
					os.exit()
				else
					Send(Link,{
						type="system",
						text="Register",
						nick=Nick,
						pw=coding.md5(pw)
					})
					local res=Get(Link)
					if type(res)~="table" then
						io.write("\t抱歉，服务器无响应，请重试。\n\n\t")
						os.execute("pause")
						return StartSTalk()
					elseif res.text=="Error" then
						io.write("\t服务器发生未知错误。请重试。\n\n\t")
						os.execute("pause")
						return StartSTalk()
					elseif res.text=="ok" then
						ID=res.id
						io.write("\t恭喜，注册成功！欢迎使用STalk。\n\t请仔细记录下用户信息后按下任意键进入主界面。\n\n\t\t === 用户信息 ===\n\t\t Nick\t\t"..Nick.."\n\t\t ID\t\t"..res.id.."\n\t\t Password\t你所输入的密码\n\n\n\t")
						os.execute("pause")
						break
					end
				end
			elseif point==3 then
				os.execute("cls")
				io.write("\t\t       === 开发者名单 ===\n\t\t\t开发 - 约修亚_RK\n\t\t\t出品 - 暗影软件\n\t\t\t支持 - 淀粉网络\n\n\t\t\t使用淀粉网络提供的VPS (dflyHost)\n\n\t\t\t    [lsgreen > 确认]\n")
				while lcon.getch()~=13 do
				end
				return StartSTalk()
			elseif point==4 then
				os.exit()
			end
		end
	end
	local ser=socket.tcp()
	ser:bind("localhost",8884)
	ser:listen(2)
	ser:settimeout(10)
	--os.execute("Start Bin/Lua.exe InBox.lua & cls")
	os.execute("Start Lua.exe InBox.lua & cls")
	local ibox=ser:accept()
	ibox:settimeout(10)
	local t={Link,ibox}
	while true do
		local c=socket.select(t)
		for i,v in ipairs(c) do
			if v==Link then
				local res=Get(v)
				if res and res.type and Registry[res.type] then
					Registry[res.type](res,v)
				end
			else
				local res,sta=v:receive("*l")
				if sta=="closed" then
					os.exit()
				else
					OnInput(res,t[1],ID,Nick)
				end
			end
		end
	end
end
----------------------------------
-- Main - OnSystemMessage
-- By Joshua
-- At 2013-02-13 23:54:01
----------------------------------
function OnSystemMessage(msg,Link)
	SetColor(Colors.lred)
	io.write("System ",msg.time,"\n\t")
	SetColor(Colors.bwhite)
	if msg.text=="Online" then
		io.write("用户 ",msg.user," 上线了。\n")
	elseif msg.text=="Offline" then
		io.write("用户 ",msg.user," 下线了。\n")
	elseif msg.text=="Leave" then
		io.write("用户 ",msg.user," 离开了。\n")
	elseif msg.text=="UserList" then
		io.write(msg.list,"\n")
	elseif msg.text=="CloseServer" then
		io.write("服务器被 ",msg.user," 关闭。\n")
	elseif msg.text=="Help" then
		io.mwrite(msg.help,"\n")
	end
end
----------------------------------
-- Main - OnMessage
-- By Joshua
-- At 2013-02-13 23:54:09
----------------------------------
function OnMessage(msg,Link)
	SetColor(Colors.lsgreen)
	io.write(msg.nick," (",msg.from,") ",msg.time,"\n\t")
	SetColor()
	io.write(msg.text:gsub(string.char(1),"\n\t"),"\n")
end
----------------------------------
-- Main - OnGroupMessage
-- By Joshua
-- At 2013-02-13 23:54:20
----------------------------------
function OnGroupMessage(msg,Link)
	SetColor(Colors.lblue)
	io.write(msg.nick," (",msg.from,") ",msg.time,"\n\t")
	SetColor()
	io.write(msg.text:gsub(string.char(1),"\n\t"),"\n")
end
----------------------------------
-- Main - OnInput
-- By Joshua
-- At 2013-02-13 23:55:34
----------------------------------
function OnInput(msg,Link,uid,nick)
	if msg:find("^%[#%d+%]%s?.+$") then
		local id,text=msg:match("^%[#(%d+)%]%s?(.+)$")
		Send(Link,{
			type="single",
			text=text,
			from=tonumber(uid),
			to=tonumber(id)
		})
		local res=Get(Link)
		SetColor(Colors.lyellow)
		io.write(nick," (",uid,") to ",res.nick or "-"," (",res.nick and id or "-",") ",res.time,"\n\t")
		SetColor()
		io.write(text:gsub(string.char(1),"\n\t"),"\n")
		if res.text~="ok" then
			local x,y=lcon.cur_x(),lcon.cur_y()
			lcon.gotoXY(3,y-1)
			SetColor(Colors.lred)
			io.write("[!]")
			SetColor()
			lcon.gotoXY(x,y)
		end
	elseif QFind(msg,"<online>") then
		Send(Link,{
			type="system",
			text="Online"
		})
	elseif QFind(msg,"<leave>") then
		Send(Link,{
			type="system",
			text="Leave"
		})
	elseif QFind(msg,"<logout>") then
		Link:close()
		os.exit()
	elseif QFind(msg,"<userlist>") then
		Send(Link,{
			type="system",
			text="GetUserList"
		})
	elseif QFind(msg,"<help>") then
		Send(Link,{
			type="system",
			text="GetHelp"
		})
	elseif QFind(msg,"<stopserver>") then
		Send(Link,{
			type="system",
			text="CloseServer"
		})
		local res=Get(Link)
		SetColor(Colors.lred)
		io.write("System ",msg.time,"\n\t")
		SetColor(Colors.bwhite)
		io.write(res.text~="ok" and "警告：你没有管理员权限。" or "服务器已经关闭。","\n")
	elseif msg:find("^<[Dd][Oo][Ll][Uu][Aa]>.+$") then
		Send(Link,{
			type="system",
			text="Dolua",
			code=msg:match("^<[Dd][Oo][Ll][Uu][Aa]>(.+)$")
		})
		local res=Get(Link)
		SetColor(Colors.lred)
		io.write("System ",res.time,"\n\t")
		SetColor(Colors.bwhite)
		io.write(res.text~="ok" and "警告：你没有管理员权限。" or res.res,"\n")
	else
		Send(Link,{
			type="group",
			text=msg,
			from=uid
		})
		local res=Get(Link)
		SetColor(Colors.lgreen)
		io.write(nick," (",uid,") ",res.time,"\n\t")
		SetColor()
		io.write(msg:gsub(string.char(1),"\n\t"),"\n")
		if res.text~="ok" then
			local x,y=lcon.cur_x(),lcon.cur_y()
			lcon.gotoXY(3,y-1)
			SetColor(Colors.lred)
			io.write("[!]")
			SetColor()
			lcon.gotoXY(x,y)
		end
	end
end
----------------------------------
-- Main - QFind
-- By Joshua
-- At 2013-02-15 16:02:47
----------------------------------
function QFind(str,fs)
	fs=fs:gsub("%a",function(char) 
		return "["..char:upper()..char:lower().."]"
	end)
	return str:find("^"..fs.."$")
end
----------------------------------
-- IO - mwrite
-- By Joshua
-- At 2013-01-28 20:49:29
----------------------------------
io.mwrite=io.write
----------------------------------
-- IO - write
-- By Joshua
-- At 2013-01-28 14:28:54
----------------------------------
function io.write(...)
	local t={...}
	for i=1,table.maxn(t) do
		t[i]=tostring(t[i])
	end
	local re=table.concat(t)
	if not re:find("%[(.-) (.-)%]") then
		return io.mwrite(re)
	end
	local s,e,color,text=re:find("%[(.-) (.-)%]")
	while s do
		if s>1 then
			SetColor()
			io.mwrite(re:sub(1,s-1))
		end
		if Colors[color] then
			SetColor(color)
			io.mwrite(text)
			SetColor()
		else
			SetColor()
			io.mwrite(re:sub(s,e))
		end
		re=re:sub(e+1,#re)
		s,e,color,text=re:find("%[(.-) (.-)%]")
	end
	SetColor()
	io.mwrite(re)
end
----------------------------------
-- IO - mread
-- By Joshua
-- At 2013-01-28 14:29:20
----------------------------------
io.mread=io.read
----------------------------------
-- IO - read
-- By Joshua
-- At 2013-01-29 19:57:50
----------------------------------
function io.read(Max,pw)
	if not Max then
		return io.mread()
	end
	local res={}
	local point=1
	local x,y=lcon.cur_x(),lcon.cur_y()
	while true do
		local key=lcon.getch()
		if key==13 then
			if #res>(pw or 0) then
				break
			end
		elseif key==8 then
			if point>=1 then
				if res[point-2] and res[point-2]:byte()>127 and res[point-1]:byte()>127 then
					point=point-1
					table.remove(res,point)
				end
				if point>1 then
					point=point-1
				end
				table.remove(res,point)
				lcon.gotoXY(x,y)
				if pw then
					io.mwrite(("*"):rep(#res),"  ")
				else
					io.mwrite(table.concat(res),"  ")
				end
				lcon.gotoXY(x+point-1,y)
			end
		elseif key==224 or key==0 then
			local key2=lcon.getch()
			if key2==75 then
				if point>1 then
					if res[point-2] and res[point-2]:byte()>127 and res[point-1]:byte()>127 then
						point=point-1
					end
					point=point-1
					lcon.gotoXY(x+point-1,y)
				end
			elseif key2==77 then
				if point<=#res then
					if res[point+2] and res[point+2]:byte()>127 and res[point+1]:byte()>127 then
						point=point+1
					end
					point=point+1
					lcon.gotoXY(x+point-1,y)
				end
			elseif key2==71 then
				point=1
				lcon.gotoXY(x,y)
			elseif key2==79 then
				point=#res+1
				lcon.gotoXY(x+point-1,y)			
			elseif key2==83 then
				if res[point+1] and res[point+1]:byte()>127 and res[point]:byte()>127 then
					table.remove(res,point)
				end
				table.remove(res,point)
				lcon.gotoXY(x,y)
				if pw then
					io.mwrite(("*"):rep(#res),"  ")
				else
					io.mwrite(table.concat(res),"  ")
				end
				lcon.gotoXY(x+point-1,y)
			elseif key2==72 or key2==80 or key2==82 or key2==81 or key2==73 then
			else
				if #res<Max then
					table.insert(res,point,string.char(key))
					point=point+1
					table.insert(res,point,string.char(key2))
					point=point+1
					lcon.gotoXY(x,y)
					if pw then
						io.mwrite(("*"):rep(#res),"  ")
					else
						io.mwrite(table.concat(res),"  ")
					end
					lcon.gotoXY(x+point-1,y)
				end
			end
		else
			if #res<Max then
				table.insert(res,point,string.char(key))
				point=point+1
				lcon.gotoXY(x,y)
				if pw then
					io.mwrite(("*"):rep(#res),"  ")
				else
					io.mwrite(table.concat(res),"  ")
				end
				lcon.gotoXY(x+point-1,y)
			end
		end
	end
	return table.concat(res)
end
----------------------------------
-- Main - Data
-- By Joshua
-- At 2013-02-10 15:09:13
----------------------------------
port=10380
key={
	0x0056,0x005F,
	0x007E,0x002E,
	0x0074,0x0061,
	0x0031,0x006B,
	0x002A,0x0066,
	0x0030,0x0072,
	0x0055,0x003D,
	0x003E,0x0072
}
host="LuaCC.54df.net"
--host="localhost"
Registry={
	system=OnSystemMessage,
	single=OnMessage,
	group=OnGroupMessage
}
Colors={
	black=0,
	blue=1,
	green=2,
	lgreen=3,
	red=4,
	purple=5,
	yellow=6,
	white=7,
	gray=8,
	lblue=9,
	lgreen=10,
	lsgreen=11,
	lred=12,
	lpurple=13,
	lyellow=14,
	bwhite=15
}
StrKey=GetKey(key)
----------------------------------
-- Main - Start
-- By Joshua
-- At 2013-02-10 15:09:28
----------------------------------
StartSTalk()