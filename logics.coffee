random = (min,max)-> ~~(Math.random()*max) + min


exports.newLogic = (min,max)->
	now = ~~(new Date().getTime()/1000)
	seconds = random(60,300)
	return logic = {
		TTL : now + seconds
		seconds : seconds
		answer : random(min,max)
		min : min
		max : max
		resolved : false
	}