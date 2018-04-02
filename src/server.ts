import * as express from "express";

import { channelGenerator } from "./lib/channelGenerator";
import { Seeder } from "./lib/seeder";

let app = express();

async function run() {

    // generate all channels
    let channels = await channelGenerator.generate("/Users/moritztomasi/Desktop/channels/");

    // initiate the seeder and seed the channels
    let seeder = new Seeder();
    await seeder.seed(channels);

    app.use((req, res, next) => {
        res.header("Access-Control-Allow-Origin", "*");
        res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
        next();
    });
    
    app.get("/api/channels", (req, res) => {
        res.status(200).json(seeder.getSeedingChannels());
    });
    
    app.listen(2000, () => {
        console.log(`server started and running on port 2000`);
    });
}

run();