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

    .input(inputNamesFormatted)
    .output(outputPath)
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

commander.parse process.argv

