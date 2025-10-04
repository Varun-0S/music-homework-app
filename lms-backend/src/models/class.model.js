const mongoose = require("mongoose");

const scheduleSchema = new mongoose.Schema({
    days: [{ type: String, enum: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"] }],
    startTime: { type: String, required: true }, 
    endTime: { type: String, required: true }
});

const feeSchema = new mongoose.Schema({
    amount: { type: Number, required: true },
    frequency: { type: String, enum: ["daily", "weekly", "monthly", "yearly"], required: true }
});

const classSchema = new mongoose.Schema({
    title: { type: String, required: true },
    description: { type: String },
    url: { type: String },
    teacher: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    students: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }],
    schedule: scheduleSchema,
    startDate: { type: String, required: true },
    endDate: { type: String, required: true },
    fee: feeSchema
}, { timestamps: true });

module.exports = mongoose.model("Class", classSchema);
