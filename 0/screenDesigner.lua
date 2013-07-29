--Kulopto @ Youtube /~ Steel_Toed_Boot

local sideDetect = false
updateId=nil
buttons ={}
backgroundData = {}
local buttonToggle = {}
local buttonFlash = {}
local windowStateId = 1
local lastBackgroundId = {}
local buttonFunc = {}

--peripheral scanner
function checkPeripheral()
	for i,side in pairs(rs.getSides()) do
		if peripheral.getType(side) =="monitor" then
			m=peripheral.wrap(side)
			sideDetect = true
			print("Monitor found on side "..side)
			break
		end
	end
	if sideDetect == false then
			print("No Monitor Detected.. waiting for 5 seconds")
			return false
	end
end

--Makes the screen and monitor ready for use. 
function housekeeping()
	repeat
		checkPeripheral()
		if not sideDetect then sleep(5) end
	until sideDetect
  m.clear()
  m.setTextScale(1)
  m.setBackgroundColor(colors.black)
  m.setTextColor(colors.white)
end

--this is the only local run function and is not necessarily required but recommended.
housekeeping()



function clearScreen()
	m.clear()
	local x,y = getMonitorSize()
	screenDesigner.writeBackground(1,1,x,y,colors.black)
end

function getMonitorSize()
	return m.getSize()
end

function setWindowState(id,clearScreenBool)
	if clearScreenBool then clearScreen() end
	windowStateId = id
	
	if backgroundData[windowStateId]~=nil then
		for i=1, #backgroundData[windowStateId] do
			drawBackground(i)
		end
	end
	
	if buttons[windowStateId]~=nil then
		for i=1,#buttons[windowStateId] do
			drawButton(i)
		end
	end
end

function setWindowStateWithoutDrawing(id)
	windowStateId = id
end

function getButtons()
	return buttons
end

function getBackgroundData()
	return backgroundData
end

function getUpdateId()
	return updateId
end

function newButtonFunction(id,func)
	buttonFunc[id]=func
end


--Button stuff
function drawButton(buttonId)
	local state = buttons[windowStateId][buttonId]["state"]
	local xmin = buttons[windowStateId][buttonId]["xmin"]
	local ymin = buttons[windowStateId][buttonId]["ymin"]
	local xmax = buttons[windowStateId][buttonId]["xmax"]
	local ymax = buttons[windowStateId][buttonId]["ymax"]
	local text = buttons[windowStateId][buttonId]["text"]
	local tColor = buttons[windowStateId][buttonId]["tColor"]
	local bColorOff = buttons[windowStateId][buttonId]["bColor1"]
	local bColorOn = buttons[windowStateId][buttonId]["bColor2"]
	local invisibleButton = buttons[windowStateId][buttonId]["invisibleButton"]
	local textAlignedLeft = buttons[windowStateId][buttonId]["textAlignedLeft"] 
	local textAlignedRight = buttons[windowStateId][buttonId]["textAlignedRight"]
	
	local xpoint = xmin+ math.floor((xmax - xmin - string.len(text)) /2) +1
	local ypoint = math.floor((ymin+ymax)/2)
	
	if not invisibleButton then
		if not state then
			m.setBackgroundColor(bColorOff)
		elseif state then
			m.setBackgroundColor(bColorOn)
		end

    --draws the actual button
		for y=ymin, ymax do
			for x=xmin, xmax do
				m.setCursorPos(x,y)
				m.write(" ")
			end
		end
		
	--draws text
		m.setCursorPos(xpoint,ypoint)
		m.setTextColor(tColor)
		m.write(text)
		
		if textAlignedLeft ~=nil then
			m.setCursorPos(xmin,ypoint)
			m.write(textAlignedLeft)
		end
		if textAlignedRight ~=nil then
			m.setCursorPos(xmax-string.len(textAlignedRight),ypoint)
			m.write(textAlignedRight)
		end
		
		m.setBackgroundColor(colors.black)
	end
end

function newButton(buttonId,state,text,xmin,ymin,xmax,ymax,invisibleButton,tColor,bColorOff,bColorOn,textAlignedLeft,textAlignedRight)
	
	if buttonToggle[windowStateId]==nil then buttonToggle[windowStateId]={} end
	if buttonToggle[windowStateId][buttonId] ==nil then buttonToggleHandler(buttonId, -8*buttonId) end
	
	if buttonFlash[windowStateId]==nil then buttonFlash[windowStateId]={} end
	if buttonFlash[windowStateId][buttonId] == nil then buttonFlash[windowStateId][buttonId] = false end
	
	if buttons[windowStateId] == nil then buttons[windowStateId] ={} end
	
	buttons[windowStateId][buttonId] = {}
	buttons[windowStateId][buttonId]["state"] = state or false
	buttons[windowStateId][buttonId]["xmin"] = xmin
	buttons[windowStateId][buttonId]["ymin"] = ymin
	buttons[windowStateId][buttonId]["xmax"] = xmax
	buttons[windowStateId][buttonId]["ymax"] = ymax
	buttons[windowStateId][buttonId]["text"] = text
	buttons[windowStateId][buttonId]["tColor"] = tColor or colors.white
	buttons[windowStateId][buttonId]["bColor1"] = bColorOff or colors.red
	buttons[windowStateId][buttonId]["bColor2"] = bColorOn or colors.green
	buttons[windowStateId][buttonId]["invisibleButton"] = invisibleButton or false
	buttons[windowStateId][buttonId]["textAlignedLeft"]  = textAlignedLeft or nil
	buttons[windowStateId][buttonId]["textAlignedRight"] = textAlignedRight or nil
	newButtonFunction(buttonId,func)
