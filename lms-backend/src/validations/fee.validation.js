const { Joi, Segments } = require("celebrate");

exports.setClassFeeValidation = {
    [Segments.BODY]: Joi.object().keys({
        classId: Joi.string().required(),
        amount: Joi.number().required(),
        frequency: Joi.string().valid("daily", "weekly", "monthly", "yearly").required()
    })
};

exports.recordPaymentValidation = {
    [Segments.BODY]: Joi.object().keys({
        classId: Joi.string().required(),
        amountPaid: Joi.number().required(),
        description: Joi.string().optional()
    })
};
