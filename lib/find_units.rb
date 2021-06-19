require 'socket'

## this is not working... need to:
# send 255 broadcast packages to port 65535 with the content
# *.SEARCH:
# where "*" is a number from 0 to 255
#
# listen to local port 65534 for a UDP response
#
# if he unit is found messages in this shape will be received:
#
# ["\xC0\xA8\x00\x01\xFF\xFF\xFF\x00\xC0\xA8\x00s\xC0\xA8\x00d\x13\x88\x13\x88\x00\x00\x01\b\bHS\x00WU\x00\nHHC-N-8I8O\x00\x00\x00\x00\x00\x11", ["AF_INET", 65535, "192.168.0.115", "192.168.0.115"]]
#

@received = []

def loop_body
  thread_socket = UDPSocket.new
  thread_socket.bind('', 65534)

  while true
    @received << thread_socket.recvfrom(100)
  end
end

tt = Thread.start { loop_body }
sleep(0.01)
socket = UDPSocket.new

socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true )
(0..255).each do |i|
  socket.send("#{i}.SEARCH:", 0, "<broadcast>", 65535)
  sleep(0.01)
end

# 2 seconds just to make sure the message is saved before we kill the background thread
sleep(2)
tt.exit

def to_hex(num)
  num.to_s(16).rjust(2, "0")
end

def find_mode(num)
  if num == 0
    "TCP Service" # you can send commands to the unit via TCP connection
  elsif num == 1
    "TCP Client"
  elsif num == 2
    "UDP"
  else
    "Unknown = #{num}"
  end
end

def decode_msg(raw_msg)
  bytes = raw_msg.bytes

  message = {
    gateway: bytes[0..3].join('.'),
    mask: bytes[4..7].join('.'),
    local_ip_address: bytes[8..11].join('.'),
    destination_ip_address: bytes[12..15].join('.'),
    # sometimes byte 16 is something else... so all the remainder become be offset by 1
    local_port: bytes[16..17].map{|b| to_hex(b) }.join.to_i(16),
    destination_port: bytes[18..19].map{|b| to_hex(b) }.join.to_i(16),
    mode: find_mode(bytes[20]),
    heart_beat_time: bytes[21],
    version: bytes[22] + bytes[23] + bytes[24],
    unit_mac_address: bytes[25..30].map{|b| to_hex(b) }.join(':'),
    implementor_name: bytes[31..-1].pack('C*').encode(Encoding::ASCII_8BIT)
  }
  p message
end

if !@received.any?
  p "no device found"
else
  @received.each do |msg|
    p msg
    decode_msg(msg[0])
  end
end
