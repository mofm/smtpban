# smtpban

This script parse from postfix log file which are trying to authenticate with bad credentials.
smtpban.sh script parse and write all ip addresses to a file(*blocked_ips file*). You can use this file for your preferred method.

## Usage

* You need to set time interval and authentication failed counts. You can change these values with environment variables.

eg: last 30 minutes and 3 authentication failed attempts

```bash
$ PARSED_MINS="30 minutes ago" PARSED_COUNTS=3 /the/path/smtpban.sh
```

* You can use this script with cronjob. For example, you can run this script every 30 minutes and 3 authentication failed attempts.

```bash
$ crontab -e
*/30 * * * * PARSED_MINS="30 minutes ago" PARSED_COUNTS=3 /the/path/smtpban.sh
```

or you can run multiple cronjobs with different values.

```bash
$ crontab -e
*/30 * * * * PARSED_MINS="30 minutes ago" PARSED_COUNTS=3 /the/path/smtpban.sh
0 * * * * PARSED_MINS="60 minutes ago" PARSED_COUNTS=5 /the/path/smtpban.sh
```

* if you want to collect ip addresses on git repository,  you need to set git remote address.

```bash
git_remote="your_git_remote_address"
```

> **_Note:_** My usage is to collect ip addresses on git repository and use this file for application firewall. You can use this file for your preferred method. Example, you can use this file for postfix check_client_access parameter.

