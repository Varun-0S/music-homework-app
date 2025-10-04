const mongoose = require("mongoose");

const submissionSchema = new mongoose.Schema({
    homeworkId: { type: mongoose.Schema.Types.ObjectId, ref: "Homework", required: true },
    student: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    audioFileId: { type: mongoose.Schema.Types.ObjectId },
    grade: { type: Number },
    feedback: { type: String },
    submittedAt: { type: Date, default: Date.now },
}, { timestamps: true });

module.exports = mongoose.model("Submission", submissionSchema);
