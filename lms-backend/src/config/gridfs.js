const mongoose = require("mongoose");

let gfs;

const initGridFS = async () => {
    if (mongoose.connection.readyState !== 1) {
        console.log("Waiting for MongoDB connection...");
        await new Promise(resolve => mongoose.connection.once("open", resolve));
    }
    gfs = new mongoose.mongo.GridFSBucket(mongoose.connection.db, {
        bucketName: "audios"
    });
    console.log("GridFSBucket initialized");
};

const getGFS = () => {
    if (!gfs) throw new Error("GridFSBucket not initialized yet");
    return gfs;
};

module.exports = { initGridFS, getGFS };
