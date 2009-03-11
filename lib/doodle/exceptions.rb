class Doodle
  # error handling
  @@raise_exception_on_error = true
  def self.raise_exception_on_error
    @@raise_exception_on_error
  end
  def self.raise_exception_on_error=(tf)
    @@raise_exception_on_error = tf
  end

  # internal error raised when a default was expected but not found
  class NoDefaultError < Exception
  end
  # raised when a validation rule returns false
  class ValidationError < Exception
  end
  # raised when an unknown parameter is passed to initialize
  class UnknownAttributeError < Exception
  end
  # raised when a conversion fails
  class ConversionError < Exception
  end
  # raised when arg_order called with incorrect arguments
  class InvalidOrderError < Exception
  end
  # raised when try to set a readonly attribute after initialization
  class ReadOnlyError < Exception
  end
end
