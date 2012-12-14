# Description:
#   Integrates with memegenerator.net
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_MEMEGEN_USERNAME
#   HUBOT_MEMEGEN_PASSWORD
#   HUBOT_MEMEGEN_DIMENSIONS
#
# Commands:
#   hubot add meme /<meme regex with two groups>/ <generatorID> <imageID>
#   hubot remove meme /<meme regex>/
#   hubot list memes
#   hubot export memes <format: either "code" or "json">
#   hubot import memes --url=<url>
#   hubot Y U NO <text>  - Generates the Y U NO GUY with the bottom caption of <text>
#   hubot I don't always <something> but when i do <text> - Generates The Most Interesting man in the World
#   hubot <text> ORLY? - Generates the ORLY? owl with the top caption of <text>
#   hubot <text> (SUCCESS|NAILED IT) - Generates success kid with the top caption of <text>
#   hubot <text> ALL the <things> - Generates ALL THE THINGS
#   hubot <text> TOO DAMN <high> - Generates THE RENT IS TOO DAMN HIGH guy
#   hubot good news everyone! <news> - Generates Professor Farnsworth
#   hubot khanify <text> - TEEEEEEEEEEEEEEEEEXT!
#   hubot Not sure if <text> or <text> - Generates Futurama Fry
#   hubot Yo dawg <text> so <text> - Generates Yo Dawg
#   hubot ALL YOUR <text> ARE BELONG TO US - Generates Zero Wing with the caption of <text>
#   hubot if <text>, <word that can start a question> <text>? - Generates Philosoraptor
#   hubot <text> FUCK YOU - Angry Linus
#   hubot (Oh|You) <text> (Please|Tell) <text> - Willy Wonka
#   hubot <text> you're gonna have a bad time - Bad Time Ski Instructor
#   hubot one does not simply <text> - Lord of the Rings Boromir
#
# Author:
#   skalnik

