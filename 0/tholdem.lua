os.loadAPI("screenDesigner")
local nickname = ""
local monX,monY = screenDesigner.getMonitorSize()
local maxCharLen = 10
local cardDeck = {}
local playerCards = {}
local tableCards = {}
local tableCardAmount = 3
local userMoney = {}
local suits = {"HRT","DMD","SPD","CLB"}
local suitColor = {colors.red,colors.red,colors.black,colors.black}
local specialCards = {"King","Queen","Jack"}
local startMoney = 200
local antey = 200
local difficulty = 1
local num_AI = 1
local onPregame = true
local playing=true
local cardSet = {}
local cardSuitSet = {}
local firstBet = false
local rankResults = {}
local betPlaced = false
local playerFold = false
local potMoney = 0
local playerBets = {}
local AIFold = {}
local needRaise = false
local inputP = ""

function copyTable(ctable)
	local newTable = {}
	
	for k,v in pairs(ctable) do
		newTable[k]=v
	end
	return newTable
end

function notifier()
	term.clear()
	term.setCursorPos(1,1)
	term.write("Texas Holdem - STB")
	term.setCursorPos(1,3)
	screenDesigner.writeText(1,monY,"Please look at computer.",colors.white,colors.cyan)
end

function helpFunc()
	notifier()
	if firstBet then
		cardSetRanker(1)
		print(rankResults[1].." High Card.")
		print(rankResults[2].." Pair(s).")
		print(tostring(rankResults[3]).."  3-of-a-kind.")
		print(tostring(rankResults[4]).." Straight.")
		print(tostring(rankResults[5]).." Flush.")
		print(tostring(rankResults[6]).." Full House.")
		print(tostring(rankResults[7]).." 4-of-a-Kind.")
		print(tostring(rankResults[8]).." Straight Flush.")
		print(tostring(rankResults[9]).." Royal Flush.")
	else
		print("Please place first bet!")
	end
	sleep(4)
	screenDesigner.setWindowState(3,true)
	tableCardsController()
	screenDesigner.writeText(monX-maxCharLen,3,tostring(potMoney))
	screenDesigner.writeText(monX-maxCharLen,2,userMoney[1])
	if firstBet then
		displayBets()
	end
end

function continueFunc()
	onPregame = false
	shuffleDeck()
	
	setup_playerCards()
	setup_tableCards()
	setup_playerMoney()
	for ai=1,num_AI do
		AIFold[ai]=0
	end
	
	for player=1, num_AI+1 do
		playerBets[player]=0
	end
end

function setDifficultyEasy()
	difficulty = 1
end

function setDifficultyHard()
	difficulty = 2
end

function setMoneyStart()
	local updateId = screenDesigner.getUpdateId()
	startMoney = 1000^(updateId-7)
end

function setAntey()
	local updateId = screenDesigner.getUpdateId()
	local anteyLevels = {200,400,800}
	antey = anteyLevels[updateId-4]
end

function setAI()
	num_AI = screenDesigner.getUpdateId()
end

function backFunc()
	joinSession()
	screenDesigner.setWindowStateWithoutDrawing(2,true)
	screenDesigner.newText(1,4,nickname.."'s game.")
	screenDesigner.setWindowState(2,true)
end

function betFunction()
	notifier()
	local playerBet = 0
	print("Please input bet:")
	repeat
		playerBet = io.read()
		playerBet=tonumber(playerBet)
		if playerBet==nil then playerBet=0 end
	until playerBet~=0 and playerBet<userMoney[1]
	
	betPlaced = true
	playerBets[1] = playerBet
end

