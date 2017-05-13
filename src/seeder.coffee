async = require "async"
Webtorrent = require "webtorrent-hybrid"
client = new Webtorrent()

class Seeder

  constructor: (@channels) ->
    @seedingChannels = []

  start: (cb) ->
    console.log @channels

    async.eachSeries @channels, (channel, channelCb) =>

      console.log channel

      # seed this folder
      client.seed channel.seed, (torrent) =>

        console.log torrent

        channel.magnetURI = torrent.magnetURI
        @seedingChannels.push channel
        channelCb()

    , =>
      console.log @seedingChannels
      cb()

  getSeedingChannels: ->
    return @seedingChannels

module.exports = Seeder
