"use strict";
const util = require('util');
const AWS = require('aws-sdk');
const log = require('./logger');

const dkimRecordName = process.env.DKIM_RECORD_NAME;
const dkimRecordValue = process.env.DKIM_RECORD_VALUE;
const hostedZoneId = process.env.HOSTED_ZONE_ID;

exports.hook_init_master = function (next, connection) {
    const route53 = new AWS.Route53();

    const params = {
        ChangeBatch: {
            Changes: [
                {
                    Action: "CREATE",
                    ResourceRecordSet: {
                        Name: dkimRecordName,
                        ResourceRecords: [
                            {
                                Value: util.format("\"%s\"", dkimRecordValue)
                            }
                        ],
                        TTL: 300,
                        Type: "TXT"
                    }
                }
            ]
        },
        HostedZoneId: hostedZoneId
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
    if (process.pid !== 1) {
        return;
    }

    const route53 = new AWS.Route53();

    const params = {
        ChangeBatch: {
            Changes: [
                {
                    Action: "DELETE",
                    ResourceRecordSet: {
                        Name: dkimRecordName,
                        ResourceRecords: [
                            {
                                Value: util.format("\"%s\"", dkimRecordValue)
                            }
                        ],
                        TTL: 300,
                        Type: "TXT"
                    }
                }
            ]
        },
        HostedZoneId: hostedZoneId
    };

    route53.changeResourceRecordSets(params, function (err, data) {
        if (err) {
            log.logerror(err.stack);
        } else {
            log.lognotice(util.format("DKIM record deleted: %s", JSON.stringify(data)));
        }
    });
}
