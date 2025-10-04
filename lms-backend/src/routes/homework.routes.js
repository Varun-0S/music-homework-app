const express = require("express");
const router = express.Router();
const { celebrate } = require("celebrate");
const homeworkController = require("../controllers/homework.controller");
const authMiddleware = require("../middlewares/auth.middleware");
const { createHomeworkValidation, submitHomeworkValidation, gradeSubmissionValidation } = require("../validations/homework.validation");
const multer = require("multer");
const upload = multer();

router.post("/create", authMiddleware("teacher"), upload.single("file"), celebrate(createHomeworkValidation), homeworkController.createHomework);
router.post("/:homeworkId/submit", authMiddleware("student"), upload.single("file"), celebrate(submitHomeworkValidation), homeworkController.submitHomework);
router.get("/class/:classId", authMiddleware(["teacher", "student"]), homeworkController.getHomeworkListByClass);
router.put("/grade/:submissionId", authMiddleware("teacher"), celebrate(gradeSubmissionValidation), homeworkController.gradeSubmission);

router.get("/audio/:fileId", authMiddleware(["teacher", "student"]), homeworkController.downloadAudio);
router.get("/:homeworkId/submissions", authMiddleware("teacher"), homeworkController.getSubmissionsForHomework);
router.get("/:homeworkId/my-submission", authMiddleware("student"), homeworkController.getMySubmissionsForHomework);
router.get("/class/:classId/search", authMiddleware(["teacher", "student"]), homeworkController.searchHomeworkInClass);
router.delete("/:homeworkId", authMiddleware("teacher"), homeworkController.deleteHomework);



module.exports = router;
