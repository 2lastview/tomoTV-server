express = require "express"
app = express()

config = require "./config"

Seeder = require "./src/seeder"
seeder = new Seeder config.channels

module.exports =
  run: ->
    app.use (req, res, next) ->
      res.header("Access-Control-Allow-Origin", "*")
      res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept")
      next()

    app.get "/channels", (req, res) ->
      res.status(200).json seeder.getSeedingChannels()

    # start seeder
    seeder.start ->
      console.log "done with seeding"
      console.log JSON.stringify config.channels, false, 4

      # start server
      app.listen config.port, ->
        console.log "server started and running on port #{config.port}"


