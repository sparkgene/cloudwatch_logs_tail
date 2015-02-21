# cloudwatch_logs_tail

Setup
=====

Requirements:
* [AWS SDK for Ruby](http://aws.amazon.com/sdk-for-ruby/)
* An Amazon AWS account with [Amazon CloudWatch](https://aws.amazon.com/cloudwatch/) and [CloudWatch Logs](http://aws.amazon.com/cloudwatch/) setup and enabled.

Usage
=====

```
% ruby tail_cwlog.rb --help

Usage: tail_cwlog [options]
        --use-iamrole                USE IAM ROLE
        --aws-region=[VALUE]         AWS REGION
        --aws-access-key=[VALUE]     AWS ACCESS KEY
        --aws-secret-key=[VALUE]     AWS SECRET KEY
        --discribe-groups            Describe log groups
        --discribe-streams           Describe log streams
        --tailf                      tail -f log stream
        --tail=[VALUE]               tail log stream
        --log-group=[VALUE]          log group name
        --log-stream=[VALUE]         log stream name
```

### describe Log Groups
```
% ruby tail_cwlog.rb --aws-region=ap-northeast-1 --discribe-groups

/var/log/cron
/var/log/maillog
/var/log/messages
/var/log/secure
```

### describe Log Streams
```
% ruby tail_cwlog.rb --aws-region=ap-northeast-1 --discribe-streams --log-group=/var/log/cron

server-apps-1
server-apps-2
server-apps-3
```

### discover old logs like `tail -100`
```
% ruby tail_cwlog.rb --aws-region=ap-northeast-1 --discribe-streams --log-group=/var/log/cron --log-stream=server-apps-3 --tail=100

Feb 21 01:22:01 server-apps-3 CROND[2837]: (root) CMD (/var/awslogs/bin/awslogs-nanny.sh > /dev/null 2>&1)
Feb 21 01:23:01 server-apps-3 CROND[2863]: (root) CMD (/var/awslogs/bin/awslogs-nanny.sh > /dev/null 2>&1)
Feb 21 01:24:01 server-apps-3 CROND[2890]: (root) CMD (/var/awslogs/bin/awslogs-nanny.sh > /dev/null 2>&1)
snip
```

### `tail -f` Log Stream
```
% ruby tail_cwlog.rb --aws-region=ap-northeast-1 --discribe-streams --log-group=/var/log/cron --log-stream=server-apps-3 --tailf

Feb 21 01:22:01 server-apps-3 CROND[2837]: (root) CMD (/var/awslogs/bin/awslogs-nanny.sh > /dev/null 2>&1)
Feb 21 01:23:01 server-apps-3 CROND[2863]: (root) CMD (/var/awslogs/bin/awslogs-nanny.sh > /dev/null 2>&1)
Feb 21 01:24:01 server-apps-3 CROND[2890]: (root) CMD (/var/awslogs/bin/awslogs-nanny.sh > /dev/null 2>&1)
```
`--tailf` option shows latest 20 logs for default.
Logs are checked at 5-second intervals.(because short interval generate many requests)
Enter `ctrl + c` to abort.

# Caution
This script downloads many log data from CloudWatch.
Please be careful to overuse.

http://aws.amazon.com/cloudwatch/pricing/
> Data Transfer OUT from CloudWatch Logs is priced equivalent to the “Data Transfer OUT from Amazon EC2 To” and “Data Transfer OUT from Amazon EC2 to Internet” tables on the [EC2 Pricing Page](http://aws.amazon.com/ec2/pricing/).
