path = require "path"
ffmpeg = require "fluent-ffmpeg"
async = require "async"

module.exports =
  run: (options, cb) ->
    console.log "encoding options:\n #{JSON.stringify options, false, 4}"

    async.eachSeries options.inputPaths, (videoPath, asyncCb) ->
      if /.*\.DS_Store.*/.test videoPath
        return asyncCb()

      dirname = path.dirname videoPath # name of directory (/path/to/dir/)
      extname = path.extname videoPath # name of extension (.html)
      basename = path.basename videoPath, extname # name of file without extension (the.simpsons.s03e01)

      if not options.outputPath?
        options.outputPath = dirname

      new ffmpeg(source: videoPath)
      .addOptions ["-y"]
      .addOptions ["-c:v", "#{options.videoCodec}"]
      .addOptions ["-filter:v", "scale=#{options.resolution}"]
      .addOptions ["-aspect", "#{options.aspect}"]
      .addOptions ["-preset", "medium"]
      .addOptions ["-b:v", "#{options.videoBitrate}k"]
      .addOptions ["-pass", "1"]
      .addOptions ["-passlogfile", dirname]
      .addOptions ["-c:a", "#{options.audioCodec}"]
      .addOptions ["-b:a", "128k"]
      .addOptions ["-f", "mp4"]

      .on "start", (cmdline) ->
        console.log "Command line pass 1: #{cmdline}"

      .on "progress", (progress) ->
        console.log "progress to encode files pass 1:\n #{JSON.stringify progress, false, 4}"
        console.log basename

      .on "error", (err) ->
        console.log "error pass 1"
        return asyncCb err

      .on "end", ->
        console.log "end pass 1"

        output = "#{path.join options.outputPath, basename}_#{options.videoCodec}_#{options.resolution}_#{options.aspect}_#{options.videoBitrate}k_#{options.audioCodec}#{extname}"

        new ffmpeg(source: videoPath)
        .addOptions ["-c:v", "#{options.videoCodec}"]
        .addOptions ["-filter:v", "scale=#{options.resolution}"]
        .addOptions ["-aspect", "#{options.aspect}"]
        .addOptions ["-preset", "medium"]
        .addOptions ["-b:v", "#{options.videoBitrate}k"]
        .addOptions ["-pass", "2"]
        .addOptions ["-passlogfile", dirname]
        .addOptions ["-c:a", "#{options.audioCodec}"]
        .addOptions ["-b:a", "128k"]

        .on "start", (cmdline) ->
          console.log "Command line pass 2: #{cmdline}"

        .on "progress", (progress) ->
          console.log "progress to encode files pass 2:\n #{JSON.stringify progress, false, 4}"
          console.log basename

        .on "error", (err) ->
          console.log "error pass 2"
          return asyncCb err

        .on "end", ->
          console.log "end pass 2"
          return asyncCb()

        .saveToFile output

      .saveToFile "/dev/null"

    , (err) ->
      if err? and cb?
        return cb err

      if cb?
        cb()
