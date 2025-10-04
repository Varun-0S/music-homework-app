const mongoose = require("mongoose");

const feeSchema = new mongoose.Schema({
    classId: { type: mongoose.Schema.Types.ObjectId, ref: "Class", required: true },
    student: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    amountPaid: { type: Number, required: true },
    description: { type: String },
    paymentDate: { type: Date, default: Date.now },
    paidBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
}, { timestamps: true });

const classFeeSchema = new mongoose.Schema({
    classId: { type: mongoose.Schema.Types.ObjectId, ref: "Class", required: true, unique: true },
    amount: { type: Number, required: true },
    frequency: { type: String, enum: ["daily", "weekly", "monthly", "yearly"], required: true },
    teacher: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
}, { timestamps: true });

module.exports = {
    Fee: mongoose.model("Fee", feeSchema),
    ClassFee: mongoose.model("ClassFee", classFeeSchema)
};
