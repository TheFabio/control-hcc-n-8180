require 'socket'

@soc = TCPSocket.new("192.168.0.105", 5000)
sleep(1) # the device is a little slow to wakeup

def set_relay_state(relay_number, on)
  @relay_state = nil

  def loop_body
    while true
      msg, _ = @soc.recvmsg(100)

      if msg[0..4] == "relay"
        @relay_state = msg[-8..-1].chars.reverse.map(&:to_i)
      end
    end
  end

  tt = Thread.start { loop_body }

  expiry = Time.now + 1
  test_result =  on ? 1 : 0

  while Time.now < expiry && (@relay_state.nil? || @relay_state[relay_number-1] != test_result)
    if on
      @soc.sendmsg("on#{relay_number}:00")
    else
      @soc.sendmsg("off#{relay_number}")
    end

    sleep(0.01)
    @soc.sendmsg("read")
    sleep(0.01)
  end

  tt.exit
end

def set_on(relay_number)
  set_relay_state(relay_number, true)
end

def set_off(relay_number)
  set_relay_state(relay_number, false)
end


# this tests all relays

(1..8).each do |number|
  set_on(number)
end

sleep(3)

(1..8).each do |number|
  set_off(number)
end

