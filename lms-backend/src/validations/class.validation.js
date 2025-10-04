const { Joi, Segments } = require("celebrate");

exports.createClassValidation = {
    [Segments.BODY]: Joi.object({
        title: Joi.string().required(),
        description: Joi.string().optional(),
        url: Joi.string().uri().optional(),
        startDate: Joi.string().required(),
        endDate: Joi.string().required(),
        schedule: Joi.object({
            days: Joi.array().items(Joi.string().valid("Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday")).required(),
            startTime: Joi.string().pattern(/^\d{2}:\d{2}$/).required(),
            endTime: Joi.string().pattern(/^\d{2}:\d{2}$/).required()
        }).required(),
        fee: Joi.object({
            amount: Joi.number().required(),
            frequency: Joi.string().valid("daily","weekly","monthly","yearly").required()
        }).required()
    })
};

exports.updateClassValidation = {
    [Segments.BODY]: Joi.object({
        title: Joi.string().optional(),
        description: Joi.string().optional(),
        url: Joi.string().uri().optional()
    })
};

exports.enrollClassValidation = {
    [Segments.BODY]: Joi.object({
        classId: Joi.string().required()
    })
};

exports.listClassValidation = {
    [Segments.QUERY]: Joi.object({
        page: Joi.number().min(1).optional(),
        limit: Joi.number().min(1).optional()
    })
};
