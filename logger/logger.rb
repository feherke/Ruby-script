
require 'date'

=begin rdoc
Logger class tailored for personal taste.

It has more formatting options then the core Logger class, plus some minor features.

There is no intention to replicate the Java Logger functionalities. The goal was to make it easy to use.
=end
class Logger

# Logging levels and their suggested use :

# Not for regular use, this level is set as the result of misconfiguration.
  UNKNOWN = 0
# The application's integrity was compromised and crash is imminent.
  FATAL = 1
# It is so bad, that processing can not go forward.
  ERROR = 2
# Something looks strange, but can be corrected or overriden.
  WARN = 3
# Just notifications of regular events, not at technical level.
  INFO = 4
# Detail useful only when actually looking for something wrong.
  DEBUG = 5
# Huge amount of details, kind of poor man's step-by-step execution.
  TRACE = 6

# Human readable names of the logging levels.
  LEVEL = %w{UNKNOWN FATAL ERROR WARN INFO DEBUG TRACE}

# Output device where the log messages are written.
  attr_reader :device
# Current logging level, only messages with this or higher level are logged.
  attr_reader :level
# Format string for the log file name. It can contain +strftime+ conversion specifiers.
  attr_accessor :fileformat
# Format string for the log lines. It can contain placeholders described at formatmessage.
  attr_accessor :logformat

=begin rdoc
Creates a new logger instance.

_device_:: Log destination. Can be a file name or an +IO+ stream.
_level_:: Logging level. Can be *UNKNOWN*, *FATAL*, *ERROR*, *WARN*, *INFO*, *DEBUG*, *TRACE*, defaults to *INFO*. Can also be specified as string.
=end
  def initialize device = STDOUT, level = INFO
    self.level = level
    @logformat = '%d{%Y-%m-%d %H:%M:%S}%t%L%t%m %s %e'
    @placeholder = {
      'n' => "\n",
      'p' => $$,
      't' => "\t",
      'x' => File.basename($0),
      'X' => File.expand_path($0)
    }

    @filename = nil
    if device.kind_of? IO then
      raise "log destination already closed #{ device }" if device.closed?
      @device = device
      @fileformat = nil
    else
      @device = nil
      @fileformat = device.to_s
      reopen
    end

    @sign = @mark = false
  end

=begin rdoc
Changes the logging level.

_level_:: Logging level. Can be *FATAL*, *ERROR*, *WARN*, *INFO*, *DEBUG*, *TRACE*, defaults to *UNKNOWN*.
=end
  def level= level
    if (0..6).include? level then @level = level
    elsif LEVEL.include? level.to_s then @level = LEVEL.index level
    else @level = UNKNOWN
    end
  end

=begin rdoc
Writes a message to the log device.

_level_:: Message's logging level. If is greater then the instance's logging level, will not be processed.
_message_:: Message part of the log line. Will appear where the +%m+ placeholder indicates.
=end
  def log level, message; write level, message, caller[0] unless level > @level end

=begin rdoc
Lazy logging at the highest level.
Only in case you are not willing to pay attention to tell apart the messages of various levels.

_message_:: Message part of the log line. Will appear where the +%m+ placeholder indicates.
=end
  def << message; write UNKNOWN, message, caller[0] end

=begin rdoc
Log the message with level set to *FATAL*.

_message_:: Message part of the log line. Will appear where the +%m+ placeholder indicates.
=end
  def fatal message; write FATAL, message, caller[0] unless level > @level end

=begin rdoc
Log the message with level set to *ERROR*.

_message_:: Message part of the log line. Will appear where the +%m+ placeholder indicates.
=end
  def error message; write ERROR, message, caller[0] unless level > @level end

=begin rdoc
Log the message with level set to *WARN*.

_message_:: Message part of the log line. Will appear where the +%m+ placeholder indicates.
=end
  def warn message; write WARN, message, caller[0] unless level > @level end

=begin rdoc
Log the message with level set to *INFO*.

