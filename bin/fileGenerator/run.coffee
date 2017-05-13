fs = require "fs"
path = require "path"
commander = require "commander"
readdir = require "readdir-absolute"

encode = require "./encode"

list = (val) ->
  return val.split ","

commander
.option "-p, --paths <list>", "All videos with paths that should be merged", list, []
.option "-i, --input <path>", "All videos in this folder will be encoded"
.option "-o, --output <path>", "Output folder for all encoded videos"

commander
.command "encode"
.description "encode all video files"
.option "-vc, --video_codec <codec>", "Codec to be used for video encoding"
.option "-ac, --audio_codec <codec>", "Codec to be used for audio encoding"
.option "-vb, --video_bitrate <bitrate>", "Bitrate to be used for video encoding"
.option "-r, --resolution <resolution>", "Resolution to be used for encoding"
.option "-a, --aspect_ratio <aspect>", "Aspect ratio to be used for encoding"
.action (command) ->

  options =
    videoCodec: command["video_codec"] or "libx264"
    audioCodec: command["audio_codec"] or "aac"
    videoBitrate: command["video_bitrate"] or 256
    resolution: command["resolution"] or "-1:480"
    aspect: command["aspect"] or "16:9"

  #
  if commander.paths?.length > 0
    options.videoPaths = commander.paths
    encode.run options, (err) ->
      console.log err

  #
  else if commander.input?
    readdir commander.input, (err, files) ->
      if err?
        throw err

      options.inputPaths = files
      options.outputPath = commander.output

      encode.run options, (err) ->
        console.log err

  #
  else
    readdir __dirname, (err, files) ->
      if err?
        throw err

      options.inputPaths = files
      options.outputPath = commander.output

      encode.run options, (err) ->
        console.log err

commander.parse process.argv
