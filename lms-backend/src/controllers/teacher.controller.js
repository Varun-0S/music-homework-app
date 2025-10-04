const Class = require("../models/class.model");
const { sendResponse } = require("../utils/response");
const User = require("../models/user.model");

exports.getTeacherClasses = async (req, res) => {
    try {
        console.log("GetTeacherClasses API called");
        console.log("Teacher ID:", req.user ? req.user._id : null);

        // const page = parseInt(req.query.page) || 1;
        // const limit = parseInt(req.query.limit) || 10;
        // const skip = (page - 1) * limit;

        const teacherClasses = await Class.find({ teacher: req.user._id })
            // .skip(skip)
            // .limit(limit)
            .populate("students", "name email");

        const total = await Class.countDocuments({ teacher: req.user._id });

        sendResponse(res, {
            success: true,
            message: "Teacher classes fetched successfully",
            data: teacherClasses,
            // pagination: { total, page, limit, totalPages: Math.ceil(total / limit) }
            pagination:null
        });
    } catch (err) {
        console.error("Error in GetTeacherClasses API:", err.message);
        sendResponse(res, { success: false, message: err.message, data: null, pagination: null, statusCode: 500 });
    }
};

exports.getStudentsInClass = async (req, res) => {
    try {
        console.log("getStudentsInClass API called");
        const { classId } = req.params;
        // const page = parseInt(req.query.page) || 1;
        // const limit = parseInt(req.query.limit) || 10;
        // const skip = (page - 1) * limit;

        const classData = await Class.findById(classId).populate("teacher", "name email");
        if (!classData) return sendResponse(res, { success: false, message: "Class not found", data: null, pagination: null, statusCode: 404 });

        const total = classData.students.length;
        
        const students = await User.find({ _id: { $in: classData.students } })
            // .skip(skip)
            // .limit(limit)
            .select("name email");

        sendResponse(res, {
            success: true,
            message: "Students fetched successfully",
            data: students,
            // pagination: { total, page: parseInt(page), limit: parseInt(limit), totalPages: Math.ceil(total / limit) }
            pagination:null
        });

    } catch (err) {
        console.error("Error in GetStudentsInClass API:", err.message);
        sendResponse(res, { success: false, message: err.message, data: null, pagination: null, statusCode: 500 });
    }
};

exports.searchStudentInClass = async (req, res) => {
    try {
        console.log("searchStudentInClass API called");
        // const { query, page = 1, limit = 10 } = req.query;
        const { query } = req.query;
        const { classId } = req.params;
        // const skip = (parseInt(page) - 1) * parseInt(limit);

        const classData = await Class.findById(classId);
        if (!classData) return sendResponse(res, { success: false, message: "Class not found", data: null, pagination: null, statusCode: 404 });

        const studentFilter = { _id: { $in: classData.students }, name: { $regex: query, $options: "i" } };

        const total = await User.countDocuments(studentFilter);

        const students = await User.find(studentFilter)
            // .skip(skip)
            // .limit(limit)
            .select("name email");

        sendResponse(res, {
            success: true,
            message: "Students search results",
            data: students,
            // pagination: { total, page: parseInt(page), limit: parseInt(limit), totalPages: Math.ceil(total / limit) }
            pagination:null
        });

    } catch (err) {
        console.error("Error in SearchStudentInClass API:", err.message);
        sendResponse(res, { success: false, message: err.message, data: null, pagination: null, statusCode: 500 });
    }
};

exports.searchTeacherClass = async (req, res) => {
    try {
        console.log("searchTeacherClass API called");
        // const { query, page = 1, limit = 10 } = req.query;
        const { query } = req.query;
        // const skip = (page - 1) * limit;

        const filter = {
            teacher: req.user._id,
            $or: [
                { title: { $regex: query, $options: "i" } },
                { description: { $regex: query, $options: "i" } }
            ]
        };

        const classes = await Class.find(filter)
            .populate("students", "name email")
            // .skip(skip)
            // .limit(limit);

        const total = await Class.countDocuments(filter); 

        sendResponse(res, {
            success: true,
            message: "Teacher classes search results",
            data: classes,
            // pagination: {
            //     total,
            //     page: parseInt(page),
            //     limit: parseInt(limit),
            //     totalPages: Math.ceil(total / limit)
            // }
            pagination: null
        });
    } catch (err) {
        console.error("Error in SearchTeacherClass API:", err.message);
        sendResponse(res, {
            success: false,
            message: err.message,
            data: null,
            pagination: null,
            statusCode: 500
        });
    }
};
