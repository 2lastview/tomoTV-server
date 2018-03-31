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
}

run();