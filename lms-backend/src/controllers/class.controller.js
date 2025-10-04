const Class = require("../models/class.model");
const User = require("../models/user.model");
const { sendResponse } = require("../utils/response");
const Homework = require("../models/homework.model");
const Submission = require("../models/submission.model");
const { getGFS } = require("../config/gridfs");
const mongoose = require("mongoose");
const { Fee, ClassFee } = require("../models/fee.model");


exports.createClass = async (req, res) => {
    try {
        console.log("create Class API is called");
        const { title, description, url, startDate, endDate, schedule, fee } = req.body;

        const teacherData = await User.findById(req.user._id).select("name email");

        const newClass = new Class({
            title, description, url, startDate, endDate, schedule, fee, teacher: req.user._id
        });
        await newClass.save();

        const responseData = {
            ...newClass.toObject(),
            teacher: {
                _id: teacherData._id,
                name: teacherData.name,
                email: teacherData.email
            }
        };

        return sendResponse(res, {
            success: true,
            message: "Class Created Successfulyy",
            data: responseData,
            pagination: null,

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


exports.updateClass = async (req, res) => {
    try {
        console.log("updateClass API Called");
        const { classId } = req.params;
        const cls = await Class.findById(classId);
        if (!cls) return sendResponse(res, {
            success: false,
            message: "Class not found",
            data: null,
            pagination: null,
            statusCode: 404
        });
        if (cls.teacher.toString() !== req.user._id.toString()) {
            return sendResponse(res, {
                success: false,
                message: "Unauthorized",
                data: null,
                pagination: null,
                statusCode: 403
            });

        }
        const { title, description, url } = req.body;
        if (title) cls.title = title;
        if (description) cls.description = description;
        if (url) cls.url = url;
        await cls.save();
        return sendResponse(res, {
            success: true,
            message: "Class Updated Successfully",
            data: cls,
            pagination: null
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

exports.deleteClass = async (req, res) => {
    try {
        console.log("deleteClass API Called");
        const { classId } = req.params;
        const gfs = getGFS();

        const cls = await Class.findById(classId);
        if (!cls) {
            return res.status(404).json({ success: false, message: "Class not found" });
        }

        if (cls.teacher.toString() !== req.user._id.toString()) {
            return res
                .status(403)
                .json({ success: false, message: "Not authorized to delete this class" });
        }

        const homeworks = await Homework.find({ classId });

        for (const homework of homeworks) {
            
            if (homework.referenceAudioFileId) {
                try {
                    await gfs.delete(new mongoose.Types.ObjectId(homework.referenceAudioFileId));
                } catch (err) {
                    console.error("Error deleting reference audio:", err.message);
                }
            }

            const submissions = await Submission.find({ homeworkId: homework._id });

            for (const submission of submissions) {
                if (submission.audioFileId) {
                    try {
                        await gfs.delete(new mongoose.Types.ObjectId(submission.audioFileId));
                    } catch (err) {
                        console.error("Error deleting submission file:", err.message);
                    }
                }
            }

            await Submission.deleteMany({ homeworkId: homework._id });
            await Homework.findByIdAndDelete(homework._id);
        }

        await Fee.deleteMany({ classId }); 
        await ClassFee.deleteOne({ classId }); 

        await Class.findByIdAndDelete(classId);

        res.json({
            success: true,
            message: "Class, homeworks, submissions, files, and fees deleted successfully",
        });
    } catch (error) {
        console.error("Error in deleteClass:", error);
        res.status(500).json({ success: false, message: "Server error" });
    }
};

exports.getClassDetails = async (req, res) => {
    try {
        console.log("Class details api called");
        const { classId } = req.params;

        const cls = await Class.findById(classId)
            .populate("teacher", "name email") 
            .lean();

        if (!cls) {
            return res.status(404).json({ success: false, message: "Class not found" });
        }

        
        const homeworkCount = await Homework.countDocuments({ classId });

        const hasHomeworks = homeworkCount > 0;

        
        let isEnrolled = false;
        let isFeePaid = false;

        if (req.user.role === "student") {
            isEnrolled = cls.students?.some(
                (studentId) => studentId.toString() === req.user._id
            );
            const feeRecord = await Fee.findOne({ classId, student: req.user._id });
            isFeePaid = !!feeRecord;
        }

        res.json({
            success: true,
            data: {
                class: cls,
                isEnrolled: req.user.role === "student" ? isEnrolled : undefined,
                hasHomeworks,
                isFeePaid: req.user.role === "student" ? isFeePaid : undefined,
            },
        });
    } catch (error) {
        console.error("Error in getClassDetails:", error);
        res.status(500).json({ success: false, message: "Server error" });
    }
};


exports.enrollClass = async (req, res) => {
    try {
        console.log("Enroll api is called")
        const { classId } = req.body;
        const cls = await Class.findById(classId);
        if (!cls)
            return sendResponse(res, {
                success: false,
                message: "Class not found",
                data: null,
                pagination: null,
                statusCode: 404
            });
        if (!cls.students.includes(req.user._id)) cls.students.push(req.user._id);
        await cls.save();
        return sendResponse(res, {
            success: true,
            message: "Enrolled successfully",
            data: cls,
            pagination: null
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


exports.getAllClasses = async (req, res) => {
    try {
        console.log("get all classes is called")
        // const page = parseInt(req.query.page) || 1;
        // const limit = parseInt(req.query.limit) || 10;
        // const skip = (page - 1) * limit;

        const classes = await Class.find()
            // .skip(skip)
            // .limit(limit)
            .populate("teacher", "name email")
            .populate("students", "name email");

        const total = await Class.countDocuments();


        const data = await Promise.all(classes.map(async cls => {

            const isEnrolled = cls.students.some(s => s._id.equals(req.user._id));
            let isFeePaid = false;
            if (req.user.role === "student") {
                const feeRecord = await Fee.findOne({ classId: cls._id, student: req.user._id });
                isFeePaid = !!feeRecord;
            }
            const scheduleWithUserTime = cls.schedule;

            const homeworks = await Homework.find({ classId: cls._id }).select("_id");
            const homeworkIds = homeworks.map(hw => hw._id);
            const submittedHomeworkIds = await Submission.distinct("homeworkId", {
                homeworkId: { $in: homeworkIds },
                student: req.user._id
            });
            const nonSubmittedCount = homeworkIds.length - submittedHomeworkIds.length;

            return {
                ...cls.toObject(),
                isEnrolled,
                schedule: scheduleWithUserTime, 
                nonSubmittedHomeworkCount: nonSubmittedCount,
                isFeePaid: req.user.role === "student" ? isFeePaid : undefined
            };
        }));

        return sendResponse(res, {
            success: true,
            message: "All Classes are Fetched Successfully",
            data: data,
            // pagination: {
            //     total,
            //     page: parseInt(page),
            //     limit: parseInt(limit),
            //     totalPages: Math.ceil(total / limit)
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


exports.searchClass = async (req, res) => {
    try {
        console.log("search classes is called")
        // const page = parseInt(req.query.page) || 1;
        // const limit = parseInt(req.query.limit) || 10;
        // const skip = (page - 1) * limit;
        const { query } = req.query;

        const filter = {
            $or: [
                { title: { $regex: query, $options: "i" } },
                { description: { $regex: query, $options: "i" } }
            ]
        };

        const total = await Class.countDocuments(filter);

        const classes = await Class.find(filter)
            // .skip(skip)
            // .limit(limit)
            .populate("teacher", "name email")
            .populate("students", "name email");

        const data = await Promise.all(classes.map(async cls => {
            const isEnrolled = cls.students.some(s => s._id.equals(req.user._id));
            let isFeePaid = false;
            if (isEnrolled) {
                const feeRecord = await Fee.findOne({
                    classId: cls._id,
                    student: req.user._id,
                });
                isFeePaid = !!feeRecord;
            }

            const scheduleWithUserTime = cls.schedule;

            const homeworks = await Homework.find({ classId: cls._id }).select("_id");
            const homeworkIds = homeworks.map(hw => hw._id);
            const submittedHomeworkIds = await Submission.distinct("homeworkId", {
                homeworkId: { $in: homeworkIds },
                student: req.user._id
            });
            const nonSubmittedCount = homeworkIds.length - submittedHomeworkIds.length;

            return {
                ...cls.toObject(),
                isEnrolled,
                schedule: scheduleWithUserTime, 
                nonSubmittedHomeworkCount: nonSubmittedCount,
                isFeePaid
            };
        }));

        return sendResponse(res, {
            success: true,
            message: "Classes search results",
            data,
            // pagination: {
            //     total,
            //     page,
            //     limit,
            //     totalPages: Math.ceil(total / limit),
            //     count: data.length
            // }
            pagination:null
        });
    } catch (err) {
        console.error("Error in SearchClass API:", err.message);
        return sendResponse(res, {
            success: false,
            message: err.message,
            data: null,
            pagination: null,
            statusCode: 500
        });
    }
};



exports.getEnrolledClasses = async (req, res) => {
    try {
        console.log("get enrolled classes is called")
        // const page = parseInt(req.query.page) || 1;
        // const limit = parseInt(req.query.limit) || 10;
        // const skip = (page - 1) * limit;

        const total = await Class.countDocuments({ students: req.user._id });

        const classes = await Class.find({ students: req.user._id })
            // .skip(skip)
            // .limit(limit)
            .populate("teacher", "name email")
            .populate("students", "name email");

        const data = await Promise.all(classes.map(async cls => {
            const isEnrolled = true;
            const feeRecord = await Fee.findOne({
                classId: cls._id,
                student: req.user._id,
            });

            const scheduleWithUserTime = cls.schedule;

            
            const homeworks = await Homework.find({ classId: cls._id }).select("_id");
            const homeworkIds = homeworks.map(hw => hw._id);
            const submittedHomeworkIds = await Submission.distinct("homeworkId", {
                homeworkId: { $in: homeworkIds },
                student: req.user._id
            });
            const nonSubmittedCount = homeworkIds.length - submittedHomeworkIds.length;

            return {
                ...cls.toObject(),
                isEnrolled,
                schedule: scheduleWithUserTime, 
                nonSubmittedHomeworkCount: nonSubmittedCount,
                isFeePaid: !!feeRecord
            };
        }));

        return sendResponse(res, {
            success: true,
            message: "Enrolled Classes Fetched Successfully",
            data,
            // pagination: {
            //     total,
            //     page,
            //     limit,
            //     totalPages: Math.ceil(total / limit),
            //     count: data.length
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

exports.searchEnrolledClass = async (req, res) => {
    try {
        console.log("search enrolled classes is called")
        // const page = parseInt(req.query.page) || 1;
        // const limit = parseInt(req.query.limit) || 10;
        // const skip = (page - 1) * limit;
        const { query } = req.query;

        const filter = {
            students: req.user._id,
            $or: [
                { title: { $regex: query, $options: "i" } },
                { description: { $regex: query, $options: "i" } }
            ]
        };

        const total = await Class.countDocuments(filter);

        const classes = await Class.find(filter)
            // .skip(skip)
            // .limit(limit)
            .populate("teacher", "name email")
            .populate("students", "name email");

        const data = await Promise.all(classes.map(async cls => {
            const isEnrolled = true;
            const feeRecord = await Fee.findOne({
                classId: cls._id,
                student: req.user._id,
            });

        
            const scheduleWithUserTime = cls.schedule;

        
            const homeworks = await Homework.find({ classId: cls._id }).select("_id");
            const homeworkIds = homeworks.map(hw => hw._id);
            const submittedHomeworkIds = await Submission.distinct("homeworkId", {
                homeworkId: { $in: homeworkIds },
                student: req.user._id
            });
            const nonSubmittedCount = homeworkIds.length - submittedHomeworkIds.length;

            return {
                ...cls.toObject(),
                isEnrolled,
                schedule: scheduleWithUserTime, 
                nonSubmittedHomeworkCount: nonSubmittedCount,
                isFeePaid: !!feeRecord
            };
        }));

        return sendResponse(res, {
            success: true,
            message: "Enrolled classes search results",
            data,
            // pagination: {
            //     total,
            //     page,
            //     limit,
            //     totalPages: Math.ceil(total / limit),
            //     count: data.length
            // }
            pagination:null
        });
    } catch (err) {
        console.error("Error in searchEnrolledClassByTeacher API:", err.message);
        return sendResponse(res, {
            success: false,
            message: err.message,
            data: null,
            pagination: null,
            statusCode: 500
        });
    }
};


