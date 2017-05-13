fs = require "fs"
path = require "path"
async = require "async"
ffmpeg = require "fluent-ffmpeg"
ptn = require "parse-torrent-name"

PUBLIC = "/Users/moritztomasi/Code/tomoTV-server/public"

module.exports =
  generate: (cb) ->
    channels = []

    async.eachSeries fs.readdirSync(PUBLIC), (channelPath, channelCb) ->

      if /.*\.DS_Store.*/.test channelPath
        fs.unlinkSync path.join PUBLIC, channelPath
        return channelCb()

      channel =
        name: path.basename(channelPath)
        id: path.basename(channelPath).replace(/\s/g, "").toLowerCase()
        seed: path.join PUBLIC, channelPath
        videos: []
        totalDuration: 0
        totalSize: 0
        cuts: []

      cutsTotal = 0

      async.eachSeries fs.readdirSync(path.join PUBLIC, channelPath), (videoPath, videoCb) ->

        if /.*\.DS_Store.*/.test videoPath
          fs.unlinkSync path.join(PUBLIC, channelPath, videoPath)
          return videoCb()

        ffmpeg.ffprobe path.join(PUBLIC, channelPath, videoPath), (err, metadata) ->
          if err?
            return cb err

          video =
            filename: path.basename videoPath
            metadata: metadata.format
            extracted: ptn path.basename(videoPath)

          channel.totalDuration += video.metadata.duration
          channel.totalSize += video.metadata.size
          cutsTotal += video.metadata.duration
          channel.cuts.push cutsTotal

          channel.videos.push video
          videoCb()

      , (err) ->
        if err?
          return channelCb err

        channels.push channel
        channelCb()

    , (err) ->
      if err?
        return cb err

      cb null, channels
