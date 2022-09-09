# This is an attempt to port interfaceUSB.cpp because I don't really know how
# to compile that, and I want ruby eventually anyway.  Can't test it until I
# get hardware...

require 'libusb'
require 'logger'

$logger = Logger.new(STDOUT)

MY_VID = 0x0314
MY_PID = 0xE457

usb = LIBUSB::Context.new
# usb.devices.each do |d|
#   p d
# end
# exit
device = usb.devices(idVendor: MY_VID, idProduct: MY_PID).first

unless device
  $logger.error "no matching device found, dumping detected devices:"
  usb.devices.each do |d|
    $logger.info "0x%04x/0x%04x" % [d.idVendor, d.idProduct]
  end
  exit
end

device.open_interface(0) do |handle|
  name = handle.string_descriptor_ascii(1)
  $logger.info "Device name: #{name}"
  case name
  when "PIN2DMD" then 2
  when "PIN2DMD XL" then 3
  when "PIN2DMD HD" then 4
  else 1 end

  planeSize = 128 * 32 / 8

  handle.claim_interface(0) do |handle|
    output = "\x01\xc3\xe8\x03" # TODO: Maybe this needs to be 64 bytes long?
    writtenBytes = handle.bulk_transfer(endpoint: 0x01, dataOut: output)
    if writtenBytes != output.length
      $logger.error "Wrote #{writtenBytes.length} of #{output.length} bytes"
      raise
    end

    readBytes = handle.bulk_transfer(endpoint: 0x81, dataIn: 3 * planeSize)

    $logger.info "Read dump:\n" + readBytes.inspect

    header = "RAW\x00\x01\x80\x20\x03\x00\x00\x00\x00".force_encoding(Encoding::ASCII_8BIT)
    body = header + readBytes
    puts body.length
    File.open("dump.raw", "w", encoding: 'ascii-8bit') {|f| f.write(body) }
  end
end