module.exports = (robot) ->

  robot.respond /remove meme \/(.+)\//i, (msg) ->
    setUpMemes robot.brain
    delete robot.brain.data.memes[msg.match[1]]
    msg.reply khanify("Meme deleted")

  robot.respond /(.*)/i, (msg) ->
    setUpMemes robot.brain
    for reg, meme of robot.brain.data.memes
      regex = new RegExp(meme.regex.toString(), "i")
      continue unless regex.test(msg.match[1])
      matches = msg.match[1].match regex
      memeResponder(msg, matches, meme)

  robot.respond /add meme \/(.+)\/\s+(.+)\s+(.+)/i, (msg) ->
    setUpMemes robot.brain
    rememberMeme robot.brain, msg.match[1], parseInt(msg.match[2]), parseInt(msg.match[3])
    msg.reply khanify("Meme added")

  robot.respond /list memes/i, (msg) ->
    setUpMemes robot.brain
    memesList = for reg, meme of robot.brain.data.memes
      meme.regex
    msg.reply memesList.join('\n')

  robot.respond /export memes (code|json)/i, (msg) ->
    setUpMemes robot.brain
    console.log msg.match[1].toLowerCase()
    if msg.match[1].toLowerCase() == 'code'
      memesList = for reg, meme of robot.brain.data.memes
        ["rememberMeme brain, '", meme.regex.replace('\\', '\\\\'), "', ", meme.generatorID, ", ", meme.imageID].join('')
      msg.reply memesList.join('\n')
    else
      msg.reply JSON.stringify(robot.brain.data.memes) + '\n'

  robot.respond /import memes --campfire=(.+)/i, (msg) ->
    filename = msg.match[1]
    filedata = msg.robot.adapter.getUploads
    console.log filedata

  robot.respond /import memes --url=(.+)/i, (msg) ->
    importMemesFromUrl robot, msg, msg.match[1]

  robot.respond /k(?:ha|ah)nify (.*)/i, (msg) ->
    memeGenerator msg, 6443, 1123022, "", khanify(msg.match[1]), (url) ->
      msg.send url

  robot.respond /(IF .*), ((ARE|CAN|DO|DOES|HOW|IS|MAY|MIGHT|SHOULD|THEN|WHAT|WHEN|WHERE|WHICH|WHO|WHY|WILL|WON\'T|WOULD)[ \'N].*)/i, (msg) ->
    memeGenerator msg, 17, 984, msg.match[1], msg.match[2] + (if msg.match[2].search(/\?$/)==(-1) then '?' else ''), (url) ->
      msg.send url

  robot.respond /((Oh|You) .*) ((Please|Tell) .*)/i, (msg) ->
    memeGenerator msg, 542616, 2729805, msg.match[1], msg.match[3], (url) ->
      msg.send url

importMemesFromUrl = (robot, msg, url) ->
  console.log url
  msg.http(url).get() (err, res, body) ->
    importedData = JSON.parse(body)
    for regex, meme of importedData
      robot.brain.data.memes[regex] = meme
    msg.reply khanify("Import successful")


setUpMemes = (brain) ->
  unless brain.data.memes?
    brain.data.memes = {}
    rememberMeme brain, '(Y U NO) (.+)', 2, 166088
    rememberMeme brain, '(I DON\'?T ALWAYS .*) (BUT WHEN I DO,? .*)', 74, 2485
    rememberMeme brain, '(.*)(O\\s?RLY\\??.*)', 920, 117049
    rememberMeme brain, '(.*)(SUCCESS|NAILED IT.*)', 121, 1031
    rememberMeme brain, '(.*) (ALL the .*)', 6013, 1121885
    rememberMeme brain, '(.*) (\\w+\\sTOO DAMN .*)', 998, 203665
    rememberMeme brain, '(GOOD NEWS EVERYONE[,.!]?) (.*)', 1591, 112464
    rememberMeme brain, '(NOT SURE IF .*) (OR .*)', 305, 84688
    rememberMeme brain, '(YO DAWG .*) (SO .*)', 79, 108785
    rememberMeme brain, '(ALL YOUR .*) (ARE BELONG TO US)', 349058, 2079825
    rememberMeme brain, '(.*) (FUCK YOU)', 1189472, 5044147
    rememberMeme brain, '(.*) (You\'?re gonna have a bad time)', 825296, 3786537
    rememberMeme brain, '(one does not simply) (.*)', 274947, 1865027
    rememberMeme brain, 'grumpy cat (.*),(.*)', 1590955, 6541210

rememberMeme = (brain, regex, generatorID, imageID) ->
    meme =
      regex: regex
      generatorID: generatorID
      imageID: imageID
    brain.data.memes[regex] = meme

memeResponder = (msg, matches, meme) ->
  msg.reply "Generating your meme..."
  memeGenerator msg, meme.generatorID, meme.imageID, matches[1], matches[2], (url) ->
    msg.send url

memeGenerator = (msg, generatorID, imageID, text0, text1, callback) ->
  username = process.env.HUBOT_MEMEGEN_USERNAME
  password = process.env.HUBOT_MEMEGEN_PASSWORD
  preferredDimensions = process.env.HUBOT_MEMEGEN_DIMENSIONS

  unless username? and password?
    msg.send "MemeGenerator account isn't setup. Sign up at http://memegenerator.net"
    msg.send "Then ensure the HUBOT_MEMEGEN_USERNAME and HUBOT_MEMEGEN_PASSWORD environment variables are set"
    return

  msg.http('http://version1.api.memegenerator.net/Instance_Create')
    .query
      username: username,
      password: password,
      languageCode: 'en',
      generatorID: generatorID,
      imageID: imageID,
      text0: text0,
      text1: text1
    .get() (err, res, body) ->
      result = JSON.parse(body)['result']
      if result? and result['instanceUrl']? and result['instanceImageUrl']? and result['instanceID']?
        instanceID = result['instanceID']
        instanceURL = result['instanceUrl']
        img = result['instanceImageUrl']
        msg.http(instanceURL).get() (err, res, body) ->
          # Need to hit instanceURL so that image gets generated
          if preferredDimensions?
            callback "http://images.memegenerator.net/instances/#{preferredDimensions}/#{instanceID}.jpg"
          else
            callback "http://images.memegenerator.net/instances/#{instanceID}.jpg"
      else
        msg.reply "Sorry, I couldn't generate that image."

khanify = (msg) ->
  msg = msg.toUpperCase()
  vowels = [ 'A', 'E', 'I', 'O', 'U' ]
  index = -1
  for v in vowels when msg.lastIndexOf(v) > index
    index = msg.lastIndexOf(v)
  "#{msg.slice 0, index}#{Array(10).join msg.charAt(index)}#{msg.slice index}!!!!!"
