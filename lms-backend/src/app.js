const express = require("express");
const connectDB = require("./config/db");
const { errors } = require("celebrate");
require("dotenv").config();
const { initGridFS } = require("./config/gridfs");
const { sendResponse } = require("./utils/response");
const { isCelebrateError } = require('celebrate');

const app = express();

app.use(express.json());

const authRoutes = require("./routes/auth.routes");
const classRoutes = require("./routes/class.routes");
const teacherRoutes = require("./routes/teacher.routes");
const homeworkRoutes = require("./routes/homework.routes");
const feeRoutes = require("./routes/fee.route");

app.use("/api/auth", authRoutes);
app.use("/api/class", classRoutes);
app.use("/api/teacher", teacherRoutes);
app.use("/api/homework", homeworkRoutes);
app.use("/api/fee", feeRoutes);

app.use((err, req, res, next) => {
    if (isCelebrateError(err)) {
       
        let firstMessage = "Invalid input";

        for (const [, celebrateError] of err.details.entries()) {
            if (celebrateError && celebrateError.details && celebrateError.details.length > 0) {
                firstMessage = celebrateError.details[0].message;
                break;
            }
        }

        return sendResponse(res, {
            success: false,
            message: firstMessage,
            data: null,
            statusCode: 400
        });
    }
   
    console.error(err);
    return sendResponse(res, {
        success: false,
        message: err.message || "Internal Server Error",
        data: null,
        statusCode: err.statusCode || 500
    });
});





connectDB().then(async () => {
    await initGridFS(); 
    const PORT = process.env.PORT || 5000;
    app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
}).catch(err => console.error("Server failed to start:", err));