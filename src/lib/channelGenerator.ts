import * as fs from "fs";
import * as readdir from "readdir-absolute";
import * as path from "path";
import * as uuidV4 from "uuid/v4";
import * as ffmpeg from "fluent-ffmpeg";
import * as ptn from "parse-torrent-name";

class ChannelGenerator {

    public async generate(publicPath:string):Promise<any> {
        
        let channels = [];

        // get all channel paths in the public directory
        let channelPaths = await this._readdirSync(publicPath);

        // loop over the channels and create the channel meta information
        for (let channelPath of channelPaths) {

            // make sure .DS_Store is ignored and unlinked
            if (/.*\.DS_Store.*/.test(channelPath)) {
                fs.unlinkSync(channelPath);
                continue;
            }

            let channel = {
                id: uuidV4(),
                name: path.basename(channelPath),
                seed: channelPath,
                videos: [],
                totalDuration: 0,
                totalSize: 0,
                cuts: []
            };

            // get all video paths for each channel
            let videoPaths = await this._readdirSync(channelPath);

            // determine when video cuts to next video
            let cutsTotal = 0

            // loop over the videos and create meta information
            for (let videoPath of videoPaths) {

                // again, make sure .DS_Store is ignored and unlinked
                if (/.*\.DS_Store.*/.test(videoPath)) {
                    fs.unlinkSync(videoPath);
                    continue;
                }

                // get video metadata by using ffmpeg
                let videoMetadata = await this._ffprobe(videoPath);

                let video = {
                    filename: path.basename(videoPath),
                    metadata: videoMetadata.format,
                    extracted: ptn(path.basename(videoPath))
                };

                // add duration of video to total duration
                channel.totalDuration += video.metadata.duration;

                // add size of video to total size
                channel.totalSize += video.metadata.size;
                
                // add duration of video to total cuts
                cutsTotal += video.metadata.duration;
                channel.cuts.push(cutsTotal);

                // add video information to channel
                channel.videos.push(video);
            }

            // add channel to final channels array
            channels.push(channel);
        }

        return channels;
    }

    private _readdirSync(path:string):Promise<any> {
        return new Promise((resolve, reject) => {
            readdir(path, (err, absolutePaths) => {
                if (err != null) {
                    return reject(err);
                }

                return resolve(absolutePaths);
            });
        });
    }

    private _ffprobe(videoPath:string):Promise<any> {
        return new Promise((resolve, reject) => {

            // run ffmpeg's ffprobe to get video metadata
            ffmpeg.ffprobe(videoPath, (err, metadata) => {
                if (err != null) {
                    return reject(err);
                }

                return resolve(metadata);
            });
        });
    }
}

export const channelGenerator = new ChannelGenerator();