const WebTorrent = require("webtorrent-hybrid");

export class Seeder {

    private torrentClient;

    private seedingChannels;

    constructor() {
        this.torrentClient = new WebTorrent();
        this.seedingChannels = [];
    }

    public async seed(channels:Array<any>) {

        // loop over the channels array and seed each channel
        for (let channel of channels) {

            console.log(`Start seeding channel: ${channel.name}`);

            try {
                await this._seed(channel);
            } catch(err) {
                console.log(`Failed to seed channel: ${channel.name}`);
                continue;
            }

            console.log(`Done seeding channel: ${channel.name}`);
        }

        console.log("-------------------------------------------");
        console.log(JSON.stringify(this.seedingChannels, null, 4));
        console.log("-------------------------------------------");
    }

    public getSeedingChannels() {
        return this.seedingChannels;
    }

    private _seed(channel:any):Promise<any> {
        return new Promise((resolve, reject) => {

            // start seeding using webtorrent client
            this.torrentClient.seed(channel.seed, (torrent) => {

                // get the magnet uri from the torrent and store it in the channel
                channel.magnetURI = torrent.magnetURI;

                // add the seeded channel to the current seeding channels
                this.seedingChannels.push(channel);

                return resolve();
            });
        });
    }
}