async = require "async"
Webtorrent = require "webtorrent-hybrid"
client = new Webtorrent()

class Seeder

  constructor: (@channels) ->
    @seedingChannels = []

  start: (cb) ->
    async.eachSeries @channels, (channel, channelCb) =>

      console.log "Start seeding channel: #{channel.name}"

      # seed this folder
      client.seed channel.seed, (torrent) =>
        channel.magnetURI = torrent.magnetURI
        @seedingChannels.push channel

        console.log "Done seeding channel: #{channel.name}"

        channelCb()

    , =>

      console.log "-------------------------------------------"
      console.log JSON.stringify @seedingChannels, false, 4
      console.log "-------------------------------------------"

      cb()

  getSeedingChannels: ->
    return @seedingChannels

module.exports = Seeder
