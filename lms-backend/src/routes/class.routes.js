const express = require("express");
const router = express.Router();
const { celebrate } = require("celebrate");
const classController = require("../controllers/class.controller");
const authMiddleware = require("../middlewares/auth.middleware");
const {
    createClassValidation,
    updateClassValidation,
    enrollClassValidation,
    listClassValidation
} = require("../validations/class.validation");


router.post("/create", authMiddleware("teacher"), celebrate(createClassValidation), classController.createClass);
router.put("/:classId", authMiddleware("teacher"), celebrate(updateClassValidation), classController.updateClass);
router.delete("/:classId", authMiddleware("teacher"), classController.deleteClass);
router.post("/enroll", authMiddleware("student"), celebrate(enrollClassValidation), classController.enrollClass);

router.get("/all", authMiddleware("student"), celebrate(listClassValidation), classController.getAllClasses);
router.get("/my", authMiddleware("student"), celebrate(listClassValidation), classController.getEnrolledClasses);
router.get("/search", authMiddleware("student"), classController.searchClass);
router.get("/my/search", authMiddleware("student"), classController.searchEnrolledClass);

router.get("/:classId", authMiddleware(["teacher", "student"]), classController.getClassDetails);



module.exports = router;
