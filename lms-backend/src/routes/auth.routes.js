const express = require("express");
const router = express.Router();
const { celebrate } = require("celebrate");
const authController = require("../controllers/auth.controller");
const authMiddleware = require("../middlewares/auth.middleware");
const { registerValidation, loginValidation, refreshTokenValidation, updateProfileValidation} = require("../validations/auth.validation");

router.post("/register", celebrate(registerValidation), authController.register);
router.post("/login", celebrate(loginValidation), authController.login);
router.post("/refresh-token", celebrate(refreshTokenValidation), authController.refreshToken);
router.post("/logout", authMiddleware(["teacher", "student"]), authController.logout);
router.get("/me", authMiddleware(["teacher", "student"]), authController.getProfile);
router.put("/me", authMiddleware(["teacher", "student"]), celebrate(updateProfileValidation), authController.updateProfile);

module.exports = router;
