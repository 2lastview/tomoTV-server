fs = require "fs"
path = require "path"
async = require "async"
commander = require "commander"
ffmpeg = require "fluent-ffmpeg"
ptn = require "parse-torrent-name"

# ------------- utils ------------- #

_fullPaths = (p, filenames) ->
  paths = []
  for filename in filenames
    paths.push path.join(p, filename)

  return paths

# ------------- encode ------------- #

__encode = (options, cb) ->
  console.log "encoding options:\n #{JSON.stringify options, false, 4}"

  async.eachSeries options.videoPaths, (videoPath, asyncCb) ->
    if /.*\.DS_Store.*/.test videoPath
      return asyncCb()

    dirname = path.dirname videoPath
    extname = path.extname videoPath
    basename = path.basename videoPath, extname

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

      output = "#{path.join dirname, basename}_#{options.videoCodec}_#{options.resolution}_#{options.aspect}#{options.videoBitrate}k_#{options.audioCodec}#{extname}"

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
    if err?
      return cb err

    cb()

# ------------- merge ------------- #

__createTsFiles = (videoPaths, cb) ->
  inputTsFiles = []
  async.eachSeries videoPaths, (videoPath, asyncCb) ->
    tmpFile = "#{videoPath}.ts"
    inputTsFiles.push tmpFile

    ffmpeg()

      .on "start", (cmdline) ->
        console.log "Command line: #{cmdline}"

      .on "progress", (progress) ->
        console.log "progress ts files:\n #{JSON.stringify progress, false, 4}"

      .on "error", (err) ->
        return asyncCb err

      .on "end", ->
        return asyncCb()

      .input videoPath
      .output tmpFile
      .videoCodec "libx264"
      .audioCodec "copy"
      .size "640x?"
      .run()
  , (err) ->
    if err?
      return cb err

    cb null, inputTsFiles

__concat = (videoPaths, outputPath, cb) ->
  inputNamesFormatted = "concat:#{videoPaths.join('|')}"

  ffmpeg()

    .on "start", (cmdline) ->
      console.log "Command line: #{cmdline}"

    .on "progress", (progress) ->
      console.log "progress concat:\n #{JSON.stringify progress, false, 4}"

    .on "error", (err) ->
      return cb err

    .on "end", ->
      return cb()

    .input inputNamesFormatted
    .output outputPath
    .videoCodec "copy"
    .audioCodec "copy"
    .run()

# ------------- meta ------------- #

__getVideoMeta = (videoPaths, mergedPath, cb) ->
  meta = []
  mergedMeta = null
  async.eachSeries videoPaths, (videoPath, asyncCb) ->
    ffmpeg.ffprobe videoPath, (err, metadata) ->
      if err?
        return asyncCb err

      if videoPath isnt mergedPath
        meta.push metadata.format
      else
        mergedMeta = metadata.format
      asyncCb()
  , (err) ->
    if err?
      return cb err

    cb null, {singleFiles: meta, mergedFile: mergedMeta}

__processVideoMeta = (meta) ->

  # process meta single parts and aggregate data
  cutsTotal = 0
  cuts = []
  for m in meta.singleFiles

    # remove path from filename
    m.filename = path.basename m.filename

    # analyze filename: get season, get episode
    m.extracted = ptn m.filename

    # create cuts
    cutsTotal += m.duration
    cuts.push cutsTotal

    # TODO: enrich data with some api

  # process merged metadata
  # remove path from filename
  meta.mergedFile.filename = path.basename meta.mergedFile.filename

  # add aggregated data from loop
  meta.cuts = cuts

  return meta

# ------------- commands ------------- #

merge = (videoPaths, outputPath) ->
  if not outputPath?
    outputPath = "./merged.mp4"

  __createTsFiles videoPaths, (err, tsFiles) ->
    if err?
      return console.log "ERROR in __createTsFiles:", err.message

    __concat tsFiles, outputPath, (err) ->
      if err?
        return console.log "ERROR in __concat:", err.message

meta = (videoPaths, mergedPath, outputPath) ->
  __getVideoMeta videoPaths, mergedPath, (err, meta) ->
    if err?
      return console.log "ERROR in __getMeta:", err.message

    meta = __processVideoMeta meta

    if outputPath?
      fs.writeFileSync outputPath, JSON.stringify(meta, false, 4)
    else
      console.log JSON.stringify meta, false, 4

    console.log "finished generating meta file at #{outputPath}"

encode = (options) ->
  __encode options, (err) ->
    if err?
      return console.log "ERROR in __encode:", err.message

# ------------- commander ------------- #

list = (val) ->
  return val.split ","

commander
.option "-p, --paths <list>", "All videos with paths that should be merged", list, []
.option "-f, --folder <path>", "All videos in this path will be merged"
.option "-o, --output <path>", "Output path for merged video"

commander
.command "merge"
.description "merge all video files to one single video"
.action ->

  #
  if commander.folder?
    files = fs.readdirSync commander.folder
    merge _fullPaths(commander.folder, files), commander.output

  #
  else if commander.paths?.length > 0
    merge commander.paths, commander.output

  #
  else
    files = fs.readdirSync __dirname
    merge _fullPaths(__dirname, files), commander.output

commander
.command "meta"
.description "get meta information on all videos"
.option "-mp, --merged_path <path>", "Path to the merged video"
.action (command) ->

  #
  if commander.folder?
    files = fs.readdirSync commander.folder
    meta _fullPaths(commander.folder, files), command.merged_path, commander.output

  #
  else if commander.paths?.length > 0
    meta commander.paths, command.merged_path, commander.output

  #
  else
    files = fs.readdirSync __dirname
    meta _fullPaths(__dirname, files), command.merged_path, commander.output

commander
.command "encode"
.description "encode all video files"
.option "-vc, --video_codec <codec>", "Codec to be used for video encoding"
.option "-ac, --audio_codec <codec>", "Codec to be used for audio encoding"
.option "-r, --resolution <resolution>", "Resolution to be used for encoding"
.option "-a, --aspect <aspect>", "Aspect ratio to be used for encoding"
.option "-vb, --video_bitrate <bitrate>", "Bitrate to be used for video encoding"
.action (command) ->

  options =
    videoCodec: command.video_codec or "libx264"
    audioCodec: command.audio_codec or "aac"
    resolution: command.resolution or "-1:480"
    aspect: command.aspect or "16:9"
    videoBitrate: command.video_bitrate or 256

  #
  if commander.folder?
    files = fs.readdirSync commander.folder
    options.videoPaths = _fullPaths(commander.folder, files) or []
    encode options

  #
  else if commander.paths?.length > 0
    options.videoPaths = commander.paths or []
    encode options

  #
  else
    files = fs.readdirSync __dirname
    options.videoPaths = _fullPaths(commander.folder, files) or []
    encode options

commander.parse process.argv

