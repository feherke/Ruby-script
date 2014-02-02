
require_relative 'logger'

# default logger : writes to STDOUT messages of level INFO and above
$log = Logger.new

# this will be logged
$log.log Logger::INFO, "Hello World !"

# this not as message's level is inferior to logger's level
$log.debug "Waiting for response..."

# but if we adjust the level...
$log.level = Logger::TRACE

# ... then DEBUG messages will also be logged
$log.debug "Loosing my patience..."

# or we can adjust the log line format
$log.logformat = "on %d{%d %B at %H:%M} the %x running with PID %p generated exception %e with message %m"

# and can log unconditionally, without specifying a message level
$log << "Goodbye, cruel World :("

# after a caught exception the %e placehold will have a value
0 / 0 rescue $log << "Goodbye again :(("

# but not in the later message
$log << "That's All Folks"

# well, not really necessary if you log to STDOUT, but a good practice
$log.close
