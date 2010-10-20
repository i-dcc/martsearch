class Marker
  def self.mark(msg)
    start = Time.now
    puts "######## #{start} --> starting #{msg} from #{caller[2]}:#{caller[1]}"
    result = yield
    finish = Time.now
    puts "######## #{finish} --< finished #{msg} --- #{"%2.3f sec" % (finish - start)}"
    result
  end
end