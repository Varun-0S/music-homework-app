const { Joi, Segments } = require("celebrate");

exports.createHomeworkValidation = {
    [Segments.BODY]: Joi.object().keys({
        classId: Joi.string().required(),
        title: Joi.string().required(),
        description: Joi.string().optional(),
        dueDate: Joi.date().required(),
    })
};

exports.submitHomeworkValidation = {
    [Segments.PARAMS]: Joi.object().keys({
        homeworkId: Joi.string().required()
    })
};

exports.gradeSubmissionValidation = {
    [Segments.PARAMS]: Joi.object().keys({
        submissionId: Joi.string().required()
    }),
    [Segments.BODY]: Joi.object().keys({
        grade: Joi.number().required(),
        feedback: Joi.string().optional()
    })
};
