# msgpack-inspect

This is a command line tool to inspect/show a data serialized by [MessagePack](http://msgpack.org/).

## Installation

Executable binary files are available from [releases](https://github.com/tagomoris/msgpack-inspect/releases). Download a file for your platform, and use it.

Otherwise, you can install rubygem version on your CRuby runtime:

    $ gem install msgpack-inspect

## Usage

```
Usage: msgpack-inspect [options] FILE

Options:

    -f, --format FORMAT              output format of inspection result (yaml/json/jsonl) [default: yaml]
    -r, --require LIB                ruby file path to require (to load ext type definitions)
    -v, --version                    Show version of this software
    -h, --help                       Show this message
```

`-r` option is available oly with rubygem version, and unavailable with mruby binary release.

FILE is a file which msgpack binary stored. Specify `-` to inspect data from STDIN.
This command shows the all data contained in specified format (YAML in default).

```
---
- format: "false"
  header: "0xc2"
  data: "0xc2"
  value: false
- format: "true"
  header: "0xc3"
  data: "0xc3"
  value: true
```

## Example

This is an example to inspect a data from STDIN.
The data corresponds to `{"compact":true,"schema":0}` in JSON.

```
$ printf "\x82\xa7compact\xc3\xa6schema\x00" | msgpack-inspect -
---
- format: "fixmap"
  header: "0x82"
  length: 2
  children:
    - key:
        format: "fixstr"
        header: "0xa7"
        length: 7
        data: "0x636f6d70616374"
        value: "compact"
      value:
        format: "true"
        header: "0xc3"
        data: "0xc3"
        value: true
    - key:
        format: "fixstr"
        header: "0xa6"
        length: 6
        data: "0x736368656d61"
        value: "schema"
      value:
        format: "fixint"
        header: "0x00"
        data: "0x00"
        value: 0
```

TODO: show more example

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/tagomoris/msgpack-inspect].

