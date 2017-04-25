express = require "express"
app = express()

config = require "./config"

Seeder = require "./src/seeder"

channelGenerator = require "./src/channelGenerator"

module.exports =
  run: ->
    # generate channels
    channelGenerator.generate (err, channels) ->
      if err?
        throw err

      # start seeder
      seeder = new Seeder channels
      seeder.start ->

        # create routes
        app.use (req, res, next) ->
          res.header("Access-Control-Allow-Origin", "*")
          res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept")
          next()

        app.get "/channels", (req, res) ->
          res.status(200).json seeder.getSeedingChannels()

        # start server
        app.listen config.port, ->
          console.log "server started and running on port #{config.port}"


