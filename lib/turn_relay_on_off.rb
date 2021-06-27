require 'socket'

@soc = TCPSocket.new("192.168.0.105", 5000)

def loop_body
  while true
    msg, _ = @soc.recvmsg(100)
    p msg
    if msg[0..4] == "relay"
      @relay_state = msg[-8..-1].chars.reverse.map(&:to_i)
    end
  end
end
tt = Thread.start { loop_body }

def set_relay_state(relay_number, on)
  @relay_state = nil

  expiry = Time.now + 1
  test_result =  on ? 1 : 0
  read_counter = 0
  while Time.now < expiry && (@relay_state.nil? || @relay_state[relay_number-1] != test_result)
    if on
      @soc.sendmsg("on#{relay_number}:00")
    else
      @soc.sendmsg("off#{relay_number}")
    end

    sleep(0.01)
    if read_counter%10 == 0
      @soc.sendmsg("read")
      read_counter = 0
    end

    read_counter++
    sleep(0.01)
  end
end

def set_on(relay_number)
  set_relay_state(relay_number, true)
end

def set_off(relay_number)
  set_relay_state(relay_number, false)
end

# this tests "on" and "off" commands
sleep(5)

(1..8).each do |number|
  set_on(number)
end

sleep(3)

(1..8).each do |number|
  set_off(number)
end

#this tests the "all" command
sleep(0.5)
@soc.sendmsg("all11111111")
sleep(0.5)
@soc.sendmsg("all01010101")
sleep(0.5)
@soc.sendmsg("all10101010")
sleep(0.5)
@soc.sendmsg("all00000000")

tt.exit
