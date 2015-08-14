module S3deploy
  class Color
    class << self
      def green(text)
        new(32).wrap(text)
      end

      def yellow(text)
        new(33).wrap(text)
      end
    end

    def initialize(color)
      @color = color
    end

    def wrap(text)
      if STDOUT.tty?
        "\e[#{@color}m#{text}\e[0m"
      else
        text
      end
    end
  end
end
