
module HandType
  class TwoPair < Base

    def handles?
      has_two_pair?
    end

    def rank
      2
    end

    def value
      highestSameValue 2
    end

    private

    def has_two_pair?
      pair_count = 0
      last_value = 0
      @cards.each do |card|
        if card.value == last_value
          pair_count += 1
        end
        last_value = card.value
      end
      return pair_count == 2
    end

  end
end