exports.sendResponse = (res, { success = true, message = "", data = null, pagination = null, statusCode = 200 }) => {
    res.status(statusCode).json({
        success,
        message,
        data,
        pagination
    });
};
