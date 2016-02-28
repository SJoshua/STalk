----------------------------------
-- STalk - Server
-- By Joshua
-- At 2013-02-10 16:25:36
----------------------------------
local socket=require("socket")
local cjson	=require("cjson")
local coding=require("coding")
----------------------------------
-- Server - Error
-- By Joshua
-- At 2013-02-12 17:31:21
----------------------------------
function Error(...)
	local str=table.concat({...})
	local f=io.open("error.log","a")
	f:write("|",os.date(),"| ",str,"\n")
	f:close()
	error(str)
end
----------------------------------
-- Server - LogPrint
-- By Joshua
-- At 2013-02-12 17:36:29
----------------------------------
function LogPrint(...)
	io.write("|",os.date(),"| ",...)
	io.write("\n")
end
----------------------------------
-- Server - GetKey
-- By Joshua
-- At 2013-02-12 17:21:11
----------------------------------
function GetKey(key)
	if type(key)~="table" then
		Error("在合成密钥时检测到密钥数据类型不正确，为",type(key),"类型")
	elseif #key~=16 then
		Error("密钥需要16个元素，元素只有",#key,"个")
	end
	local res={}
	for i=1,16 do
		res[i]=string.char(key[((i+5)%16)+1])
	end
	return table.concat(res)
end
----------------------------------
-- Server - DeJson
-- By Joshua
-- At 2013-02-12 17:27:31
----------------------------------
function DeJson(str)
	str=(str or ""):match("^({.+}).-$")
	if type(str)~="string" then
		LogPrint("解码Json时发现类型错误，为",type(key),"类型")
		return false
	end
	local a,b=pcall(cjson.decode,str)
	if a and b then
		return b
	else
		LogPrint("收到了不正确的Json数据。")
		return false
	end
end
----------------------------------
-- Server - ToJson
-- By Joshua
-- At 2013-02-12 17:51:46
----------------------------------
function ToJson(t)
	if type(table)~="table" then
		LogPrint("转码Json时发现类型错误，为",type(key),"类型")
		return false
	end
	local a,b=pcall(cjson.encode,t)
	if a and b then
		return b
	else
		LogPrint("转码Json时发生错误，错误信息为『",b,"』")
		return false
	end
end
----------------------------------
-- Server - ToLua
-- By Joshua
-- At 2013-02-12 17:50:42
----------------------------------
function ToLua(k,v,n)
	local r={}
	n=n or 0
	if type(v)~='table' then
		table.insert(r,table.concat{('\t'):rep(n),'[',type(k)=='string' and '"'..k..'"' or k,']\t= ',type(v)=='string' and '"'..tostring(v)..'"' or tostring(v),',\n'})
	else
		if n~=0 then
			table.insert(r,table.concat{('\t'):rep(n),'[',type(k)=='string' and '"'..k..'"' or k,']\t= {\n'})
		else
			table.insert(r,table.concat{k,"{\n"})
		end
		for i,t in pairs(v) do
			table.insert(r,ToLua(i,t,n+1))
		end
		if n~=0 then
			table.insert(r,table.concat{('\t'):rep(n),'},\n'})
		else
			table.insert(r,table.concat{"}"})
		end
	end
	return table.concat(r)
end
----------------------------------
-- Server - LoadData
-- By Joshua
-- At 2013-02-12 17:44:11
----------------------------------
function LoadData(fn)
	local file=io.open(fn,"r")
	if not file then
		Error("读取文件",fn,"时失败，找不到该文件或者没有读取权限。")
	end
	local str=file:read("*all")
	file:close()
	local a,b=pcall(loadstring(str))
	if a and b then
		return b
	elseif not a and b then
		Error("文件",fn,"数据失效，无法正常读取。")
	end
end
----------------------------------
-- Server - SaveData
-- By Joshua
-- At 2013-02-12 17:51:11
----------------------------------
function SaveData(fn,t)
	local file = io.open(fn,"w")
	file:write(ToLua("return ",t))
	file:close()
end
----------------------------------
-- Server - Tea
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
-- Server - Teadec
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
-- Server - Send
-- By Joshua
-- At 2013-02-13 13:35:49
----------------------------------
function Send(obj,t)
	obj:send(coding.base64(Tea(ToJson(t),StrKey)).."\n")
end
----------------------------------
-- Server - AllSend
-- By Joshua
-- At 2013-02-13 16:57:11
----------------------------------
function AllSend(str)
	for i,v in pairs(Links) do
		if i~=1 then
			Send(v,str)
		end
	end
end
----------------------------------
-- Server - Register
-- By Joshua
-- At 2013-02-13 15:27:18
----------------------------------
function Register(nick,pw)
	local ID=0
	for i,v in pairs(UserData) do
		ID=ID+1
	end
	if ID==1 then
		ID=100001
	else
		ID=tonumber(string.format("1%.5d",ID))
	end
	UserData[ID]={
		nick=nick,
		password=coding.base64(coding.md5(pw)),
		admin=false
	}
	SaveData("users.ldb",UserData)
	return ID
end
----------------------------------
-- Server - Login
-- By Joshua
-- At 2013-02-13 15:44:55
----------------------------------
function Login(ID,pw)
	if not UserData[tonumber(ID)] then
		return -1
	elseif coding.debase64(UserData[tonumber(ID)].password)==coding.md5(pw) then
		return UserData[tonumber(ID)].nick
	else
		return -2
	end
end
----------------------------------
-- Server - OnMessage
-- By Joshua
-- At 2013-02-12 22:07:37
----------------------------------
function OnMessage(msg,obj)
	if not msg.from or (msg.from and not LoginData[msg.from]) then
		Send(obj,{
			type="return",
			text="You are offline",
			time=os.date("%X")
		})
	elseif not msg.to then
		Send(obj,{
			type="return",
			text="No target",
			time=os.date("%X")
		})
	elseif not UserData[msg.to] then
		Send(obj,{
			type="return",
			text="The user does not exist",
			time=os.date("%X")
		})
	elseif not LoginData[msg.to] then
		Send(obj,{
			type="return",
			text="The user is offline",
			time=os.date("%X")
		})
	elseif not msg.text or type(msg.text)~="string" then
		Send(obj,{
			type="return",
			text="No text",
			time=os.date("%X")
		})
	else
		Send(obj,{
			type="return",
			text="ok",
			nick=UserData[msg.to].nick,
			time=os.date("%X")
		})
		Send(LoginData[msg.to].obj,{
			type="single",
			text=msg.text,
			from=msg.from,
			nick=UserData[msg.from].nick,
			time=os.date("%X")
		})
	end
end
----------------------------------
-- Server - OnGroupMessage
-- By Joshua
-- At 2013-02-12 22:07:55
----------------------------------
function OnGroupMessage(msg,obj)
	if not msg.from or (msg.from and not LoginData[msg.from]) then
		Send(obj,{
			type="return",
			text="You are offline",
			time=os.date("%X")
		})
	elseif not msg.text or type(msg.text)~="string" then
		Send(obj,{
			type="return",
			text="No text",
			time=os.date("%X")
		})
	else
		Send(obj,{
			type="return",
			time=os.date("%X"),
			text="ok"
		})
		for i,v in pairs(Links) do
			if i~=1 and v~=obj then
				Send(Links[i],{
					type="group",
					text=msg.text,
					nick=UserData[msg.from].nick,
					from=msg.from,
					time=os.date("%X")
				})
			end
		end
	end
end
----------------------------------
-- Server - OnSystemMessage
-- By Joshua
-- At 2013-02-12 23:32:48
----------------------------------
function OnSystemMessage(msg,obj)
	if not msg.from then
		for i,v in pairs(LoginData) do
			if v.obj==obj then
				msg.from=i
				break
			end
		end
	end
	if not msg.text or type(msg.text)~="string" then
		Send(obj,{
			type="return",
			text="No text",
		})
	elseif msg.text=="Login" then
		local ID=tonumber(msg.id)
		local pw=msg.pw
		if not ID or not pw then
			return
		end
		local res=Login(ID,pw)
		if type(res)=="string" then
			LogPrint("用户 "..UserData[ID].nick.." ("..ID..") 登录了。")
			LoginData[ID]={
				nick=res,
				status="online",
				obj=obj,
			}
			Send(obj,{
				type="return",
				text="ok",
				nick=res
			})
			AllSend({
				type="system",
				text="Online",
				user=UserData[ID].nick,
				time=os.date("%X")
			})
		elseif res==-1 then
			Send(obj,{
				type="return",
				text="No data",
			})
		elseif res==-2 then
			Send(obj,{
				type="return",
				text="Password error",
			})
		end
	elseif msg.text=="Register" then
		local nick=msg.nick
		local pw=msg.pw
		if not nick or not pw then
			return
		end
		local ID=Register(nick,pw)
		if type(ID)=="number" then
			LogPrint("用户 "..nick.." ("..ID..") 注册了。")
			LoginData[ID]={
				nick=res,
				obj=obj,
				status="online"
			}
			Send(obj,{
				type="return",
				text="ok",
				id=ID
			})
			AllSend({
				type="system",
				text="Online",
				user=nick,
				time=os.date("%X")
			})
		else
			Send(obj,{
				type="return",
				text="Error",
			})
		end
	elseif msg.text=="GetUserList" then
		local res="Users List:\n\t\t"
		for i,v in pairs(LoginData) do
			res=res..UserData[i].nick.." ("..i..") - "..v.status.."\n\t\t"
		end
		Send(obj,{
			type="system",
			text="UserList",
			list=res,
			time=os.date("%X")
		})
	elseif msg.text=="Leave" then
		LoginData[msg.from].status="leave"
		LogPrint("用户 "..UserData[msg.from].nick.." ("..msg.from..") 离开了。")
		AllSend({
			type="system",
			text="Leave",
			user=UserData[msg.from].nick,
			time=os.date("%X")
		})
	elseif msg.text=="Online" then
		LoginData[msg.from].status="online"
		LogPrint("用户 "..UserData[msg.from].nick.." ("..msg.from..") 上线了。")
		AllSend({
			type="system",
			text="Online",
			user=UserData[msg.from].nick,
			time=os.date("%X")
		})
	elseif msg.text=="GetHelp" then
		Send(obj,{
			type="system",
			text="Help",
			time=os.date("%X"),
			help="系统指令：\n\t\t<online>\t改变状态为在线\n\t\t<leave>\t\t改变状态为离开\n\t\t<logout>\t退出程序\n\t\t<userlist>\t调出在线用户列表\n\t\t<help>\t\t调出本帮助\n\n\t语法规则：\n\t\t1. 普通发送信息默认为群消息，要发送单人消息需要在信息前\n\t\t   加上[#对方号码]。\n\t\t2. 文字允许彩色，方法为[颜色 文本]。颜色列表附后。\n\n\t颜色列表：\n\t\tblack\tblue\tgreen\tlgreen\tred\tpurple\tyellow\twhite\n\t\tgray\tlblue\tlgreen\tlsgreen\tlred\tlpurple\tlyellow\tbwhite\t"
		})
	elseif msg.text=="Dolua" then
		if UserData[msg.from].admin then
			local t={pcall(loadstring(msg.code))}
			local ts=""
			for i=1,table.maxn(t) do
				ts=ts.."[return "..i.."]"..tostring(t[i]).."\n\t"
			end
			Send(obj,{
				type="return",
				text="ok",
				time=os.date("%X"),
				res=ts.."[finished]"
			})
		else
			Send(obj,{
				type="return",
				time=os.date("%X"),
				text="No permission"
			})
		end
	elseif msg.text=="CloseServer" then
		if UserData[msg.from].admin then
			Send(obj,{
				type="return",
				text="ok",
				time=os.date("%X")
			})
			AllSend({
				type="system",
				text="CloseServer",
				user=UserData[msg.from].nick,
				time=os.date("%X")
			})
			os.exit()
		else
			Send(obj,{
				type="return",
				time=os.date("%X"),
				text="No permission"
			})
		end
	end
end
----------------------------------
-- Server - Assert
-- By Joshua
-- At 2013-02-12 22:51:17
----------------------------------
function Assert(obj)
	for i,v in pairs(Links) do
		if i~=1 then
			if obj==v then
				Links[i]=nil
				break
			end
		end
	end
	for i,v in pairs(LoginData) do
		if obj==v.obj then
			LogPrint("用户 "..UserData[i].nick.." ("..i..") 下线了。")
			AllSend({
				type="system",
				text="Offline",
				user=UserData[i].nick,
				time=os.date("%X")
			})
			LoginData[i]=nil
			break
		end
	end
	obj:close()
end
----------------------------------
-- Server - StartServer
-- By Joshua
-- At 2013-02-12 18:38:49
----------------------------------
function StartServer()
	local Server=socket.tcp()
	Server:bind("*",port)
	Server:listen(8)
	Server:settimeout(10)
	table.insert(Links,Server)
	while true do
		local c=socket.select(Links)
		for i,v in ipairs(c) do
			if v==Server then
				table.insert(Links,Server:accept())
				Links[#Links]:settimeout(0)
			else
				local r,s
				while s~="timeout" do
					r,s=v:receive("*l")
					if s=="closed" then
						Assert(v)
						break
					else
						local s=Teadec(coding.debase64(r),StrKey)
						local res=DeJson(s)
						if res then
							if res.type and Registry[res.type] then
								Registry[res.type](res,v)
							else
								LogPrint("发现不支持的类型",res.type)
							end
						end
					end
				end
			end
		end
	end
end
----------------------------------
-- Server - Data
-- By Joshua
-- At 2013-02-10 19:57:58
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
UserData=LoadData("users.ldb")
StrKey=GetKey(key)
LoginData={}
Links={}
Registry={
	single=OnMessage,
	group=OnGroupMessage,
	system=OnSystemMessage
}
----------------------------------
-- Server - Start
-- By Joshua
-- At 2013-02-12 18:39:36
----------------------------------
local _,res=pcall(StartServer)
io.write(res)
local f=io.open("error.log","w")
f:write("|",os.date(),"| ",res)
f:close()