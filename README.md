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
- :format: :false
  :header: c2
  :data: c2
  :value: false
- :format: :true
  :header: c3
  :data: c3
  :value: true
```

## Example

This is a example to inspect a data from STDIN.
The data corresponds to `{"compact":true,"schema":0}` in JSON.

```
$ printf "\x82\xa7compact\xc3\xa6schema\x00" | msgpack-inspect -
---
- :format: :fixmap
  :header: '82'
  :length: 2
  :children:
  - :key:
      :format: :fixstr
      :header: a7
      :length: 7
      :data: 636f6d70616374
      :value: compact
    :value:
      :format: :true
      :header: c3
      :data: c3
      :value: true
  - :key:
      :format: :fixstr
      :header: a6
      :length: 6
      :data: 736368656d61
      :value: schema
    :value:
      :format: :fixint
      :header: '00'
      :data: '00'
      :value: 0
```

TODO: show more example

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/tagomoris/msgpack-inspect].

