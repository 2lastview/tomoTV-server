path = require "path"

module.exports =

  port: 2000

  channels: [

    # The Simpsons
    name: "The Simpsons"
    path: "/Users/moritztomasi/Code/tomoTV-server/public/TheSimpsons"
    seeds: [
      name: "Season 1"
      folder: "S01"
      video: "merged.mp4"
      meta: "meta.json"
    ,
      name: "Season 2"
      folder: "S02"
      video: "merged.mp4"
      meta: "meta.json"
    ]
  ,
    # Family Guy
    name: "Family Guy"
    path: "/Users/moritztomasi/Code/tomoTV-server/public/FamilyGuy"
    seeds: [
      name: "Season 1"
      folder: "S01"
      video: "FamilyGuy_merged_S01.mp4"
      meta: "FamilyGuy_merged_S01.json"
    ]

  ]
