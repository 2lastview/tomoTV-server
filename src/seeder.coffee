os_path = require "path"
async = require "async"
Webtorrent = require "webtorrent-hybrid"
client = new Webtorrent()

class Seeder

  constructor: (@channels) ->
    @seedingChannels = []

  start: (cb) ->
    async.eachSeries @channels, (channel, channelCb) =>

      # seed this folder
      client.seed channel.seed, (torrent) =>
        channel.magnetURI = torrent.magnetURI
        @seedingChannels.push channel
        channelCb()

    , =>
      cb()

  getSeedingChannels: ->
    return @seedingChannels

module.exports = Seeder
