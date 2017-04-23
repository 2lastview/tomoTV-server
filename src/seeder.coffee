os_path = require "path"
async = require "async"
Webtorrent = require "webtorrent-hybrid"
client = new Webtorrent()

class Seeder

  constructor: (@channels) ->
    @seedingChannels = []

  start: (cb) ->
    async.eachSeries @channels, (channel, channelCb) =>
      result =
        name: channel.name
        seeds: []

      path = channel.path

      # seed each file in seeds
      async.eachSeries channel.seeds, (seed, seedCb) =>
        # get the folder where the files are
        folder = os_path.join path, seed.folder

        # get video file path
        # video = os_path.join folder, seed.video
        # meta = os_path.join folder, seed.meta

        # seed this folder
        client.seed folder, (torrent) =>
          result.seeds.push
            name: seed.name
            magnetURI: torrent.magnetURI

          seedCb()
      , =>
        @seedingChannels.push result
        channelCb()
    , =>
      cb()

  getSeedingChannels: ->
    return @seedingChannels

module.exports = Seeder