end

function func()
	print("button id:"..updateId.."pressed")
end

function buttonToggleHandler(buttonId, toggleId)
	buttonToggle[windowStateId][buttonId] = toggleId
end

function makeFlashButton(buttonId)
	buttonFlash[windowStateId][buttonId]=true
end

function buttonsEditor(buttonId, data, newValue,keepState)
	keepState = keepState or true
	if keepState then buttons[windowStateId][buttonId]["state"]=not buttons[windowStateId][buttonId]["state"] end
	buttons[windowStateId][buttonId][data] = newValue
	updateButtons(buttonId)
end


--Background and text stuff
function newBackground(xmin,ymin,xmax,ymax,bColor,tColor,text,xpoint,ypoint,fontScale)
	if lastBackgroundId[windowStateId] == nil then lastBackgroundId[windowStateId] =0 end
	
	local id = lastBackgroundId[windowStateId] +1
	lastBackgroundId[windowStateId] = lastBackgroundId[windowStateId]+1
	
	if backgroundData[windowStateId] == nil then backgroundData[windowStateId] ={} end
	
	text=text or ""
	backgroundData[windowStateId][id] = {}
	backgroundData[windowStateId][id]["xmin"] = xmin
	backgroundData[windowStateId][id]["ymin"] = ymin
	backgroundData[windowStateId][id]["xmax"] = xmax
	backgroundData[windowStateId][id]["ymax"] = ymax
	backgroundData[windowStateId][id]["bColor"] = bColor
	backgroundData[windowStateId][id]["tColor"] = tColor or colors.white
	backgroundData[windowStateId][id]["text"] = text or ""
	backgroundData[windowStateId][id]["xpoint"] = xpoint or xmin+ math.floor((xmax - xmin - string.len(text)) /2) +1 or 1
	backgroundData[windowStateId][id]["ypoint"] = ypoint or ymin or 1
	backgroundData[windowStateId][id]["fontScale"] = fontScale or 1
end

function newText(x,y,text,bgColor,textColor,fontScale)
	bgColor = bgColor or colors.black
	newBackground(x,y,x,y,bgColor,textColor,text,x,y,fontScale)
end

function writeText(xpoint,ypoint,text,bgColor,textColor,fontScale)
	bgColor = bgColor or colors.black
	textColor = textColor or colors.white
	fontScale = fontScale or 1
	m.setBackgroundColor(bgColor)
	m.setTextColor(textColor)
	m.setTextScale(fontScale)
	
	m.setCursorPos(xpoint,ypoint)
	m.write(text)
end

function writeBackground(xmin,ymin,xmax,ymax,bColor,tColor,text,xpoint,ypoint,fontScale)
	local tColor = tColor or colors.white
	local text = text or ""
	local xpoint = xpoint or xmin+ math.floor((xmax - xmin - string.len(text)) /2) +1
	local ypoint = ypoint or ymin
	local fontScale = fontScale or 1
	
	m.setBackgroundColor(bColor)
	for y=ymin, ymax do
		for x=xmin, xmax do
			m.setCursorPos(x,y)
			m.write(" ")
		end
	end
  
	--draws header if given respected values (text, xpoint, ypoint)
	m.setTextScale(fontScale)
	m.setCursorPos(xpoint,ypoint)
	m.setTextColor(tColor)
	m.write(text)
end

function drawBackground(id)
	local xmin = backgroundData[windowStateId][id]["xmin"]
	local ymin = backgroundData[windowStateId][id]["ymin"]
	local xmax = backgroundData[windowStateId][id]["xmax"]
	local ymax = backgroundData[windowStateId][id]["ymax"]
	local bColor = backgroundData[windowStateId][id]["bColor"]
	local tColor = backgroundData[windowStateId][id]["tColor"]
	local text = backgroundData[windowStateId][id]["text"]
	local xpoint = backgroundData[windowStateId][id]["xpoint"]
	local ypoint = backgroundData[windowStateId][id]["ypoint"]
	local fontScale = backgroundData[windowStateId][id]["fontScale"]
	
	writeBackground(xmin,ymin,xmax,ymax,bColor,tColor,text,xpoint,ypoint,fontScale)
end



--Technical stuff
function testTouch()
	event,side,x,y = os.pullEvent("monitor_touch")
	--checks if touch was within button boundaries
	if #buttons[windowStateId] ~=nil then
	
	for buttonId=1, #buttons[windowStateId] do
		if buttons[windowStateId][buttonId]["ymin"]<=y and buttons[windowStateId][buttonId]["ymax"]>=y then
			if buttons[windowStateId][buttonId]["xmin"]<=x and buttons[windowStateId][buttonId]["xmax"]>=x then
				updateButtons(buttonId)
				updateId = buttonId
				
				if buttonFlash[windowStateId][updateId] then
					sleep(.2) 
					updateButtons(updateId)
				end
				
				buttonFunc[buttonId]()
				
			end
		end
	end
	
	end
end

function updateButtons(buttonId)
	if buttonId ~= nil then
		buttons[windowStateId][buttonId]["state"] = not buttons[windowStateId][buttonId]["state"]
		for id=1, #buttons[windowStateId] do
			if buttonToggle[windowStateId][id] == buttonToggle[windowStateId][buttonId] and id ~= buttonId then
				buttons[windowStateId][id]["state"] = false
			end
			drawButton(id)
		end
	end
end
