const User = require("../models/user.model");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { sendResponse } = require("../utils/response");

const generateToken = (user) => {
    return jwt.sign({ _id: user._id, role: user.role }, process.env.JWT_SECRET, { expiresIn: "1h" });
};

const generateRefreshToken = (user) => {
    return jwt.sign({ _id: user._id, role: user.role }, process.env.JWT_REFRESH_SECRET, { expiresIn: "7d" });
};

exports.register = async (req, res) => {
    try {
        console.log("Register API Called");
        const { name, email, password, role } = req.body;

        const existingUser = await User.findOne({ email });
        if (existingUser)
            return sendResponse(res, {
                success: false,
                message: "User already exists",
                data: null,
                pagination: null,
                statusCode: 400
            });

        const hashedPassword = await bcrypt.hash(password, 10);

        const user = new User({ name, email, password: hashedPassword, role });
        await user.save();

        sendResponse(res, {
            success: true,
            message: "User registered successfully",
            data: null,
            pagination: null
        });
    } catch (err) {
        console.error("Register Error:", err.message);

        sendResponse(res, {
            success: false,
            message: err.message,
            data: null,
            pagination: null,
            statusCode: 500
        });
    }
};

exports.login = async (req, res) => {
    try {
        console.log("Login API Called");
        const { email, password } = req.body;

        const user = await User.findOne({ email });
        if (!user)
            return sendResponse(res, {
                success: false,
                message: "User not found",
                data: null,
                pagination: null,
                statusCode: 404
            });


        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch)
            return sendResponse(res, {
                success: false,
                message: "Invalid credentials",
                data: null,
                pagination: null,
                statusCode: 400
            });

        const token = generateToken(user);
        const refreshToken = generateRefreshToken(user);

        user.refreshToken = refreshToken;
        await user.save();
        sendResponse(res, {
            success: true,
            message: "Login successful",
            data: { token, refreshToken, user: { _id: user._id, name: user.name, email: user.email, role: user.role } },
            pagination: null
        });

    } catch (err) {
        console.error("Login Error:", err.message);
        sendResponse(res, {
            success: false,
            message: err.message,
            data: null,
            pagination: null,
            statusCode: 500
        });
    }
};

exports.refreshToken = async (req, res) => {
    try {
        console.log("refreshToken API Called");
        const { refreshToken } = req.body;
        if (!refreshToken)
            return sendResponse(res, {
                success: false,
                message: "Refresh token required",
                data: null,
                pagination: null,
                statusCode: 400
            });

        const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
        const user = await User.findById(decoded._id);
        if (!user || user.refreshToken !== refreshToken)
            return sendResponse(res, {
                success: false,
                message: "Invalid refresh token",
                data: null,
                pagination: null,
                statusCode: 401
            });
        const token = generateToken(user);
        const newRefreshToken = generateRefreshToken(user);
        user.refreshToken = newRefreshToken;
        await user.save();

        sendResponse(res, {
            success: true,
            message: "Token refreshed",
            data: { token, refreshToken: newRefreshToken },
            pagination: null,

        });
    } catch (err) {
        console.error("Refresh Token Error:", err.message);
        sendResponse(res, {
            success: false,
            message: err.message,
            data: null,
            pagination: null,
            statusCode: 500
        });
    }
};

exports.logout = async (req, res) => {
    try {
        console.log("logout API Called");
        const userId = req.user._id;
        const user = await User.findById(userId);
        if (user) {
            user.refreshToken = null;
            await user.save();
        }

        sendResponse(res, {
            success: true,
            message: "Logged out successfully",
            data: null,
            pagination: null,

        });
    } catch (err) {
        console.error("Logout Error:", err.message);
        sendResponse(res, {
            success: false,
            message: err.message,
            data: null,
            pagination: null,
            statusCode: 500
        });
    }
};

exports.getProfile = async (req, res) => {
    try {
        console.log("getProfile API Called");
        const user = await User.findById(req.user._id).select("-password -refreshToken");

        sendResponse(res, {
            success: true,
            message: "User profile",
            data: user,
            pagination: null,

        });
    } catch (err) {
        console.error("Get Profile Error:", err.message);
        sendResponse(res, {
            success: false,
            message: err.message,
            data: null,
            pagination: null,
            statusCode: 500
        });
    }
};

exports.updateProfile = async (req, res) => {
    try {
        console.log("updateProfile API Called");
        const { name } = req.body;
        const user = await User.findById(req.user._id);
        if (!user)
            return sendResponse(res, {
                success: false,
                message: "User not found",
                data: null,
                pagination: null,
                statusCode: 404
            });
        if (name) user.name = name;

        await user.save();

        sendResponse(res, {
            success: true,
            message: "Profile updated successfully",
            data: user,
            pagination: null,

        });
    } catch (err) {
        console.error("Update Profile Error:", err.message);
        sendResponse(res, {
            success: false,
            message: err.message,
            data: null,
            pagination: null,
            statusCode: 500
        });
    }
};
