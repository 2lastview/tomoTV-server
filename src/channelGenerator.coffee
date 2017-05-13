fs = require "fs"
path = require "path"
async = require "async"
ffmpeg = require "fluent-ffmpeg"
ptn = require "parse-torrent-name"
readdir = require "readdir-absolute"
uuidV4 = require("uuid").v4

config = require "../config"

module.exports =
  generate: (cb) ->
    channels = []

    # get every channel path from the public directory
    readdir config.public, (err, channelPaths) ->
      if err?
        return cb err

      # loop over each channel
      async.eachSeries channelPaths, (channelPath, channelCb) ->

        # make sure .DS_Store is ignored
        if /.*\.DS_Store.*/.test channelPath
          fs.unlinkSync channelPath
          return channelCb()

        channel =
          name: path.basename channelPath
          id: uuidV4()
          seed: channelPath
          videos: []
          totalDuration: 0
          totalSize: 0
          cuts: []

        # for each channel directory get all video paths
        readdir channelPath, (err, videoPaths) ->
          if err?
            return channelCb err

          cutsTotal = 0

          # for each video generate metadata
          async.eachSeries videoPaths, (videoPath, videoCb) ->

            # make sure .DS_Store is ignored
            if /.*\.DS_Store.*/.test videoPath
              fs.unlinkSync videoPath
              return videoCb()

            ffmpeg.ffprobe videoPath, (err, metadata) ->
              if err?
                return videoCb err

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