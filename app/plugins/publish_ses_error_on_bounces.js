"use strict";
const AWS = require('aws-sdk');
const util = require('util');

const bouncesSnsTopicArn = process.env.BOUNCES_SNS_TOPIC_ARN;

exports.hook_bounce = function (next, connection) {
    connection.logdebug(util.inspect(connection, false, null));

    const date = new Date();
    const innerMessage = {
        notificationType: "Complaint",
        bounce: {
            bounceType: "Transient",
            bounceSubType: "General",
            bouncedRecipients: connection.todo.rcpt_to.map(function (rcpt_to) {
                return {
                    emailAddress: rcpt_to.address(),
                    action: "failed",
                    status: "UNKNOWN",
                    diagnosticCode: rcpt_to.reason ? rcpt_to.reason : connection.bounce_error
                };
            }),
            timestamp: date.toISOString(),
            feedbackId: "UNKNOWN",
            reportingMTA: "UNKNOWN"
        },
        mail: {
            timestamp: date.toISOString(),
            source: connection.todo.mail_from.original,
            sourceArn: "N/A",
            sourceIp: "UNKNOWN",
            sendingAccountId: "UNKNOWN",
            messageId: connection.todo.uuid,
            destination: connection.todo.rcpt_to.map(function (rcpt_to) {
                return rcpt_to.address();
            })
        }
    };

    connection.logdebug(util.inspect(innerMessage, false, null));

    const sns = new AWS.SNS();
    sns.publish({
        Message: JSON.stringify({default: JSON.stringify(innerMessage)}),
        MessageStructure: 'json',
        TargetArn: bouncesSnsTopicArn
    }, function (err, data) {
        if (err) {
            connection.logerror(err.stack);
        } else {
            connection.lognotice('Bounce sent to Lambda ', util.inspect(data, false, null));
        }
    });

    next(OK);
};
