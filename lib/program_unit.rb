require 'socket'

# be sure to fill in all the data from the uni before this is sent

configuration = {
  current_ip_address: "192.168.0.105", #must be the unit's current ip address

  gateway: "192.168.0.1",
  mask: "255.255.255.0",
  local_ip_address: "192.168.0.105",
  destination_ip_address: "192.168.0.100",
  local_port: 5000,
  destination_port: 5000,
  mode: 0, # check the find_unit pack for the other mode options
  heart_beat_time: 0,
  unit_mac_address: "48:53:00:57:55:00",
  implementor_name: "HHC-N-8I8O",  # up to 15 chars no spaces
}

def encode_ip_address(ip_address)
  ip_address.split('.').map{|s| s.to_i}
end

def encode_port(port)
  hex = port.to_s(16)
  [hex[0..1].to_i(16), hex[2..3].to_i(16)]
end


def encode_msg(msg)
  current_ip = encode_ip_address(msg[:current_ip_address])
  bytes = current_ip[3].to_s.bytes
  bytes += ".SETND:".bytes
  bytes += encode_ip_address(msg[:gateway]) #0..3
  bytes += encode_ip_address(msg[:mask]) #4..7
  bytes += encode_ip_address(msg[:local_ip_address]) #8..11
  bytes += encode_ip_address(msg[:destination_ip_address]) #12..15
  bytes += encode_port(msg[:local_port]) #16..17
  bytes += encode_port(msg[:destination_port]) #18..19
  bytes << msg[:mode] #20
  bytes << msg[:heart_beat_time] #21
  bytes += [1, 8, 8] #22..24 (version 17)
  bytes += msg[:unit_mac_address].split(':').map{|s| s.to_i(16)} #25..30
  bytes << 10 # start of string
  bytes += msg[:implementor_name].bytes

  bytes.pack('C*')
end

msg = encode_msg(configuration)

@socket = UDPSocket.new

@socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true )
@socket.bind('', 65534)
@socket.send(msg, 0, "<broadcast>", 65535)
def loop_body
  while true
    @confirmation = @socket.recvfrom(100)
  end
end

tt = Thread.start { loop_body }
# 2 seconds just to make sure the message is saved before we kill the background thread
sleep(5)
tt.exit

p "response:\n#{@confirmation}"
