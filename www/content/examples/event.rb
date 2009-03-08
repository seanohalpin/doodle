class Event < Doodle
  BASE_DATE = Date.civil(2008, 1, 1)
  has :start_date, :kind => Date do
    default { Date.today }
    must "be >= #{BASE_DATE}" do |value|
      value >= BASE_DATE
    end
  end
  has :end_date, :kind => Date do
    default { start_date }
  end

  must "have end_date >= start_date" do
    end_date >= start_date
  end
end
