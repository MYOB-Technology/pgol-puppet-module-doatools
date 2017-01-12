Puppet::Functions.create_function('make_cidr') do
  def make_cidr(cidr, index, total)
     cidr_array = cidr.split("/")
     cidr_base = cidr_array[0]
     cidr_range = cidr_array[1]

    # Convert the cidr_base into a number.
    cidr_integer = cidr_base.split(".").map(&:to_i).reduce(0) { |sum, num| (sum << 8) + num }

    # Calculate the size of each cidr.
    bitshift = 0
    loop do
      offset = 1 << bitshift
      break unless offset < total
      bitshift += 1
    end

    new_cidr_size = cidr_range.to_i + bitshift
    new_base = cidr_integer + (index << (32 - new_cidr_size))

    (new_base >> 24).to_s + "." + (new_base >> 16 & 0xFF).to_s + "." + (new_base >> 8 & 0xFF).to_s + "." + (new_base & 0xFF).to_s + "/" + new_cidr_size.to_s
  end
end
