config = require './config.json'
TelegramBot = require 'node-telegram-bot-api'
logics = require './logics.coffee'
crypto = require 'crypto'

mem = {}

token  = config.telegramBot
bot = new TelegramBot token,{polling:true}

bot.onText /\/start$/, (msg)->
	game = {
		host : msg.from
		room : msg.chat
	}
	console.log "Game started on #{game.room.id} by #{game.host.id}"
	hash = crypto.createHash('md5').update(game.host.id.toString()).digest("hex")
	game.logic = logics.newLogic(1,100)
	mem[hash] = game
	bot.sendMessage msg.chat.id, """
		Setting up new Bomb...
		Gathering new logic...
		Bomb is armed
		-------------
		Guess a number between #{game.logic.min} and #{game.logic.max}
		Answer with /answer <your response>
		You have #{game.logic.seconds} seconds left
	"""

bot.onText /\/answer (.*)$/, (msg,match)->
	hash = crypto.createHash('md5').update(msg.chat.id.toString()).digest("hex")
	game = mem[hash]
	return if !game?
	if game.logic.answer is ~~match[1]
		delete mem[hash]
		bot.sendMessage msg.chat.id, "Bomb disarmed! You win"
	else
		if game.logic.answer > ~~match[1]
			bot.sendMessage msg.chat.id, "Nope, go up (you loose 10 seconds)"
		else
			bot.sendMessage msg.chat.id, "Nope, go down (you loose 10 seconds)"
		game.logic.TTL = game.logic.TTL - 10
		mem[hash] = game

timer = false
checkStuff = ->
	clearTimeout(timer) if timer
	now = ~~(new Date().getTime()/1000)
	alive = []
	for own k,game of mem
		if (game.logic.TTL-now)%10 is 0
			bot.sendMessage game.room.id, """
				#{game.logic.TTL-now} Seconds left
			"""
		if game.logic.TTL < now
			bot.sendMessage game.room.id, "Bomb exploded, you all die :("
		else
			alive.push {k:k,game:game}
	mem = {}
	for item in alive
		mem[item.k] = item.game
	timer = setTimeout ->
		checkStuff()
	,1000

checkStuff()