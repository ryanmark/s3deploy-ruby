module S3deploy
  class Color
    class << self
      def green(text)
        self.new(32).wrap(text)
      end

      def yellow(text)
        self.new(33).wrap(text)
      end
    end

    def initialize(color)
      @color = color
    end

    def wrap(text)
      "\e[#{@color}m#{text}\e[0m"
    end
  end
end
