###Starting a new order from scratch
  o = Order.new
  => #<Order:0xb7c53dcc @signatures=[]>
  # attributes with default values (here: signatures) are set
  # automatically

  xml=o.save_to_xml
  XML::MappingError: no value, and no default value, for attribute: reference
        from ../lib/xml/../xml/mapping/base.rb:696:in `obj_to_xml'
        from ../lib/xml/../xml/mapping/base.rb:217:in `fill_into_xml'
        from ../lib/xml/../xml/mapping/base.rb:216:in `each'
        from ../lib/xml/../xml/mapping/base.rb:216:in `fill_into_xml'
        from ../lib/xml/../xml/mapping/base.rb:228:in `save_to_xml'
  # can't save as long as there are still unset attributes without
  # default values

  o.reference = "FOOBAR-1234"

  o.client = Client.new
  o.client.name = 'Ford Prefect'
  o.client.home_address = Address.new
  o.client.home_address.street = '42 Park Av.'
  o.client.home_address.city = 'small planet'
  o.client.home_address.zip = 17263
  o.client.home_address.state = 'Betelgeuse system'

  o.items={'XY-42' => Item.new}
  o.items['XY-42'].descr = 'improbability drive'
  o.items['XY-42'].quantity = 3
  o.items['XY-42'].unit_price = 299.95

  xml=o.save_to_xml
  xml.write($stdout,2)
