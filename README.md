# Fluentd TCP capturer

`fluentd-tcp-capturer` is a tool to inspect/dump/handle message to Fluentd TCP input, to:

- debug a message to fluentd from somewhere
- try other configuration on other fluentd node

without changing Fluentd configuration.

## Installation

```shell
$ gem install 'fluentd-tcp-capturer'
```

Then command `fm-cap` becomes available.


## Usage

```shell
Usage: fm-cap [options]
    -d, --device DEVICE              Device name [default: eth0]
    -p, --port PORT                  Fluentd port to capture [default: 24224]
        --forward-host HOST          If set, message will be forwarded to other Fluentd host
        --forward-port PORT          Fluentd port to forward message (used when --forward-host is set)
        --debug                      Set loglevel DEBUG
```

### Dump mode

This mode captures tcp packet to Fluentd, dump it in the terminal.

```shell
# TODO
$ sudo fm-cap
I, [2017-03-03T22:41:31.141436 #14088]  INFO -- : Start capturing lo0/port=24224
2017-03-03 13:41:34 +0000 | tag=test.20170303224134 msg={"name"=>"John", "age"=>15}
2017-03-03 13:41:46 +0000 | tag=test.20170303224145 msg={"name"=>"Michel", "age"=>16}
```

You can specify other network device, also port number of Fluentd.

```shell
$ sudo fm-cap -d lo0
$ sudo fm-cap -p 4567
```

### Transfer mode

This mode captures tcp packet, transfer it to other Fluentd tcp input.

```shell
$ sudo fm-cap --forward-host other-fluentd-node --forward-port 4567
I, [2017-03-03T22:46:31.878876 #14564]  INFO -- : Start capturing lo0/port=24224
I, [2017-03-03T22:46:34.577661 #14564]  INFO -- : Forwarded message to other-fluentd-node:4567
I, [2017-03-03T22:46:41.460288 #14564]  INFO -- : Forwarded message to other-fluentd-node:4567
I, [2017-03-03T22:46:42.461110 #14564]  INFO -- : Forwarded message to other-fluentd-node:4567
```

## TODO

- Support timezone in the dumpped message.
- Dump message over embed Fluend.
- Support other protocol, e.g. UDP
- Tests ...

## Patch

Welcome
