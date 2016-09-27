def show_usage
  msg = <<-EOL
Usage: msgpack-inspect [options] FILE"

Options:
  -f, --format FORMAT   Output format of inspection result (yaml/json) [default: yaml]
  -r, --require LIB     (Not supported in binary executable)
  -h, --help            Show this message
  -v, --version         Show version of this software
EOL
  puts msg
end

def __main__(argv)
  # argv includes $0 in mruby
  argv.shift
  format = :yaml
  filename = nil

  parsing_option = true
  while parsing_option && !argv.empty?
    case argv[0]
    when '-f', '--format'
      argv.shift
      format = argv.shift.to_sym
    when '-r', '--require'
      show_usage
      raise "This release doesn't support -r/--require option."
    when '-h', '--help'
      show_usage
      return
    when '-v', '--version'
      puts "msgpack-inspect #{MessagePack::Inspect::VERSION} (mruby binary)"
      return
    else
      arg = argv.shift
      if arg == '--'
        parsing_option = false
      elsif arg.start_with?('-')
        show_usage
        raise "Unknown option specified: #{arg}"
      else
        filename = arg
        parsing_option = false
      end
    end
  end
  if !filename && argv.size > 0
    filename = argv.shift
  end
  if !filename
    show_usage
    raise "Input file path not specified."
  end

  io = if filename == '-'
         STDIN
       else
         File.open(filename, 'rb')
       end
  unless MessagePack::Inspect::FORMATS.include?(format)
    show_usage
    raise "Unsupported format: #{format}"
  end
  puts MessagePack::Inspect.inspect(io).dump(format)
end