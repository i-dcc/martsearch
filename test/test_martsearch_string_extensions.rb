class TestMartSearchStringExtensions < Test::Unit::TestCase
  context "A String" do
    setup do
      @string  = "MGKKQNKKKVEEVLEEEEEEYVVEKVLDRRVVKGKVEYLLKWKGFSDQKSHEALPGVWSQSGLLELLTPVESSCS*"
      @strings = {
        "MGKKQNKKKVEEVLEEEEEEYVVEKVLDRRVVKGKVEYLLKWKGFSDQKSHEALPGVWSQSGLLELLTPVESSCS*" => {
          10 => "MGKKQNKKKV\nEEVLEEEEEE\nYVVEKVLDRR\nVVKGKVEYLL\nKWKGFSDQKS\nHEALPGVWSQ\nSGLLELLTPV\nESSCS*",
          30 => "MGKKQNKKKVEEVLEEEEEEYVVEKVLDRR\nVVKGKVEYLLKWKGFSDQKSHEALPGVWSQ\nSGLLELLTPVESSCS*",
          80 => "MGKKQNKKKVEEVLEEEEEEYVVEKVLDRRVVKGKVEYLLKWKGFSDQKSHEALPGVWSQSGLLELLTPVESSCS*"
        },
        "" => { 10 => "", 30 => "", 80 => "" }
      }
    end

    should "wrap with the defaults" do
      assert_equal( @string, @string.wrap )
    end

    should "not throw any exceptions" do
      assert_nothing_raised do
        @string.wrap
      end
    end

    should "wrap as expected" do
      @strings.each_key do |string|
        @strings[string].each do |width, expected|
          assert_equal( expected, string.wrap( width ) )
        end
      end
    end
  end
end
