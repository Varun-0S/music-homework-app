const express = require("express");
const router = express.Router();
const authMiddleware = require("../middlewares/auth.middleware");
const { getTeacherClasses, getStudentsInClass, searchStudentInClass, searchTeacherClass } = require("../controllers/teacher.controller");

router.get("/classes", authMiddleware("teacher"), getTeacherClasses);
router.get("/class/:classId/students", authMiddleware("teacher"), getStudentsInClass);
router.get("/class/:classId/students/search", authMiddleware("teacher"), searchStudentInClass);
router.get("/classes/search", authMiddleware("teacher"), searchTeacherClass);


module.exports = router;
