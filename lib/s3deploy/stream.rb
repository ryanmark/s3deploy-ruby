module S3deploy
  # Helper class for buffers
  class Stream < StringIO
    def initialize(*)
      super
      set_encoding 'BINARY'
    end

    def close
      rewind
    end
  end
end
