const Homework = require("../models/homework.model");
const Submission = require("../models/submission.model");
const { getGFS } = require("../config/gridfs");
const mongoose = require("mongoose");
const { ObjectId } = mongoose.Types;
const { sendResponse } = require("../utils/response");

exports.createHomework = async (req, res) => {
    try {
        console.log("createHomework API Called");
        const { classId, title, description, dueDate } = req.body;
        let fileId = null;

        if (req.file) {
            if (!req.file.mimetype.startsWith("audio/"))
                return sendResponse(res, {
                    success: false,
                    message: "Only audio files are allowed",
                    data: null,
                    pagination: null,
                    statusCode: 400
                });
            if (req.file.size > 10 * 1024 * 1024)
                return sendResponse(res, {
                    success: false,
                    message: "File size exceeds 10MB",
                    data: null,
                    pagination: null,
                    statusCode: 400
                });
            const gfs = getGFS();
            const uploadStream = gfs.openUploadStream(Date.now() + "-" + req.file.originalname, {
                contentType: req.file.mimetype,
                metadata: { originalName: req.file.originalname, uploadedBy: req.user._id }
            });
            uploadStream.end(req.file.buffer);
            await new Promise((resolve, reject) => {
                uploadStream.on("finish", () => { fileId = uploadStream.id; resolve(); });
                uploadStream.on("error", reject);
            });
        }

        const homework = new Homework({ classId, teacher: req.user._id, title, description, dueDate, referenceAudioFileId: fileId });
        await homework.save();
        return sendResponse(res, {
            success: true,
            message: "Homework created successfully",
            data: homework,
            pagination: null,
        });
    } catch (err) {

        console.log(err);
        return sendResponse(res, {
            success: false,
            message: err.message,
            data: null,
            pagination: null,
            statusCode: 500
        });
    }
};

