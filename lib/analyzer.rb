require 'logger'
require 'pin2dmd_dump'
require 'dimension'

class Analyzer
  class Pin2DMD
    MY_VID = 0x0314
    MY_PID = 0xE457

    def initialize
    end

    def dimensions
      Dimensions.wh(128, 32) # Hard-coded for now
    end

    def open
      # This code is ported from CPP snippet provided here
      #   https://github.com/lucky01/PIN2DMD/issues/21#issuecomment-1200426120
      #
      # It's also checked into this repo for posterity in `misc`
      device = usb.devices(idVendor: MY_VID, idProduct: MY_PID).first
      unless device
        raise "No connected PIN2DMD device"
      end
      device.open_interface(0) do |handle|
        name = handle.string_descriptor_ascii(1)
        unless name == "PIN2DMD"
          raise "Unsupported device: #{name}"
        end
        plane_size = 128 * 32 / 8

        handle.claim_interface(0) do |handle|
          # Dunno whether we need to send the whole 64 bytes but that's what
          # the original code does...
          output = ("\x01\xc3\xe8\x03" + "\x00" * 60).force_encoding(Encoding::ASCII_8BIT)
          f = -> {
            written_bytes = handle.bulk_transfer(endpoint: 0x01, dataOut: output)
            if written_bytes != output.length
              raise "Wrote #{written_bytes.length} of #{output.length} bytes"
            end

            bytes = handle.bulk_transfer(endpoint: 0x81, dataIn: 3 * plane_size)
            time = Time.now.utc.to_f * 1000
            [time.to_i].pack("L<") + bytes
          }
          yield f
        end
      end
    end
  end

  class WPCEmuDump
    def initialize(filename)
      @dump = Pin2DmdDump.from_file(filename)
    end

    def dimensions
      @dump.dimensions
    end

    def open
      frames = @dump.frames.dup
      handle = ->{ frames.shift.bytes }
      yield(handle)
    end
  end

  def run(device: WPCEmuDump.new("data/dm-1p-3ball.raw.gz"))
    logger = Logger.new(STDOUT)
    logger.formatter = ->(_, _,  _, msg) {
      time = Time.now.utc.to_f * 1000
      [time.to_i].pack("L<") + msg
    }
    device.open do |handle|
      while true
        data = handle.call
        break unless data
        frame = Pin2DmdDump::Frame.from_bytes(data, dimensions: device.dimensions, images: 3)
        puts frame.monochrome_image.formatted
        # logger.info(data)
        sleep 0.1
      end
    end
  end
end