_message_:: Message part of the log line. Will appear where the +%m+ placeholder indicates.
=end
  def info message; write INFO, message, caller[0] unless level > @level end

=begin rdoc
Log the message with level set to *DEBUG*.

_message_:: Message part of the log line. Will appear where the +%m+ placeholder indicates.
=end
  def debug message; write DEBUG, message, caller[0] unless level > @level end

=begin rdoc
Log the message with level set to *TRACE*.

_message_:: Message part of the log line. Will appear where the +%m+ placeholder indicates.
=end
  def trace message; write TRACE, message, caller[0] unless level > @level end

=begin rdoc
Unconditionally writes an unformatted message to the log device.

_message_:: Message to be written as is.
=end
  def plain message
    reopen unless @filename == nil

    @device.print message + "\n"
  end

=begin rdoc
Log each item of an array as separate messages.

_level_:: Messages' logging level. If is greater then the instance's logging level, will not be processed.
_message_:: +Array+ of messages.
=end
  def multi level, message
    return if level>@level

    caller0 = caller[0]
    if message.kind_of? Array then message.each { |one| write level, one, caller0 }
    else log level, message, caller0
    end
  end

=begin rdoc
Closes the log destination device.
=end
  def close
    return if @fileformat == nil

    @device.close unless @device == nil || @device.closed?
  end

private

=begin rdoc
Reopen the log file if needed.

Needed means, either the log file is not open, or the file name format forces a rotation.

If an IO stream was passed to log into, does nothing.
=end
  def reopen
    return if @fileformat == nil

    newname = DateTime.now.strftime @fileformat
    return if @filename == newname && File.exist?(@filename)

    @filename = newname
    @device.close unless @device == nil || @device.closed?
    @device = File.new @filename, 'a'
    @device.sync = true
#    @device.print "-- log file #{ @filename } opened by #{ File.expand_path($0) } as ##{ $$ } on #{ DateTime.now.strftime '%Y-%m-%d %H:%M:%S' } --\n"
  end

=begin rdoc
Formats the message part of the log line by replacing the placeholders, then writes it out.

_level_:: Level to be used for the +%l+ and +%L+ placeholders.
_message_:: Message to be used for the +%m+ placeholder.
_callline_:: Call stack top item to be used for the +%c+ placeholder.

The placeholders can be the following :
*%c*:: caller
*%d*:: DateTime, may be called with parameter as *%d{format}*. The _format_ parameter is a strftime format string.
*%e*:: Exception
*%l*:: level number
*%L*:: level name
*%m*:: message, may be called with parameter as *%m{case}*. The _case_ parameter is *capitalize*, *downcase*, *swapcase*, *upcase*.
*%n*:: New Line
*%p*:: PID
*%s*:: error line
*%S*:: error stack, may be called with parameter as *%S{separator}*. The _separator_ is the separator between stack lines.
*%t*:: Horizontal Tab
*%x*:: executable file
*%X*:: executable path
=end
  def write level, message, callline
    placeholder = {
      'c' => callline,
      'd' => DateTime.now,
      'e' => $!,
      'l' => level,
      'L' => LEVEL[level],
      'm' => message,
      's' => $@ ? $@[0] : nil,
      'S' => $@
    }
    placeholder.merge! @placeholder

    reopen unless @filename == nil

    clear = false
    line = @logformat.gsub(/%(?:(.)(?:\{(.*?)\})?)/m) do
      clear = true if 'esS'[$1] != nil
      ($2 == nil || placeholder[$1] == nil) ? placeholder[$1] : case $1
        when 'd' then placeholder[$1].strftime $2
        when 'm' then placeholder[$1].send $2 if ['capitalize', 'downcase', 'swapcase', 'upcase'].include? $2
        when 'S' then $2 + placeholder[$1].join($2)
      end
    end

# throws error in Ruby 1.9.2 "$! is a read-only variable"
#    $! = $@ = nil if clear and $! != nil

    @device.print line + "\n"
  end
end