exports.submitHomework = async (req, res) => {
    try {
        console.log("submitHomework API Called");
        const { homeworkId } = req.params;
        let fileId = null;

        const submissionCount = await Submission.countDocuments({ homeworkId, student: req.user._id });
        if (submissionCount >= 3)
            return sendResponse(res, {
                success: false,
                message: "Maximum 3 submissions allowed per homework",
                data: null,
                pagination: null,
                statusCode: 400
            });
        if (req.file) {
            if (!req.file.mimetype.startsWith("audio/"))
                return sendResponse(res, {
                    success: false,
                    message: "Only audio files are allowed",
                    data: null,
                    pagination: null,
                    statusCode: 400
                });
            if (req.file.size > 10 * 1024 * 1024)
                return sendResponse(res, {
                    success: false,
                    message: "File size exceeds 10MB",
                    data: null,
                    pagination: null,
                    statusCode: 400
                });
            const gfs = getGFS();
            const uploadStream = gfs.openUploadStream(Date.now() + "-" + req.file.originalname, {
                contentType: req.file.mimetype,
                metadata: { originalName: req.file.originalname, uploadedBy: req.user._id }
            });
            uploadStream.end(req.file.buffer);
            await new Promise((resolve, reject) => {
                uploadStream.on("finish", () => { fileId = uploadStream.id; resolve(); });
                uploadStream.on("error", reject);
            });
        }

        const submission = new Submission({ homeworkId, student: req.user._id, audioFileId: fileId });
        await submission.save();

        return sendResponse(res, {
            success: true,
            message: "Homework submitted successfully",
            data: submission,
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

exports.getHomeworkListByClass = async (req, res) => {
    try {
        console.log("getHomeworkListByClass API Called");
        const { classId } = req.params;
        // const page = parseInt(req.query.page) || 1;
        // const limit = parseInt(req.query.limit) || 10;
        // const skip = (page - 1) * limit;

        const homeworks = await Homework.find({ classId })
            // .skip(skip)
            // .limit(limit)
            .populate("teacher", "name email");
        const total = await Homework.countDocuments({ classId });
        
        const data = await Promise.all(
            homeworks.map(async (hw) => {
                const submission = await Submission.findOne({
                    homeworkId: hw._id,
                    student: req.user._id
                });
                return {
                    ...hw.toObject(),
                    isHomeworkSubmitted: !!submission   
                };
            })
        );

        return sendResponse(res, {
            success: true,
            message: "Homework list",
            data,
            // pagination: {
            //     total,
            //     page,
            //     limit,
            //     totalPages: Math.ceil(total / limit),
            // },
            pagination:null
        });
    } catch (err) {
        console.error(err);
        return sendResponse(res, {
            success: false,
            message: err.message,
            data: null,
            pagination: null,
            statusCode: 500,
        });
    }
};

exports.downloadAudio = async (req, res) => {
    try {
        console.log("DownloadAudio API called");
        const { fileId } = req.params;

        if (!ObjectId.isValid(fileId)) {
            return sendResponse(res, { success: false, message: "Invalid file ID", data: null, statusCode: 400 });
        }

        const _id = new ObjectId(fileId);
        const gfs = getGFS();
        const filesCollection = gfs.s.db.collection("audios.files");
        const fileDoc = await filesCollection.findOne({ _id });

        if (!fileDoc) {
            return sendResponse(res, { success: false, message: "File not found", data: null, statusCode: 404 });
        }

        const filename = fileDoc.metadata?.originalName || fileDoc.filename;
        res.set({
            "Content-Type": fileDoc.contentType,
            "Content-Disposition": `attachment; filename="${filename}"`
        });

        const downloadStream = gfs.openDownloadStream(_id);
        downloadStream.on("error", (err) => {
            console.error("Error streaming file:", err);
            res.status(500).json({ message: "Error downloading file" });
        });

        downloadStream.pipe(res);
    } catch (err) {
        console.error("Error in DownloadAudio API:", err.message);
        sendResponse(res, { success: false, message: err.message, data: null, statusCode: 500 });
    }
};

exports.gradeSubmission = async (req, res) => {
    try {
        console.log("gradeSubmission API called");
        const { submissionId } = req.params;
        const { grade, feedback } = req.body;

        const submission = await Submission.findById(submissionId);
        if (!submission)
            return sendResponse(res, {
                success: false,
                message: "Submission not found",
                data: null,
                pagination: null,
                statusCode: 404
            });
        submission.grade = grade;
        submission.feedback = feedback || "";
        await submission.save();
        return sendResponse(res, {
            success: true,
            message: "Submission graded successfully",
            data: submission,
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

exports.getStudentSubmission = async (req, res) => {
    try {
        console.log("GetStudentSubmission API called");

        const { homeworkId } = req.params;
        const submission = await Submission.findOne({ homeworkId, student: req.user._id });

        if (!submission) {
            return sendResponse(res, { success: false, message: "No submission found", data: null, statusCode: 404 });
        }

        sendResponse(res, { success: true, message: "Student submission fetched", data: submission });
    } catch (err) {
        console.error("Error in GetStudentSubmission API:", err.message);
        sendResponse(res, { success: false, message: err.message, data: null, statusCode: 500 });
    }
};

exports.getSubmissionsForHomework = async (req, res) => {
    try {
        console.log("getSubmissionsForHomework API called");
        const { homeworkId } = req.params;
        // const page = parseInt(req.query.page) || 1;
        // const limit = parseInt(req.query.limit) || 10;
        // const skip = (page - 1) * limit;

        const filter = { homeworkId };
        const submissions = await Submission.find(filter)
        // .skip(skip)
        // .limit(limit)
        .populate("student", "name email");
        const total = await Submission.countDocuments(filter);

        sendResponse(res, {
            success: true,
            message: "Submissions fetched successfully",
            data: submissions,
            // pagination: { total, page, limit, totalPages: Math.ceil(total / limit) }
            pagination:null
        });
    } catch (err) {
        console.error("Error in GetAllSubmissions API:", err.message);
        sendResponse(res, { success: false, message: err.message, data: null, statusCode: 500 });
    }
};

exports.getMySubmissionsForHomework = async (req, res) => {
    try {
        console.log("getMySubmissionsForHomework API called");
        const { homeworkId } = req.params;
        // const page = parseInt(req.query.page) || 1;
        // const limit = parseInt(req.query.limit) || 10;
        // const skip = (page - 1) * limit;
        
        const filter = { homeworkId, student: req.user._id };

        const submissions = await Submission.find(filter)
            // .skip(skip)
            // .limit(limit)
            .populate("student", "name email");

        const total = await Submission.countDocuments(filter);

        return sendResponse(res, {
            success: true,
            message: "Your submissions fetched successfully",
            data: submissions,
            // pagination: {
            //     total,
            //     page,
            //     limit,
            //     totalPages: Math.ceil(total / limit),
            //     count: submissions.length
            // }
            pagination:null
        });
    } catch (err) {
        console.error("Error in getMySubmissionsForHomework API:", err.message);
        return sendResponse(res, {
            success: false,
            message: err.message,
            data: null,
            pagination: null,
            statusCode: 500
        });
    }
};

exports.searchHomeworkInClass = async (req, res) => {
    try {
        console.log("searchHomeworkInClass API called");
        // const { query, page = 1, limit = 10 } = req.query;
        const { query} = req.query;
        const { classId } = req.params;
        // const skip = (page - 1) * limit;

        const homeworkList = await Homework.find({
            classId,
            $or: [
                { title: { $regex: query, $options: "i" } },
                { description: { $regex: query, $options: "i" } }
            ]
        })
        // .skip(skip).limit(limit);

        sendResponse(res, {
            success: true,
            message: "Homework search results",
            data: homeworkList,
            // pagination: { total: homeworkList.length, page: parseInt(page), limit: parseInt(limit), totalPages: Math.ceil(homeworkList.length / limit) }
            pagination: null
        });
    } catch (err) {
        console.error("Error in SearchHomeworkInClass API:", err.message);
        sendResponse(res, { success: false, message: err.message, data: null, statusCode: 500 });
    }
};

exports.deleteHomework = async (req, res) => {
    try {
        console.log("DeleteHomework API called");

        const { homeworkId } = req.params;
        const homework = await Homework.findById(homeworkId);

        if (!homework) {
            return sendResponse(res, { success: false, message: "Homework not found", data: null, statusCode: 404 });
        }

        if (homework.teacher.toString() !== req.user._id.toString()) {
            return sendResponse(res, { success: false, message: "Not authorized to delete this homework", data: null, statusCode: 403 });
        }

        const gfs = getGFS();

        if (homework.referenceAudioFileId) {
            try {
                await gfs.delete(new mongoose.Types.ObjectId(homework.referenceAudioFileId));
            } catch (err) {
                console.error("Error deleting reference audio:", err.message);
            }
        }

        const submissions = await Submission.find({ homeworkId });
        for (const submission of submissions) {
            if (submission.audioFileId) {
                try {
                    await gfs.delete(new mongoose.Types.ObjectId(submission.audioFileId));
                } catch (err) {
                    console.error("Error deleting submission file:", err.message);
                }
            }
        }

        await Submission.deleteMany({ homeworkId });
        await Homework.findByIdAndDelete(homeworkId);

        sendResponse(res, { success: true, message: "Homework and related submissions deleted successfully", data: null });
    } catch (err) {
        console.error("Error in DeleteHomework API:", err.message);
        sendResponse(res, { success: false, message: err.message, data: null, statusCode: 500 });
    }
};