function check_pairs()
	local tempCardSet = {}
	local numPairs = 0
	local cardPairs = {}
	tempCardSet = copyTable(cardSet)
	for card1=1, #tempCardSet do
		for card2=2,#tempCardSet do
			if tempCardSet[card1] == tempCardSet[card2] and card2~=card1 and tempCardSet[card1] *tempCardSet[card2]~=0  then
				numPairs = numPairs+1
				cardPairs[#cardPairs+1]=tempCardSet[card1]
				tempCardSet[card1],tempCardSet[card2]=0,0
			end
		end
	end
	return numPairs,cardPairs
end

function check_3Kind()
	--check for 3-of-a-kind
	local tempCardSet = {}
	local TcardSet={}
	local hasThreeKind = false
	tempCardSet = copyTable(cardSet)
	table.sort(tempCardSet)
	for card=1,#tempCardSet-2 do
		if tempCardSet[card]==tempCardSet[card+1] and tempCardSet[card]==tempCardSet[card+2] then
			TcardSet[card],TcardSet[card+1],TcardSet[card+2]=tempCardSet[card],tempCardSet[card+1],tempCardSet[card+2]
			hasThreeKind=true
		end
	end
	return hasThreeKind,TcardSet
end

function check_straight()
	local tempCardSet = {}
	local isStraight = false
	local n,cardPairs= check_pairs()
	tempCardSet = copyTable(cardSet)
	
	local p=#tempCardSet
	table.sort(tempCardSet)
	for pair=1,#cardPairs do
		tempCardSet[cardPairs[n]]=0
		n=n-1
	end
	local maxCard = tempCardSet[p]
	local multiplied = 0
	while maxCard >=5 do
		multiplied = maxCard*tempCardSet[p-1]*tempCardSet[p-2]*tempCardSet[p-3]*tempCardSet[p-4]
		if multiplied==(factorial(maxCard)/factorial(maxCard-5)) then
			isStraight = true
			break
		else
			tempCardSet[p]=0
			table.sort(tempCardSet)
			maxCard = tempCardSet[p]
		end
	end
	
	return isStraight,multiplied
end

function check_flush()
	--check for flush
	local tempCardSuitSet = {}
	local isFlush = false
	tempCardSuitSet = copyTable(cardSuitSet)
	table.sort(tempCardSuitSet)
	for card=1, #tempCardSuitSet-4 do
		if tempCardSuitSet[card]==tempCardSuitSet[card+1] and tempCardSuitSet[card]==tempCardSuitSet[card+2] and tempCardSuitSet[card]==tempCardSuitSet[card+3] and tempCardSuitSet[card]==tempCardSuitSet[card+4] then
			isFlush=true
		end
	end
	return isFlush
end

function check_4Kind()
	--check for four-of-a-kind
	local n,cardPairs= check_pairs()
	local fourKind = false
	if cardPairs[1]==cardPairs[2] and cardPairs[1]~=nil then
		fourKind = true
	end
	return fourKind
end

function check_fullHouse()
	--check for full house
	local n,cardPairs= check_pairs()
	local h,TcardSet = check_3Kind()
	local isFullHouse = false
	
	if n>0 and h then
		if TcardSet[1]~=cardPairs[1] or TcardSet[1]~=cardPairs[2] then
			isFullHouse =true
		end
	end
	
	return isFullHouse
end

function check_royalFlush()
	local tempCardSet = {}
	tempCardSet = copyTable(cardSet)
	
	local isFlush = check_flush()
	local multiplied = 0
	local isRoyalFlush = false
	
	local p=#tempCardSet
	table.sort(tempCardSet)
	multiplied = tempCardSet[p]*tempCardSet[p-1]*tempCardSet[p-2]*tempCardSet[p-3]
	
	if isFlush and multiplied==17160 and math.min(unpack(tempCardSet))==1 then
		isRoyalFlush = true
	end
	
	return isRoyalFlush
end

function check_straightFlush()
	local isStraight = check_straight()
	local isFlush = check_flush()
	local isStraightFlush = false
	if isStraight and isFlush then
		isStraightFlush = true
	end
	
	return isStraightFlush
end

function check_highCard()
	--check for high card
	local highCard 
	if math.min(cardSet[1],cardSet[2])==1 then
		highCard="Ace"
	else
		highCard = math.max(cardSet[1],cardSet[2])
		
		if highCard>10 then
		highCard = specialCards[14-highCard]
		end
	end
	return highCard
end

function cardSetRanker(player)
	cardSuitSet[1],cardSet[1] = decypherCard(playerCards[player][1])
	cardSuitSet[2],cardSet[2] = decypherCard(playerCards[player][2])
	for card=1,tableCardAmount do
		cardSuitSet[card+2],cardSet[card+2] =decypherCard(tableCards[card])
	end
	
	for card=1,#cardSet do
		if cardSet[card] == "King" then
			cardSet[card]=13
		elseif  cardSet[card] =="Queen" then
			cardSet[card]=12
		elseif cardSet[card] == "Jack" then
			cardSet[card]=11
		end
		cardSet[card]=tonumber(cardSet[card])
	end
	
	--testing stuff
	--cardSet={1,2,3,9,4,5}
	--cardSuitSet = {1,1,3,4,1,1,1}
	
	rankResults[1] = check_highCard()
	numPairs,cardPairs= check_pairs()
	rankResults[2]=numPairs
	rankResults[3],TcardSet = check_3Kind()
	rankResults[4] = check_straight()
	rankResults[5] = check_flush()
	rankResults[6] = check_fullHouse()
	rankResults[7] = check_4Kind()
	rankResults[8] = check_straightFlush()
	rankResults[9] = check_royalFlush()
end

function factorial(n)
	if n==0 then
		return 1
	else
		return n*factorial(n-1)
	end
end

function foldFunction()
	playerFold = true
end

function raiseFunction()
	raiseController()
end

function setup_playerMoney()
	for player=1,num_AI+1 do
		if player==1 then
			userMoney[player]=startMoney
		else
			userMoney[player]=startMoney*difficulty
		end
	end
end

function playerMoneyController()
	
end

function decypherCard(cardString)
	for suit,card in string.gmatch(cardString,"(.+):(.+)") do
		return tonumber(suit),card
	end
end

function setup_playerCards()
	for player=1,num_AI+1 do
		playerCards[player]={}
		for card=1,2 do
			local randomSuit= math.random(1,4)
			playerCards[player][card]=tostring(randomSuit..":"..cardDeck[randomSuit][1])
			table.remove(cardDeck[randomSuit],1)
		end
	end
end

function setup_tableCards()
	for card=1,5 do
		local randomSuit= math.random(1,4)
		tableCards[card]=tostring(randomSuit..":"..cardDeck[randomSuit][1])
		table.remove(cardDeck[randomSuit],1)
	end
end

function screen_play()
	screenDesigner.setWindowStateWithoutDrawing(3)
	screenDesigner.newText(1,1,"Texas Holdem' - STB",nil,colors.cyan)
	screenDesigner.newText(monX-maxCharLen-7,1,"Player:",nil,colors.red)
	screenDesigner.newText(monX-maxCharLen-7,2,"Money:",nil,colors.red)
	screenDesigner.newText(monX-maxCharLen-1,2,"$",nil,colors.lime)
	screenDesigner.newText(monX-maxCharLen-7,3,"Pot:",nil,colors.purple)
	screenDesigner.newText(monX-maxCharLen-1,3,"$",nil,colors.lime)
	
	--highlight for cards
	screenDesigner.newBackground(1,5,36,13,colors.magenta)
	screenDesigner.newBackground(1,16,15,24,colors.purple)
	
	--information
	screenDesigner.newText(1,15,"Your cards:",colors.black,colors.orange)
	screenDesigner.newText(28,15,"Bets:",colors.black,colors.yellow)
	
	--important buttons raiseFunction
	screenDesigner.newButton(1,nil,"Bet",17,16,25,18,true,nil,colors.lime,colors.red)
	screenDesigner.newButtonFunction(1,betFunction)
	screenDesigner.newButton(2,nil,"Raise",17,19,25,21,true,nil,colors.green,colors.red)
	screenDesigner.newButtonFunction(2,raiseFunction)
	screenDesigner.newButton(3,nil,"Fold",17,22,25,24,false,colors.yellow,colors.gray,colors.red)
	screenDesigner.newButtonFunction(3,foldFunction)
	for button=1,3 do
		screenDesigner.makeFlashButton(button)
	end
	
	--/help button
	screenDesigner.newButton(4,false,"?",1,monY,1,monY,false,colors.black,colors.white,colors.black)
	screenDesigner.makeFlashButton(4)
	screenDesigner.newButtonFunction(4,helpFunc)
	
end

function displayBets()
	local playerN
	for player=1, num_AI+1 do
		if player==1 then
			playerText = "You:"
			playerN=""
		else
			playerText = "AI:"
			playerN = tostring(player-1)
		end
		screenDesigner.writeText(28,14+2*player,playerText..playerN.." $"..playerBets[player],colors.black,colors.red)
	end
end

function betController()
	local param1,param2,aBet = 0
	local playerBet = playerBets[1]
	userMoney[1]=userMoney[1]-playerBet
	
	for ai=1,num_AI do
		local A = math.random(1,15)
		local B = math.random(1,15)
		if A>9 then
			param1=playerBet
		else
			param1=playerBet+math.random(1,10)
		end
		if B<=8 then
			aBet=param1
		elseif B>8 and B<=13 then
			param2=math.random(playerBet,userMoney[ai])
			aBet = math.random(param1,param2)
		elseif B>13 then
			AIFold[ai]=1
		end
		
		playerBets[ai]=aBet
		potMoney = potMoney+aBet
		--sleep(math.random(1,5))
	end
	potMoney = potMoney+playerBet
end

function raiseController()
	for player=2,num_AI+1 do
		if playerBets[player]~=playerBets[player+1] and playerBets[player+1]~=nil then
			local A = math.random(1,50)
			if A>=25 then
				playerBets[player+1]=playerBets[player]
			else
				playerBets[player]=playerBets[player+1]
			end
		end
	end
	if playerBets[1]<playerBets[2] then
		inputRaise(playerBets[2]-playerBets[1])
	end
end

function input()
	inputP=io.read()
end

function inputRaise(raise)
	local playerRaise
	notifier()
	print("Please input raise of $"..raise.." or Fold.")
	repeat
		parallel.waitForAny(input,screenDesigner.testTouch)
		local updateId = screenDesigner.getUpdateId
		playerRaise=inputP
	until playerRaise==tostring(raise) or updateId==3
	potMoney = potMoney+playerRaise
end

function gameController()
	--go through each player and place bet
	betPlaced=false
	screenDesigner.buttonsEditor(1, "invisibleButton", false)
	screenDesigner.buttonsEditor(2, "invisibleButton", true)
	while true and not playerFold do
		screenDesigner.testTouch()
		local updateId = screenDesigner.getUpdateId()
		if playerFold then
			break
		end
		if updateId~=4 then
			betController()
			screenDesigner.buttonsEditor(1, "invisibleButton", true)
			screenDesigner.buttonsEditor(2, "invisibleButton", false)
			raiseController()
			break
		end
	end
end

function window_setup_tableCards()
	local add=0
	for card=0, 4 do
		add=card*2
		screenDesigner.newBackground(2+card*5+add,6,7+card*5+add,12,colors.white) --draws table cards
		--draw table card traits
		local card_suit,card_num = decypherCard(tableCards[card+1])
		screenDesigner.newText(2+card*7,6,suits[card_suit],colors.white,suitColor[card_suit])
		screenDesigner.newText(5+card*7,12,suits[card_suit],colors.white,suitColor[card_suit])
		if card_num=="1" then card_num="Ace" end
		screenDesigner.newText(2+card*5+add+ math.floor((5 - string.len(card_num)) /2) +1,9,card_num,colors.white,suitColor[card_suit])
	end
end

function window_setup_playerCards()
	local add=0
	for card=0, 1 do
		add=card*2
		screenDesigner.newBackground(2+card*5+add,17,7+card*5+add,23,colors.white) --draws player cards
		--draw player card traits
		local card_suit,card_num = decypherCard(playerCards[1][card+1])
		screenDesigner.newText(2+card*7,17,suits[card_suit],colors.white,suitColor[card_suit])
		screenDesigner.newText(5+card*7,23,suits[card_suit],colors.white,suitColor[card_suit])
		if card_num=="1" then card_num="Ace" end
		screenDesigner.newText(2+card*5+add+ math.floor((5 - string.len(card_num)) /2) +1,20,card_num,colors.white,suitColor[card_suit])
	end
end

function tableCardsController()
	local add=0
	for card=tableCardAmount,4 do
		add=card*2
		screenDesigner.writeBackground(2+card*5+add,6,7+card*5+add,12,colors.magenta)
	end
	if not firstBet then
		screenDesigner.writeBackground(1,5,36,13,colors.magenta)
	end
end

function screen_gameSetup()
	screenDesigner.setWindowStateWithoutDrawing(2)
	screenDesigner.newText(1,1,"Texas Holdem' - STB",nil,colors.cyan)
	screenDesigner.newText(1,3,"Customize Game:",nil,colors.lime)
	screenDesigner.newBackground(1,5,39,22,colors.cyan)
	
	screenDesigner.newText(1,7,"Amount of AI:",colors.cyan)
	screenDesigner.newButton(1,true,tostring(1),15,7,17,7,false,colors.red,colors.black,colors.lime)
	screenDesigner.buttonToggleHandler(1,1)
	screenDesigner.newButtonFunction(1,setAI)
	for button=2, 4 do
		screenDesigner.newButton(button,false,tostring(button),11+button*4,7,13+button*4,7,false,colors.red,colors.black,colors.lime)
		screenDesigner.buttonToggleHandler(button,1)
		screenDesigner.newButtonFunction(button,setAI)
	end
	
	screenDesigner.newText(1,11,"Antey Amount:",colors.cyan)
	for button=1, 2 do
		if button ==1 then state = true else state = false end
		screenDesigner.newButton(button+4,state,tostring("$"..200*button),8+button*7,11,13+button*7,11,false,colors.red,colors.black,colors.lime)
		screenDesigner.buttonToggleHandler(button+4,2)
		screenDesigner.newButtonFunction(button+4,setAntey)
	end
	screenDesigner.newButton(7,false,tostring("$"..800),29,11,33,11,false,colors.red,colors.black,colors.lime)
	screenDesigner.buttonToggleHandler(7,2)
	screenDesigner.newButtonFunction(7,setAntey)
	
	screenDesigner.newText(1,19,"Start Amount:",colors.cyan)
	for button =1, 2 do
		if button ==1 then state = true else state = false end
		screenDesigner.newButton(7+button,state,tostring("$"..1000^button),4+button*11,19,13+button*11,19,false,colors.red,colors.black,colors.lime)
		screenDesigner.buttonToggleHandler(7+button,3)
		screenDesigner.newButtonFunction(button+7,setMoneyStart)
	end
	
	screenDesigner.newText(1,15,"AI Difficulty:",colors.cyan)
	screenDesigner.newButton(10,true,"Easy",15,15,20,15,false,colors.red,colors.black,colors.lime)
	screenDesigner.newButtonFunction(10,setDifficultyEasy)
	screenDesigner.buttonToggleHandler(10,4)
	
	screenDesigner.newButton(11,false,"Hard",22,15,27,15,false,colors.red,colors.black,colors.lime)
	screenDesigner.newButtonFunction(11,setDifficultyHard)
	screenDesigner.buttonToggleHandler(11,4)
	
	--/continue button
	screenDesigner.newButton(12,false,"Continue ->",29,22,monX,22,false,colors.purple,colors.white,colors.yellow)
	screenDesigner.makeFlashButton(12)
	screenDesigner.newButtonFunction(12,continueFunc)
	
	--/back button
	screenDesigner.newButton(13,false,"<- Back",1,22,7,22,false,colors.purple,colors.white,colors.yellow)
	screenDesigner.makeFlashButton(13)
	screenDesigner.newButtonFunction(13,backFunc)
end

function screen_welcome()
	screenDesigner.setWindowStateWithoutDrawing(1)
	screenDesigner.newText(1,1,"Texas Holdem' - STB",nil,colors.cyan)
	screenDesigner.newText(10,7,"Welcome!",nil,colors.white)
	screenDesigner.newText(10,10,"Nickname:",nil,colors.white)
	screenDesigner.newText(10,11,"-Type on Computer :)",nil,colors.white)
	screenDesigner.newText(1,monY,"Max character length:"..maxCharLen,nil,colors.cyan)
end

function screenData()
	screen_welcome()
	screen_gameSetup()
	screen_play()
end

function joinSession()
	while true do
		screenDesigner.setWindowState(1,true)
		term.clear()
		term.setCursorPos(1,1)
		term.write("Please input your nickname:")
		term.setCursorPos(1,2)
		nickname=io.read() 
		screenDesigner.writeText(19,10,nickname,colors.gray,colors.yellow)
		
		if string.len(nickname)>maxCharLen or nickname== "" then
			term.setCursorPos(1,3)
			local info
			if nickname =="" then
				info="No nickname entered."
			else
				info="has too many characters."
			end
			term.write(nickname..info)
			if string.len(nickname..info)>=monX-12 then
				screenDesigner.writeText(10,12,nickname,colors.white,colors.red)
				screenDesigner.writeText(10,13,info,colors.white,colors.red)
			else
				screenDesigner.writeText(10,12,nickname..info,colors.white,colors.red)
			end
			sleep(4)
			nickname = ""
		else
			break
		end
	end
	--waits so you can read it. just cool feature I guess
	for t=1,2 do
		screenDesigner.writeText(math.floor((monX -2+t*2)/2),12,".")
		sleep(1.3)
	end
end

function shuffleDeck()
	local tempDeck = {}
	for suit=1,4 do
		cardDeck[suit]={}
		--makes cards
		for card=1,13 do
			if card>10 then
				value = specialCards[14-card]
			else
				value = card
			end
			cardDeck[suit][card]=value
		end
		
		for flips=1,100 do
			local spotA= math.random(8,13)
			local spotB= math.random(1,7)
			local tempVar = cardDeck[suit][spotA]
			cardDeck[suit][spotA] = cardDeck[suit][spotB]
			cardDeck[suit][spotB] = tempVar
		end
		
	end
end

function game()
	screenData()
	joinSession()
	screenDesigner.setWindowStateWithoutDrawing(2,true)
	screenDesigner.newText(1,4,nickname.."'s game.")
	screenDesigner.setWindowState(2,true)
	while onPregame do
		screenDesigner.testTouch()
	end
	prePlay()
	play()
end

function prePlay()
	screenDesigner.setWindowStateWithoutDrawing(3)
	screenDesigner.newText(monX-maxCharLen,1,nickname)
	screenDesigner.newText(monX-maxCharLen,2,tostring(startMoney))
	window_setup_playerCards()
	window_setup_tableCards()
	screenDesigner.newText(monX-maxCharLen,3,"0")
end

function play_firstRound()
	firstBet = false
	screenDesigner.setWindowState(3,true)
	tableCardsController()
	gameController()
	firstBet = true
	screenDesigner.setWindowState(3,true)
	tableCardsController()
end

function play_normalRound()
	for round=1,2 do
		gameController()
		screenDesigner.setWindowState(3,true)
		displayBets()
		screenDesigner.writeText(monX-maxCharLen,3,potMoney)
		screenDesigner.writeText(monX-maxCharLen,2,userMoney[1])
		tableCardAmount=tableCardAmount+1
		tableCardsController()
	end
end

function play()
	play_firstRound()
	screenDesigner.writeText(monX-maxCharLen,3,potMoney)
	screenDesigner.writeText(monX-maxCharLen,2,userMoney[1])
	displayBets()
	play_normalRound()
	determineVictor()
end

function determineVictor()
	helpFunc()
end

game()
