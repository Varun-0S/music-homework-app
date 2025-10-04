const { Fee, ClassFee } = require("../models/fee.model");
const { sendResponse } = require("../utils/response");
const mongoose = require("mongoose");
const Class = require("../models/class.model");

exports.setClassFee = async (req, res) => {
    try {
        console.log("setClassFee API Called");
        const { classId, amount, frequency } = req.body;

        let classFee = await ClassFee.findOne({ classId });
        if (classFee) {
            classFee.amount = amount;
            classFee.frequency = frequency;
            await classFee.save();
            return sendResponse(res, {
                success: true,
                message: "Class fee updated successfully",
                data: classFee,
                pagination: null
            });
        }

        classFee = new ClassFee({ classId, amount, frequency, teacher: req.user._id });
        await classFee.save();

        return sendResponse(res, {
            success: true,
            message: "Class fee set successfully",
            data: classFee,
            pagination: null
        });
    } catch (err) {
        console.error(err);
       
        return sendResponse(res, {
            success: false,
            message: err.message,
            data: null,
            pagination: null,
            statusCode:500
        });

    }
};

exports.recordPayment = async (req, res) => {
    try {
        console.log("recordPayment API Called");
        const { classId, amountPaid, description } = req.body;

        const fee = new Fee({
            classId,
            student: req.user._id,
            amountPaid,
            description,
            paidBy: req.user._id
        });
        await fee.save();
        
         return sendResponse(res, {
            success: true,
            message: "Payment recorded successfully",
            data: fee,
            pagination: null
        });
    } catch (err) {
        console.error(err);
         return sendResponse(res, {
            success: false,
            message: err.message,
            data: null,
            pagination: null,
            statusCode:500
        });
    }
};

exports.getClassPayments = async (req, res) => {
    try {
        console.log("getClassPayments API Called");
        // const { page = 1, limit = 10 } = req.query;
        const { classId } = req.params;
        // const skip = (page - 1) * limit;

        const cls = await Class.findById(classId).populate("students", "name email");
        if (!cls) 
         return sendResponse(res, {
            success: false,
            message:"Class not found",
            data: null,
            pagination: null,
            statusCode: 404
        });

    
        const paidFees = await Fee.find({ classId })
            .populate("student", "name email")
            // .skip(skip)
            // .limit(limit);
        const paidStudentIds = paidFees.map(f => f.student._id.toString());

        
        const unpaidStudents = cls.students.filter(s => !paidStudentIds.includes(s._id.toString()));

        
        const totalPaid = paidFees.length;
        const totalUnpaid = unpaidStudents.length;

        return sendResponse(res, {
            success: true,
            message: "Payment list",
            data: {
                paid: paidFees,
                unpaid: unpaidStudents
            },
            // pagination: {
            //     page: parseInt(page),
            //     limit: parseInt(limit),
            //     totalPaid,
            //     totalUnpaid
            // }
            pagination:null
        });

    } catch (err) {
        console.error(err);
        return sendResponse(res, {
            success: false,
            message: err.message,
            data: null,
            pagination: null,
            statusCode: 500
        });
    }
};

exports.getStudentPayments = async (req, res) => {
    try {
        console.log("getStudentPayments API Called");
        const { classId } = req.params;

        const payments = await Fee.find({ classId, student: req.user._id });
        const classFee = await ClassFee.findOne({ classId });

        const totalPaid = payments.reduce((sum, p) => sum + p.amountPaid, 0);
        const remaining = classFee ? classFee.amount - totalPaid : 0;

       
         return sendResponse(res, {
            success: true,
            message: "Payment status",
            data: { totalPaid, remaining, payments },
            pagination: null,
           
        });
    } catch (err) {
        console.error(err);
         return sendResponse(res, {
            success: false,
            message: err.message,
            data: null,
            pagination: null,
            statusCode:500
        });
    }
};
