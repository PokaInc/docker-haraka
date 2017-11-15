"use strict";
const util = require('util');
const AWS = require('aws-sdk');
const log   = require('./logger');

exports.hook_init_master = function (next, connection) {
    var route53 = new AWS.Route53();

    var params = {
        ChangeBatch: {
            Changes: [
                {
                    Action: "CREATE",
                    ResourceRecordSet: {
                        Name: process.env.DKIM_RECORD_NAME,
                        ResourceRecords: [
                            {
                                Value: util.format("\"%s\"", process.env.DKIM_RECORD_VALUE)
                            }
                        ],
                        TTL: 300,
                        Type: "TXT"
                    }
                }
            ]
        },
        HostedZoneId: process.env.HOSTED_ZONE_ID
    };

    route53.changeResourceRecordSets(params, function (err, data) {
        if (err) {
            connection.logerror(err.stack);
        } else {
            connection.lognotice('DKIM record created ', JSON.stringify(data));
        }
    });

    next();
};

// Graceful shutdown only happens when receiving a SIGINT
process.on('SIGTERM', function () {
    process.kill(process.pid, 'SIGINT');
});

exports.shutdown = () => {
    // Leave the record cleanup to the main process
    if(process.pid !== 1) {
        return;
    }

    var route53 = new AWS.Route53();

    var params = {
        ChangeBatch: {
            Changes: [
                {
                    Action: "DELETE",
                    ResourceRecordSet: {
                        Name: process.env.DKIM_RECORD_NAME,
                        ResourceRecords: [
                            {
                                Value: util.format("\"%s\"", process.env.DKIM_RECORD_VALUE)
                            }
                        ],
                        TTL: 300,
                        Type: "TXT"
                    }
                }
            ]
        },
        HostedZoneId: process.env.HOSTED_ZONE_ID
    };

    route53.changeResourceRecordSets(params, function (err, data) {
        if (err) {
            log.logerror(err.stack);
        } else {
            log.lognotice(util.format("DKIM record deleted: %s", JSON.stringify(data)));
        }
    });
}