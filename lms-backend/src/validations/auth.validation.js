const { Joi, Segments } = require("celebrate");

exports.registerValidation = {
    [Segments.BODY]: Joi.object({
        name: Joi.string()
            .required()
            .messages({
                "string.empty": "Name is required",
                "any.required": "Name is required"
            }),
        email: Joi.string()
            .email()
            .required()
            .messages({
                "string.empty": "Email is required",
                "string.email": "Please enter a valid email address",
                "any.required": "Email is required"
            }),
        password: Joi.string()
            .min(6)
            .required()
            .messages({
                "string.empty": "Password is required",
                "string.min": "Password must be at least 6 characters",
                "any.required": "Password is required"
            }),
        role: Joi.string()
            .valid("teacher", "student")
            .required()
            .messages({
                "any.only": "Role must be either 'teacher' or 'student'",
                "string.empty": "Role is required",
                "any.required": "Role is required"
            })
    })
};

exports.loginValidation = {
    [Segments.BODY]: Joi.object({
        email: Joi.string()
            .email()
            .required()
            .messages({
                "string.empty": "Email is required",
                "string.email": "Please enter a valid email address",
                "any.required": "Email is required"
            }),
        password: Joi.string()
            .required()
            .messages({
                "string.empty": "Password is required",
                "any.required": "Password is required"
            })
    })
};

exports.refreshTokenValidation = {
    [Segments.BODY]: Joi.object({
        refreshToken: Joi.string()
            .required()
            .messages({
                "string.empty": "Refresh token is required",
                "any.required": "Refresh token is required"
            })
    })
};

exports.updateProfileValidation = {
    [Segments.BODY]: Joi.object({
        name: Joi.string()
            .messages({
                "string.empty": "Name cannot be empty"
            })
    })
};
