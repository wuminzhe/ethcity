class BaseHandler
  attr_accessor :config
  def initialize
    @config = Currency.find_by_symbol(self.class.name.upcase[0 .. 2])
  end
end
