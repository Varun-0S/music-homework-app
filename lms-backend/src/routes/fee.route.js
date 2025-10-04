const express = require("express");
const router = express.Router();
const { celebrate } = require("celebrate");
const feeController = require("../controllers/fee.controller");
const authMiddleware = require("../middlewares/auth.middleware");
const { setClassFeeValidation, recordPaymentValidation } = require("../validations/fee.validation");


router.post("/class", authMiddleware("teacher"), celebrate(setClassFeeValidation), feeController.setClassFee);
router.post("/pay", authMiddleware("student"), celebrate(recordPaymentValidation), feeController.recordPayment);
router.get("/class/:classId", authMiddleware("teacher"), feeController.getClassPayments);
router.get("/student/:classId", authMiddleware("student"), feeController.getStudentPayments);

module.exports = router;
