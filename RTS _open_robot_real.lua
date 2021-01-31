function LOGGING(text, param)
	stime = GetInfoParam("SERVERTIME")
	LogFile:write(stime..": "..text..": "..param.."\n")
end

function OnTrade(trade)
	Sec_code = trade["sec_code"]
	Price = math.floor(trade["price"]) --îêðóãëåíèå
	Qty = trade["qty"]	
	LOGGING("Trade is done","Price:"..tostring(Price)..", Quantity:"..tostring(Qty))
end

function get_candles(Identifier, n)
	num = getNumCandles(Identifier)
	t, n, b = getCandlesByIndex(Identifier, 0, num-n, n);
	return t
end

function get_sber_direction(day, month)
	price = get_candles("SBER",2)
	stime = GetInfoParam("SERVERTIME")
	while (price[1]["datetime"]["day"]~=day) or (price[1]["datetime"]["month"]~=month) or (stime~="10:00:00" and stime ~="10:00:01" and stime ~="10:00:02") do
		stime = GetInfoParam("SERVERTIME")
		price = get_candles("SBER",2)
		sleep(10)
	end
	if price[0]["close"]<price[1]["open"] then
		return 1
	end
	if price[0]["close"]==price[1]["open"] then
		return 0
	end
	return -1
end
function get_gazp_direction(day, month)
	price = get_candles("GAZP",2)
	stime = GetInfoParam("SERVERTIME")
	while (price[1]["datetime"]["day"]~=day) or (price[1]["datetime"]["month"]~=month) or (stime~="10:00:00" and stime ~="10:00:01" and stime ~="10:00:02") do --ïðîâåðèòü íîâîå óñëîâèå
		stime = GetInfoParam("SERVERTIME")
		price = get_candles("GAZP",2)
		sleep(10)
	end
	if price[0]["close"]<price[1]["open"] then
		return 1
	end
	if price[0]["close"]==price[1]["open"] then
		return 0
	end
	return -1
end
function get_lkoh_direction(day, month)
	price = get_candles("LKOH",2)
	stime = GetInfoParam("SERVERTIME")
	while (price[1]["datetime"]["day"]~=day) or (price[1]["datetime"]["month"]~=month) or (stime~="10:00:00" and stime ~="10:00:01" and stime ~="10:00:02") do
		stime = GetInfoParam("SERVERTIME")
		price = get_candles("LKOH",2)
		sleep(10)
	end
	if price[0]["close"]<price[1]["open"] then
		return 1
	end
	if price[0]["close"]==price[1]["open"] then
		return 0
	end
	return -1
end

function buy(prc, qty)
	if prc == 0 then
		Transaction = {
			ACCOUNT=Account,
			TYPE="M",
			TRANS_ID=tostring(id),
			CLASSCODE="SPBFUT",
			SECCODE=Seccode,
			ACTION="NEW_ORDER",
			OPERATION="B",
			PRICE="0",
			QUANTITY=tostring(qty)
		}
		ERROR = sendTransaction(Transaction)
		message(ERROR)
		LOGGING("Buy transaction is sent",tostring(ERROR))
		id = id+1
		return 1
	elseif Price ~= 0 then 
		Transaction = {
			ACCOUNT=Account,
			TYPE="M",
			TRANS_ID=tostring(id),
			CLASSCODE="SPBFUT",
			SECCODE=Seccode,
			ACTION="NEW_STOP_ORDER",
			STOP_ORDER_KIND = "TAKE_PROFIT_AND_STOP_LIMIT_ORDER",
			MARKET_STOP_LIMIT = "YES",
			MARKET_TAKE_PROFIT = "YES",
			STOPPRICE = tostring(Price-prc),
			STOPPRICE2 = tostring(Price+2*prc),
			OPERATION="B",
			PRICE="0",
			QUANTITY=tostring(qty)
		}
		ERROR = sendTransaction(Transaction)
		message(ERROR)
		LOGGING("Take-profit and Stop-limit transaction is sent","Take-prof:"..tostring(Price-prc)..", Stop-lim:"..tostring(Price+2*prc))
		id = id+1
		return 2
	end
	return 0
end
function sell(prc, qty)
	if prc == 0 then
		Transaction = {
			ACCOUNT=Account,
			--CLIENT_CODE="XXX",
			TYPE="M",
			TRANS_ID=tostring(id),
			CLASSCODE="SPBFUT",
			SECCODE=Seccode,
			ACTION="NEW_ORDER",
			OPERATION="S",
			PRICE="0",
			QUANTITY=tostring(qty)
		}
		ERROR = sendTransaction(Transaction)
		message(ERROR)
		LOGGING("Sell transaction is sent",tostring(ERROR))

		id = id+1
		return 1
	elseif Price ~= 0 then 
		Transaction = {
			ACCOUNT=Account,
			TYPE="M",
			TRANS_ID=tostring(id),
			CLASSCODE="SPBFUT",
			SECCODE=Seccode,
			ACTION="NEW_STOP_ORDER",
			STOP_ORDER_KIND = "TAKE_PROFIT_AND_STOP_LIMIT_ORDER",
			MARKET_STOP_LIMIT = "YES",
			MARKET_TAKE_PROFIT = "YES",
			STOPPRICE = tostring(Price+prc),
			STOPPRICE2 = tostring(Price-2*prc),
			OPERATION="S",
			PRICE="0",
			QUANTITY=tostring(qty)
		}
		ERROR = sendTransaction(Transaction)
		message(ERROR)
		LOGGING("Take-profit and Stop-limit transaction is sent","Take-prof:"..tostring(Price+prc)..", Stop-lim:"..tostring(Price-2*prc))
		id = id+1
		return 2
	end
	return 0
end

function logic(day, month,prc) 
	sber = -get_sber_direction(day,month) --  ÄËß Si íóæåí ìèíóñ, à äëÿ RI íåò
	LOGGING("Got SBER direction",tostring(sber))

	lkoh = -get_lkoh_direction(day,month) -- ÄËß Si íóæåí ìèíóñ, à äëÿ RI íåò
	LOGGING("Got LKOH direction",tostring(lkoh))

	gazp = -get_gazp_direction(day,month) -- ÄËß Si íóæåí ìèíóñ, à äëÿ RI íåò
	LOGGING("Got GAZP direction",tostring(gazp))

	message(tostring(sber)..tostring(gazp)..tostring(lkoh))
	if (sber==1) and (lkoh==1) and (gazp==1) then
		buy(0, 1)
		while Price==0 do
			sleep(100)
		end
		sell(prc, 1)
		return 1
	end
	if (sber==-1) and (lkoh==-1) and (gazp==-1) then
		sell(0, 1)
		while Price==0 do
			sleep(100)
		end
		buy(prc, 1)
		return -1
	end
	return 0
	
end

function main()
	DAY = 4
	MONTH = 8
	PRC = 50

	LOGGERPATH = "C:\\Buffer\\Trading\\scripts\\RTS_open\\log.log"
	LogFile = io.open(LOGGERPATH, "a")
	LOGGING(tostring(DAY).."."..tostring(MONTH),"")

	id = 1
	Price = 0
	Qty = 0
	Account = ""
	Seccode = "SiU0"

	logic(DAY,MONTH,PRC)
	stime = GetInfoParam("SERVERTIME")
	message(stime)
end
