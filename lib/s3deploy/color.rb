module S3deploy
  module Color
    ANSI_COLOR = { red: 31, green: 32, yellow: 33 }

    def colorize(color, text)
      if STDOUT.tty?
        "\e[#{ANSI_COLOR[color.to_sym]}m#{text}\e[0m"
      else
        text
      end
    end
  end
end
