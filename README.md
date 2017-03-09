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
        --fluentd-config PATH        Config path for embed Fluentd (must be used with --forward-host/--forward-port)

```

### Dump mode

This mode captures tcp packet to Fluentd, dump it in the terminal.

```shell
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

#### with embed Fluentd

Also embed Fluentd instance will be running by setting config path to `--fluentd-config`.

You can try/debug configuration without running other Fluentd instance.

```shell
# fluentd.conf
#<source>
# @type forward
# port 4567
#</source>
#<match **>
#  @type stdout
#</match>
$ sudo fm-cap --forward-host localhost --forward-port 4567 --fluentd-config=./fluentd.conf
Password:
I, [2017-03-09T09:06:38.356349 #29021]  INFO -- : Starting embed Fluentd config_path='./fluentd.conf'
2017-03-09 09:06:38 +0900 [info]: reading config file path="./fluentd.conf"
2017-03-09 09:06:38 +0900 [info]: starting fluentd-0.14.13 without supervision pid=29021
2017-03-09 09:06:38 +0900 [info]: gem 'fluentd' version '0.14.13'
2017-03-09 09:06:38 +0900 [info]: adding match pattern="**" type="stdout"
2017-03-09 09:06:38 +0900 [info]: adding source type="forward"
2017-03-09 09:06:38 +0900 [info]: using configuration file: <ROOT>
  <source>
    @type forward
    port 4567
  </source>
  <match **>
    @type stdout
  </match>
</ROOT>
2017-03-09 09:06:38 +0900 [info]: starting fluentd worker pid=29021 ppid=29020 worker=0
2017-03-09 09:06:38 +0900 [info]: listening port port=4567 bind="0.0.0.0"
2017-03-09 09:06:38 +0900 [info]: fluentd worker is now running worker=0
2017-03-09 09:06:38.585371000 +0900 fluent.info: {"worker":0,"message":"fluentd worker is now running worker=0"}
I, [2017-03-09T09:06:39.363509 #29021]  INFO -- : Start capturing lo0/port=24224 other-fluentd-node:4567
I, [2017-03-09T09:07:36.201729 #29021]  INFO -- : Forwarded message to localhost:4567
2017-03-09 09:07:34.119623000 +0900 test.20170309090731: {"name":"George","age":21}
I, [2017-03-09T09:07:37.203102 #29021]  INFO -- : Forwarded message to localhost:4567
2017-03-09 09:07:36.201292000 +0900 test.20170309090735: {"name":"Michel","age":15}
```


## TODO

- Support other protocol, e.g. UDP
- Support debugging also src packet
- Tests ...

## Patch

Welcome
