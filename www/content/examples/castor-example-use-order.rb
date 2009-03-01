#: requires
base_dir = Dir.pwd
path = File.join(base_dir, "content", "examples", "castor-xml-example")
require path
# Starting a new order from scratch
#require 'orders'
#include Orders
#: use
order = Orders.Order do
  reference "FOOBAR-1234"
  client do
    name 'Ford Prefect'
    address do
      street '42 Park Av.'
      city 'small planet'
      zip 17263
      state 'Betelgeuse system'
    end
  end
  item 'RF-1234' do
    description 'improbability drive'
    quantity 3
    unit_price 299.95
  end
  signed_by "Sean"
end
puts order.to_xml
#: output
